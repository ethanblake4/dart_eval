part of 'runtime.dart';

typedef _SignatureParameterRelations = ({
  Map<int, int> renames,
  Map<(int, int), int> bounds,
  Set<(int, int)> active,
});

/// The bridge boundary accepts canonical language values. Function signatures
/// prescribe every conversion before entering the typed register loop.
extension TypedRuntimeInterop on Runtime {
  int? _typedTypeId(BridgeTypeSpec spec) {
    final library = _libraryMap[spec.library];
    return library == null ? null : typeIds[library]?[spec.name];
  }

  Object? typedConstant(int index) => _constantPool[index];

  /// Canonicalizes a `const`-context [value]: returns the existing interned
  /// instance whose type and key parts match, or installs [value] as the
  /// canonical one. Interned collections become unmodifiable — a `const`
  /// collection is always frozen.
  ///
  /// Key parts compare by identity for evaluated objects, records, and
  /// collections (nested `const` values intern bottom-up, so identity is
  /// sound), and loosely by `==` for opaque host values. Boxed scalars are
  /// normalized to their payload so `const A(1)` and `const A(1)` share a
  /// key even though each field holds a distinct wrapper.
  Object? internConst(Object? value, int typeId) {
    var v = value;
    var keyTypeId = typeId;
    final List<Object?> key;
    var loose = false;
    switch (v) {
      case TypedInstance():
        // A redirecting const factory can have a different static type from
        // its result. Canonicalize by the instance's actual type.
        keyTypeId = v.$getRuntimeType(this);
        final parts = <Object?>[];
        Object? level = v;
        while (level is TypedInstance) {
          parts.addAll(level.values);
          level = level.superclass;
        }
        key = [for (final part in parts) _constKeyPart(part)];
      case TypedClosure():
        // An instantiated or bound tear-off canonicalizes on its adapter
        // and captures — `f<int>` at separate sites is one value.
        key = [
          v.descriptor.functionId,
          for (final part in v.captures) _constKeyPart(part),
        ];
      case $Record():
        key = [for (final part in v.fields) _constKeyPart(part)];
      case List<Object?>():
        v = List<Object?>.unmodifiable(v);
        key = [for (final part in v) _constKeyPart(part)];
      case Map():
        v = UnmodifiableMapView(TypedCollections.canonicalizeMap(v, this));
        key = [
          for (final entry in v.entries) ...[
            _constKeyPart(entry.key),
            _constKeyPart(entry.value),
          ],
        ];
      case Set():
        v = UnmodifiableSetView(TypedCollections.canonicalizeSet(v, this));
        key = [for (final part in v) _constKeyPart(part)];
      case String():
        // Const strings canonicalize by content: a pooled literal and an
        // interned runtime string of equal content are identical.
        return _constInternedStrings[v] ??= v;
      case $String():
        v = $String(_constInternedStrings[v.$value] ??= v.$value);
        loose = true;
        key = [v.$value];
      default:
        loose = true;
        key = [v];
    }
    final hash = loose
        ? keyTypeId
        : Object.hashAll([
            keyTypeId,
            for (final part in key) identityHashCode(part),
          ]);
    final bucket = _constIntern.putIfAbsent(hash, () => []);
    for (final (existingTypeId, existingKey, existing, existingLoose)
        in bucket) {
      if (existingTypeId != keyTypeId ||
          existingLoose != loose ||
          existingKey.length != key.length) {
        continue;
      }
      var equal = true;
      for (var i = 0; i < key.length; i++) {
        final match = loose
            ? _constLooseEquals(existingKey[i], key[i])
            : identical(existingKey[i], key[i]);
        if (!match) {
          equal = false;
          break;
        }
      }
      if (equal) return existing;
    }
    bucket.add((keyTypeId, key, v, loose));
    return v;
  }

  /// Normalizes a key part: boxed scalars compare by payload, strings by
  /// canonical instance (equal const strings are identical in the host),
  /// collection wrappers by their canonical payload, and everything else by
  /// identity (nested consts are already canonicalized).
  Object? _constKeyPart(Object? part) => switch (part) {
    $int p => p.$value,
    $double p => p.$value,
    $bool p => p.$value,
    $String p => _constKeyPart(p.$value),
    // Boxing a canonical collection can create a fresh bridge wrapper.
    // Its payload carries the constant's identity.
    $List p => p.$value,
    $Map p => p.$value,
    $Set p => p.$value,
    $null() => null,
    String p => _constInternedStrings[p] ??= p,
    TypedClosure p => internConst(p, p.descriptor.runtimeTypeId),
    _ => part,
  };

  /// Loose key equality for opaque values: host `==`, except that two
  /// bare `$Object` wrappers — host objects whose fields are invisible to
  /// the evaluator — canonicalize within the same type id.
  bool _constLooseEquals(Object? left, Object? right) =>
      left is $Value && right is $Value
      ? (left.runtimeType == $Object && right.runtimeType == $Object) ||
            TypedInterop.equals(this, left, right)
      : left == right;

  /// Prepare bridge registrations and runtime-owned globals at a VM entry.
  @pragma('vm:never-inline')
  void prepareTypedRuntime() => _setup();

  @pragma('vm:never-inline')
  bool isTypedValueType(Object? value, int expected) {
    if (expected < 0 || expected >= _typeDescriptors.length) return true;
    final expectedDescriptor = _typeDescriptors[expected];
    final expectedNominal = expectedDescriptor[0];
    if (expectedNominal == _dynamicTypeId || expectedNominal == _voidTypeId) {
      return true;
    }
    if (value == null || value is $null) {
      return _acceptsNullType(expected);
    }
    // Every non-null value satisfies Object. Host bridge values may be opaque
    // and unable to report a runtime type, so accept before reifying.
    if (expectedNominal == _objectTypeId && expectedDescriptor.length == 2) {
      return true;
    }
    // Generated MapEntry wrappers expose a nominal runtime type. Check their
    // payload when the destination expects instantiated key/value arguments.
    if (expectedNominal == lookupType(CoreTypes.mapEntry) &&
        expectedDescriptor.length >= 4 &&
        value is $Value &&
        value.$reified is MapEntry) {
      final entry = value.$reified as MapEntry;
      return isTypedValueType(wrapAlways(entry.key), expectedDescriptor[2]) &&
          isTypedValueType(wrapAlways(entry.value), expectedDescriptor[3]);
    }
    final actual = (value as $Value).$getRuntimeType(this);
    return _isSubtypeMemoized(actual, expected, null);
  }

  /// Reuse subtype answers across alternating argument types as well as
  /// repeated scalar checks. Owner types and the type-table version are part
  /// of the contract; callable type arguments use the uncached path.
  bool _isSubtypeMemoized(int actual, int expected, int? actualOwnerType) {
    if (actual == expected) return true;
    if (_subtypeMemoVersion == _typeTableVersion &&
        actual == _subtypeMemoActual &&
        expected == _subtypeMemoExpected &&
        actualOwnerType == _subtypeMemoOwner) {
      return _subtypeMemoResult;
    }
    if (_subtypeMemoVersion != _typeTableVersion) _subtypeCache.clear();
    final key = (actual, expected, actualOwnerType);
    var result = _subtypeCache[key];
    if (result == null) {
      result = _isTypedDescriptorSubtypeInEnvironment(
        actual,
        expected,
        actualOwnerType,
        const [],
      );
      if (_subtypeCache.length == 256) _subtypeCache.clear();
      _subtypeCache[key] = result;
    }
    _subtypeMemoActual = actual;
    _subtypeMemoExpected = expected;
    _subtypeMemoOwner = actualOwnerType;
    _subtypeMemoVersion = _typeTableVersion;
    _subtypeMemoResult = result;
    return result;
  }

