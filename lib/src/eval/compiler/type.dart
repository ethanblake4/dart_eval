import 'package:analyzer/dart/ast/ast.dart';
import 'package:collection/collection.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/expression/method_invocation.dart';
import 'package:dart_eval/src/eval/compiler/model/function_type.dart';

import 'context.dart';
import 'errors.dart';
import 'types/type_decl.dart';

export 'types/type_decl.dart';
export 'types/type_system.dart';
export 'types/runtime_types.dart';
export 'types/type_scope.dart';

/// The action required to assign a value to a typed slot.
enum AssignmentConversion {
  /// The source type is a subtype of the destination type.
  none,

  /// Dart permits the assignment, but the value must be checked at runtime.
  runtimeCheck,

  /// Dart rejects the assignment statically.
  invalid,

  /// `int` into a `double` context — requires an `int → double` widening.
  intToDouble,
}

/// Reference to a type in the compiler. A nominal reference is just a
/// [file] + [name] pair with a [decl]; the declaration owns the resolved
/// structure (supertypes, type parameters) through
/// [CompilerContext.typeSystem].
class TypeRef {
  const TypeRef(
    this.file,
    this.name, {
    this.decl,
    this.specifiedTypeArgs = const [],
    this.recordFields = const [],
    this.functionType,
    this.typeParameterOwner,
    this.typeParameterIndex,
    this.typeParameterBound,
    this.nullable = false,
  });

  final int file;
  final String name;

  /// The declaration this type names — null for type parameters, records,
  /// and the extension namespace pseudo-type.
  final TypeDecl? decl;
  final List<TypeRef> specifiedTypeArgs;
  final List<RecordParameterType> recordFields;
  final EvalFunctionType? functionType;
  final String? typeParameterOwner;
  final int? typeParameterIndex;
  final TypeRef? typeParameterBound;
  final bool nullable;

  /// Given a set of [TypeRef]s, find their closest common ancestor type.
  factory TypeRef.commonBaseType(CompilerContext ctx, Set<TypeRef> types) =>
      ctx.typeSystem.leastUpperBound(types);

  /// Create a [TypeRef] from a [TypeAnnotation] and library ID.
  factory TypeRef.fromAnnotation(
    CompilerContext ctx,
    int library,
    TypeAnnotation typeAnnotation, {
    Map<String, TypeRef> typeParameters = const {},
  }) {
    if (typeAnnotation is GenericFunctionType) {
      return CoreTypes.function
          .ref(ctx)
          .copyWith(
            functionType: EvalFunctionType.fromAnnotation(
              ctx,
              library,
              typeAnnotation,
              typeParameters: typeParameters,
            ),
            nullable: typeAnnotation.question != null,
          );
    }
    if (typeAnnotation is RecordTypeAnnotation) {
      final fields = <RecordParameterType>[];

      var positionalFields = 1;
      for (final field in typeAnnotation.positionalFields) {
        fields.add(
          RecordParameterType(
            '\$${positionalFields++}',
            TypeRef.fromAnnotation(
              ctx,
              library,
              field.type,
              typeParameters: typeParameters,
            ),
            false,
          ),
        );
      }

      for (final field
          in typeAnnotation.namedFields?.fields ??
              <RecordTypeAnnotationNamedField>[]) {
        fields.add(
          RecordParameterType(
            field.name.lexeme,
            TypeRef.fromAnnotation(
              ctx,
              library,
              field.type,
              typeParameters: typeParameters,
            ),
            true,
          ),
        );
      }
      final name = recordTypeName(fields);
      return TypeRef(
        -1,
        name,
        recordFields: fields,
        nullable: typeAnnotation.question != null,
      );
    }
    typeAnnotation as NamedType;
    final prefix = typeAnnotation.importPrefix;
    final n = prefix == null
        ? typeAnnotation.name.stringValue ?? typeAnnotation.name.value()
        : '${prefix.name.lexeme}.${typeAnnotation.name.lexeme}';
    final unspecifiedType =
        typeParameters[n] ??
        ctx.typeScopes[library]?[n] ??
        ctx.visibleTypes[library]?[n];
    if (unspecifiedType == null) {
      final alias = ctx.typeAliases[library]?[n];
      if (alias != null) {
        return resolveTypeAlias(
          ctx,
          library,
          alias,
          nullable: typeAnnotation.question != null,
          typeArgs: typeAnnotation.typeArguments?.arguments,
          callerTypeParameters: typeParameters,
        );
      }
      // `FutureOr<T>` is a union type (`Future<T> | T`), which this compiler
      // cannot represent; it degrades to `dynamic` so `is`/`as` and
      // assignability checks remain permissive in both directions.
      if (n == 'FutureOr') {
        return CoreTypes.dynamic.ref(ctx);
      }
      throw CompileError(
        'Unknown type $n',
        typeAnnotation.parent,
        library,
        ctx,
      );
    }
    final typeArgs = typeAnnotation.typeArguments;
    if (typeArgs != null) {
      final resolved = <TypeRef>[];
      for (final arg in typeArgs.arguments) {
        resolved.add(
          TypeRef.fromAnnotation(
            ctx,
            library,
            arg,
            typeParameters: typeParameters,
          ),
        );
      }
      return unspecifiedType.copyWith(
        specifiedTypeArgs: resolved,
        nullable: typeAnnotation.question != null || unspecifiedType.nullable,
      );
    }
    // A bare type-parameter reference keeps the nullability of its bound
    // value — `T` is nullable when T resolves to `String?`.
    return unspecifiedType.copyWith(
      nullable: typeAnnotation.question != null || unspecifiedType.nullable,
    );
  }

  /// Create a [TypeRef] from a [BridgeTypeAnnotation].
  factory TypeRef.fromBridgeAnnotation(
    CompilerContext ctx,
    BridgeTypeAnnotation typeAnnotation, {
    TypeRef? specifyingType,
    TypeRef? specifiedType,
    Map<String, TypeRef> typeParameters = const {},
  }) {
    return TypeRef.fromBridgeTypeRef(
      ctx,
      typeAnnotation.type,
      specifyingType: specifyingType,
      specifiedType: specifiedType,
      typeParameters: typeParameters,
    ).copyWith(nullable: typeAnnotation.nullable);
  }

