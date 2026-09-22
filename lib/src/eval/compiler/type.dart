import 'package:analyzer/dart/ast/ast.dart';
import 'package:collection/collection.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/expression/method_invocation.dart';
import 'package:dart_eval/src/eval/compiler/model/function_type.dart';
import 'package:dart_eval/src/eval/shared/runtime_type_descriptor.dart';

import 'builtins.dart';
import 'context.dart';
import 'errors.dart';

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

/// Reference to a type in the compiler. Types are initially created
/// with a [file] and [name], and resolved lazily with [resolveTypeChain]
/// to fill in information such as [extendsType], [implementsType], and
/// [withType].
class TypeRef {
  const TypeRef(
    this.file,
    this.name, {
    this.extendsType,
    this.implementsType = const [],
    this.withType = const [],
    this.genericParams = const [],
    this.specifiedTypeArgs = const [],
    this.recordFields = const [],
    this.resolved = false,
    this.functionType,
    this.typeParameterOwner,
    this.typeParameterIndex,
    this.typeParameterBound,
    this.boxed = true,
    this.nullable = false,
  });

  // Library IDs are assigned independently in each compilation. A type resolved
  // for one context must never be reused against another context's library IDs.
  static final _caches = Expando<_TypeRefCache>();

  final int file;
  final String name;
  final TypeRef? extendsType;
  final List<TypeRef> implementsType;
  final List<TypeRef> withType;
  final List<GenericParam> genericParams;
  final List<TypeRef> specifiedTypeArgs;
  final List<RecordParameterType> recordFields;
  final EvalFunctionType? functionType;
  final String? typeParameterOwner;
  final int? typeParameterIndex;
  final TypeRef? typeParameterBound;
  final bool resolved;
  final bool boxed;
  final bool nullable;

  /// Create and cache a [TypeRef] given a [file] and [name].
  /// This type ref contains only basic info and can be resolved later.
  factory TypeRef.cache(
    CompilerContext ctx,
    int file,
    String name, {
    int? fileRef,
  }) {
    final cache = _caches[ctx] ??= _TypeRefCache();
    final fileCache = cache.types.putIfAbsent(file, () => {});
    final $type = fileCache.putIfAbsent(name, () => TypeRef(file, name));
    if (fileRef != null) {
      cache.visibleLibraries.putIfAbsent($type, () => []).add(fileRef);
    }

    ctx.typeRefIndexMap[$type] = ctx.typeNames.length;
    ctx.runtimeTypeDescriptorIds[$type._runtimeDescriptorKey] =
        ctx.typeNames.length;
    ctx.runtimeTypeList.add($type);
    ctx.typeNames.add(name);

    return $type;
  }

  /// Given a set of [TypeRef]s, find their closest common ancestor type.
  factory TypeRef.commonBaseType(CompilerContext ctx, Set<TypeRef> types) {
    assert(types.isNotEmpty);
    var makeNullable = types.remove(CoreTypes.nullType.ref(ctx));
    if (types.isEmpty) {
      return CoreTypes.nullType.ref(ctx);
    }
    if (types.length == 1) {
      return makeNullable ? types.first.copyWith(nullable: true) : types.first;
    }
    final chains = types
        .map((e) => e.resolveTypeChain(ctx).getTypeChain(ctx))
        .toList();

    // Cross-level type deduplication
    for (final chain in chains) {
      final typeSet = <TypeRef>{};
      for (final typeList in chain) {
        for (final type in [...typeList]) {
          if (!typeSet.contains(type)) {
            typeSet.add(type);
          } else {
            typeList.remove(type);
          }
        }
      }
    }

    final refCount = <TypeRef, int>{};
    final layer = <TypeRef, int>{};
    var i = 0;

    var passes = 0;
    t:
    while (true) {
      for (final chain in chains) {
        if (i > chain.length - 1) {
          passes++;
          if (passes > chains.length - 1) {
            break t;
          }
          continue;
        }
        final types = chain[i];
        for (final type in types) {
          if (refCount[type] == null) {
            refCount[type] = 1;
            layer[type] = i;
          } else {
            refCount[type] = refCount[type]! + 1;
            layer[type] = layer[type]! + i;
          }
        }
      }
      passes = 0;
      i++;
    }

    refCount.removeWhere((key, value) => value < types.length);

    final sorted = refCount.keys.toList()
      ..sort((k1, k2) => layer[k1]! - layer[k2]!);
    if (sorted.isEmpty) {
      return CoreTypes.dynamic.ref(ctx).copyWith(nullable: makeNullable);
    }
    // Among the shallowest common supertypes, pick the one that is a subtype
    // of all the others (e.g. `num` over `Object`). When several are
    // incomparable (a class `implements B1, B2` with both shared), pick the
    // last inserted — `getTypeChain` walks `implementsType.reversed`, so the
    // last candidate is the first-declared interface.
    final minLayer = layer[sorted[0]]!;
    final candidates = sorted
        .where((t) => layer[t] == minLayer)
        .toList(growable: false);
    final best = candidates.firstWhere(
      (c) => candidates.every(
        (o) => c == o || c.isAssignableTo(ctx, o, forceAllowDynamic: false),
      ),
      orElse: () => candidates.last,
    );
    return makeNullable ? best.copyWith(nullable: true) : best;
  }

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

      var name = '@record<';
      var positionalFields = 1;
      for (var i = 0; i < typeAnnotation.positionalFields.length; i++) {
        final field = typeAnnotation.positionalFields[i];
        final fType = TypeRef.fromAnnotation(
          ctx,
          library,
          field.type,
          typeParameters: typeParameters,
        );
        fields.add(
          RecordParameterType('\$${positionalFields++}', fType, false),
        );
        name += '$fType';
        if (i < typeAnnotation.positionalFields.length - 1) {
          name += ',';
        }
      }