  bool _acceptsNullType(int type) {
    final descriptor = _typeDescriptors[type];
    if (descriptor.length == 6 &&
        descriptor[2] == RuntimeTypeDescriptorTag.typeParameter) {
      return descriptor[1] == 1;
    }
    final nominal = descriptor[0];
    if (descriptor[1] == 1 ||
        nominal == _dynamicTypeId ||
        nominal == _voidTypeId ||
        nominal == _nullTypeId) {
      return true;
    }
    return descriptor.length == 4 &&
        descriptor[2] == RuntimeTypeDescriptorTag.futureOr &&
        _acceptsNullType(descriptor[3]);
  }

  /// Whether [type] is a plain nominal descriptor with no type arguments or
  /// structural record/function payload. Descriptor IDs need not equal their
  /// nominal IDs because compiler pipelines may intern an equivalent row in a
  /// separate slot.
  bool isTypedNominalTypeDescriptor(int type, BridgeTypeSpec nominal) {
    if (type < 0 || type >= _typeDescriptors.length) return false;
    final nominalType = _typedTypeId(nominal);
    final descriptor = _typeDescriptors[type];
    return nominalType != null &&
        descriptor.length == 2 &&
        descriptor[0] == nominalType;
  }

  /// Whether [type] is a structural function descriptor.
  bool isTypedFunctionTypeDescriptor(int type) {
    if (type < 0 || type >= _typeDescriptors.length) return false;
    final descriptor = _typeDescriptors[type];
    return descriptor.length >= 7 &&
        descriptor[2] == RuntimeTypeDescriptorTag.function;
  }

  /// Whether the checked legacy-function adapter can enforce [type].
  ///
  /// Named and generic signatures need invocation metadata that the legacy
  /// [$Closure]/[$Function] protocol does not carry.
  bool isSupportedTypedFunctionAdapterDescriptor(int type) {
    if (!isTypedFunctionTypeDescriptor(type)) return false;
    final descriptor = _typeDescriptors[type];
    if (descriptor[6] != 0 || descriptor[7] != 0) return false;

    bool containsCallableTypeParameter(int current, Set<int> visiting) {
      if (!visiting.add(current)) return false;
      final value = _typeDescriptors[current];
      if (value.length > 2 &&
          value[2] == RuntimeTypeDescriptorTag.typeParameter &&
          value[3] < 0) {
        return true;
      }
      for (final child in _descriptorChildren(value)) {
        if (containsCallableTypeParameter(child, visiting)) return true;
      }
      visiting.remove(current);
      return false;
    }

    return !containsCallableTypeParameter(type, <int>{});
  }