  factory TypeRef.fromBridgeTypeRef(
    CompilerContext ctx,
    BridgeTypeRef typeReference, {
    TypeRef? specifyingType,
    TypeRef? specifiedType,
    Map<String, TypeRef> typeParameters = const {},
  }) {
    final cacheId = typeReference.cacheId;
    if (cacheId != null) {
      final t = ctx.runtimeTypes.list[cacheId];
      return ctx.bridgeTypeRefCache.putIfAbsent(cacheId, () => t);
    }
    final spec = typeReference.spec;
    if (spec != null) {
      final specifiedTypeArgs = <TypeRef>[];
      for (final arg in typeReference.typeArgs) {
        specifiedTypeArgs.add(
          TypeRef.fromBridgeAnnotation(
            ctx,
            arg,
            specifiedType: specifiedType,
            typeParameters: typeParameters,
          ),
        );
      }
      final lib =
          ctx.libraryMap[spec.library] ??
          (throw CompileError('Bridge: cannot find library ${spec.library}'));
      final typeSpec =
          ctx.visibleTypes[lib]![spec.name] ??
          (throw CompileError(
            'Bridge: cannot find type ${spec.name} in library ${spec.library}',
          ));
      return typeSpec.copyWith(specifiedTypeArgs: specifiedTypeArgs);
    }
    final ref = typeReference.ref;
    if (ref != null) {
      final typeParameter = typeParameters[ref];
      if (typeParameter != null) return typeParameter;
      specifiedType ??= ctx.visibleTypes[ctx.library]![ctx.currentClassName];

      if (specifiedType == null) {
        return CoreTypes.dynamic.ref(ctx);
      }

      final declaration =
          ctx.topLevelDeclarationsMap[specifiedType.file]![specifiedType.name]!;
      if (!declaration.isBridge) {
        // `ref` is declared on a bridge type, but [specifiedType] is a plain
        // class — resolve through a bridged ancestor in its chain (e.g. a
        // Dart class extending `List<T>`), else degrade to dynamic.
        return ctx.typeSystem.bridgedTypeArgument(specifiedType, ref) ??
            CoreTypes.dynamic.ref(ctx);
      }
      final dec = declaration.bridge!;
      if (dec is! BridgeClassDef) {
        throw CompileError(
          'Trying to resolve bridged generic type $ref on $specifiedType, which is not a bridge class',
        );
      }

      final genericIndex = dec.type.generics.keys.toList().indexWhere(
        (key) => key == ref,
      );
      if (genericIndex >= 0 &&
          genericIndex < specifiedType.specifiedTypeArgs.length) {
        return specifiedType.specifiedTypeArgs[genericIndex];
      }
      final generic = dec.type.generics[ref];
      if (generic == null) return CoreTypes.dynamic.ref(ctx);
      final $extends = generic.$extends;
      final boundType = $extends == null
          ? CoreTypes.dynamic.ref(ctx)
          : TypeRef.fromBridgeTypeRef(ctx, $extends);

      if (specifyingType != null && genericIndex >= 0) {
        final instantiatedType =
            [
              specifyingType,
              ...ctx.typeSystem.superclassChain(specifyingType),
            ].firstWhereOrNull(
              (candidate) =>
                  candidate.hasSameDeclarationAs(specifiedType!) &&
                  genericIndex < candidate.specifiedTypeArgs.length,
            );
        if (instantiatedType != null) {
          final resolvedDeclaredType =
              instantiatedType.specifiedTypeArgs[genericIndex];
          if (!resolvedDeclaredType.isAssignableTo(ctx, boundType)) {
            throw CompileError(
              "Type argument $resolvedDeclaredType does not conform to type parameter $ref's"
              "bound ($boundType)",
            );
          }
          return resolvedDeclaredType;
        }
      }

      return boundType;
    }
    final gft = typeReference.gft;
    if (gft != null) {
      return CoreTypes.function
          .ref(ctx)
          .copyWith(
            functionType: EvalFunctionType.fromBridgeFunctionDef(
              ctx,
              gft,
              typeParameters: typeParameters,
            ),
          );
    }
    throw CompileError(
      'No support for looking up types by other bridge annotation types',
    );
  }

  static TypeRef? $this(CompilerContext ctx) {
    final currentClass = ctx.currentClass;
    if (currentClass == null) {
      return null;
    }
    final ref = TypeRef.lookupDeclaration(
      ctx,
      ctx.enclosingLibrary ?? ctx.library,
      currentClass,
    );
    // Inside the class, `this` is self-instantiated: `C<T>` where `T` is the
    // class's own parameter — not the raw declaration type `C<dynamic>`.
    final decl = ref.decl;
    if (decl != null && decl.typeParameters.isNotEmpty) {
      final params = classLikeClauses(currentClass).$4;
      final refs = classTypeParameterRefs(ref.file, ref.name, params);
      if (refs.isNotEmpty) {
        return ref.copyWith(specifiedTypeArgs: refs.values.toList());
      }
    }
    return ref;
  }

  factory TypeRef.lookupDeclaration(
    CompilerContext ctx,
    int library,
    Declaration dec, {
    String? prefix,
  }) {
    final name = declarationName(dec);
    return ctx
            .visibleTypes[library]!['${prefix != null ? '$prefix.' : ''}$name'] ??
        (throw CompileError('Class/enum $name not found'));
  }

  static TypeRef? lookupFieldType(
    CompilerContext ctx,
    TypeRef $class,
    String field, {
    bool forFieldFormal = false,
    bool forSet = false,
    AstNode? source,
    Map<(String, int), TypeRef> substitutions = const {},
  }) {
    if ($class.isSpec(CoreTypes.dynamic)) {
      return null;
    }

    if ($class.isTypeParameter) {
      final bound = $class.typeParameterBound;
      if (bound == null) return null;
      return TypeRef.lookupFieldType(
        ctx,
        bound,
        field,
        forFieldFormal: forFieldFormal,
        forSet: forSet,
        source: source,
        substitutions: substitutions,
      );
    }

    if ($class.recordFields.isNotEmpty) {
      final field0 = $class.recordFields.firstWhereOrNull(
        (f) => f.name == field,
      );
      if (field0 != null) {
        return field0.type;
      }
    }
    if (ctx.instanceDeclarationsMap[$class.file]!.containsKey($class.name)) {
      final $declarations =
          ctx.instanceDeclarationsMap[$class.file]![$class.name]!;
      // Member annotations can reference the class's type parameters; resolve
      // them in the class's type environment rather than the caller's.
      final classDecl =
          ctx.topLevelDeclarationsMap[$class.file]![$class.name]!.declaration;
      final typeParams = classLikeClauses(classDecl).$4?.typeParameters;
      var memberMatched = true;
      final resolved = ctx.withTypeParameters(
        $class.file,
        'class:${$class.file}:${$class.name}',
        typeParams,
        () {
          // A raw type use substitutes the parameter's bound (instantiate to
          // bounds); otherwise the argument at the same position.
          TypeRef substituteClassTypeArguments(TypeRef resolved) {
            final localSubstitutions = <(String, int), TypeRef>{
              ...substitutions,
            };
            for (var i = 0; i < (typeParams?.length ?? 0); i++) {
              final bound = ctx
                  .typeScopes[$class.file]![typeParams![i].name.lexeme]!
                  .typeParameterBound;
              final arg = i < $class.specifiedTypeArgs.length
                  ? $class.specifiedTypeArgs[i]
                  : (bound ?? CoreTypes.dynamic.ref(ctx));
              localSubstitutions[('class:${$class.file}:${$class.name}', i)] =
                  arg.substituteTypeParameters(substitutions);
            }
            if (localSubstitutions.isEmpty) return resolved;
            return resolved.substituteTypeParameters(localSubstitutions);
          }

          if (forSet) {
            if ($declarations.containsKey('$field*s')) {
              final f = $declarations['$field*s'];
              if (f is! MethodDeclaration) {
                throw CompileError(
                  'Cannot query setter type of F${$class.file}:${$class.name}.$field, which is not a method',
                  source,
                );
              }
              final parameter = f.parameters!.parameters.first;
              final annotation = parameter.type;
              if (annotation == null) {
                return null;
              }
              return substituteClassTypeArguments(
                TypeRef.fromAnnotation(ctx, $class.file, annotation),
              );
            }
          }
          if ($declarations.containsKey(field)) {
            final f = $declarations[field];
            if (f is MethodDeclaration && !f.isGetter && !f.isSetter) {
              return CoreTypes.function.ref(ctx);
            }
            if (f is! VariableDeclaration) {
              throw CompileError(
                'Cannot query field type of ${$class.name}.$field, which is not a field',
                source,
              );
            }
            final annotation = (f.parent as VariableDeclarationList).type;
            if (annotation != null) {
              return substituteClassTypeArguments(
                TypeRef.fromAnnotation(ctx, $class.file, annotation),
              );
            }
            if (ctx.inferredFieldTypes.containsKey($class.file) &&
                ctx.inferredFieldTypes[$class.file]!.containsKey($class.name) &&
                ctx.inferredFieldTypes[$class.file]![$class.name]!.containsKey(
                  field,
                )) {
              return ctx.inferredFieldTypes[$class.file]![$class.name]![field]!;
            }
            return null;
          }
          if (!forFieldFormal && $declarations.containsKey('$field*g')) {
            final f = $declarations['$field*g'];
            if (f is! MethodDeclaration) {
              throw CompileError(
                'Cannot query getter type of F${$class.file}:${$class.name}.$field, which is not a method',
                source,
              );
            }
            final annotation = f.returnType;
            if (annotation == null) {
              return null;
            }
            return substituteClassTypeArguments(
              TypeRef.fromAnnotation(ctx, $class.file, annotation),
            );
          }
          memberMatched = false;
          return null;
        },
      );
      if (memberMatched) return resolved;
    }
    final dec0 = ctx.topLevelDeclarationsMap[$class.file]?[$class.name];
    if (dec0 == null) {
      // Structural types (records, function types) have no declaration of
      // their own; their members come from the nominal supertype.
      final extendsType = ctx.typeSystem.superclassOf($class);
      if (extendsType == null) return null;
      return TypeRef.lookupFieldType(
        ctx,
        extendsType,
        field,
        forFieldFormal: forFieldFormal,
        forSet: forSet,
        source: source,
        substitutions: substitutions,
      );
    }
    final dec = dec0;

    if (dec.isBridge) {
      final bridge = dec.bridge!;
      if (bridge is BridgeEnumDef) {
        final fd = bridge.fields[field];
        if (fd != null) {
          return TypeRef.fromBridgeAnnotation(
            ctx,
            fd.type,
            specifiedType: $class,
          );
        }
        final get = bridge.getters[field];
        if (get != null) {
          return TypeRef.fromBridgeAnnotation(
            ctx,
            get.functionDescriptor.returns,
            specifiedType: $class,
          );
        }
        return TypeRef.lookupFieldType(
          ctx,
          CoreTypes.enumType.ref(ctx),
          field,
          source: source,
        );
      }
      final br = bridge as BridgeClassDef;
      final fd = br.fields[field];
      if (fd != null) {
        return TypeRef.fromBridgeAnnotation(
          ctx,
          fd.type,
          specifiedType: $class,
        );
      }
      final get = br.getters[field];
      if (get != null) {
        return TypeRef.fromBridgeAnnotation(
          ctx,
          get.functionDescriptor.returns,
          specifiedType: $class,
        );
      }
      final set = br.getters[field];
      if (set != null) {
        return TypeRef.fromBridgeAnnotation(
          ctx,
          set.functionDescriptor.returns,
          specifiedType: $class,
        );
      }
      final $extends = br.type.$extends;
      if ($extends == null) {
        throw CompileError(
          'Field $field not found in bridge class ${$class}',
          source,
        );
      } else {
        final $super = TypeRef.fromBridgeTypeRef(
          ctx,
          $extends,
          specifiedType: $class,
        );
        return TypeRef.lookupFieldType(
          ctx,
          ctx.typeSystem.asInstanceOf($class, $super.decl) ?? $super,
          field,
          source: source,
        );
      }
    } else if (dec.declaration is EnumDeclaration && field == 'index') {
      return CoreTypes.int.ref(ctx);
    } else if (dec.declaration is EnumDeclaration && field == 'name') {
      return CoreTypes.string.ref(ctx);
    } else {
      if (forFieldFormal) {
        throw CompileError(
          'Field formals did not find field $field in class ${$class}',
          source,
        );
      }
      final superclass = ctx.typeSystem.superclassOf($class);
      if (superclass == null) {
        if ($class.isSpec(CoreTypes.object)) {
          throw CompileError(
            'Field $field not found in class ${$class} or its superclasses',
            source,
          );
        }
        return TypeRef.lookupFieldType(ctx, CoreTypes.object.ref(ctx), field);
      }
      // Fold the caller's surviving substitutions into the instantiated
      // superclass reference so member types keep resolving through them.
      return TypeRef.lookupFieldType(
        ctx,
        superclass.substituteTypeParameters(substitutions),
        field,
        source: source,
        substitutions: substitutions,
      );
    }
  }

