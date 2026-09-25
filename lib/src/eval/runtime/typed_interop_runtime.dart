part of 'runtime.dart';

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
    final List<Object?> key;
    var loose = false;
    switch (v) {
      case TypedInstance():
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
        ? typeId
        : Object.hashAll([
            typeId,
            for (final part in key) identityHashCode(part),
          ]);
    final bucket = _constIntern.putIfAbsent(hash, () => []);
    for (final (existingKey, existing, existingLoose) in bucket) {
      if (existingLoose != loose || existingKey.length != key.length) {
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
    bucket.add((key, v, loose));
    return v;
  }

  /// Normalizes a key part: boxed scalars compare by payload, strings by
  /// canonical instance (equal const strings are identical in the host),
  /// everything else by identity (nested consts are already canonicalized).
  Object? _constKeyPart(Object? part) => switch (part) {
    $int p => p.$value,
    $double p => p.$value,
    $bool p => p.$value,
    $String p => _constKeyPart(p.$value),
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
    if (expectedNominal == _typedTypeId(CoreTypes.dynamic) ||
        expectedNominal == _typedTypeId(CoreTypes.voidType)) {
      return true;
    }
    if (value == null || value is $null) {
      return expectedDescriptor[1] == 1 ||
          expectedNominal == _typedTypeId(CoreTypes.nullType);
    }
    // Every non-null value satisfies Object. Host bridge values may be opaque
    // and unable to report a runtime type, so accept before reifying.
    if (expectedNominal == _typedTypeId(CoreTypes.object)) return true;
    final actual = (value as $Value).$getRuntimeType(this);
    return _isSubtypeMemoized(actual, expected, null);
  }

  /// One-entry monomorphic memo over
  /// [_isTypedDescriptorSubtypeInEnvironment]. Hot checked paths — collection
  /// writes, closure arguments, conversion asserts — repeat the same
  /// (actual, expected, owner) triple virtually every iteration. Only used by
  /// callers without callable type arguments or a propagated nullability
  /// expectation, where the check is fully determined by the triple.
  bool _isSubtypeMemoized(int actual, int expected, int? actualOwnerType) {
    if (actual == expected) return true;
    if (_subtypeMemoVersion == _typeTableVersion &&
        actual == _subtypeMemoActual &&
        expected == _subtypeMemoExpected &&
        actualOwnerType == _subtypeMemoOwner) {
      return _subtypeMemoResult;
    }
    final result = _isTypedDescriptorSubtypeInEnvironment(
      actual,
      expected,
      actualOwnerType,
      const [],
    );
    _subtypeMemoActual = actual;
    _subtypeMemoExpected = expected;
    _subtypeMemoOwner = actualOwnerType;
    _subtypeMemoVersion = _typeTableVersion;
    _subtypeMemoResult = result;
    return result;
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
    if (descriptor[6] != 0) return false;

    bool containsCallableTypeParameter(int current, Set<int> visiting) {
      if (!visiting.add(current)) return false;
      final value = _typeDescriptors[current];
      if (value.length > 2 &&
          value[2] == RuntimeTypeDescriptorTag.typeParameter &&
          value[3] == RuntimeTypeDescriptorTag.callableTypeParameterOwner) {
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
    for (var i = 0; i < arguments.length; i++) {
      if (!isTypedValueType(arguments[i], descriptor[7 + i])) {
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
    if (!isTypedValueType(value, payloadType)) throw TypeError();
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
    if (returned[0] == lookupType(CoreTypes.future) && returned.length > 2) {
      payloadType = returned[2];
    }
    final futureNominal = lookupType(CoreTypes.future);
    for (var index = 0; index < _typeDescriptors.length; index++) {
      final descriptor = _typeDescriptors[index];
      if (descriptor.length == 3 &&
          descriptor[0] == futureNominal &&
          descriptor[2] == payloadType) {
        return index;
      }
    }
    return null;
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
    // Positional fields are stored first (record literals are
    // positionals-before-named by grammar), so index == ordinal.
    for (var i = 0; i < positional; i++) {
      final fieldType = _recordFieldType(fields[i]);
      fieldIds.add(fieldType);
      matchesTemplate &= fieldType == templateDescriptor[5 + i];
    }
    for (var i = 0; i < named; i++) {
      final nameIndex = templateDescriptor[namedOffset + i * 2];
      final fieldType = _recordFieldType(
        fields[mapping[_constantPool[nameIndex] as String]!],
      );
      fieldIds.add(fieldType);
      matchesTemplate &= fieldType == templateDescriptor[namedOffset + i * 2 + 1];
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
        : _internResolvedType(descriptor, template, null, const [], {});
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

  @pragma('vm:never-inline')
  bool isTypedValueTypeInClassEnvironment(
    Object? value,
    int expected,
    int actualOwnerType,
  ) {
    if (expected < 0 || expected >= _typeDescriptors.length) return false;
    final expectedDescriptor = _typeDescriptors[expected];
    if (expectedDescriptor.length == 2 &&
        (expectedDescriptor[0] == _typedTypeId(CoreTypes.dynamic) ||
            expectedDescriptor[0] == _typedTypeId(CoreTypes.voidType))) {
      return true;
    }
    if (value == null || value is $null) {
      final descriptor = expectedDescriptor;
      final nominal = descriptor[0];
      if (descriptor[1] == 1 ||
          nominal == _typedTypeId(CoreTypes.dynamic) ||
          nominal == _typedTypeId(CoreTypes.nullType)) {
        return true;
      }
      final resolved = _resolveTypeParameter(expected, actualOwnerType);
      if (resolved == null) return true;
      final resolvedDescriptor = _typeDescriptors[resolved];
      return resolvedDescriptor[1] == 1 ||
          resolvedDescriptor[0] == _typedTypeId(CoreTypes.dynamic) ||
          resolvedDescriptor[0] == _typedTypeId(CoreTypes.nullType);
    }
    if (expectedDescriptor.length == 2 &&
        expectedDescriptor[0] == _typedTypeId(CoreTypes.object)) {
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
  }) {
    if (expected < 0 || expected >= _typeDescriptors.length) return false;
    final expectedDescriptor = _typeDescriptors[expected];
    if (expectedDescriptor.length == 2 &&
        (expectedDescriptor[0] == _typedTypeId(CoreTypes.dynamic) ||
            expectedDescriptor[0] == _typedTypeId(CoreTypes.voidType))) {
      return true;
    }
    if (value == null || value is $null) {
      final descriptor = expectedDescriptor;
      if (descriptor[1] == 1) return true;
      final resolved = _resolveTypeParameter(
        expected,
        actualOwnerType,
        typeArguments,
      );
      if (resolved == null) return true;
      final resolvedDescriptor = _typeDescriptors[resolved];
      return resolvedDescriptor[1] == 1 ||
          resolvedDescriptor[0] == _typedTypeId(CoreTypes.dynamic) ||
          resolvedDescriptor[0] == _typedTypeId(CoreTypes.nullType);
    }
    if (expectedDescriptor.length == 2 &&
        expectedDescriptor[0] == _typedTypeId(CoreTypes.object)) {
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
  }) {
    if (typeArguments.length != bounds.length) throw TypeError();
    for (var index = 0; index < typeArguments.length; index++) {
      if (!_isTypedDescriptorSubtypeInEnvironment(
        typeArguments[index],
        bounds[index],
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
  }) => typeArguments.isEmpty
      ? const <int>[]
      : [
          for (final type in typeArguments)
            callableTypeArguments.isEmpty
                ? resolveTypedEnvironmentType(
                    type,
                    actualOwnerType: actualOwnerType,
                  )
                : _resolveEnvironmentType(
                    type,
                    actualOwnerType,
                    callableTypeArguments,
                    <int, int>{},
                  ),
        ];

  /// Resolves a descriptor before it is retained by a value allocated in the
  /// active callable and class type environment.
  int resolveTypedEnvironmentType(
    int type, {
    int? actualOwnerType,
    List<int> callableTypeArguments = const [],
  }) {
    // Most allocations have a concrete descriptor. Do not allocate a recursive
    // substitution map, or rebuild its arguments, for these ordinary values.
    if (!_requiresTypeEnvironment(type)) return type;
    if (callableTypeArguments.isEmpty) {
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
          <int, int>{},
        ),
      );
    }
    return _resolveEnvironmentType(
      type,
      actualOwnerType,
      callableTypeArguments,
      <int, int>{},
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
      yield* descriptor.skip(7).take(descriptor[5]);
      for (
        var index = 7 + descriptor[5];
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
    }
  }

  int _resolveEnvironmentType(
    int type,
    int? actualOwnerType,
    List<int> callableTypeArguments,
    Map<int, int> resolved,
  ) {
    final cached = resolved[type];
    if (cached != null) return cached;
    resolved[type] = type;
    final descriptor = _typeDescriptors[type];
    final parameter = _resolveTypeParameter(
      type,
      actualOwnerType,
      callableTypeArguments,
    );
    if (parameter != null && parameter != type) {
      var result = _resolveEnvironmentType(
        parameter,
        actualOwnerType,
        callableTypeArguments,
        resolved,
      );
      if (descriptor[1] == 1 && _typeDescriptors[result][1] == 0) {
        result = _internResolvedType(
          [_typeDescriptors[result][0], 1, ..._typeDescriptors[result].skip(2)],
          result,
          actualOwnerType,
          callableTypeArguments,
          resolved,
        );
      }
      return resolved[type] = result;
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
            resolved,
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
                resolved,
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
                resolved,
              ),
            );
          }
        case RuntimeTypeDescriptorTag.function:
          translated.addAll([
            descriptor[2],
            _resolveEnvironmentType(
              descriptor[3],
              actualOwnerType,
              callableTypeArguments,
              resolved,
            ),
            descriptor[4],
            descriptor[5],
            descriptor[6],
          ]);
          for (final parameter in descriptor.skip(7).take(descriptor[5])) {
            translated.add(
              _resolveEnvironmentType(
                parameter,
                actualOwnerType,
                callableTypeArguments,
                resolved,
              ),
            );
          }
          for (
            var index = 7 + descriptor[5];
            index < descriptor.length;
            index += 3
          ) {
            translated.addAll([descriptor[index], descriptor[index + 1]]);
            translated.add(
              _resolveEnvironmentType(
                descriptor[index + 2],
                actualOwnerType,
                callableTypeArguments,
                resolved,
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
            resolved,
          );
      }
    }
    if (_sameTypeDescriptor(descriptor, translated)) return type;
    return resolved[type] = _internResolvedType(
      translated,
      type,
      actualOwnerType,
      callableTypeArguments,
      resolved,
    );
  }

  int _internResolvedType(
    List<int> descriptor,
    int source,
    int? actualOwnerType,
    List<int> callableTypeArguments,
    Map<int, int> resolved,
  ) {
    final existing = _findRuntimeTypeDescriptor(descriptor);
    if (existing >= 0) return existing;
    final id = _typeDescriptors.length;
    _typeDescriptors.add(descriptor);
    _typeIdentities.add(null);
    _typeTypes.add({id});
    _typeTableVersion++;
    resolved[source] = id;
    if (source < _typeTypes.length) {
      for (final supertype in _typeTypes[source]) {
        _typeTypes[id].add(
          _resolveEnvironmentType(
            supertype,
            actualOwnerType,
            callableTypeArguments,
            resolved,
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
    List<int> callableTypeArguments,
  ) {
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
  ]) {
    final descriptor = _typeDescriptors[type];
    if (descriptor.length != 6 ||
        descriptor[2] != RuntimeTypeDescriptorTag.typeParameter) {
      return type;
    }
    final ownerNominalType = descriptor[3];
    final parameterIndex = descriptor[4];
    if (ownerNominalType ==
        RuntimeTypeDescriptorTag.callableTypeParameterOwner) {
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
    );
  }

  bool _isTypedDescriptorSubtypeInEnvironment(
    int actual,
    int expected,
    int? actualOwnerType,
    List<int> callableTypeArguments, {
    bool nullableExpected = false,
  }) {
    if (actual < 0 ||
        actual >= _typeDescriptors.length ||
        expected < 0 ||
        expected >= _typeDescriptors.length) {
      return false;
    }
    if (actual == expected) return true;
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
      );
    }
    final source = _typeDescriptors[actual];
    final target = _typeDescriptors[expected];
    final sourceNominal = source[0], targetNominal = target[0];
    if (targetNominal == lookupType(CoreTypes.dynamic)) return true;
    // Never is a subtype of every type.
    if (sourceNominal == _typedTypeId(CoreTypes.never)) return true;
    // Null <: T only when T is nullable or a top type (dynamic handled above).
    if (sourceNominal == _typedTypeId(CoreTypes.nullType)) {
      return target[1] == 1 || nullableExpected;
    }
    if (source[1] == 1 && target[1] == 0 && !nullableExpected) return false;
    final targetTag = target.length > 2 && target[2] < 0 ? target[2] : null;
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
          ),
        RuntimeTypeDescriptorTag.function =>
          _isTypedFunctionSubtypeInClassEnvironment(
            source,
            target,
            actualOwnerType,
            callableTypeArguments,
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
            )) {
          return true;
        }
      }
      return false;
    }
    if (target.length == 2) return true;
    if (source.length != target.length) return false;
    for (var index = 2; index < source.length; index++) {
      if (!_isTypedDescriptorSubtypeInEnvironment(
        source[index],
        target[index],
        actualOwnerType,
        callableTypeArguments,
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
  ]) {
    final sourceRequired = source[4], sourcePositional = source[5];
    final targetRequired = target[4], targetPositional = target[5];
    if (sourceRequired > targetRequired ||
        sourcePositional < targetPositional) {
      return false;
    }
    final targetReturnId =
        _resolveTypeParameter(
          target[3],
          actualOwnerType,
          callableTypeArguments,
        ) ??
        target[3];
    final targetReturn = _typeDescriptors[targetReturnId];
    // In component positions dynamic and void are permissive — a `dynamic`
    // return satisfies any target return type, and a `void` target accepts
    // any source return.
    final sourceReturnId =
        _resolveTypeParameter(
          source[3],
          actualOwnerType,
          callableTypeArguments,
        ) ??
        source[3];
    final sourceReturn = _typeDescriptors[sourceReturnId];
    if (targetReturn[0] != _typedTypeId(CoreTypes.voidType) &&
        sourceReturn[0] != _typedTypeId(CoreTypes.dynamic) &&
        sourceReturn[0] != _typedTypeId(CoreTypes.voidType) &&
        !_isTypedDescriptorSubtypeInEnvironment(
          source[3],
          target[3],
          actualOwnerType,
          callableTypeArguments,
        )) {
      return false;
    }
    for (var i = 0; i < targetPositional; i++) {
      if (!_isTypedFunctionParameterSubtypeInClassEnvironment(
        target[7 + i],
        source[7 + i],
        actualOwnerType,
        callableTypeArguments,
      )) {
        return false;
      }
    }

    Map<Object?, (bool, int)> namedParameters(List<int> descriptor) {
      final positional = descriptor[5], namedCount = descriptor[6];
      final offset = 7 + positional;
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
  ]) {
    final resolvedSource =
        _resolveTypeParameter(source, actualOwnerType, callableTypeArguments) ??
        source;
    final sourceDescriptor = _typeDescriptors[resolvedSource];
    final resolvedTarget =
        _resolveTypeParameter(
          target,
          actualOwnerType,
          callableTypeArguments,
        ) ??
        target;
    if (sourceDescriptor[0] == _typedTypeId(CoreTypes.dynamic)) {
      final targetDescriptor = _typeDescriptors[resolvedTarget];
      return targetDescriptor[0] == _typedTypeId(CoreTypes.dynamic) ||
          (targetDescriptor[0] == _typedTypeId(CoreTypes.object) &&
              targetDescriptor[1] == 1);
    }
    return _isTypedDescriptorSubtypeInEnvironment(
      resolvedSource,
      resolvedTarget,
      actualOwnerType,
      callableTypeArguments,
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
    final callable = object.$getProperty(this, name);
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