  /// Validate a positional invocation against a structural function type.
  /// The export binder has already validated the adapter's descriptor shape.
  void assertTypedFunctionAdapterArguments(int type, List<$Value?> arguments) {
    final descriptor = _typeDescriptors[type];
    final required = descriptor[4], positional = descriptor[5];
    if (arguments.length < required || arguments.length > positional) {
      throw NoSuchMethodError.withInvocation(
        null,
        Invocation.method(#call, arguments),
      );
    }
    final offset = 9 + descriptor[7];
    for (var i = 0; i < arguments.length; i++) {
      if (!isTypedValueType(arguments[i], descriptor[offset + i])) {
        throw TypeError();
      }
    }
  }

  /// Validate and normalize the result of a checked legacy function.
  $Value? validateTypedFunctionAdapterResult(int type, $Value? result) {
    final resultType = _typeDescriptors[type][3];
    if (_typeDescriptors[resultType][0] == lookupType(CoreTypes.voidType)) {
      return null;
    }
    if (!isTypedValueType(result, resultType)) throw TypeError();
    return result;
  }

  /// Checks a value against a reified type argument of [ownerType].
  ///
  /// Raw types have no argument to check, so writes through them retain their
  /// existing unchecked behavior.
  @pragma('vm:never-inline')
  void assertTypedTypeArgument(
    Object? value,
    int ownerType,
    int argumentIndex,
  ) {
    if (ownerType < 0 || ownerType >= _typeDescriptors.length) return;
    final descriptor = _typeDescriptors[ownerType];
    final descriptorIndex = argumentIndex + 2;
    if (descriptorIndex >= descriptor.length) return;
    if (!isTypedValueType(value, descriptor[descriptorIndex])) {
      throw TypeError();
    }
  }

  /// The descriptor row for [type] — `[]` when the id is out of range.
  List<int> descriptorFor(int type) =>
      type < 0 || type >= _typeDescriptors.length
      ? const []
      : _typeDescriptors[type];

  @pragma('vm:never-inline')
  void assertTypedFuturePayload(Object? value, int futureType) {
    if (futureType < 0 || futureType >= _typeDescriptors.length) return;
    final descriptor = _typeDescriptors[futureType];
    if (descriptor.length < 3 ||
        descriptor[0] != lookupType(CoreTypes.future)) {
      return;
    }
    final payloadType = descriptor[2];
    final payloadDescriptor = _typeDescriptors[payloadType];
    final payloadNominal = payloadDescriptor[0];
    if (payloadNominal == lookupType(CoreTypes.dynamic) ||
        payloadNominal == lookupType(CoreTypes.voidType)) {
      return;
    }
    if (!isTypedValueType(value, payloadType)) {
      throw TypeError();
    }
  }

  /// Returns an already-compiled `Future<R>` descriptor for a typed callback.
  /// Raw function signatures deliberately produce a raw Future.
  int? typedFutureTypeForCallback($Value callback) {
    final callbackType = callback.$getRuntimeType(this);
    if (callbackType < 0 || callbackType >= _typeDescriptors.length) {
      return null;
    }
    final function = _typeDescriptors[callbackType];
    if (function.length < 4 ||
        function[2] != RuntimeTypeDescriptorTag.function) {
      return null;
    }
    var payloadType = function[3];
    final returned = _typeDescriptors[payloadType];
    // Future constructors and then adopt the Future branch of FutureOr<R>.
    if (returned.length == 4 &&
        returned[2] == RuntimeTypeDescriptorTag.futureOr) {
      payloadType = returned[3];
    } else if (returned[0] == lookupType(CoreTypes.future) &&
        returned.length > 2) {
      payloadType = returned[2];
    }
    // Intern rather than scan — `Future<R>` may have no existing descriptor
    // when the program never spelled it.
    return internParameterizedType(CoreTypes.future, [payloadType]);
  }

  /// The declared return-type descriptor of a typed callback, or null for
  /// raw/dynamic signatures. When [unwrap] names a nominal (e.g. `Iterable`
  /// for `expand`), its first type argument is returned instead.
  int? typedCallbackReturnType(Object? callback, {BridgeTypeSpec? unwrap}) {
    if (callback is! $Value) return null;
    final callbackType = callback.$getRuntimeType(this);
    if (callbackType < 0 || callbackType >= _typeDescriptors.length) {
      return null;
    }
    final function = _typeDescriptors[callbackType];
    if (function.length < 4 ||
        function[2] != RuntimeTypeDescriptorTag.function) {
      return null;
    }
    var result = function[3];
    if (unwrap != null) {
      final descriptor = _typeDescriptors[result];
      if (descriptor.length < 3 || descriptor[0] != lookupType(unwrap)) {
        return null;
      }
      result = descriptor[2];
    }
    return result;
  }

  /// A record's runtime type is determined by the *runtime* types of its
  /// fields, not the literal's static type — e.g. `(baseVar,)` where `baseVar`
  /// holds an `A` reports `(A,)` even though it is statically `(Base,)`.
  /// [template] is the literal's declared record descriptor: it supplies the
  /// field-name constants and shape while each field type slot is replaced by
  /// the value's own runtime type. Since field value types are always
  /// subtypes of the declared field types, [template] is a supertype of the
  /// result and is copied into its supertype set.
  @pragma('vm:never-inline')
  int reifyRecordType(
    int template,
    List<Object?> fields,
    Map<String, int> mapping,
  ) {
    final templateDescriptor = _typeDescriptors[template];
    final positional = templateDescriptor[3], named = templateDescriptor[4];
    final namedOffset = 5 + positional;
    final fieldIds = _recordFieldTypeIds..length = 0;
    var matchesTemplate = templateDescriptor[1] == 0;
    // Fields retain literal source order, which can mix positional and
    // named fields. Resolve each positional field through its layout key.
    for (var i = 0; i < positional; i++) {
      final fieldType = _recordFieldType(fields[mapping['\$${i + 1}']!]);
      fieldIds.add(fieldType);
      matchesTemplate &= fieldType == templateDescriptor[5 + i];
    }
    for (var i = 0; i < named; i++) {
      final nameIndex = templateDescriptor[namedOffset + i * 2];
      final fieldType = _recordFieldType(
        fields[mapping[_constantPool[nameIndex] as String]!],
      );
      fieldIds.add(fieldType);
      matchesTemplate &=
          fieldType == templateDescriptor[namedOffset + i * 2 + 1];
    }
    // Every field's runtime type equals its declared type and the template
    // is non-nullable: the record's runtime type IS the template.
    if (matchesTemplate) return template;
    final key = Object.hash(template, Object.hashAll(fieldIds));
    final bucket = _reifiedRecordTypes.putIfAbsent(key, () => []);
    for (final (cachedIds, cachedType) in bucket) {
      if (_recordTypeIdsEqual(cachedIds, fieldIds)) {
        fieldIds.length = 0;
        return cachedType;
      }
    }
    final descriptor = List<int>.of(templateDescriptor);
    descriptor[1] = 0;
    for (var i = 0; i < positional; i++) {
      descriptor[5 + i] = fieldIds[i];
    }
    for (var i = 0; i < named; i++) {
      descriptor[namedOffset + i * 2 + 1] = fieldIds[positional + i];
    }
    final existing = _findRuntimeTypeDescriptor(descriptor);
    final typeId = existing >= 0
        ? existing
        : _internResolvedType(
            descriptor,
            template,
            null,
            const [],
            _TypeResolution(null),
            const {},
          );
    bucket.add((List.of(fieldIds), typeId));
    fieldIds.length = 0;
    return typeId;
  }

  static bool _recordTypeIdsEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  int _recordFieldType(Object? field) =>
      (field as $Value?)?.$getRuntimeType(this) ??
      lookupType(CoreTypes.nullType);

  /// The [index]-th argument of a nominal instantiation descriptor, or null
  /// when [typeId] carries no such argument (raw nominals, params, records).
  int? runtimeTypeArgumentAt(int typeId, int index) {
    final descriptor = _typeDescriptors[typeId];
    final offset = index + 2;
    return offset < descriptor.length ? descriptor[offset] : null;
  }

  /// Interns the nominal instantiation `[spec]<[arguments]>` from resolved
  /// runtime type-ids — for stamping bridged wrappers whose element type is
  /// recovered from the producing receiver's runtime type.
  int internParameterizedType(
    BridgeTypeSpec spec,
    List<int> arguments, {
    bool nullable = false,
  }) {
    final nominal = lookupType(spec);
    return _internResolvedType(
      [nominal, nullable ? 1 : 0, ...arguments],
      nominal,
      null,
      const [],
      _TypeResolution(null),
      const {},
    );
  }

  /// Adds nullability to an already resolved nominal or structural type.
  int nullableRuntimeType(int type) {
    final descriptor = _typeDescriptors[type];
    if (descriptor[1] == 1) return type;
    return _internResolvedType(
      [descriptor[0], 1, ...descriptor.skip(2)],
      type,
      null,
      const [],
      _TypeResolution(null),
      const {},
    );
  }

  /// The runtime type of a present value excludes top-level nullability.
  int nonNullableRuntimeType(int type) {
    final descriptor = _typeDescriptors[type];
    if (descriptor[1] == 0) return type;
    return _internResolvedType(
      [descriptor[0], 0, ...descriptor.skip(2)],
      type,
      null,
      const [],
      _TypeResolution(null),
      const {},
    );
  }

  @pragma('vm:never-inline')
  bool isTypedValueTypeInClassEnvironment(
    Object? value,
    int expected,
    int actualOwnerType,
  ) {
    if (expected < 0 || expected >= _typeDescriptors.length) return false;
    final expectedDescriptor = _typeDescriptors[expected];
    if (expectedDescriptor.length == 2 &&
        (expectedDescriptor[0] == _dynamicTypeId ||
            expectedDescriptor[0] == _voidTypeId)) {
      return true;
    }
    if (value == null || value is $null) {
      if (_acceptsNullType(expected)) return true;
      final resolved = _resolveTypeParameter(expected, actualOwnerType);
      if (resolved == null) return true;
      return _acceptsNullType(resolved);
    }
    if (expectedDescriptor.length == 2 &&
        expectedDescriptor[0] == _objectTypeId) {
      return true;
    }
    final actual = (value as $Value).$getRuntimeType(this);
    return _isSubtypeMemoized(actual, expected, actualOwnerType);
  }

  @pragma('vm:never-inline')
  bool isTypedValueTypeInCallableEnvironment(
    Object? value,
    int expected,
    List<int> typeArguments, {
    int? actualOwnerType,
    TypedTypeEnvironment? typeEnvironment,
  }) {
    if (expected < 0 || expected >= _typeDescriptors.length) return false;
    if (typeEnvironment != null) {
      expected = resolveTypedEnvironmentType(
        expected,
        actualOwnerType: actualOwnerType,
        callableTypeArguments: typeArguments,
        typeEnvironment: typeEnvironment,
      );
      typeArguments = const [];
    }
    final expectedDescriptor = _typeDescriptors[expected];
    if (expectedDescriptor.length == 2 &&
        (expectedDescriptor[0] == _dynamicTypeId ||
            expectedDescriptor[0] == _voidTypeId)) {
      return true;
    }
    if (value == null || value is $null) {
      if (_acceptsNullType(expected)) return true;
      final resolved = _resolveTypeParameter(
        expected,
        actualOwnerType,
        typeArguments,
      );
      if (resolved == null) return true;
      return _acceptsNullType(resolved);
    }
    if (expectedDescriptor.length == 2 &&
        expectedDescriptor[0] == _objectTypeId) {
      return true;
    }
    // VM-built host-function adapters carry no signature — accept them
    // wherever a function type is expected (the host side enforces itself).
    if (value is TypedHostFunction && isTypedFunctionTypeDescriptor(expected)) {
      return true;
    }
    final actual = (value as $Value).$getRuntimeType(this);
    if (typeArguments.isEmpty) {
      return _isSubtypeMemoized(actual, expected, actualOwnerType);
    }
    return _isTypedDescriptorSubtypeInEnvironment(
      actual,
      expected,
      actualOwnerType,
      typeArguments,
    );
  }

  @pragma('vm:never-inline')
  void assertTypedTypeArguments(
    List<int> typeArguments,
    List<int> bounds, {
    int? actualOwnerType,
    TypedTypeEnvironment? typeEnvironment,
  }) {
    if (typeArguments.length != bounds.length) throw TypeError();
    for (var index = 0; index < typeArguments.length; index++) {
      final resolvedBound = typeEnvironment == null
          ? bounds[index]
          : resolveTypedEnvironmentType(
              bounds[index],
              actualOwnerType: actualOwnerType,
              typeEnvironment: typeEnvironment,
            );
      if (!_isTypedDescriptorSubtypeInEnvironment(
        typeArguments[index],
        resolvedBound,
        actualOwnerType,
        typeArguments,
      )) {
        throw TypeError();
      }
    }
  }

  /// Resolves call-site descriptors against the caller before the callee uses
  /// the same descriptor slots for its own type parameters.
  List<int> resolveTypedCallTypeArguments(
    List<int> typeArguments, {
    int? actualOwnerType,
    List<int> callableTypeArguments = const [],
    TypedTypeEnvironment? typeEnvironment,
  }) {
    if (typeArguments.isEmpty) return const <int>[];
    // Concrete descriptors cannot refer to the caller's type environment.
    // Program metadata vectors are immutable, so reuse one without copying.
    var needsResolution = false;
    for (final type in typeArguments) {
      if (_requiresTypeEnvironment(type)) {
        needsResolution = true;
        break;
      }
    }
    if (!needsResolution) return typeArguments;
    return [
      for (final type in typeArguments)
        callableTypeArguments.isEmpty && typeEnvironment == null
            ? resolveTypedEnvironmentType(
                type,
                actualOwnerType: actualOwnerType,
              )
            : _resolveEnvironmentType(
                type,
                actualOwnerType,
                callableTypeArguments,
                _TypeResolution(typeEnvironment),
              ),
    ];
  }

  /// Resolves a descriptor before it is retained by a value allocated in the
  /// active callable and class type environment.
  int resolveTypedEnvironmentType(
    int type, {
    int? actualOwnerType,
    List<int> callableTypeArguments = const [],
    TypedTypeEnvironment? typeEnvironment,
  }) {
    // Most allocations have a concrete descriptor. Do not allocate a recursive
    // substitution map, or rebuild its arguments, for these ordinary values.
    if (!_requiresTypeEnvironment(type)) return type;
    if (callableTypeArguments.isEmpty && typeEnvironment == null) {
      if (_resolvedEnvironmentTypesVersion != _typeTableVersion) {
        _resolvedEnvironmentTypes.clear();
        _resolvedEnvironmentTypesVersion = _typeTableVersion;
      }
      return _resolvedEnvironmentTypes.putIfAbsent(
        (type, actualOwnerType),
        () => _resolveEnvironmentType(
          type,
          actualOwnerType,
          const [],
          _TypeResolution(typeEnvironment),
        ),
      );
    }
    return _resolveEnvironmentType(
      type,
      actualOwnerType,
      callableTypeArguments,
      _TypeResolution(typeEnvironment),
    );
  }

  bool _requiresTypeEnvironment(int type) {
    final descriptor = _typeDescriptors[type];
    if (descriptor.length == 2) return false;
    final cached = _typeEnvironmentRequirements[type];
    if (cached != null) return cached;
    if (descriptor[2] == RuntimeTypeDescriptorTag.typeParameter) return true;
    _typeEnvironmentRequirements[type] = false;
    return _typeEnvironmentRequirements[type] = _descriptorChildren(
      descriptor,
    ).any(_requiresTypeEnvironment);
  }

  Iterable<int> _descriptorChildren(List<int> descriptor) sync* {
    if (descriptor.length <= 2) return;
    if (descriptor[2] >= 0) {
      yield* descriptor.skip(2);
    } else if (descriptor[2] == RuntimeTypeDescriptorTag.function) {
      yield descriptor[3];
      yield* descriptor.skip(9).take(descriptor[7]);
      yield* descriptor.skip(9 + descriptor[7]).take(descriptor[5]);
      for (
        var index = 9 + descriptor[7] + descriptor[5];
        index < descriptor.length;
        index += 3
      ) {
        yield descriptor[index + 2];
      }
    } else if (descriptor[2] == RuntimeTypeDescriptorTag.record) {
      yield* descriptor.skip(5).take(descriptor[3]);
      for (
        var index = 5 + descriptor[3];
        index < descriptor.length;
        index += 2
      ) {
        yield descriptor[index + 1];
      }
    } else if (descriptor[2] == RuntimeTypeDescriptorTag.futureOr) {
      yield descriptor[3];
    }
  }

  int _resolveEnvironmentType(
    int type,
    int? actualOwnerType,
    List<int> callableTypeArguments,
    _TypeResolution resolution, [
    Set<int> signatureBoundOwners = const {},
  ]) {
    final cached = resolution.types[(type, signatureBoundOwners)];
    if (cached != null) return cached;
    resolution.types[(type, signatureBoundOwners)] = type;
    final descriptor = _typeDescriptors[type];
    if (signatureBoundOwners.isNotEmpty &&
        descriptor.length == 6 &&
        descriptor[2] == RuntimeTypeDescriptorTag.typeParameter &&
        signatureBoundOwners.contains(descriptor[3])) {
      // A callable-owned reference in a generic signature's components is
      // bound by an enclosing signature — keep it abstract rather than
      // substituting an environment argument or bound. Its bound can still
      // reference the receiver's class parameters (`S extends T` in C<T>).
      final bound = _resolveEnvironmentType(
        descriptor[5],
        actualOwnerType,
        callableTypeArguments,
        resolution,
        signatureBoundOwners,
      );
      if (bound == descriptor[5]) return type;
      return resolution.types[(
        type,
        signatureBoundOwners,
      )] = _internResolvedType(
        [...descriptor.take(5), bound],
        type,
        actualOwnerType,
        callableTypeArguments,
        resolution,
        signatureBoundOwners,
      );
    }
    final parameter =
        descriptor.length == 6 &&
            descriptor[2] == RuntimeTypeDescriptorTag.typeParameter
        ? _resolveTypeParameter(
            type,
            actualOwnerType,
            callableTypeArguments,
            resolution.environment,
          )
        : null;
    if (parameter != null && parameter != type) {
      var result = _resolveEnvironmentType(
        parameter,
        actualOwnerType,
        callableTypeArguments,
        resolution,
        signatureBoundOwners,
      );
      if (descriptor[1] == 1 && _typeDescriptors[result][1] == 0) {
        result = _internResolvedType(
          [_typeDescriptors[result][0], 1, ..._typeDescriptors[result].skip(2)],
          result,
          actualOwnerType,
          callableTypeArguments,
          resolution,
          signatureBoundOwners,
        );
      }
      return resolution.types[(type, signatureBoundOwners)] = result;
    }
    if (descriptor.length < 3) return type;

    final translated = <int>[descriptor[0], descriptor[1]];
    if (descriptor[2] >= 0) {
      translated.addAll([
        for (final argument in descriptor.skip(2))
          _resolveEnvironmentType(
            argument,
            actualOwnerType,
            callableTypeArguments,
            resolution,
            signatureBoundOwners,
          ),
      ]);
    } else {
      switch (descriptor[2]) {
        case RuntimeTypeDescriptorTag.record:
          translated.addAll([descriptor[2], descriptor[3], descriptor[4]]);
          for (final field in descriptor.skip(5).take(descriptor[3])) {
            translated.add(
              _resolveEnvironmentType(
                field,
                actualOwnerType,
                callableTypeArguments,
                resolution,
                signatureBoundOwners,
              ),
            );
          }
          for (
            var index = 5 + descriptor[3];
            index < descriptor.length;
            index += 2
          ) {
            translated.add(descriptor[index]);
            translated.add(
              _resolveEnvironmentType(
                descriptor[index + 1],
                actualOwnerType,
                callableTypeArguments,
                resolution,
                signatureBoundOwners,
              ),
            );
          }
        case RuntimeTypeDescriptorTag.function:
          // Only parameters owned by an enclosing signature's binder stay
          // abstract inside it — a ref owned by a different callable (the
          // enclosing function's `T` inside `F Function<F>(T)`) still
          // resolves against the environment.
          final boundOwners = descriptor[7] > 0
              ? (signatureBoundOwners.isEmpty
                    ? {descriptor[8]}
                    : {...signatureBoundOwners, descriptor[8]})
              : signatureBoundOwners;
          translated.addAll([
            descriptor[2],
            _resolveEnvironmentType(
              descriptor[3],
              actualOwnerType,
              callableTypeArguments,
              resolution,
              boundOwners,
            ),
            descriptor[4],
            descriptor[5],
            descriptor[6],
            descriptor[7],
            descriptor[8],
          ]);
          for (final bound in descriptor.skip(9).take(descriptor[7])) {
            translated.add(
              _resolveEnvironmentType(
                bound,
                actualOwnerType,
                callableTypeArguments,
                resolution,
                boundOwners,
              ),
            );
          }
          for (final parameter
              in descriptor.skip(9 + descriptor[7]).take(descriptor[5])) {
            translated.add(
              _resolveEnvironmentType(
                parameter,
                actualOwnerType,
                callableTypeArguments,
                resolution,
                boundOwners,
              ),
            );
          }
          for (
            var index = 9 + descriptor[7] + descriptor[5];
            index < descriptor.length;
            index += 3
          ) {
            translated.addAll([descriptor[index], descriptor[index + 1]]);
            translated.add(
              _resolveEnvironmentType(
                descriptor[index + 2],
                actualOwnerType,
                callableTypeArguments,
                resolution,
                boundOwners,
              ),
            );
          }
        case RuntimeTypeDescriptorTag.typeParameter:
          // Unresolvable in this environment (e.g. a raw generic owner row):
          // substitute the parameter's bound, matching
          // resolveTypeParameterInEnvironment's fallback.
          return _resolveEnvironmentType(
            descriptor[5],
            actualOwnerType,
            callableTypeArguments,
            resolution,
            signatureBoundOwners,
          );
        case RuntimeTypeDescriptorTag.futureOr:
          translated.addAll([
            descriptor[2],
            _resolveEnvironmentType(
              descriptor[3],
              actualOwnerType,
              callableTypeArguments,
              resolution,
              signatureBoundOwners,
            ),
          ]);
      }
    }
    if (_sameTypeDescriptor(descriptor, translated)) return type;
    return resolution.types[(type, signatureBoundOwners)] = _internResolvedType(
      translated,
      type,
      actualOwnerType,
      callableTypeArguments,
      resolution,
      signatureBoundOwners,
    );
  }

  int _internResolvedType(
    List<int> descriptor,
    int source,
    int? actualOwnerType,
    List<int> callableTypeArguments,
    _TypeResolution resolution,
    Set<int> signatureBoundOwners,
  ) {
    final existing = _findRuntimeTypeDescriptor(descriptor);
    if (existing >= 0) return existing;
    final id = _typeDescriptors.length;
    _typeDescriptors.add(descriptor);
    _typeIdentities.add(null);
    _typeTypes.add({id});
    _typeTableVersion++;
    resolution.types[(source, signatureBoundOwners)] = id;
    if (source < _typeTypes.length) {
      for (final supertype in _typeTypes[source]) {
        _typeTypes[id].add(
          _resolveEnvironmentType(
            supertype,
            actualOwnerType,
            callableTypeArguments,
            resolution,
          ),
        );
      }
    }
    return id;
  }

  bool _sameTypeDescriptor(List<int> left, List<int> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }

  /// Resolves a type parameter descriptor to the concrete runtime type id it
  /// is bound to in the current callable environment, falling back to the
  /// parameter's bound when it cannot be resolved.
  int resolveTypeParameterInEnvironment(
    int type,
    int? actualOwnerType,
    List<int> callableTypeArguments, {
    TypedTypeEnvironment? typeEnvironment,
  }) {
    if (typeEnvironment != null) {
      return resolveTypedEnvironmentType(
        type,
        actualOwnerType: actualOwnerType,
        callableTypeArguments: callableTypeArguments,
        typeEnvironment: typeEnvironment,
      );
    }
    final descriptor = _typeDescriptors[type];
    if (descriptor.length != 6 ||
        descriptor[2] != RuntimeTypeDescriptorTag.typeParameter) {
      // A composite type still carries nested type-parameter arguments
      // (e.g. a folded mixin's `T` bound to `Map<List<U>, V>`): substitute
      // them against the active environments.
      return resolveTypedEnvironmentType(
        type,
        actualOwnerType: actualOwnerType,
        callableTypeArguments: callableTypeArguments,
      );
    }
    return _resolveTypeParameter(
          type,
          actualOwnerType,
          callableTypeArguments,
        ) ??
        descriptor[5];
  }

  int? _resolveTypeParameter(
    int type,
    int? actualOwnerType, [
    List<int> callableTypeArguments = const [],
    TypedTypeEnvironment? typeEnvironment,
  ]) {
    final descriptor = _typeDescriptors[type];
    if (descriptor.length != 6 ||
        descriptor[2] != RuntimeTypeDescriptorTag.typeParameter) {
      return type;
    }
    final ownerNominalType = descriptor[3];
    final parameterIndex = descriptor[4];
    if (typeEnvironment != null) {
      final argument = typeEnvironment.lookup(ownerNominalType, parameterIndex);
      if (argument != null) return argument;
      if (ownerNominalType < 0) return descriptor[5];
    }
    if (ownerNominalType < 0) {
      // Any callable owner (function, method, signature binder) resolves
      // positionally against the active callable's type arguments.
      return parameterIndex < callableTypeArguments.length
          ? callableTypeArguments[parameterIndex]
          : descriptor[5];
    }
    // Factory constructors have no receiver, so their class's type arguments
    // arrive through the callable-type-arguments channel instead.
    if (actualOwnerType == null) {
      return parameterIndex < callableTypeArguments.length
          ? callableTypeArguments[parameterIndex]
          : descriptor[5];
    }
    int? instantiatedOwner;
    if (_typeDescriptors[actualOwnerType][0] == ownerNominalType) {
      instantiatedOwner = actualOwnerType;
    } else if (actualOwnerType < _typeTypes.length) {
      for (final candidate in _typeTypes[actualOwnerType]) {
        if (candidate >= 0 &&
            candidate < _typeDescriptors.length &&
            _typeDescriptors[candidate][0] == ownerNominalType) {
          instantiatedOwner = candidate;
          break;
        }
      }
    }
    if (instantiatedOwner == null) return descriptor[5];
    final ownerDescriptor = _typeDescriptors[instantiatedOwner];
    final argumentOffset = parameterIndex + 2;
    if (argumentOffset >= ownerDescriptor.length) return null;
    final argument = ownerDescriptor[argumentOffset];
    // The argument may itself reference the owner's own type parameters
    // (e.g. `class C<T> = S with M2<T>`) — resolve it in the environment too.
    return resolveTypedEnvironmentType(
      argument,
      actualOwnerType: actualOwnerType,
      callableTypeArguments: callableTypeArguments,
      typeEnvironment: typeEnvironment,
    );
  }

  bool _isTypedDescriptorSubtypeInEnvironment(
    int actual,
    int expected,
    int? actualOwnerType,
    List<int> callableTypeArguments, {
    bool nullableExpected = false,
    _SignatureParameterRelations? signatureParameterRenames,
  }) {
    if (actual < 0 ||
        actual >= _typeDescriptors.length ||
        expected < 0 ||
        expected >= _typeDescriptors.length) {
      return false;
    }
    if (actual == expected) return true;
    final actualDescriptor = _typeDescriptors[actual];
    final expectedDescriptor = _typeDescriptors[expected];
    // Normalization can make generic signatures equal before their symbolic
    // components are compared by the structural subtype rules below.
    if (actualDescriptor.length >= 9 &&
        expectedDescriptor.length >= 9 &&
        actualDescriptor[2] == RuntimeTypeDescriptorTag.function &&
        expectedDescriptor[2] == RuntimeTypeDescriptorTag.function &&
        actualDescriptor[7] > 0 &&
        expectedDescriptor[7] > 0 &&
        _runtimeTypeSemanticKey(actual) == _runtimeTypeSemanticKey(expected)) {
      return true;
    }
    if (signatureParameterRenames != null) {
      final expectedRow = _typeDescriptors[expected];
      if (expectedRow.length == 6 &&
          expectedRow[2] == RuntimeTypeDescriptorTag.typeParameter &&
          expectedRow[3] < 0 &&
          signatureParameterRenames.renames.containsKey(expectedRow[3])) {
        // Generic signatures compare by renaming their type parameters, so
        // a bound expected-side parameter is an abstract variable: it
        // accepts only the corresponding renamed variable, another variable
        // bounded by it, or a bottom type — never the variable's bound.
        final renamed = signatureParameterRenames.renames[expectedRow[3]]!;
        final actualRow = _typeDescriptors[actual];
        if (actualRow.length == 6 &&
            actualRow[2] == RuntimeTypeDescriptorTag.typeParameter &&
            actualRow[3] < 0) {
          if (actualRow[3] == renamed && actualRow[4] == expectedRow[4]) {
            return actualRow[1] == 0 || expectedRow[1] == 1 || nullableExpected;
          }
          final relation = (actual, expected);
          if (!signatureParameterRenames.active.add(relation)) return false;
          try {
            final bound =
                signatureParameterRenames.bounds[(
                  actualRow[3],
                  actualRow[4],
                )] ??
                actualRow[5];
            return _isTypedDescriptorSubtypeInEnvironment(
              actualRow[1] == 1 ? nullableRuntimeType(bound) : bound,
              expected,
              actualOwnerType,
              callableTypeArguments,
              nullableExpected: nullableExpected,
              signatureParameterRenames: signatureParameterRenames,
            );
          } finally {
            signatureParameterRenames.active.remove(relation);
          }
        }
        if (actualRow[0] == _typedTypeId(CoreTypes.never)) return true;
        return actualRow[0] == _nullTypeId &&
            (expectedRow[1] == 1 || nullableExpected);
      }
    }
    if (signatureParameterRenames != null &&
        actualDescriptor.length == 6 &&
        actualDescriptor[2] == RuntimeTypeDescriptorTag.typeParameter &&
        signatureParameterRenames.renames.containsKey(actualDescriptor[3])) {
      // Keep a bound signature variable symbolic when it occurs as a union
      // member, before falling back to its signature's declared bound.
      if (expectedDescriptor.length == 4 &&
          expectedDescriptor[2] == RuntimeTypeDescriptorTag.futureOr &&
          _isTypedDescriptorSubtypeInEnvironment(
            actual,
            expectedDescriptor[3],
            actualOwnerType,
            callableTypeArguments,
            nullableExpected: nullableExpected || expectedDescriptor[1] == 1,
            signatureParameterRenames: signatureParameterRenames,
          )) {
        return true;
      }
      final relation = (actual, expected);
      if (!signatureParameterRenames.active.add(relation)) return false;
      try {
        final bound =
            signatureParameterRenames.bounds[(
              actualDescriptor[3],
              actualDescriptor[4],
            )] ??
            actualDescriptor[5];
        return _isTypedDescriptorSubtypeInEnvironment(
          actualDescriptor[1] == 1 ? nullableRuntimeType(bound) : bound,
          expected,
          actualOwnerType,
          callableTypeArguments,
          nullableExpected: nullableExpected,
          signatureParameterRenames: signatureParameterRenames,
        );
      } finally {
        signatureParameterRenames.active.remove(relation);
      }
    }
    final resolvedExpected = _resolveTypeParameter(
      expected,
      actualOwnerType,
      callableTypeArguments,
    );
    if (resolvedExpected == null) return true;
    if (resolvedExpected != expected) {
      return _isTypedDescriptorSubtypeInEnvironment(
        actual,
        resolvedExpected,
        actualOwnerType,
        callableTypeArguments,
        nullableExpected: _typeDescriptors[expected][1] == 1,
        signatureParameterRenames: signatureParameterRenames,
      );
    }
    final resolvedActual = _resolveTypeParameter(
      actual,
      actualOwnerType,
      callableTypeArguments,
    );
    if (resolvedActual != null && resolvedActual != actual) {
      return _isTypedDescriptorSubtypeInEnvironment(
        resolvedActual,
        expected,
        actualOwnerType,
        callableTypeArguments,
        nullableExpected: nullableExpected,
        signatureParameterRenames: signatureParameterRenames,
      );
    }
    final source = _typeDescriptors[actual];
    final target = _typeDescriptors[expected];
    final sourceNominal = source[0], targetNominal = target[0];
    final targetTag = target.length > 2 && target[2] < 0 ? target[2] : null;
    if (source.length == 4 && source[2] == RuntimeTypeDescriptorTag.futureOr) {
      if (_acceptsNullType(actual) &&
          !_acceptsNullType(expected) &&
          !nullableExpected) {
        return false;
      }
      final member = source[3];
      if (!_isTypedDescriptorSubtypeInEnvironment(
        member,
        expected,
        actualOwnerType,
        callableTypeArguments,
        nullableExpected: nullableExpected,
        signatureParameterRenames: signatureParameterRenames,
      )) {
        return false;
      }

      // FutureOr<S> also includes Future<S>. Check that branch only for union
      // sources, keeping ordinary subtype checks on their existing path.
      bool futureBranchIsSubtype(int type) {
        final row = _typeDescriptors[type];
        final nominal = row[0];
        if (row.length == 2 &&
            (nominal == _dynamicTypeId ||
                nominal == _voidTypeId ||
                nominal == _objectTypeId)) {
          return true;
        }
        if (row.length == 4 && row[2] == RuntimeTypeDescriptorTag.futureOr) {
          return _isTypedDescriptorSubtypeInEnvironment(
                member,
                row[3],
                actualOwnerType,
                callableTypeArguments,
                signatureParameterRenames: signatureParameterRenames,
              ) ||
              futureBranchIsSubtype(row[3]);
        }
        return nominal == _typedTypeId(CoreTypes.future) &&
            row.length > 2 &&
            _isTypedDescriptorSubtypeInEnvironment(
              member,
              row[2],
              actualOwnerType,
              callableTypeArguments,
              signatureParameterRenames: signatureParameterRenames,
            );
      }

      return futureBranchIsSubtype(expected);
    }
    if (targetTag == RuntimeTypeDescriptorTag.futureOr) {
      if (source[1] == 1 && !_acceptsNullType(expected)) return false;
      if (sourceNominal == _nullTypeId &&
          (target[1] == 1 || nullableExpected)) {
        return true;
      }
      if (_isTypedDescriptorSubtypeInEnvironment(
        actual,
        target[3],
        actualOwnerType,
        callableTypeArguments,
        signatureParameterRenames: signatureParameterRenames,
      )) {
        return true;
      }
      final futureNominal = _typedTypeId(CoreTypes.future);
      if (futureNominal == null) return false;
      final candidates = actual < _typeTypes.length
          ? _typeTypes[actual]
          : {actual};
      for (final candidate in candidates) {
        final row = _typeDescriptors[candidate];
        if (row[0] == futureNominal &&
            row.length > 2 &&
            _isTypedDescriptorSubtypeInEnvironment(
              row[2],
              target[3],
              actualOwnerType,
              callableTypeArguments,
              signatureParameterRenames: signatureParameterRenames,
            )) {
          return true;
        }
      }
      return false;
    }
    // Object? is a top type even for dynamic and abstract signature bounds,
    // which do not necessarily have an Object entry in their supertype table.
    if (targetNominal == _dynamicTypeId ||
        targetNominal == _voidTypeId ||
        (targetNominal == _objectTypeId &&
            (target[1] == 1 || nullableExpected))) {
      return true;
    }
    // Never is a subtype of every type.
    if (sourceNominal == _typedTypeId(CoreTypes.never)) return true;
    // Null <: T only when T is nullable or a top type (dynamic handled above).
    if (sourceNominal == _nullTypeId) {
      return target[1] == 1 || nullableExpected;
    }
    if (source[1] == 1 && target[1] == 0 && !nullableExpected) return false;
    if (targetTag != null) {
      final sourceTag = source.length > 2 && source[2] < 0 ? source[2] : null;
      if (sourceTag != targetTag) {
        // A class instance satisfies a function type through its `call`
        // method, whose signature is registered among its supertypes.
        if (actual < _typeTypes.length) {
          for (final candidate in _typeTypes[actual]) {
            if (candidate >= 0 &&
                candidate != actual &&
                candidate < _typeDescriptors.length &&
                _isTypedDescriptorSubtypeInEnvironment(
                  candidate,
                  expected,
                  actual,
                  callableTypeArguments,
                  signatureParameterRenames: signatureParameterRenames,
                )) {
              return true;
            }
          }
        }
        return false;
      }
      return switch (targetTag) {
        RuntimeTypeDescriptorTag.record =>
          _isTypedRecordSubtypeInClassEnvironment(
            source,
            target,
            actualOwnerType,
            callableTypeArguments,
            signatureParameterRenames,
          ),
        RuntimeTypeDescriptorTag.function =>
          _isTypedFunctionSubtypeInClassEnvironment(
            source,
            target,
            actualOwnerType,
            callableTypeArguments,
            signatureParameterRenames,
          ),
        _ => false,
      };
    }
    if (sourceNominal != targetNominal) {
      if (actual >= _typeTypes.length) return false;
      for (final candidate in _typeTypes[actual]) {
        if (candidate != actual &&
            _isTypedDescriptorSubtypeInEnvironment(
              candidate,
              expected,
              actualOwnerType,
              callableTypeArguments,
              signatureParameterRenames: signatureParameterRenames,
            )) {
          return true;
        }
      }
      return false;
    }
    if (target.length == 2) return true;
    if (source.length != target.length) return false;
    final variances = _typeVariances[targetNominal];
    for (var index = 2; index < source.length; index++) {
      final variance = variances != null && index - 2 < variances.length
          ? variances[index - 2]
          : TypeParameterVariance.covariant;
      if (variance != TypeParameterVariance.contravariant && !_isTypedDescriptorSubtypeInEnvironment(
        source[index],
        target[index],
        actualOwnerType,
        callableTypeArguments,
        signatureParameterRenames: signatureParameterRenames,
      )) {
        return false;
      }
      if (variance != TypeParameterVariance.covariant &&
          !_isTypedDescriptorSubtypeInEnvironment(
            target[index], source[index], actualOwnerType, callableTypeArguments,
            signatureParameterRenames: signatureParameterRenames,
          )) {
        return false;
      }
    }
    return true;
  }

  bool _isTypedRecordSubtypeInClassEnvironment(
    List<int> source,
    List<int> target,
    int? actualOwnerType, [
    List<int> callableTypeArguments = const [],
    _SignatureParameterRelations? signatureParameterRenames,
  ]) {
    final sourcePositional = source[3], sourceNamed = source[4];
    final targetPositional = target[3], targetNamed = target[4];
    if (sourcePositional != targetPositional || sourceNamed != targetNamed) {
      return false;
    }
    for (var i = 0; i < sourcePositional; i++) {
      if (!_isTypedDescriptorSubtypeInEnvironment(
        source[5 + i],
        target[5 + i],
        actualOwnerType,
        callableTypeArguments,
        signatureParameterRenames: signatureParameterRenames,
      )) {
        return false;
      }
    }
    final sourceOffset = 5 + sourcePositional;
    final targetOffset = 5 + targetPositional;
    for (var i = 0; i < sourceNamed; i++) {
      final sourceName = typedConstant(source[sourceOffset + i * 2]);
      final targetName = typedConstant(target[targetOffset + i * 2]);
      if (sourceName != targetName ||
          !_isTypedDescriptorSubtypeInEnvironment(
            source[sourceOffset + i * 2 + 1],
            target[targetOffset + i * 2 + 1],
            actualOwnerType,
            callableTypeArguments,
            signatureParameterRenames: signatureParameterRenames,
          )) {
        return false;
      }
    }
    return true;
  }

  bool _isTypedFunctionSubtypeInClassEnvironment(
    List<int> source,
    List<int> target,
    int? actualOwnerType, [
    List<int> callableTypeArguments = const [],
    _SignatureParameterRelations? signatureParameterRenames,
  ]) {
    final sourceRequired = source[4], sourcePositional = source[5];
    final targetRequired = target[4], targetPositional = target[5];
    if (sourceRequired > targetRequired ||
        sourcePositional < targetPositional) {
      return false;
    }
    // Generic signatures subtype only when arities agree and each bound is
    // mutually compatible (the source must work wherever the target's own
    // parameter could be used). The parameters compare as renamed variables:
    // the target's binder (descriptor[8]) is mapped onto the source's, and
    // bound expected-side references accept only their renamed counterpart.
    final sourceParameters = source[7], targetParameters = target[7];
    if (sourceParameters != targetParameters) return false;
    // Bound-parameter references compare across the pair by owner identity:
    // the map is bidirectional so a parameter appearing on either side of a
    // nested contravariant check still resolves to its counterpart.
    final renames = targetParameters > 0
        ? (
            renames: {
              ...?signatureParameterRenames?.renames,
              target[8]: source[8],
              source[8]: target[8],
            },
            bounds: {
              ...?signatureParameterRenames?.bounds,
              for (var i = 0; i < sourceParameters; i++)
                (source[8], i): source[9 + i],
              for (var i = 0; i < targetParameters; i++)
                (target[8], i): target[9 + i],
            },
            active: signatureParameterRenames?.active ?? <(int, int)>{},
          )
        : signatureParameterRenames;
    int resolveSignatureReturn(int type) {
      final descriptor = _typeDescriptors[type];
      if (renames != null &&
          descriptor.length == 6 &&
          descriptor[2] == RuntimeTypeDescriptorTag.typeParameter &&
          renames.renames.containsKey(descriptor[3])) {
        return type;
      }
      return _resolveTypeParameter(
            type,
            actualOwnerType,
            callableTypeArguments,
          ) ??
          type;
    }

    for (var i = 0; i < targetParameters; i++) {
      final sourceBound = source[9 + i], targetBound = target[9 + i];
      if (!_isTypedDescriptorSubtypeInEnvironment(
            sourceBound,
            targetBound,
            actualOwnerType,
            callableTypeArguments,
            signatureParameterRenames: renames,
          ) ||
          !_isTypedDescriptorSubtypeInEnvironment(
            targetBound,
            sourceBound,
            actualOwnerType,
            callableTypeArguments,
            signatureParameterRenames: renames,
          )) {
        return false;
      }
    }
    final sourceOffset = 9 + sourceParameters;
    final targetOffset = 9 + targetParameters;
    final targetReturnId = resolveSignatureReturn(target[3]);
    final targetReturn = _typeDescriptors[targetReturnId];
    // In component positions a `void` target accepts any return. A `dynamic`
    // source return satisfies only top-type targets — `dynamic <: MyView`
    // fails at runtime (`(dynamic) => dynamic is MyView Function(Object)`),
    // and a `void` source return is likewise not permissive.
    final sourceReturnId = resolveSignatureReturn(source[3]);
    final sourceReturn = _typeDescriptors[sourceReturnId];
    // A type-parameter descriptor carries `dynamic` as its nominal type, but
    // a bound signature parameter is not permissive like dynamic.
    final sourceIsParameter =
        sourceReturn.length == 6 &&
        sourceReturn[2] == RuntimeTypeDescriptorTag.typeParameter;
    if (targetReturn[0] != _voidTypeId &&
        (sourceReturn[0] == _dynamicTypeId && !sourceIsParameter
            ? targetReturn[0] != _dynamicTypeId &&
                  !(targetReturn[0] == _objectTypeId && targetReturn[1] == 1)
            : !_isTypedDescriptorSubtypeInEnvironment(
                source[3],
                target[3],
                actualOwnerType,
                callableTypeArguments,
                signatureParameterRenames: renames,
              ))) {
      return false;
    }
    for (var i = 0; i < targetPositional; i++) {
      if (!_isTypedFunctionParameterSubtypeInClassEnvironment(
        target[targetOffset + i],
        source[sourceOffset + i],
        actualOwnerType,
        callableTypeArguments,
        renames,
      )) {
        return false;
      }
    }

    Map<Object?, (bool, int)> namedParameters(List<int> descriptor) {
      final positional = descriptor[5], namedCount = descriptor[6];
      final offset = 9 + descriptor[7] + positional;
      return {
        for (var i = 0; i < namedCount; i++)
          typedConstant(descriptor[offset + i * 3]): (
            descriptor[offset + i * 3 + 1] == 1,
            descriptor[offset + i * 3 + 2],
          ),
      };
    }

    final sourceNamed = namedParameters(source);
    final targetNamed = namedParameters(target);
    for (final entry in targetNamed.entries) {
      final sourceParameter = sourceNamed[entry.key];
      if (sourceParameter == null ||
          (!entry.value.$1 && sourceParameter.$1) ||
          !_isTypedFunctionParameterSubtypeInClassEnvironment(
            entry.value.$2,
            sourceParameter.$2,
            actualOwnerType,
            callableTypeArguments,
            renames,
          )) {
        return false;
      }
    }
    for (final entry in sourceNamed.entries) {
      if (entry.value.$1 && !(targetNamed[entry.key]?.$1 ?? false)) {
        return false;
      }
    }
    return true;
  }

  bool _isTypedFunctionParameterSubtypeInClassEnvironment(
    int source,
    int target,
    int? actualOwnerType, [
    List<int> callableTypeArguments = const [],
    _SignatureParameterRelations? signatureParameterRenames,
  ]) {
    bool isSignatureBoundParameter(int type) =>
        signatureParameterRenames != null &&
        _typeDescriptors[type].length == 6 &&
        _typeDescriptors[type][2] == RuntimeTypeDescriptorTag.typeParameter &&
        _typeDescriptors[type][3] < 0;
    if (isSignatureBoundParameter(source) ||
        isSignatureBoundParameter(target)) {
      return _isTypedDescriptorSubtypeInEnvironment(
        source,
        target,
        actualOwnerType,
        callableTypeArguments,
        signatureParameterRenames: signatureParameterRenames,
      );
    }
    final resolvedSource =
        _resolveTypeParameter(source, actualOwnerType, callableTypeArguments) ??
        source;
    final sourceDescriptor = _typeDescriptors[resolvedSource];
    final resolvedTarget =
        _resolveTypeParameter(target, actualOwnerType, callableTypeArguments) ??
        target;
    if (sourceDescriptor[0] == _dynamicTypeId) {
      final targetDescriptor = _typeDescriptors[resolvedTarget];
      return targetDescriptor[0] == _dynamicTypeId ||
          (targetDescriptor[0] == _objectTypeId && targetDescriptor[1] == 1);
    }
    return _isTypedDescriptorSubtypeInEnvironment(
      resolvedSource,
      resolvedTarget,
      actualOwnerType,
      callableTypeArguments,
      signatureParameterRenames: signatureParameterRenames,
    );
  }

  bool _isTypedDescriptorSubtype(int actual, int expected) =>
      _isTypedDescriptorSubtypeInEnvironment(actual, expected, null, const []);

  $Value? invokeTypedExternal(
    int functionId,
    int argumentCount,
    Object? first,
    Object? second,
    Object? rest,
  ) {
    _setup();
    if (functionId < 0 || functionId >= _bridgeFunctions.length) {
      throw ArgumentError.value(functionId, 'functionId', 'Invalid bridge ID');
    }
    final direct = _bridgeFunctions[functionId];
    if (direct == null) {
      throw UnimplementedError(
        'Tried to invoke a nonexistent external function; did you forget to add it with registerBridgeFuncRegisters()?',
      );
    }
    final result = direct(this, first, second, rest);
    return result is $null ? null : result;
  }

  bool isTypedExternalAssignable($Value value, String library, String name) {
    _setup();
    if (library == 'dart:core' &&
        (name == 'dynamic' ||
            name == 'void' ||
            (name == 'Object' && value is! $null))) {
      return true;
    }
    final expected = lookupType(BridgeTypeSpec(library, name));
    final actual = value.$getRuntimeType(this);
    return _isTypedDescriptorSubtype(actual, expected);
  }

  /// Invoke [name] on [receiver] with a register call vector: [first] is
  /// argument 0, [rest] is argument 1 when [count] is 2 or a borrowed
  /// `List<Object?>` of arguments 1..count-1 when [count] exceeds 2.
  $Value? invokeTypedObject(
    Object? receiver,
    String name,
    int count,
    Object? first,
    Object? rest,
  ) {
    _setup();
    final result = _dispatchTypedObject(receiver, name, count, first, rest);
    return result is $null ? null : result;
  }

  $Value? _dispatchTypedObject(
    Object? receiver,
    String name,
    int count,
    Object? first,
    Object? rest,
  ) {
    if (receiver == null || receiver is $null) {
      throw NoSuchMethodError.withInvocation(
        null,
        Invocation.method(Symbol(name), [
          for (final argument in TypedInterop.argList(count, first, rest))
            argument?.$reified,
        ]),
      );
    }
    if (receiver is TypedInstance) {
      return receiver.invoke(name, count, first, rest, runtime: this);
    }
    if (name == 'call' && receiver is EvalCallable) {
      return TypedInterop.callCallable(this, receiver, count, first, rest);
    }
    final object = receiver as $Instance;
    final $Value? callable;
    try {
      callable = object.$getProperty(this, name);
    } on EvalUnknownPropertyException {
      throw NoSuchMethodError.withInvocation(
        object,
        Invocation.method(Symbol(name), [
          for (final argument in TypedInterop.argList(count, first, rest))
            argument?.$reified,
        ]),
      );
    }
    // A getter may return a guest instance whose `call` member is the
    // intended target (e.g. `list.first()` on an element with `call`).
    if (callable is TypedInstance) {
      return callable.invoke('call', count, first, rest, runtime: this);
    }
    if (callable is! EvalCallable) throw StateError('$name is not callable');
    return TypedInterop.callCallable(
      this,
      object,
      count,
      first,
      rest,
      callable: callable as EvalCallable,
    );
  }
}

/// One recursive substitution shares its memo table and captured owner bindings.
final class _TypeResolution {
  _TypeResolution(this.environment);
  final TypedTypeEnvironment? environment;
  final types = <(int, Set<int>), int>{};
}