  String get semanticKey =>
      '${isTypeParameter ? 'parameter:$typeParameterOwner:$typeParameterIndex' : '$file:$name'}${nullable ? '?' : ''}'
      '${specifiedTypeArgs.isEmpty ? '' : '<${specifiedTypeArgs.map((type) => type.semanticKey).join(',')}>'}'
      '${recordFields.isEmpty ? '' : ':record:${recordFields.map((field) => '${field.isNamed ? 'n' : 'p'}:${field.name}:${field.type.semanticKey}').join(',')}'}'
      '${functionType == null ? '' : ':fn:${functionType!.semanticKey()}'}';

  /// The canonical `@record` type name for [fields]: positionals in order,
  /// then named fields sorted by name — the single identity shared by every
  /// record producer so `(int, {b: B, a: A})` and `(int, {a: A, b: B})` are
  /// the same type.
  static String recordTypeName(List<RecordParameterType> fields) {
    final name = StringBuffer('@record<');
    var first = true;
    void comma() {
      if (first) {
        first = false;
      } else {
        name.write(',');
      }
    }

    for (final field in fields) {
      if (field.isNamed) continue;
      comma();
      name.write('${field.type}');
    }
    final named = [
      for (final field in fields)
        if (field.isNamed) field,
    ]..sort((a, b) => a.name!.compareTo(b.name!));
    if (named.isNotEmpty) {
      comma();
      name.write('{');
      for (var i = 0; i < named.length; i++) {
        if (i > 0) name.write(',');
        name.write('${named[i].name}:${named[i].type}');
      }
      name.write('}');
    }
    name.write('>');
    return name.toString();
  }

  /// Whether two references name the same declaration. This intentionally
  /// ignores type arguments, nullability, and representation details.
  bool hasSameDeclarationAs(TypeRef other) =>
      isTypeParameter || other.isTypeParameter
      ? isTypeParameter &&
            other.isTypeParameter &&
            typeParameterOwner == other.typeParameterOwner &&
            typeParameterIndex == other.typeParameterIndex
      : (file == other.file || isRecord) && name == other.name;

  /// Whether this type names the declaration [spec] refers to. Nullability
  /// and type arguments are ignored, matching today's nominal `==`.
  bool isSpec(BridgeTypeSpec spec) => decl?.isSpec(spec) ?? false;

  /// Whether this type's declaration lives in `dart:core`.
  bool get isDartCore => decl?.isDartCore ?? false;

  /// Records have no declaration — the canonical `@record` name is the only
  /// identity ([recordFields] may be empty for the `()` record).
  bool get isRecord => name.startsWith('@record');

  /// Whether every value of this type reports exactly this runtime type:
  /// leaf classes that cannot be subclassed (`int`, `double`, `bool`,
  /// `String`, `Null`) and records built entirely of them. Nullable and
  /// subclassable types can hold values whose runtime type is narrower.
  /// Used to skip record-type reification when it can never change the
  /// declared record type.
  bool hasFixedRuntimeType(CompilerContext ctx) {
    if (nullable) return false;
    if (isRecord) {
      return recordFields.every((f) => f.type.hasFixedRuntimeType(ctx));
    }
    return isSpec(CoreTypes.int) ||
        isSpec(CoreTypes.double) ||
        isSpec(CoreTypes.bool) ||
        isSpec(CoreTypes.string) ||
        isSpec(CoreTypes.nullType);
  }

  /// Positional record fields in declaration order — [recordFields] lists
  /// fields in source order, which may interleave positional and named.
  List<RecordParameterType> get recordPositionalFields =>
      recordFields.positionalFields;

  /// Named record fields sorted by name (the canonical/descriptor order).
  List<RecordParameterType> get recordNamedFields => recordFields.namedFields;

  bool get isTypeParameter => typeParameterIndex != null;

  bool get isClassTypeParameter =>
      isTypeParameter && typeParameterOwner!.startsWith('class:');

  /// Whether the runtime descriptor for this type embeds a type parameter,
  /// so its id must be resolved against the active type environment.
  bool get requiresTypeEnvironment =>
      isTypeParameter ||
      specifiedTypeArgs.any((arg) => arg.requiresTypeEnvironment);