      final namedFields =
          typeAnnotation.namedFields?.fields ??
          <RecordTypeAnnotationNamedField>[];
      if (namedFields.isNotEmpty) {
        name += ',{';
      }
      for (var i = 0; i < namedFields.length; i++) {
        final field = namedFields[i];
        final fType = TypeRef.fromAnnotation(
          ctx,
          library,
          field.type,
          typeParameters: typeParameters,
        );
        fields.add(RecordParameterType(field.name.lexeme, fType, true));
        name += '${field.name.lexeme}:$fType';
        if (i < namedFields.length - 1) {
          name += ',';
        }
      }
      if (namedFields.isNotEmpty) {
        name += '}';
      }
      name += '>';
      return TypeRef(
        -1,
        name,
        recordFields: fields,
        extendsType: CoreTypes.record.ref(ctx),
        resolved: true,
        boxed: false,
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
        ctx.temporaryTypes[library]?[n] ??
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
        nullable:
            typeAnnotation.question != null || unspecifiedType.nullable,
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
    bool staticSource = true,
  }) {
    return TypeRef.fromBridgeTypeRef(
      ctx,
      typeAnnotation.type,
      staticSource: staticSource,
      specifyingType: specifyingType,
      specifiedType: specifiedType,
      typeParameters: typeParameters,
    ).copyWith(nullable: typeAnnotation.nullable);
  }

  factory TypeRef.fromBridgeTypeRef(
    CompilerContext ctx,
    BridgeTypeRef typeReference, {
    bool staticSource = true,
    TypeRef? specifyingType,
    TypeRef? specifiedType,
    Map<String, TypeRef> typeParameters = const {},
  }) {
    final cacheId = typeReference.cacheId;
    if (cacheId != null) {
      final t = ctx.runtimeTypeList[cacheId];
      if (staticSource) {
        return t.isUnboxedAcrossFunctionBoundaries
            ? t.copyWith(boxed: false)
            : t.copyWith(boxed: true);
      }
      return t.copyWith(boxed: true);
    }
    final spec = typeReference.spec;
    if (spec != null) {
      final specifiedTypeArgs = <TypeRef>[];
      for (final arg in typeReference.typeArgs) {
        specifiedTypeArgs.add(
          TypeRef.fromBridgeAnnotation(
            ctx,
            arg,
            staticSource: staticSource,
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
      return typeSpec.copyWith(
        specifiedTypeArgs: specifiedTypeArgs,
        boxed: true,
      );
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
        return bridgedTypeArgument(ctx, specifiedType, ref) ??
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
        final resolvedSpecifyingType = specifyingType.resolveTypeChain(ctx);
        final instantiatedType =
            [
              resolvedSpecifyingType,
              ...resolvedSpecifyingType.extendsChain,
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
    final resolved = ref.resolved ? ref : ref.resolveTypeChain(ctx);
    if (resolved.genericParams.isNotEmpty) {
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
    if ($class == CoreTypes.dynamic.ref(ctx)) {
      return null;
    }

    if ($class.isTypeParameter) {
      final bound = $class.typeParameterBound;
      if (bound == null) return null;
      return TypeRef.lookupFieldType(
            ctx,
            bound.resolveTypeChain(ctx),
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
        return field0.type.copyWith(boxed: true);
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
      final previousTypes = {...?ctx.temporaryTypes[$class.file]};
      TypeRef.loadTemporaryTypes(
        ctx,
        typeParams,
        library: $class.file,
        owner: 'class:${$class.file}:${$class.name}',
      );
      // A raw type use substitutes the parameter's bound (instantiate to
      // bounds); otherwise the argument at the same position.
      TypeRef substituteClassTypeArguments(TypeRef resolved) {
        final localSubstitutions = <(String, int), TypeRef>{
          ...substitutions,
        };
        for (var i = 0; i < (typeParams?.length ?? 0); i++) {
          final bound = ctx
              .temporaryTypes[$class.file]![typeParams![i].name.lexeme]!
              .typeParameterBound;
          final arg = i < $class.specifiedTypeArgs.length
              ? $class.specifiedTypeArgs[i]
              : (bound ?? CoreTypes.dynamic.ref(ctx));
          localSubstitutions[('class:${$class.file}:${$class.name}', i)] = arg
              .substituteTypeParameters(substitutions);
        }
        if (localSubstitutions.isEmpty) return resolved;
        return resolved.substituteTypeParameters(localSubstitutions);
      }

      try {
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
            ).copyWith(boxed: true);
          }
          if (ctx.inferredFieldTypes.containsKey($class.file) &&
              ctx.inferredFieldTypes[$class.file]!.containsKey($class.name) &&
              ctx.inferredFieldTypes[$class.file]![$class.name]!.containsKey(
                field,
              )) {
            return ctx.inferredFieldTypes[$class.file]![$class.name]![field]!;
          }
          return null;
        } else if (!forFieldFormal && $declarations.containsKey('$field*g')) {
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
      } finally {
        ctx.temporaryTypes[$class.file] = previousTypes;
      }
    }
    final dec = ctx.topLevelDeclarationsMap[$class.file]![$class.name]!;

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
          $super.inheritTypeArgsFrom(ctx, $class),
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
      final dec0 = dec.declaration as Declaration;
      if (classLikeClauses(dec0).$1 == null) {
        if ($class == CoreTypes.object.ref(ctx)) {
          throw CompileError(
            'Field $field not found in class ${$class} or its superclasses',
            source,
          );
        }
        return TypeRef.lookupFieldType(ctx, CoreTypes.object.ref(ctx), field);
      } else {
        final resolved = $class.resolveTypeChain(ctx, source: source);
        final $super = resolved.extendsType!;
        // Fold this class's own arguments into the superclass reference and
        // keep composing substitutions down the chain so e.g. `extends S<T>`
        // on `C<int>` walks `S<int>` rather than `S<T>`.
        final levelParams = resolved.genericParams;
        final levelSubstitutions = {
          ...substitutions,
          for (var i = 0; i < levelParams.length; i++)
            ('class:${$class.file}:${$class.name}', i):
                (i < $class.specifiedTypeArgs.length
                        ? $class.specifiedTypeArgs[i]
                        : levelParams[i].extendsType ??
                            CoreTypes.dynamic.ref(ctx))
                    .substituteTypeParameters(substitutions),
        };
        return TypeRef.lookupFieldType(
          ctx,
          $super.substituteTypeParameters(levelSubstitutions),
          field,
          source: source,
          substitutions: levelSubstitutions,
        );
      }
    }
  }

  /// Resolve the full type chain of this [TypeRef]. If it or its supertypes
  /// have already been resolved, it will return a copy of the resolved type
  /// from the cache.
  TypeRef resolveTypeChain(
    CompilerContext ctx, {
    int recursionGuard = 0,
    Set<TypeRef> stack = const {},
    AstNode? source,
  }) {
    if (isTypeParameter) return this;
    if (recursionGuard > 500) {
      throw CompileError(
        'Reached max limit on recursion while resolving types. '
        'Your type hierarchy is probably recursive (caught while resolving $this)',
      );
    }
    final stack0 = {...stack, this};
    final rg = recursionGuard + 1;
    final resolvedSpecifiedTypeArgs = specifiedTypeArgs
        .map(
          (e) => stack.contains(e)
              ? e
              : e.resolveTypeChain(ctx, recursionGuard: rg, stack: stack0),
        )
        .toList();
    if (resolved) {
      return copyWith(specifiedTypeArgs: resolvedSpecifiedTypeArgs);
    }

    if (recordFields.isNotEmpty) {
      return copyWith(
        resolved: true,
        extendsType: CoreTypes.record.ref(ctx),
        specifiedTypeArgs: resolvedSpecifiedTypeArgs,
        boxed: false,
      );
    }

    final cache = _caches[ctx]!;
    final $cached = cache.types[file]![name]!;
    if ($cached.resolved) {
      return $cached.copyWith(
        boxed: boxed,
        functionType: functionType,
        specifiedTypeArgs: resolvedSpecifiedTypeArgs,
        nullable: nullable,
      );
    }

    TypeRef? $super;
    final $with = <TypeRef>[];
    final $implements = <TypeRef>[];

    final declaration = ctx.topLevelDeclarationsMap[file]![name]!;

    NamedType? superName;
    List<NamedType> implementsNames;
    List<NamedType> withNames;
    List<GenericParam> generics;

    if (declaration.isBridge) {
      implementsNames = [];
      withNames = [];
      generics = [];

      if (declaration.bridge is BridgeEnumDef) {
        $super = CoreTypes.enumType.ref(ctx);
      } else {
        final br = declaration.bridge as BridgeClassDef;
        final type = br.type;

        for (final $g in type.generics.entries) {
          final gExtends = $g.value.$extends;
          final type0 = gExtends == null
              ? null
              : TypeRef.fromBridgeTypeRef(ctx, gExtends);
          generics.add(
            GenericParam(
              $g.key,
              type0?.resolveTypeChain(
                ctx,
                recursionGuard: rg,
                stack: stack0,
                source: source,
              ),
            ),
          );
        }

        // The resolved supertypes are cached on the declaration, shared by
        // every instantiation (`List<int>` and `List<double>` alike), so
        // type-parameter refs must stay parameterized — they are substituted
        // with the applied arguments at each use site.
        final ownTypeParams = <String, TypeRef>{
          for (var i = 0; i < generics.length; i++)
            generics[i].name: TypeRef(
              file,
              generics[i].name,
              resolved: true,
              typeParameterOwner: 'class:$file:$name',
              typeParameterIndex: i,
              typeParameterBound:
                  generics[i].extendsType ?? CoreTypes.dynamic.ref(ctx),
            ),
        };

        if (type.$extends != null) {
          $super =
              TypeRef.fromBridgeTypeRef(
                ctx,
                type.$extends!,
                specifiedType: this,
                typeParameters: ownTypeParams,
              ).resolveTypeChain(
                ctx,
                recursionGuard: rg,
                stack: stack0,
                source: source,
              );
          // Null's nominal superclass is Object, but `Null <: T` holds only
          // when T is nullable or a top type — model that as extends Object?.
          if (this == CoreTypes.nullType.ref(ctx)) {
            $super = $super.copyWith(nullable: true);
          }
        }

        for (final $i in type.$implements) {
          $implements.add(
            TypeRef.fromBridgeTypeRef(
              ctx,
              $i,
              specifiedType: this,
              typeParameters: ownTypeParams,
            ).resolveTypeChain(
              ctx,
              recursionGuard: rg,
              stack: stack0,
              source: source,
            ),
          );
        }

        for (final $i in type.$with) {
          $with.add(
            TypeRef.fromBridgeTypeRef(
              ctx,
              $i,
              specifiedType: this,
              typeParameters: ownTypeParams,
            ).resolveTypeChain(
              ctx,
              recursionGuard: rg,
              stack: stack0,
              source: source,
            ),
          );
        }
      }
    } else {
      final dec = declaration.declaration!;
      final (extendsClause, withClause, implementsClause, typeParameters) =
          classLikeClauses(dec);
      superName = extendsClause;
      withNames = withClause;
      implementsNames = implementsClause;
      // Bounds can reference earlier parameters (`S extends T`), so resolve
      // them with the class's own parameters already seeded.
      final paramRefs = classTypeParameterRefs(file, name, typeParameters);
      generics =
          typeParameters?.typeParameters
              .map(
                (t) => GenericParam(
                  t.name.lexeme,
                  t.bound == null
                      ? null
                      : TypeRef.fromAnnotation(
                          ctx,
                          file,
                          t.bound!,
                          typeParameters: paramRefs,
                        ),
                ),
              )
              .toList() ??
          [];
    }

    // Type arguments in `extends`/`with`/`implements` clauses may mention the
    // class's own type parameters (`class D<T> extends C<T>`). Seed a lookup
    // so [TypeRef.fromAnnotation] resolves them even though the class's
    // temporary-type scope is not active when the chain resolves lazily.
    final ownTypeParams = <String, TypeRef>{
      for (var i = 0; i < generics.length; i++)
        generics[i].name: TypeRef(
          file,
          generics[i].name,
          resolved: true,
          typeParameterOwner: 'class:$file:$name',
          typeParameterIndex: i,
          typeParameterBound:
              generics[i].extendsType ?? CoreTypes.dynamic.ref(ctx),
        ),
    };
    List<TypeRef> resolveClauseTypeArgs(NamedType clauseName) =>
        clauseName.typeArguments?.arguments
            .map(
              (a) => TypeRef.fromAnnotation(
                ctx,
                file,
                a,
                typeParameters: ownTypeParams,
              ),
            )
            .map(
              (a) => stack.contains(a)
                  ? a
                  : a.resolveTypeChain(
                      ctx,
                      recursionGuard: rg,
                      stack: stack0,
                      source: source,
                    ),
            )
            .toList() ??
        [];

    // `extends`/`with`/`implements` targets may be prefixed (`p.C`); the
    // visible-types map keys prefixed types as 'prefix.Name'.
    String clauseTypeName(NamedType clauseName) {
      final prefix = clauseName.importPrefix;
      return prefix == null
          ? clauseName.name.lexeme
          : '${prefix.name.lexeme}.${clauseName.name.lexeme}';
    }

    TypeRef resolveClauseType(NamedType clauseName) {
      final name = clauseTypeName(clauseName);
      var type = ctx.visibleTypes[file]![name];
      if (type == null) {
        final alias = ctx.typeAliases[file]?[name];
        if (alias != null) {
          type = resolveTypeAlias(ctx, file, alias);
        }
      }
      if (type == null) {
        throw CompileError('Type $name not found', source);
      }
      return type
          .copyWith(specifiedTypeArgs: resolveClauseTypeArgs(clauseName))
          .resolveTypeChain(
            ctx,
            recursionGuard: rg,
            stack: stack0,
            source: source,
          );
    }

    if (superName != null) {
      $super = resolveClauseType(superName);
    } else if (declaration.declaration is EnumDeclaration) {
      $super = CoreTypes.enumType.ref(ctx);
    } else if (!declaration.isBridge) {
      $super = CoreTypes.object.ref(ctx);
    }

    for (final withName in withNames) {
      var mixin = resolveClauseType(withName);
      // Mixin-application inference: `with M` where `M<T> on I<T>` and the
      // superclass chain provides `I<int>` binds `T → int` from the `on`
      // constraints.
      if (withName.typeArguments == null && mixin.specifiedTypeArgs.isEmpty) {
        final mixinDeclRef = mixin.resolveTypeChain(ctx);
        final mixinDecl = ctx
            .topLevelDeclarationsMap[mixinDeclRef.file]?[mixinDeclRef.name]
            ?.declaration;
        if (mixinDecl is MixinDeclaration && mixinDecl.onClause != null) {
          final substitutions = <(String, int), TypeRef>{};
          final mixinParams = classTypeParameterRefs(
            mixinDeclRef.file,
            mixinDeclRef.name,
            mixinDecl.typeParameters,
          );
          final chain = [?$super, ...$with];
          for (final constraint in mixinDecl.onClause!.superclassConstraints) {
            final pattern = TypeRef.fromAnnotation(
              ctx,
              mixinDeclRef.file,
              constraint,
              typeParameters: mixinParams,
            );
            for (final sup in chain) {
              final found = findSupertypeInstantiation(ctx, pattern, sup);
              if (found != null) {
                collectTypeParameterSubstitutions(
                  ctx,
                  pattern,
                  found,
                  substitutions,
                );
              }
            }
          }
          if (substitutions.isNotEmpty) {
            mixin = mixin.copyWith(
              specifiedTypeArgs: [
                for (var i = 0; i < mixinDeclRef.genericParams.length; i++)
                  substitutions[(
                        'class:${mixinDeclRef.file}:${mixinDeclRef.name}',
                        i,
                      )] ??
                      mixinDeclRef.genericParams[i].extendsType
                          ?.substituteTypeParameters(substitutions) ??
                      CoreTypes.dynamic.ref(ctx),
              ],
            );
          }
        }
      }
      $with.add(mixin);
    }

    for (final implementsName in implementsNames) {
      $implements.add(resolveClauseType(implementsName));
    }

    final resolvedRef = TypeRef(
      file,
      name,
      functionType: functionType,
      extendsType: $super,
      withType: $with,
      implementsType: $implements,
      genericParams: generics,
      resolved: true,
      boxed: boxed,
      specifiedTypeArgs: resolvedSpecifiedTypeArgs,
      nullable: nullable,
    );

    for (final $file in cache.visibleLibraries[this]!) {
      ctx.visibleTypes[$file]![name] ??= resolvedRef;
    }

    final fileCache = cache.types[file]!;
    if (fileCache[name] == null || !fileCache[name]!.resolved) {
      fileCache[name] = resolvedRef.copyWith(boxed: true, nullable: false);
    }

    return resolvedRef;
  }

  Set<int> getRuntimeIndices(CompilerContext ctx) {
    final indices = {
      runtimeTypeId(ctx),
      ctx.typeRefIndexMap[this] ?? runtimeTypeId(ctx),
    };
    // Supertypes are declared in each supertype's own parameter keyspace; map
    // them back through the supertype's applied arguments as we walk.
    final seen = {semanticKey};
    final substitutions = appliedTypeArguments(ctx);
    final worklist = [
      for (final supertype in allSupertypes)
        supertype.substituteTypeParameters(substitutions),
    ];
    while (worklist.isNotEmpty) {
      final supertype = worklist.removeLast();
      if (!seen.add(supertype.semanticKey)) continue;
      indices.add(supertype.runtimeTypeId(ctx));
      indices.add(
        ctx.typeRefIndexMap[supertype] ?? supertype.runtimeTypeId(ctx),
      );
      final substitutions = supertype.appliedTypeArguments(ctx);
      for (final next in supertype.allSupertypes) {
        worklist.add(next.substituteTypeParameters(substitutions));
      }
    }
    return indices;
  }

  /// Maps this type's declared parameters to the applied arguments, so that
  /// members and supertypes declared in its parameter keyspace can be
  /// resolved through it.
  Map<(String, int), TypeRef> appliedTypeArguments(CompilerContext ctx) {
    if (genericParams.isEmpty) {
      // Refs constructed without resolved parameter declarations still map
      // their positional arguments into the class's parameter namespace.
      if (specifiedTypeArgs.isEmpty) return const {};
      return {
        for (var i = 0; i < specifiedTypeArgs.length; i++)
          ('class:$file:$name', i): specifiedTypeArgs[i],
      };
    }
    return {
      for (var i = 0; i < genericParams.length; i++)
        ('class:$file:$name', i): i < specifiedTypeArgs.length
            ? specifiedTypeArgs[i]
            : (genericParams[i].extendsType ?? CoreTypes.dynamic.ref(ctx)),
    };
  }

  String get semanticKey =>
      '${isTypeParameter ? 'parameter:$typeParameterOwner:$typeParameterIndex' : '$file:$name'}${nullable ? '?' : ''}'
      '${specifiedTypeArgs.isEmpty ? '' : '<${specifiedTypeArgs.map((type) => type.semanticKey).join(',')}>'}'
      '${recordFields.isEmpty ? '' : ':record:${recordFields.map((field) => '${field.isNamed ? 'n' : 'p'}:${field.name}:${field.type.semanticKey}').join(',')}'}'
      '${functionType == null ? '' : ':fn:${functionType!.semanticKey()}'}';

  String get _runtimeDescriptorKey => semanticKey;

  List<int> runtimeDescriptor(CompilerContext ctx) {
    if (isTypeParameter) {
      final ownerType = isClassTypeParameter
          ? () {
              final owner = typeParameterOwner!.split(':');
              final ownerLibrary = int.parse(owner[1]);
              return ctx.visibleTypes[ownerLibrary]![owner[2]]!.runtimeTypeId(
                ctx,
              );
            }()
          : RuntimeTypeDescriptorTag.callableTypeParameterOwner;
      return [
        CoreTypes.dynamic.ref(ctx).runtimeTypeId(ctx),
        nullable ? 1 : 0,
        RuntimeTypeDescriptorTag.typeParameter,
        ownerType,
        typeParameterIndex!,
        // F-bounds reference the parameter itself (`T extends Foo<T>`); erase
        // the self-reference to dynamic — descriptors can't be cyclic.
        (typeParameterBound ?? CoreTypes.dynamic.ref(ctx))
            .substituteTypeParameters({
              (typeParameterOwner!, typeParameterIndex!): CoreTypes.dynamic.ref(
                ctx,
              ),
            })
            .runtimeTypeId(ctx),
      ];
    }
    if (recordFields.isNotEmpty) {
      final positional = recordFields.where((field) => !field.isNamed).toList();
      final named = recordFields.where((field) => field.isNamed).toList()
        ..sort((a, b) => a.name!.compareTo(b.name!));
      return [
        CoreTypes.record.ref(ctx).runtimeTypeId(ctx),
        nullable ? 1 : 0,
        RuntimeTypeDescriptorTag.record,
        positional.length,
        named.length,
        for (final field in positional) field.type.runtimeTypeId(ctx),
        for (final field in named) ...[
          ctx.constantPool.addOrGet(field.name!),
          field.type.runtimeTypeId(ctx),
        ],
      ];
    }
    final signature = functionType;
    if (signature != null && signature.generics.isEmpty) {
      TypeRef resolve(FunctionTypeAnnotation annotation) =>
          annotation.type ?? CoreTypes.dynamic.ref(ctx);
      final positional = [
        ...signature.normalParameters,
        ...signature.optionalParameters,
      ];
      final named = signature.namedParameters.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      return [
        CoreTypes.function.ref(ctx).runtimeTypeId(ctx),
        nullable ? 1 : 0,
        RuntimeTypeDescriptorTag.function,
        resolve(signature.returnType).runtimeTypeId(ctx),
        signature.normalParameters.length,
        positional.length,
        named.length,
        for (final parameter in positional)
          resolve(parameter.type).runtimeTypeId(ctx),
        for (final entry in named) ...[
          ctx.constantPool.addOrGet(entry.key),
          entry.value.isRequired ? 1 : 0,
          resolve(entry.value.type).runtimeTypeId(ctx),
        ],
      ];
    }
    return [
      ctx.typeRefIndexMap[this] ?? runtimeTypeId(ctx),
      nullable ? 1 : 0,
      for (final argument in specifiedTypeArgs) argument.runtimeTypeId(ctx),
    ];
  }

  int runtimeTypeId(CompilerContext ctx) {
    final existing = ctx.runtimeTypeDescriptorIds[_runtimeDescriptorKey];
    if (existing != null) return existing;
    final id = ctx.runtimeTypeList.length;
    ctx.runtimeTypeDescriptorIds[_runtimeDescriptorKey] = id;
    ctx.runtimeTypeList.add(this);
    ctx.typeNames.add(name);
    return id;
  }

  List<TypeRef> get allSupertypes => [
    ?extendsType,
    ...implementsType,
    ...withType,
  ];

  List<TypeRef> get extendsChain => [
    ?extendsType,
    if (extendsType != null) ...extendsType!.extendsChain,
  ];

  List<List<TypeRef>> getTypeChain(CompilerContext ctx) {
    // `extends`/`implements`/`with` entries are declared in this class's type
    // parameter namespace (`class C<T> implements B<T>`), so substitute this
    // instance's arguments into them before walking their own chains —
    // otherwise `C1<int>` and `C2<int>` see `B<C1.T>` and `B<C2.T>` as
    // unrelated types.
    final substitutions = appliedTypeArguments(ctx);
    TypeRef applied(TypeRef t) =>
        substitutions.isEmpty ? t : t.substituteTypeParameters(substitutions);

    final l1extends = extendsType == null ? null : applied(extendsType!);
    final l2extends =
        l1extends?.resolveTypeChain(ctx).getTypeChain(ctx) ?? [];
    final chain = <List<TypeRef>>[
      if (l1extends != null && l2extends.isEmpty) [l1extends],
      ...l2extends,
    ];

    for (final imp in implementsType.reversed.map(applied)) {
      if (chain.isEmpty) {
        chain.add([]);
      }
      chain[0].add(imp);
      final tc = imp.resolveTypeChain(ctx).getTypeChain(ctx);
      for (var i = 0; i < tc.length; i++) {
        if (chain.length < i + 2) {
          chain.add([]);
        }
        chain[i + 1].addAll(tc[i]);
      }
    }

    for (final w in withType.reversed.map(applied)) {
      if (chain.isEmpty) {
        chain.add([]);
      }
      chain[0].add(w);
      final tc = w.resolveTypeChain(ctx).getTypeChain(ctx);
      for (var i = 0; i < tc.length; i++) {
        while (chain.length <= i + 1) {
          chain.add([]);
        }
        chain[i + 1].addAll(tc[i]);
      }
    }

    return [
      [this],
      ...chain,
    ];
  }

  bool get isUnboxedAcrossFunctionBoundaries =>
      unboxedAcrossFunctionBoundaries.contains(this) && !nullable;

  /// This type as it is stored when passed across a function boundary: boxed
  /// unless it is one of the types that can travel unboxed (e.g. non-nullable
  /// `int`, `double`, `bool`).
  TypeRef get typeAcrossFunctionBoundary =>
      copyWith(boxed: !isUnboxedAcrossFunctionBoundaries);

  /// Whether two references name the same declaration. This intentionally
  /// ignores type arguments, nullability, and representation details.
  bool hasSameDeclarationAs(TypeRef other) =>
      isTypeParameter || other.isTypeParameter
      ? isTypeParameter &&
            other.isTypeParameter &&
            typeParameterOwner == other.typeParameterOwner &&
            typeParameterIndex == other.typeParameterIndex
      : (file == other.file || name.startsWith('@record')) &&
            name == other.name;

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
    final left = resolveTypeChain(ctx);
    final right = other.resolveTypeChain(ctx);
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

  /// Classifies Dart assignment compatibility without conflating `dynamic`
  /// with a subtype proof.
  AssignmentConversion assignmentConversionTo(
    CompilerContext ctx,
    TypeRef slot,
  ) {
    final dynamicType = CoreTypes.dynamic.ref(ctx);
    if (slot == dynamicType || slot == CoreTypes.voidType.ref(ctx)) {
      return AssignmentConversion.none;
    }
    if (this == dynamicType) {
      if (slot == CoreTypes.object.ref(ctx) && slot.nullable) {
        return AssignmentConversion.none;
      }
      return AssignmentConversion.runtimeCheck;
    }
    if (nullable &&
        !slot.nullable &&
        copyWith(
          nullable: false,
        ).isAssignableTo(ctx, slot, forceAllowDynamic: false)) {
      return AssignmentConversion.runtimeCheck;
    }
    if (this == CoreTypes.int.ref(ctx) &&
        (slot == CoreTypes.double.ref(ctx) ||
            slot == CoreTypes.double.ref(ctx).copyWith(nullable: true))) {
      return AssignmentConversion.intToDouble;
    }
    return isAssignableTo(ctx, slot, forceAllowDynamic: false)
        ? AssignmentConversion.none
        : AssignmentConversion.invalid;
  }

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
  }) {
    if (slot == CoreTypes.dynamic.ref(ctx) ||
        slot == CoreTypes.voidType.ref(ctx) ||
        (forceAllowDynamic && this == CoreTypes.dynamic.ref(ctx))) {
      return true;
    }

    if (this == CoreTypes.never.ref(ctx)) {
      // `Never` is the bottom type: assignable to every type.
      return true;
    }
    if (this == CoreTypes.nullType.ref(ctx)) {
      return slot.nullable || slot == CoreTypes.nullType.ref(ctx);
    }
    if (nullable && !slot.nullable) return false;

    if (isTypeParameter) {
      // Same parameter: identical owner and index.
      if (this == slot) return true;
      // A type parameter is assignable to [slot] iff its declared bound is.
      // An unbounded parameter (`<T>`) has the implicit bound `Object?`.
      return (typeParameterBound ??
              CoreTypes.object.ref(ctx).copyWith(nullable: true))
          .isAssignableTo(
            ctx,
            slot,
            forceAllowDynamic: forceAllowDynamic,
          );
    }

    final generics = overrideGenerics ?? specifiedTypeArgs;

    if (hasSameDeclarationAs(slot) &&
        (!nullable || slot.nullable || this == CoreTypes.nullType.ref(ctx))) {
      if (slot.specifiedTypeArgs.isNotEmpty && generics.isNotEmpty &&
          generics.length != slot.specifiedTypeArgs.length) {
        return false;
      }
      // A raw generic (`Future` for `Future<C>`) acts like `Future<dynamic>`:
      // its missing arguments are assignable both ways.
      for (var i = 0;
          i < slot.specifiedTypeArgs.length && i < generics.length;
          i++) {
        if (!generics[i].isAssignableTo(
          ctx,
          slot.specifiedTypeArgs[i],
          forceAllowDynamic: false,
        )) {
          return false;
        }
      }
      return true;
    }

    for (final type in resolveTypeChain(ctx).allSupertypes) {
      final inheritedGenerics = type.specifiedTypeArgs.isEmpty
          ? generics
          : [
              for (final argument in type.specifiedTypeArgs)
                if (argument.isTypeParameter &&
                    argument.typeParameterIndex! < generics.length)
                  generics[argument.typeParameterIndex!].copyWith(
                    nullable:
                        argument.nullable ||
                        generics[argument.typeParameterIndex!].nullable,
                  )
                else
                  argument,
            ];
      if (type.isAssignableTo(
        ctx,
        slot,
        overrideGenerics: inheritedGenerics,
        forceAllowDynamic: false,
      )) {
        return true;
      }
    }

    return false;
  }

  TypeRef inheritTypeArgsFrom(CompilerContext ctx, TypeRef prototype) {
    final prototype0 = prototype.resolveTypeChain(ctx);
    var i = 0;
    var gmap = <String, int>{};
    for (final generic in genericParams) {
      gmap[generic.name] = i;
      i++;
    }
    var j = 0;
    var resolvedGenerics = List<TypeRef>.filled(i, CoreTypes.dynamic.ref(ctx));
    for (final generic in prototype0.genericParams) {
      if (gmap.containsKey(generic.name)) {
        resolvedGenerics[gmap[generic.name]!] = prototype0.specifiedTypeArgs[j];
      }
      j++;
    }
    return resolveTypeChain(ctx).copyWith(specifiedTypeArgs: resolvedGenerics);
  }

  TypeRef copyWith({
    int? file,
    String? name,
    TypeRef? extendsType,
    List<TypeRef>? implementsType,
    List<TypeRef>? withType,
    List<GenericParam>? genericParams,
    List<TypeRef>? specifiedTypeArgs,
    List<RecordParameterType>? recordFields,
    EvalFunctionType? functionType,
    String? typeParameterOwner,
    int? typeParameterIndex,
    TypeRef? typeParameterBound,
    bool? boxed,
    bool? resolved,
    bool? nullable,
  }) {
    return TypeRef(
      file ?? this.file,
      name ?? this.name,
      extendsType: extendsType ?? this.extendsType,
      implementsType: implementsType ?? this.implementsType,
      withType: withType ?? this.withType,
      genericParams: genericParams ?? this.genericParams,
      specifiedTypeArgs: specifiedTypeArgs ?? this.specifiedTypeArgs,
      functionType: functionType ?? this.functionType,
      typeParameterOwner: typeParameterOwner ?? this.typeParameterOwner,
      typeParameterIndex: typeParameterIndex ?? this.typeParameterIndex,
      typeParameterBound: typeParameterBound ?? this.typeParameterBound,
      recordFields: recordFields ?? this.recordFields,
      boxed: boxed ?? this.boxed,
      resolved: resolved ?? this.resolved,
      nullable: nullable ?? this.nullable,
    );
  }

  /// Replaces every free type-parameter reference inside this type with its
  /// declared bound (or `dynamic` when unbounded). Callers use this when a
  /// type leaves the scope that gave those parameters meaning — an
  /// unconstrained `T` is not a usable type for the caller.
  TypeRef lowerTypeParameters(CompilerContext ctx) {
    final substitutions = <(String, int), TypeRef>{};
    void collect(TypeRef t) {
      if (t.isTypeParameter) {
        substitutions.putIfAbsent(
          (t.typeParameterOwner!, t.typeParameterIndex!),
          () => t.typeParameterBound ?? CoreTypes.dynamic.ref(ctx),
        );
        return;
      }
      for (final argument in t.specifiedTypeArgs) {
        collect(argument);
      }
      for (final field in t.recordFields) {
        collect(field.type);
      }
      final signature = t.functionType;
      if (signature != null) {
        final returnType = signature.returnType.type;
        if (returnType != null) collect(returnType);
        for (final parameter in signature.normalParameters) {
          final parameterType = parameter.type.type;
          if (parameterType != null) collect(parameterType);
        }
        for (final parameter in signature.optionalParameters) {
          final parameterType = parameter.type.type;
          if (parameterType != null) collect(parameterType);
        }
        for (final parameter in signature.namedParameters.values) {
          final parameterType = parameter.type.type;
          if (parameterType != null) collect(parameterType);
        }
      }
    }

    collect(this);
    return substitutions.isEmpty
        ? this
        : substituteTypeParameters(substitutions);
  }

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
              : (file == other.file || name.startsWith('@record')) &&
                    name == other.name);

  @override
  int get hashCode => isTypeParameter
      ? Object.hash(typeParameterOwner, typeParameterIndex)
      : name.startsWith('@record')
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
  }) {
    if (typeParams == null) return;
    final lib = library ?? ctx.library;
    final temps = ctx.temporaryTypes[lib] ??= {};
    // First seed every parameter name so F-bounds can self-reference
    // (`T extends Foo<T>`): the bound resolves while `T` is visible.
    for (var index = 0; index < typeParams.length; index++) {
      final param = typeParams[index];
      temps[param.name.lexeme] = TypeRef(
        lib,
        param.name.lexeme,
        resolved: true,
        typeParameterOwner: owner ?? 'function:${ctx.currentFunctionId ?? -1}',
        typeParameterIndex: index,
      );
    }
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
  MixinDeclaration(:final onClause, :final implementsClause, :final typeParameters) =>
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

/// Breadth-first search for [type]'s supertype named `file:name`, returning
/// it instantiated with the receiver's arguments. Each hop's clause types
/// are expressed in that hop's own parameters, so they are substituted with
/// the hop's specified arguments before continuing.
TypeRef? instantiatedSupertypeView(
  CompilerContext ctx,
  TypeRef type,
  int file,
  String name,
) {
  final visited = <(int, String)>{};
  final queue = [type];
  while (queue.isNotEmpty) {
    final t = queue.removeAt(0);
    if (t.isTypeParameter || !visited.add((t.file, t.name))) continue;
    final params = t.specifiedTypeArgs;
    final subs = params.isEmpty
        ? const <(String, int), TypeRef>{}
        : <(String, int), TypeRef>{
            for (var i = 0; i < params.length; i++)
              ('class:${t.file}:${t.name}', i): params[i],
          };
    for (final sup in t.resolveTypeChain(ctx).allSupertypes) {
      final next = subs.isEmpty ? sup : sup.substituteTypeParameters(subs);
      if (!next.isTypeParameter &&
          next.file == file &&
          next.name == name) {
        return next;
      }
      queue.add(next);
    }
  }
  return null;
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
  final hostTypeParams = host is Declaration
      ? classLikeClauses(host).$4
      : null;
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
    typeParameters: classTypeParameterRefs(
      hostFile,
      hostName,
      hostTypeParams,
    ),
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
      : instantiatedSupertypeView(ctx, receiverType, hostFile, hostName);
  if (declaringType == null || declaringType.specifiedTypeArgs.isEmpty) {
    return rt;
  }
  final subs = <(String, int), TypeRef>{
    for (var i = 0; i < hostTypeParams.typeParameters.length; i++)
      ('class:$hostFile:$hostName', i): declaringType.specifiedTypeArgs[i],
  };
  return AlwaysReturnType(
    rt.type!.substituteTypeParameters(subs),
    rt.nullable,
  );
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
        TypeRef.fromAnnotation(ctx, library, rt, typeParameters: typeParameters),
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
    final lookupType = resolveThroughTypeParameters(ctx, type);
    if (lookupType == CoreTypes.dynamic.ref(ctx)) {
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
    final targetSubs = targetType?.appliedTypeArguments(ctx);
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
      resolved: true,
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
    final res = TypeRef.fromBridgeTypeRef(ctx, BridgeTypeRef(this, typeArgs));
    if (library == 'dart:core') {
      dartCoreFile = res.file;
    }
    return res;
  }
}

final class _TypeRefCache {
  final types = <int, Map<String, TypeRef>>{};
  final visibleLibraries = <TypeRef, List<int>>{};
}

/// Unifies [pattern] against [concrete] positionally, recording the binding
/// for each type-parameter slot encountered (e.g. unifying `List<X>` with
/// `List<num>` binds `X → num`). Used to map a type alias's parameters onto a
/// downward-inference bound.
void collectTypeParameterSubstitutions(
  CompilerContext ctx,
  TypeRef pattern,
  TypeRef concrete,
  Map<(String, int), TypeRef> substitutions,
) {
  if (pattern.isTypeParameter) {
    substitutions[(pattern.typeParameterOwner!, pattern.typeParameterIndex!)] =
        concrete;
    return;
  }
  if (!pattern.hasSameDeclarationAs(concrete)) {
    _collectViaSupertypes(ctx, pattern, concrete, substitutions);
    return;
  }
  final args = pattern.specifiedTypeArgs;
  for (var i = 0; i < args.length && i < concrete.specifiedTypeArgs.length; i++) {
    collectTypeParameterSubstitutions(
      ctx,
      args[i],
      concrete.specifiedTypeArgs[i],
      substitutions,
    );
  }
}

/// Unifies [pattern] against [concrete] via [pattern]'s declared supertypes
/// (e.g. `List<X>` against `Iterable<num>` reaches `Iterable<X>`), binding any
/// type parameters encountered. Declared supertypes live in the declaring
/// class's parameter keyspace, so each is instantiated through the pattern's
/// own applied arguments before unifying.
void _collectViaSupertypes(
  CompilerContext ctx,
  TypeRef pattern,
  TypeRef concrete,
  Map<(String, int), TypeRef> substitutions,
) {
  final queue = <TypeRef>[pattern];
  final seen = <String>{};
  while (queue.isNotEmpty) {
    final current = queue.removeLast();
    if (!seen.add(current.semanticKey)) continue;
    if (current.hasSameDeclarationAs(concrete)) {
      if (current.specifiedTypeArgs.isEmpty &&
          !identical(current, pattern) &&
          pattern.specifiedTypeArgs.length == concrete.specifiedTypeArgs.length) {
        // The declaring class's supertype is raw (e.g. `List<E> $extends
        // Iterable`); bind `pattern`'s arguments positionally instead.
        final pArgs = pattern.specifiedTypeArgs;
        for (var i = 0; i < pArgs.length; i++) {
          collectTypeParameterSubstitutions(
            ctx,
            pArgs[i],
            concrete.specifiedTypeArgs[i],
            substitutions,
          );
        }
      } else {
        collectTypeParameterSubstitutions(ctx, current, concrete, substitutions);
      }
      return;
    }
    final resolvedChain = current.resolveTypeChain(ctx);
    // Map the declaring class's parameter slots to `current`'s applied
    // arguments (use-site refs may not carry `genericParams`).
    final applied = <(String, int), TypeRef>{
      for (var i = 0; i < current.specifiedTypeArgs.length; i++)
        ('class:${resolvedChain.file}:${resolvedChain.name}', i):
            current.specifiedTypeArgs[i],
    };
    for (final sup in resolvedChain.allSupertypes) {
      queue.add(sup.substituteTypeParameters(applied));
    }
  }
}

/// Finds the instantiation of [target]'s declaration in [concrete]'s supertype
/// hierarchy (e.g. `I<int>` when target is `I<T>` and concrete is
/// `C<int> implements I<T>`), or null. Supertypes are instantiated through
/// each intermediate class's applied arguments.
TypeRef? findSupertypeInstantiation(
  CompilerContext ctx,
  TypeRef target,
  TypeRef concrete,
) {
  final queue = <TypeRef>[concrete];
  final seen = <String>{};
  while (queue.isNotEmpty) {
    final current = queue.removeLast();
    if (!seen.add(current.semanticKey)) continue;
    if (current.hasSameDeclarationAs(target)) return current;
    final resolvedChain = current.resolveTypeChain(ctx);
    final applied = <(String, int), TypeRef>{
      for (var i = 0; i < current.specifiedTypeArgs.length; i++)
        ('class:${resolvedChain.file}:${resolvedChain.name}', i):
            current.specifiedTypeArgs[i],
    };
    for (final sup in resolvedChain.allSupertypes) {
      queue.add(sup.substituteTypeParameters(applied));
    }
  }
  return null;
}

/// Fully unwraps a type-parameter chain (`T extends U, U extends C`) to the
/// outermost non-parameter bound, or `dynamic` when unbounded.
TypeRef resolveThroughTypeParameters(
  CompilerContext ctx,
  TypeRef type,
) {
  var t = type.resolveTypeChain(ctx);
  final seen = <String>{};
  while (t.isTypeParameter && seen.add(t.semanticKey)) {
    final bound = t.typeParameterBound;
    if (bound == null) {
      return CoreTypes.dynamic.ref(ctx);
    }
    t = bound.resolveTypeChain(ctx);
  }
  return t;
}

/// The `flatten` function from the async spec: the value type `T` such that
/// `await`/`async` treat a `FutureOr<T>`/`Future<T>`-shaped value as `T`.
/// `FutureOr` peels to its argument; a type implementing `Future<S>` peels
/// to `S`, recursively. Self-referential futures (`F implements Future<F>`)
/// return themselves.
TypeRef flattenType(CompilerContext ctx, TypeRef type) {
  var t = type.resolveTypeChain(ctx);
  var nullable = type.nullable;
  final seen = <String>{};
  while (seen.add(t.semanticKey)) {
    if (t.name == 'FutureOr' && t.specifiedTypeArgs.isNotEmpty) {
      nullable = nullable || t.nullable;
      t = t.specifiedTypeArgs.first.resolveTypeChain(ctx);
      continue;
    }
    final instantiation = findSupertypeInstantiation(
      ctx,
      CoreTypes.future.ref(ctx),
      t,
    );
    if (instantiation == null) {
      return t.copyWith(nullable: t.nullable || nullable);
    }
    nullable = nullable || t.nullable;
    t =
        (instantiation.specifiedTypeArgs.isEmpty
                ? CoreTypes.dynamic.ref(ctx)
                : instantiation.specifiedTypeArgs.first)
            .resolveTypeChain(ctx);
  }
  return t.copyWith(nullable: t.nullable || nullable);
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
        resolved: true,
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
        resolved: true,
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
        : CoreTypes.function.ref(ctx).copyWith(
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
    target = CoreTypes.function.ref(ctx).copyWith(
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
          resolved: true,
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
    final mixinParams = switch (mixinDecl) {
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
        mixinParams[i].name.lexeme: resolveAppliedMixinArg(
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
      : TypeRef.fromAnnotation(ctx, file, bound).substituteTypeParameters(
          substitutions,
        );
}


/// For [member] folded into [applier] from a mixin or mixin-class (possibly
/// through a chain of mixin applications), seeds `temporaryTypes` in the
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
  ctx.temporaryTypes[memberLibrary] ??= {};
  ctx.temporaryTypes[memberLibrary]!.addAll(applied);
}

/// Resolves [ref] — a generic parameter declared by a bridge class — through
/// [type]'s supertypes when [type] itself is a plain class. A Dart class
/// extending or mixing a bridged generic (e.g. `class L extends List<T>`)
/// maps the bridge's parameters to its applied arguments positionally.
/// Returns null when no bridged ancestor declares [ref].
TypeRef? bridgedTypeArgument(CompilerContext ctx, TypeRef type, String ref) {
  final seen = <String>{};
  final worklist = <TypeRef>[type.resolveTypeChain(ctx)];
  while (worklist.isNotEmpty) {
    final current = worklist.removeLast();
    if (!seen.add('${current.file}:${current.name}')) continue;
    final declaration =
        ctx.topLevelDeclarationsMap[current.file]?[current.name];
    final bridge = declaration?.bridge;
    if (bridge is BridgeClassDef) {
      final names = bridge.type.generics.keys.toList();
      final index = names.indexOf(ref);
      if (index < 0) continue;
      if (index < current.specifiedTypeArgs.length) {
        return current.specifiedTypeArgs[index];
      }
      final bound = bridge.type.generics[ref]!.$extends;
      return bound == null
          ? CoreTypes.dynamic.ref(ctx)
          : TypeRef.fromBridgeTypeRef(ctx, bound);
    }
    final substitutions = current.appliedTypeArguments(ctx);
    for (final next in current.resolveTypeChain(ctx).allSupertypes) {
      worklist.add(next.substituteTypeParameters(substitutions));
    }
  }
  return null;
}

/// Dart's "no declared type" inference widens a `Null`-typed initializer to
/// `dynamic` (`var x = null`, `var f = null`): an uninhabited declared type
/// would reject every later assignment.
TypeRef widenedInferredType(CompilerContext ctx, TypeRef type) =>
    type.resolveTypeChain(ctx) == CoreTypes.nullType.ref(ctx)
        ? CoreTypes.dynamic.ref(ctx)
        : type;