  /// Semantic type equality for language checks. Unlike [operator ==], this
  /// includes nullability, type arguments, record fields, and function shape.
  bool isSameSemanticType(CompilerContext ctx, TypeRef other) {
    final left = this;
    final right = other;
    if (!left.hasSameDeclarationAs(right) ||
        left.nullable != right.nullable ||
        left.specifiedTypeArgs.length != right.specifiedTypeArgs.length ||
        left.recordFields.length != right.recordFields.length) {
      return false;
    }
    for (var i = 0; i < left.specifiedTypeArgs.length; i++) {
      if (!left.specifiedTypeArgs[i].isSameSemanticType(
        ctx,
        right.specifiedTypeArgs[i],
      )) {
        return false;
      }
    }
    for (var i = 0; i < left.recordFields.length; i++) {
      final a = left.recordFields[i], b = right.recordFields[i];
      if (a.name != b.name ||
          a.isNamed != b.isNamed ||
          !a.type.isSameSemanticType(ctx, b.type)) {
        return false;
      }
    }
    // Function types are currently represented by their analyzer model. Do not
    // accidentally equate a structural function type with plain Function.
    return left.functionType?.semanticKey() ==
        right.functionType?.semanticKey();
  }

  /// Classifies Dart assignment compatibility of a [this] value into a
  /// [slot] without conflating `dynamic` with a subtype proof.
  AssignmentConversion assignmentConversionTo(
    CompilerContext ctx,
    TypeRef slot,
  ) => ctx.typeSystem.assignmentConversion(this, slot);

  /// Checks whether a value of this type can be assigned to the
  /// field of the type [slot]. This is the main check for assignments,
  /// but also useful to check for function types.
  ///
  /// When [forceAllowDynamic] is set (which is the default), immediately
  /// returns "true" if [this] or [slot] are of the dynamic type. Disable
  /// when needed to enforce type strictness.
  ///
  /// You most likely won't need to use [overrideGenerics]: it uses the
  /// type arguments by default, as it should.
  bool isAssignableTo(
    CompilerContext ctx,
    TypeRef slot, {
    List<TypeRef>? overrideGenerics,
    bool forceAllowDynamic = true,
  }) => ctx.typeSystem.isAssignable(
    this,
    slot,
    overrideGenerics: overrideGenerics,
    forceAllowDynamic: forceAllowDynamic,
  );

  TypeRef copyWith({
    int? file,
    String? name,
    TypeDecl? decl,
    List<TypeRef>? specifiedTypeArgs,
    List<RecordParameterType>? recordFields,
    EvalFunctionType? functionType,
    String? typeParameterOwner,
    int? typeParameterIndex,
    TypeRef? typeParameterBound,
    bool? nullable,
  }) {
    return TypeRef(
      file ?? this.file,
      name ?? this.name,
      decl: decl ?? this.decl,
      specifiedTypeArgs: specifiedTypeArgs ?? this.specifiedTypeArgs,
      functionType: functionType ?? this.functionType,
      typeParameterOwner: typeParameterOwner ?? this.typeParameterOwner,
      typeParameterIndex: typeParameterIndex ?? this.typeParameterIndex,
      typeParameterBound: typeParameterBound ?? this.typeParameterBound,
      recordFields: recordFields ?? this.recordFields,
      nullable: nullable ?? this.nullable,
    );
  }

  /// Replaces every free type-parameter reference inside this type with its
  /// declared bound (or `dynamic` when unbounded). Callers use this when a
  /// type leaves the scope that gave those parameters meaning — an
  /// unconstrained `T` is not a usable type for the caller.
  TypeRef lowerTypeParameters(CompilerContext ctx) =>
      ctx.typeSystem.lowerTypeParameters(this);

  /// Replaces retained type-parameter references anywhere inside this type.
  TypeRef substituteTypeParameters(Map<(String, int), TypeRef> substitutions) {
    if (isTypeParameter) {
      final replacement =
          substitutions[(typeParameterOwner!, typeParameterIndex!)];
      if (replacement != null) {
        return replacement.copyWith(nullable: nullable || replacement.nullable);
      }
      return this;
    }
    if (specifiedTypeArgs.isEmpty &&
        recordFields.isEmpty &&
        functionType == null) {
      return this;
    }

    FunctionTypeAnnotation substituteAnnotation(FunctionTypeAnnotation value) {
      final type = value.type;
      return type == null
          ? value
          : FunctionTypeAnnotation.type(
              type.substituteTypeParameters(substitutions),
            );
    }

    FunctionFormalParameter substituteParameter(
      FunctionFormalParameter value,
    ) => FunctionFormalParameter(
      value.name,
      substituteAnnotation(value.type),
      value.isRequired,
    );

    final signature = functionType;
    return copyWith(
      specifiedTypeArgs: [
        for (final argument in specifiedTypeArgs)
          argument.substituteTypeParameters(substitutions),
      ],
      recordFields: [
        for (final field in recordFields)
          RecordParameterType(
            field.name,
            field.type.substituteTypeParameters(substitutions),
            field.isNamed,
          ),
      ],
      functionType: signature == null
          ? null
          : EvalFunctionType(
              [
                for (final parameter in signature.normalParameters)
                  substituteParameter(parameter),
              ],
              [
                for (final parameter in signature.optionalParameters)
                  substituteParameter(parameter),
              ],
              {
                for (final entry in signature.namedParameters.entries)
                  entry.key: substituteParameter(entry.value),
              },
              substituteAnnotation(signature.returnType),
              [
                for (final generic in signature.generics)
                  FunctionGenericParam(
                    generic.name,
                    bound: generic.bound == null
                        ? null
                        : substituteAnnotation(generic.bound!),
                  ),
              ],
            ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TypeRef &&
          runtimeType == other.runtimeType &&
          (isTypeParameter || other.isTypeParameter
              ? typeParameterOwner == other.typeParameterOwner &&
                    typeParameterIndex == other.typeParameterIndex
              : (file == other.file || isRecord) && name == other.name);

  @override
  int get hashCode => isTypeParameter
      ? Object.hash(typeParameterOwner, typeParameterIndex)
      : isRecord
      ? name.hashCode
      : file.hashCode ^ name.hashCode;

  @override
  String toString() {
    return name;
  }

  /// Convert to string while clarifying the source file if the name is the same
  /// as another type being printed.
  String toStringClear(CompilerContext ctx, TypeRef other) {
    if (name == other.name) {
      String? library;
      for (final entry in ctx.libraryMap.entries) {
        if (entry.value == file) {
          library = entry.key;
        }
      }
      return '$name (from "$library")';
    } else {
      return name;
    }
  }

  static void loadTemporaryTypes(
    CompilerContext ctx,
    List<TypeParameter>? typeParams, {
    int? library,
    String? owner,
    bool resolveBounds = true,
  }) {
    if (typeParams == null) return;
    final lib = library ?? ctx.library;
    final temps = ctx.typeParameterScope(lib);
    // First seed every parameter name so F-bounds can self-reference
    // (`T extends Foo<T>`): the bound resolves while `T` is visible.
    for (var index = 0; index < typeParams.length; index++) {
      final param = typeParams[index];
      temps[param.name.lexeme] = TypeRef(
        lib,
        param.name.lexeme,
        typeParameterOwner: owner ?? 'function:${ctx.currentFunctionId ?? -1}',
        typeParameterIndex: index,
      );
    }
    if (!resolveBounds) return;
    for (var index = 0; index < typeParams.length; index++) {
      final param = typeParams[index];
      final bound = param.bound;
      if (bound != null) {
        temps[param.name.lexeme] = temps[param.name.lexeme]!.copyWith(
          typeParameterBound: TypeRef.fromAnnotation(ctx, lib, bound),
        );
      }
    }
    // A bound naming another parameter declared later (`T extends U,
    // U extends C`) captures U's still-unbound ref in the first pass —
    // re-resolve now that every bound is populated.
    for (var index = 0; index < typeParams.length; index++) {
      final param = typeParams[index];
      final bound = param.bound;
      if (bound != null &&
          temps[param.name.lexeme]!.typeParameterBound?.isTypeParameter ==
              true) {
        temps[param.name.lexeme] = temps[param.name.lexeme]!.copyWith(
          typeParameterBound: TypeRef.fromAnnotation(ctx, lib, bound),
        );
      }
    }
  }
}

/// The superclass, mixin, implements, and type-parameter clauses of a
/// class-like declaration — class, enum, mixin, or class type alias — in one
/// record. For a mixin the "superclass" is its `on` clause constraint, and for
/// a class type alias (`class C = S with M`) the clauses come from the alias
/// itself. Returns nulls for declarations without such clauses.
(NamedType?, List<NamedType>, List<NamedType>, TypeParameterList?)
classLikeClauses(Declaration? dec) => switch (dec) {
  ClassDeclaration(
    :final extendsClause,
    :final withClause,
    :final implementsClause,
    :final namePart,
  ) =>
    (
      extendsClause?.superclass,
      withClause?.mixinTypes.toList() ?? const <NamedType>[],
      implementsClause?.interfaces.toList() ?? const <NamedType>[],
      namePart.typeParameters,
    ),
  EnumDeclaration(
    :final withClause,
    :final implementsClause,
    :final namePart,
  ) =>
    (
      null,
      withClause?.mixinTypes.toList() ?? const <NamedType>[],
      implementsClause?.interfaces.toList() ?? const <NamedType>[],
      namePart.typeParameters,
    ),
  MixinDeclaration(
    :final onClause,
    :final implementsClause,
    :final typeParameters,
  ) =>
    (
      onClause?.superclassConstraints.firstOrNull,
      const <NamedType>[],
      implementsClause?.interfaces.toList() ?? const <NamedType>[],
      typeParameters,
    ),
  ClassTypeAlias(
    :final superclass,
    :final withClause,
    :final implementsClause,
    :final typeParameters,
  ) =>
    (
      superclass,
      withClause.mixinTypes.toList(),
      implementsClause?.interfaces.toList() ?? const <NamedType>[],
      typeParameters,
    ),
  _ => (null, const <NamedType>[], const <NamedType>[], null),
};

/// For `super` in a class declared with `with` mixins, the mixin-application
/// layer's members are folded into the applying class's declaration maps.
/// Returns the applying class's [TypeRef] — under which the folded member is
/// compiled — when [name] resolves to a member of one of those mixins
/// (checked last-to-first, matching application order). Returns null when the
/// member being compiled is itself folded in from a mixin — `super` there
/// refers to the mixin's `on` constraint — or when no mixin declares [name].
TypeRef? superMixinMemberOwner(CompilerContext ctx, String name) {
  if (ctx.memberDeclaringClass != null) return null;
  final hostDecl = ctx.currentClass;
  if (hostDecl == null) return null;
  for (final mixinType in classLikeClauses(hostDecl).$2.reversed) {
    final prefix = mixinType.importPrefix;
    final mixinName = prefix == null
        ? mixinType.name.lexeme
        : '${prefix.name.lexeme}.${mixinType.name.lexeme}';
    var ref = ctx.visibleTypes[ctx.library]![mixinName];
    final alias = ctx.typeAliases[ctx.library]?[mixinName];
    if (ref == null && alias != null) {
      ref = resolveTypeAlias(
        ctx,
        ctx.library,
        alias,
        typeArgs: mixinType.typeArguments?.arguments,
      );
    }
    if (ref == null) continue;
    final declarations = ctx.instanceDeclarationsMap[ref.file]?[ref.name];
    if (declarations == null) continue;
    if (declarations.containsKey(name) ||
        declarations.containsKey('$name*g') ||
        declarations.containsKey('$name*s')) {
      return TypeRef.lookupDeclaration(ctx, ctx.library, hostDecl);
    }
  }
  return null;
}

/// Normalizes a parsed constructor name: `.new` names the unnamed
/// constructor, whose internal name is the empty string.
String ctorNameOf(String? name) => name == 'new' ? '' : name ?? '';

/// Splits an instance-creation's type head into the class-name key and the
/// constructor selector. The analyzer represents `p.C()`, `p.C.n()`, and
/// `C.n()` alike as `NamedType(importPrefix: first, name: second)` plus an
/// optional trailing selector, so whether the first segment is an import
/// prefix (vs. the class itself) is decided by [ctx]'s visible declarations.
(String typeName, String ctorName) splitConstructorTypeName(
  CompilerContext ctx,
  int library,
  NamedType type,
  String? trailingSelector,
) {
  final ctorName = ctorNameOf(trailingSelector);
  final prefix = type.importPrefix;
  if (prefix != null &&
      ctx.visibleDeclarations[library]?[prefix.name.lexeme]?.children != null) {
    // `prefix.C.new`: trailing selector already folded into [ctorName].
    return ('${prefix.name.lexeme}.${type.name.lexeme}', ctorName);
  }
  if (prefix != null) {
    // `C.new` parses `C` as the prefix and `new` as the type name.
    if (type.name.lexeme == 'new') {
      return (prefix.name.lexeme, '');
    }
    return (prefix.name.lexeme, type.name.lexeme);
  }
  return (type.name.lexeme, ctorName);
}

class RecordParameterType {
  const RecordParameterType(this.name, this.type, this.isNamed);

  final String? name;
  final TypeRef type;
  final bool isNamed;

  @override
  String toString() {
    return '$name: ${type.toString()}';
  }
}

extension RecordParameterTypeList on List<RecordParameterType> {
  /// Positional fields in declaration order — a record's field list may
  /// interleave positional and named entries in source order.
  List<RecordParameterType> get positionalFields => [
    for (final field in this)
      if (!field.isNamed) field,
  ];

  /// Named fields sorted by name (the canonical/descriptor order).
  List<RecordParameterType> get namedFields => [
    for (final field in this)
      if (field.isNamed) field,
  ]..sort((a, b) => a.name!.compareTo(b.name!));
}

/// Computes the [ReturnType] of a bridged function descriptor, including
/// parameter-type-dependent return types carried by
/// [BridgeFunctionDef.returnTypeDependency].
ReturnType bridgeFunctionReturnType(
  CompilerContext ctx,
  BridgeFunctionDef fd, {
  TypeRef? specifiedType,
  Map<String, TypeRef> typeParameters = const {},
}) {
  AlwaysReturnType toReturnType(BridgeTypeAnnotation annotation) =>
      AlwaysReturnType(
        TypeRef.fromBridgeAnnotation(
          ctx,
          annotation,
          specifiedType: specifiedType,
          typeParameters: typeParameters,
        ),
        annotation.nullable,
      );
  final dep = fd.returnTypeDependency;
  if (dep == null) {
    return toReturnType(fd.returns);
  }
  return ParameterTypeDependentReturnType(
    {
      for (final c in dep.cases)
        TypeRef.fromBridgeTypeRef(ctx, c.when): toReturnType(c.then),
    },
    paramIndex: dep.paramIndex,
    paramName: dep.paramName,
    fallback: toReturnType(dep.fallback ?? fd.returns),
  );
}

abstract class ReturnType {
  AlwaysReturnType? toAlwaysReturnType(
    CompilerContext ctx,
    TypeRef? targetType,
    List<TypeRef?> argTypes,
    Map<String, TypeRef?> namedArgTypes, {
    List<TypeRef> typeArgs = const [],
  });
}

class BridgedReturnType implements ReturnType {
  final BridgeTypeSpec spec;
  final bool nullable;

  BridgedReturnType(this.spec, this.nullable);

  @override
  AlwaysReturnType? toAlwaysReturnType(
    CompilerContext ctx,
    TypeRef? targetType,
    List<TypeRef?> argTypes,
    Map<String, TypeRef?> namedArgTypes, {
    List<TypeRef> typeArgs = const [],
  }) {
    final rt = TypeRef.fromBridgeTypeRef(ctx, BridgeTypeRef(spec));
    return AlwaysReturnType(rt, nullable);
  }
}

/// Resolves an instance member's declared return type with the declaring
/// class's type parameters in scope, instantiated to [receiverType]'s
/// arguments when the member is declared on the receiver's own class.
AlwaysReturnType _memberReturnAnnotation(
  CompilerContext ctx,
  TypeRef receiverType,
  ClassMember member,
  TypeRef? fallback, {
  int? declaringFile,
}) {
  final returnType = (member as MethodDeclaration).returnType;
  final host = member.parent?.parent;
  final hostName = host is Declaration ? declarationName(host) : null;
  final hostTypeParams = host is Declaration ? classLikeClauses(host).$4 : null;
  if (hostName == null) {
    return AlwaysReturnType.fromAnnotation(
      ctx,
      receiverType.file,
      returnType,
      fallback,
    );
  }
  final hostFile = declaringFile ?? receiverType.file;
  final rt = AlwaysReturnType.fromAnnotation(
    ctx,
    hostFile,
    returnType,
    fallback,
    typeParameters: classTypeParameterRefs(hostFile, hostName, hostTypeParams),
  );
  if (rt.type == null ||
      hostTypeParams == null ||
      hostTypeParams.typeParameters.isEmpty) {
    return rt;
  }
  // Instantiate the declaring class's parameters from the receiver — either
  // the receiver itself or the matching transitive supertype (`C<E>` in
  // `class B<T> with M<T>` where `M<S> implements C<S>`).
  final declaringType = hostName == receiverType.name
      ? receiverType
      : ctx.typeSystem.asInstanceOf(
          receiverType,
          ctx.types.find(hostFile, hostName),
        );
  if (declaringType == null || declaringType.specifiedTypeArgs.isEmpty) {
    return rt;
  }
  final subs = <(String, int), TypeRef>{
    for (var i = 0; i < hostTypeParams.typeParameters.length; i++)
      ('class:$hostFile:$hostName', i): declaringType.specifiedTypeArgs[i],
  };
  return AlwaysReturnType(rt.type!.substituteTypeParameters(subs), rt.nullable);
}

class AlwaysReturnType implements ReturnType {
  const AlwaysReturnType(this.type, this.nullable);

  factory AlwaysReturnType.fromAnnotation(
    CompilerContext ctx,
    int library,
    TypeAnnotation? typeAnnotation,
    TypeRef? fallback, {
    Map<String, TypeRef> typeParameters = const {},
  }) {
    final rt = typeAnnotation;
    if (rt != null) {
      return AlwaysReturnType(
        TypeRef.fromAnnotation(
          ctx,
          library,
          rt,
          typeParameters: typeParameters,
        ),
        rt.question != null,
      );
    } else {
      return AlwaysReturnType(fallback, true);
    }
  }

  factory AlwaysReturnType.fromInstanceMethod(
    CompilerContext ctx,
    TypeRef type,
    String method,
    TypeRef? fallback,
  ) {
    final m = resolveInstanceMethod(ctx, type, method);
    if (m.isBridge) {
      return bridgeFunctionReturnType(
        ctx,
        m.bridge!.functionDescriptor,
        specifiedType: type,
      ).toAlwaysReturnType(ctx, type, const [], const {})!;
    }
    final d = m.declaration!;
    if (d is! MethodDeclaration) {
      // A field holding a callable — its call signature isn't modelled here.
      return AlwaysReturnType(fallback ?? CoreTypes.dynamic.ref(ctx), true);
    }
    return _memberReturnAnnotation(
      ctx,
      type,
      d,
      fallback,
      declaringFile: m.sourceLib,
    );
  }

  factory AlwaysReturnType.fromStaticMethod(
    CompilerContext ctx,
    TypeRef type,
    String method,
    TypeRef? fallback,
  ) {
    final m = resolveStaticMethod(ctx, type, method);
    if (m.isBridge) {
      if (m.bridge is! BridgeMethodDef) {
        return AlwaysReturnType(CoreTypes.dynamic.ref(ctx), true);
      }
      final fn = (m.bridge as BridgeMethodDef).functionDescriptor;
      return bridgeFunctionReturnType(
        ctx,
        fn,
        specifiedType: type,
      ).toAlwaysReturnType(ctx, type, const [], const {})!;
    }
    final d = m.declaration!;
    if (d is ConstructorDeclaration) {
      return AlwaysReturnType(type, false);
    }
    return AlwaysReturnType.fromAnnotation(
      ctx,
      type.file,
      (d as MethodDeclaration).returnType,
      fallback,
    );
  }

  static AlwaysReturnType? fromInstanceMethodOrBuiltin(
    CompilerContext ctx,
    TypeRef type,
    String method,
    List<TypeRef?> argTypes,
    Map<String, TypeRef?> namedArgTypes, {
    List<TypeRef> typeArgs = const [],
    bool $static = false,
  }) {
    final lookupType = ctx.typeSystem.throughTypeParameters(type);
    if (lookupType.isSpec(CoreTypes.dynamic)) {
      return AlwaysReturnType(CoreTypes.dynamic.ref(ctx), true);
    }

    if ($static) {
      final m = resolveStaticMethod(ctx, lookupType, method);
      if (m.isBridge) {
        final bridge = m.bridge!;
        final fd = bridge is BridgeMethodDef
            ? bridge.functionDescriptor
            : bridge is BridgeConstructorDef
            ? bridge.functionDescriptor
            : null;
        if (fd == null) {
          return AlwaysReturnType(CoreTypes.dynamic.ref(ctx), true);
        }
        return bridgeFunctionReturnType(ctx, fd).toAlwaysReturnType(
          ctx,
          lookupType,
          argTypes,
          namedArgTypes,
          typeArgs: typeArgs,
        );
      }
      final d = m.declaration!;
      if (d is ConstructorDeclaration) {
        return AlwaysReturnType(lookupType, false);
      }
      return AlwaysReturnType.fromAnnotation(
        ctx,
        lookupType.file,
        (d as MethodDeclaration).returnType,
        CoreTypes.dynamic.ref(ctx),
      );
    }

    if (method == 'noSuchMethod') {
      // `Object.noSuchMethod` is implicit — absent from declaration metadata.
      return AlwaysReturnType(CoreTypes.dynamic.ref(ctx), true);
    }
    final m = resolveInstanceMethod(ctx, lookupType, method);
    if (m.isBridge) {
      final fd = (m.bridge as BridgeMethodDef).functionDescriptor;
      return bridgeFunctionReturnType(
        ctx,
        fd,
        specifiedType: lookupType,
      ).toAlwaysReturnType(
        ctx,
        lookupType,
        argTypes,
        namedArgTypes,
        typeArgs: typeArgs,
      );
    }
    final d = m.declaration!;
    if (d is! MethodDeclaration) {
      // A field holding a callable — its call signature isn't modelled here.
      return AlwaysReturnType(CoreTypes.dynamic.ref(ctx), true);
    }
    return _memberReturnAnnotation(
      ctx,
      lookupType,
      d,
      CoreTypes.dynamic.ref(ctx),
      declaringFile: m.sourceLib,
    );
  }

  final TypeRef? type;
  final bool nullable;

  @override
  AlwaysReturnType? toAlwaysReturnType(
    CompilerContext ctx,
    TypeRef? targetType,
    List<TypeRef?> argTypes,
    Map<String, TypeRef?> namedArgTypes, {
    List<TypeRef> typeArgs = const [],
  }) {
    var resolved = type;
    if (resolved == null) return this;
    // Class-scoped parameter references take their bindings from the
    // receiver (e.g. `List<int>.first` resolves `E` to `int`).
    final targetSubs = targetType == null
        ? null
        : ctx.typeSystem.appliedArguments(targetType);
    if (targetSubs != null && targetSubs.isNotEmpty) {
      resolved = resolved.substituteTypeParameters(targetSubs);
    }
    // Any remaining free parameters are callee-scoped and were never bound
    // at this call site — an unconstrained `T` is meaningless to the caller,
    // so lower each to its declared bound (or `dynamic`).
    final lowered = resolved.lowerTypeParameters(ctx);
    return identical(lowered, resolved)
        ? this
        : AlwaysReturnType(lowered, nullable);
  }
}

class ParameterTypeDependentReturnType implements ReturnType {
  const ParameterTypeDependentReturnType(
    this.map, {
    this.paramIndex,
    this.paramName,
    this.fallback,
  });

  final int? paramIndex;
  final String? paramName;
  final Map<TypeRef, AlwaysReturnType> map;
  final AlwaysReturnType? fallback;

  @override
  AlwaysReturnType? toAlwaysReturnType(
    CompilerContext ctx,
    TypeRef? targetType,
    List<TypeRef?> argTypes,
    Map<String, TypeRef?> namedArgTypes, {
    List<TypeRef> typeArgs = const [],
  }) {
    AlwaysReturnType? resolvedType;
    if (paramIndex != null && paramIndex! < argTypes.length) {
      resolvedType = map[argTypes[paramIndex!]];
    } else if (paramName != null) {
      resolvedType = map[namedArgTypes[paramName]];
    }

    if (resolvedType == null) {
      return fallback;
    }
    return resolvedType;
  }
}

class TargetTypeArgDependentReturnType implements ReturnType {
  const TargetTypeArgDependentReturnType(this.typeArgIndex);

  final int typeArgIndex;

  @override
  AlwaysReturnType? toAlwaysReturnType(
    CompilerContext ctx,
    TypeRef? targetType,
    List<TypeRef?> argTypes,
    Map<String, TypeRef?> namedArgTypes, {
    List<TypeRef> typeArgs = const [],
  }) {
    return AlwaysReturnType(targetType!.specifiedTypeArgs[typeArgIndex], false);
  }
}

class TypeArgDependentReturnType implements ReturnType {
  const TypeArgDependentReturnType(this.typeArgIndex);

  final int typeArgIndex;

  @override
  AlwaysReturnType? toAlwaysReturnType(
    CompilerContext ctx,
    TypeRef? targetType,
    List<TypeRef?> argTypes,
    Map<String, TypeRef?> namedArgTypes, {
    List<TypeRef> typeArgs = const [],
  }) {
    return AlwaysReturnType(typeArgs[typeArgIndex], false);
  }
}

/// Maps each parameter of [typeParameters] to a resolvable [TypeRef] belonging
/// to the declaring class `file:name` — the scope in which clause types like
/// `extends C<T>` and parameter bounds are resolved.
Map<String, TypeRef> classTypeParameterRefs(
  int file,
  String name,
  TypeParameterList? typeParameters,
) => {
  for (var i = 0; i < (typeParameters?.typeParameters.length ?? 0); i++)
    typeParameters!.typeParameters[i].name.lexeme: TypeRef(
      file,
      typeParameters.typeParameters[i].name.lexeme,
      typeParameterOwner: 'class:$file:$name',
      typeParameterIndex: i,
    ),
};

class GenericParam {
  const GenericParam(this.name, this.extendsType);

  final String name;
  final TypeRef? extendsType;
}

extension Refify on BridgeTypeSpec {
  TypeRef ref(
    CompilerContext ctx, [
    List<BridgeTypeAnnotation> typeArgs = const [],
  ]) {
    return ctx.types.bySpec(this).instantiate([
      for (final arg in typeArgs) TypeRef.fromBridgeAnnotation(ctx, arg),
    ]);
  }
}

/// Resolves a `typedef` use to the type it aliases. Function-type aliases
/// (`typedef void F()`, `typedef F = void Function()`) map to `Function`;
/// named-type aliases (`typedef X = List<int>`) resolve recursively. Type
/// parameters on the alias are bound (and substituted by any supplied type
/// arguments) while the underlying annotation resolves.
TypeRef resolveTypeAlias(
  CompilerContext ctx,
  int library,
  TypeAlias alias, {
  bool nullable = false,
  List<TypeAnnotation>? typeArgs,
  Map<String, TypeRef> callerTypeParameters = const {},
  bool rawParams = false,
}) {
  // Resolve supplied type arguments first — they are finite annotations that
  // may legally mention this same alias (`Fcov<Fcov<Never>>`). Only the
  // alias's own body resolution is guarded against recursion.
  final argRefs = typeArgs == null
      ? null
      : [
          for (final arg in typeArgs)
            TypeRef.fromAnnotation(
              ctx,
              library,
              arg,
              typeParameters: callerTypeParameters,
            ),
        ];
  if (!ctx.resolvingTypeAliases.add(alias)) {
    throw CompileError(
      'Type alias ${alias.name.lexeme} references itself recursively',
      alias,
      library,
      ctx,
    );
  }
  try {
    return _resolveTypeAlias(
      ctx,
      library,
      alias,
      nullable: nullable,
      argRefs: argRefs,
      callerTypeParameters: callerTypeParameters,
      rawParams: rawParams,
    );
  } finally {
    ctx.resolvingTypeAliases.remove(alias);
  }
}

TypeRef _resolveTypeAlias(
  CompilerContext ctx,
  int library,
  TypeAlias alias, {
  bool nullable = false,
  List<TypeRef>? argRefs,
  Map<String, TypeRef> callerTypeParameters = const {},
  bool rawParams = false,
}) {
  final typeParameters =
      switch (alias) {
        GenericTypeAlias(:final typeParameters) => typeParameters,
        FunctionTypeAlias(:final typeParameters) => typeParameters,
        ClassTypeAlias(:final typeParameters) => typeParameters,
        _ => null,
      }?.typeParameters ??
      const <TypeParameter>[];
  // Bind the alias's own type parameters inside its body. With concrete
  // arguments, substitute them. Without arguments the alias instantiates to
  // bounds (`typedef TB<T extends C> = T` referenced bare is `TB<C>`); with
  // [rawParams] the parameters stay abstract type-parameter references so a
  // caller performing downward inference can substitute them itself. The body
  // resolves against the alias's own file — it may name types private to that
  // library.
  final declLibrary = ctx.typeAliasFiles[alias] ?? library;
  final bindings = <String, TypeRef>{};
  for (var i = 0; i < typeParameters.length; i++) {
    final param = typeParameters[i];
    final arg = argRefs == null || i >= argRefs.length ? null : argRefs[i];
    final bound = param.bound;
    if (arg != null) {
      bindings[param.name.lexeme] = arg;
    } else if (rawParams) {
      bindings[param.name.lexeme] = TypeRef(
        declLibrary,
        param.name.lexeme,
        typeParameterOwner: 'typeAlias:$declLibrary:${alias.name.lexeme}',
        typeParameterIndex: i,
      );
    } else if (bound == null) {
      bindings[param.name.lexeme] = CoreTypes.dynamic.ref(ctx);
    } else {
      // A recursive bound (`X extends A<X>`) sees the parameter itself.
      bindings[param.name.lexeme] = TypeRef(
        declLibrary,
        param.name.lexeme,
        typeParameterOwner: 'typeAlias:$declLibrary:${alias.name.lexeme}',
        typeParameterIndex: i,
      );
      bindings[param.name.lexeme] = TypeRef.fromAnnotation(
        ctx,
        declLibrary,
        bound,
        typeParameters: bindings,
      );
    }
  }

  final TypeRef target;
  if (alias is GenericTypeAlias) {
    final functionType = alias.functionType;
    target = functionType == null
        ? TypeRef.fromAnnotation(
            ctx,
            declLibrary,
            alias.type,
            typeParameters: bindings,
          )
        : CoreTypes.function
              .ref(ctx)
              .copyWith(
                functionType: EvalFunctionType.fromAnnotation(
                  ctx,
                  declLibrary,
                  functionType,
                  typeParameters: bindings,
                ),
              );
  } else if (alias is FunctionTypeAlias) {
    // Legacy `typedef R f(P...)` syntax declares the signature inline. The
    // alias's parameters become the signature's own generics only under
    // [rawParams] (downward inference); otherwise [bindings] instantiate
    // them so the result is a plain function type.
    target = CoreTypes.function
        .ref(ctx)
        .copyWith(
          functionType: EvalFunctionType.fromParts(
            ctx,
            declLibrary,
            returnType: alias.returnType,
            typeParameterList: rawParams ? alias.typeParameters : null,
            parameterList: alias.parameters,
            owner: 'typeAlias:$declLibrary:${alias.name.lexeme}',
            typeParameters: bindings,
          ),
        );
  } else {
    target = CoreTypes.function.ref(ctx);
  }
  return target.copyWith(nullable: nullable || target.nullable);
}

/// Resolves a type argument in a `with`/`extends` application: a bare name
/// matching one of [classParams] resolves to that parameter's [TypeRef];
/// other named types resolve their arguments recursively (so `List<U>`
/// resolves when `U` is a parameter of the applying class). Concrete
/// arguments resolve normally. Returns null when the argument resolves to
/// none of these.
TypeRef? resolveAppliedTypeArgument(
  CompilerContext ctx,
  int libraryIndex,
  String ownerClassName,
  List<TypeParameter>? classParams,
  TypeAnnotation arg,
) {
  if (arg is NamedType) {
    if (arg.importPrefix == null) {
      final index = (classParams ?? const <TypeParameter>[]).indexWhere(
        (p) => p.name.lexeme == arg.name.lexeme,
      );
      if (index >= 0) {
        final bound = classParams![index].bound;
        return TypeRef(
          libraryIndex,
          arg.name.lexeme,
          typeParameterOwner: 'class:$libraryIndex:$ownerClassName',
          typeParameterIndex: index,
          typeParameterBound: bound == null
              ? CoreTypes.dynamic.ref(ctx)
              : TypeRef.fromAnnotation(ctx, libraryIndex, bound),
        );
      }
    }
    final prefix = arg.importPrefix;
    final name = prefix == null
        ? arg.name.lexeme
        : '${prefix.name.lexeme}.${arg.name.lexeme}';
    final base = ctx.visibleTypes[libraryIndex]?[name];
    if (base != null) {
      final nestedArgs = arg.typeArguments?.arguments;
      if (nestedArgs == null) return base;
      return base.copyWith(
        specifiedTypeArgs: [
          for (final nested in nestedArgs)
            resolveAppliedTypeArgument(
                  ctx,
                  libraryIndex,
                  ownerClassName,
                  classParams,
                  nested,
                ) ??
                CoreTypes.dynamic.ref(ctx),
        ],
      );
    }
  }
  try {
    return TypeRef.fromAnnotation(ctx, libraryIndex, arg);
  } on CompileError {
    return null;
  }
}

/// Finds an application of [mixinOwner] in [decl]'s `with` clause, including
/// through entries that are themselves mixin applications (`class C = S with
/// M`, `mixin class`). Returns the mixin's parameter names mapped to their
/// effective types under [substitutions], or null when [mixinOwner] is not
/// applied anywhere in the clause.
Map<String, TypeRef>? findMixinApplication(
  CompilerContext ctx,
  Declaration decl,
  int declFile,
  String declName,
  Declaration mixinOwner,
  int ownerLibrary,
  Map<(String, int), TypeRef> substitutions,
) {
  for (final mixinType in classLikeClauses(decl).$2) {
    final prefix = mixinType.importPrefix;
    final mixinName = prefix == null
        ? mixinType.name.lexeme
        : '${prefix.name.lexeme}.${mixinType.name.lexeme}';
    final ref = ctx.visibleTypes[declFile]?[mixinName];
    if (ref == null) continue;
    final mixinDecl =
        ctx.topLevelDeclarationsMap[ref.file]?[ref.name]?.declaration;
    final mixinParams =
        switch (mixinDecl) {
          MixinDeclaration m => m.typeParameters?.typeParameters,
          ClassDeclaration c => c.namePart.typeParameters?.typeParameters,
          ClassTypeAlias a => a.typeParameters?.typeParameters,
          _ => null,
        } ??
        const <TypeParameter>[];
    final appliedArgs = mixinType.typeArguments?.arguments;
    final classParams = classLikeClauses(decl).$4?.typeParameters;
    // Each parameter's effective type under the substitutions accumulated so
    // far (bounds apply when the application omits an argument).
    final applied = <String, TypeRef>{
      for (var i = 0; i < mixinParams.length; i++)
        mixinParams[i].name.lexeme:
            resolveAppliedMixinArg(
              ctx,
              declFile,
              declName,
              classParams,
              appliedArgs != null && i < appliedArgs.length
                  ? appliedArgs[i]
                  : null,
              substitutions,
            ) ??
            substitutedParamBound(ctx, declFile, mixinParams[i], substitutions),
    };
    if (identical(mixinDecl, mixinOwner)) {
      return applied;
    }
    if (mixinDecl is ClassDeclaration || mixinDecl is ClassTypeAlias) {
      final inner = findMixinApplication(
        ctx,
        mixinDecl!,
        ref.file,
        ref.name,
        mixinOwner,
        ownerLibrary,
        {
          ...substitutions,
          for (var i = 0; i < mixinParams.length; i++)
            ('class:${ref.file}:${ref.name}', i):
                applied[mixinParams[i].name.lexeme]!,
        },
      );
      if (inner != null) return inner;
    }
  }
  return null;
}

/// Resolves a type argument in a `with` clause entry: a bare name matching
/// one of the applying class's own type parameters resolves to that
/// parameter; other named types resolve with their arguments resolved
/// recursively (so `List<U>` resolves when `U` is the alias's parameter).
/// [substitutions] are applied to the result.
TypeRef? resolveAppliedMixinArg(
  CompilerContext ctx,
  int declFile,
  String declName,
  List<TypeParameter>? classParams,
  TypeAnnotation? arg,
  Map<(String, int), TypeRef> substitutions,
) {
  if (arg == null) return null;
  return resolveAppliedTypeArgument(
    ctx,
    declFile,
    declName,
    classParams,
    arg,
  )?.substituteTypeParameters(substitutions);
}

/// The bound of a mixin type parameter, substituted through [substitutions].
TypeRef substitutedParamBound(
  CompilerContext ctx,
  int file,
  TypeParameter param,
  Map<(String, int), TypeRef> substitutions,
) {
  final bound = param.bound;
  return bound == null
      ? CoreTypes.dynamic.ref(ctx)
      : TypeRef.fromAnnotation(
          ctx,
          file,
          bound,
        ).substituteTypeParameters(substitutions);
}

/// For [member] folded into [applier] from a mixin or mixin-class (possibly
/// through a chain of mixin applications), seeds [CompilerContext.typeScopes] in the
/// member's declaring library so its type parameters resolve to the applied
/// arguments, expressed in [applier]'s own type parameters.
void seedFoldedMemberTypeParams(
  CompilerContext ctx,
  Declaration applier,
  ClassMember member,
  int memberLibrary,
  int applierLibrary,
) {
  final owner = member.parent?.parent;
  if (owner is! Declaration || identical(owner, applier)) {
    return;
  }
  final applied = findMixinApplication(
    ctx,
    applier,
    applierLibrary,
    declarationName(applier),
    owner,
    memberLibrary,
    const {},
  );
  if (applied == null) return;
  ctx.typeParameterScope(memberLibrary).addAll(applied);
}

/// Dart's "no declared type" inference widens a `Null`-typed initializer to
/// `dynamic` (`var x = null`, `var f = null`): an uninhabited declared type
/// would reject every later assignment.
TypeRef widenedInferredType(CompilerContext ctx, TypeRef type) =>
    type.isSpec(CoreTypes.nullType) ? CoreTypes.dynamic.ref(ctx) : type;
