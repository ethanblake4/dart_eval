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

    return makeNullable ? sorted[0].copyWith(nullable: true) : sorted[0];
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
        );
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
        nullable: typeAnnotation.question != null,
      );
    }
    return unspecifiedType.copyWith(nullable: typeAnnotation.question != null);
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
        throw CompileError(
          'Trying to resolve bridged generic type $ref on $specifiedType, which is not a bridge class',
        );
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
    if (ctx.currentClass == null) {
      return null;
    }
    return TypeRef.lookupDeclaration(ctx, ctx.library, ctx.currentClass!);
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
  }) {
    if ($class == CoreTypes.dynamic.ref(ctx)) {
      return null;
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
          return TypeRef.fromAnnotation(ctx, $class.file, annotation);
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
          return TypeRef.fromAnnotation(
            ctx,
            $class.file,
            annotation,
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
        return TypeRef.fromAnnotation(ctx, $class.file, annotation);
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
      final $extends = dec0 is ClassDeclaration ? dec0.extendsClause : null;
      if ($extends == null) {
        if ($class == CoreTypes.object.ref(ctx)) {
          throw CompileError(
            'Field $field not found in class ${$class} or its superclasses',
            source,
          );
        }
        return TypeRef.lookupFieldType(ctx, CoreTypes.object.ref(ctx), field);
      } else {
        final $super = $class
            .resolveTypeChain(ctx, source: source)
            .extendsType!;
        return TypeRef.lookupFieldType(ctx, $super, field, source: source);
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

        if (type.$extends != null) {
          $super =
              TypeRef.fromBridgeTypeRef(
                ctx,
                type.$extends!,
                specifiedType: this,
              ).resolveTypeChain(
                ctx,
                recursionGuard: rg,
                stack: stack0,
                source: source,
              );
        }

        for (final $i in type.$implements) {
          $implements.add(
            TypeRef.fromBridgeTypeRef(
              ctx,
              $i,
              specifiedType: this,
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
            ).resolveTypeChain(
              ctx,
              recursionGuard: rg,
              stack: stack0,
              source: source,
            ),
          );
        }

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
      }
    } else {
      final dec = declaration.declaration!;
      final extendsClause = dec is ClassDeclaration ? dec.extendsClause : null;
      final withClause = dec is ClassDeclaration
          ? dec.withClause
          : (dec as EnumDeclaration).withClause;
      final implementsClause = dec is ClassDeclaration
          ? dec.implementsClause
          : (dec as EnumDeclaration).implementsClause;
      final typeParameters = dec is ClassDeclaration
          ? dec.namePart.typeParameters
          : (dec as EnumDeclaration).namePart.typeParameters;
      superName = extendsClause?.superclass;
      withNames = withClause?.mixinTypes.toList() ?? [];
      implementsNames = implementsClause?.interfaces.toList() ?? [];
      generics =
          typeParameters?.typeParameters
              .map(
                (t) => GenericParam(
                  t.name.lexeme,
                  t.bound == null
                      ? null
                      : TypeRef.fromAnnotation(ctx, file, t.bound!),
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

    TypeRef resolveClauseType(NamedType clauseName) =>
        (ctx.visibleTypes[file]![clauseTypeName(clauseName)] ??
                (throw CompileError(
                  'Type ${clauseTypeName(clauseName)} not found',
                  source,
                )))
            .copyWith(specifiedTypeArgs: resolveClauseTypeArgs(clauseName))
            .resolveTypeChain(
              ctx,
              recursionGuard: rg,
              stack: stack0,
              source: source,
            );

    if (superName != null) {
      $super = resolveClauseType(superName);
    } else if (declaration.declaration is EnumDeclaration) {
      $super = CoreTypes.enumType.ref(ctx);
    } else if (!declaration.isBridge) {
      $super = CoreTypes.object.ref(ctx);
    }

    for (final withName in withNames) {
      $with.add(resolveClauseType(withName));
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
    return {
      runtimeTypeId(ctx),
      ctx.typeRefIndexMap[this] ?? runtimeTypeId(ctx),
      for (final a in allSupertypes) ...a.getRuntimeIndices(ctx),
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
        (typeParameterBound ?? CoreTypes.dynamic.ref(ctx)).runtimeTypeId(ctx),
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
    final l1extends = extendsType;
    final l2extends =
        extendsType?.resolveTypeChain(ctx).getTypeChain(ctx) ?? [];
    final chain = <List<TypeRef>>[
      if (l1extends != null && l2extends.isEmpty) [l1extends],
      ...l2extends,
    ];

    for (final imp in implementsType.reversed) {
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

    for (final w in withType.reversed) {
      if (chain.isEmpty) {
        chain.add([]);
      }
      chain[0].add(w);
      final tc = w.resolveTypeChain(ctx).getTypeChain(ctx);
      for (var i = 0; i < tc.length; i++) {
        if (chain.length < i + 1) {
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

    if (this == CoreTypes.nullType.ref(ctx)) {
      return slot.nullable || slot == CoreTypes.nullType.ref(ctx);
    }
    if (nullable && !slot.nullable) return false;

    if (isTypeParameter) {
      // Same parameter: identical owner and index.
      if (this == slot) return true;
      // A type parameter is assignable to [slot] iff its declared bound is.
      return typeParameterBound?.isAssignableTo(
            ctx,
            slot,
            forceAllowDynamic: forceAllowDynamic,
          ) ??
          false;
    }

    final generics = overrideGenerics ?? specifiedTypeArgs;

    if (hasSameDeclarationAs(slot) &&
        (!nullable || slot.nullable || this == CoreTypes.nullType.ref(ctx))) {
      if (slot.specifiedTypeArgs.isNotEmpty &&
          generics.length != slot.specifiedTypeArgs.length) {
        return false;
      }
      for (var i = 0; i < slot.specifiedTypeArgs.length; i++) {
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

    // A type with a `.call` method is assignable to `Function` (implicit
    // call — `Function f = callableObject`).
    if (slot == CoreTypes.function.ref(ctx)) {
      final chain = [this, ...resolveTypeChain(ctx).allSupertypes];
      for (final t in chain) {
        if (ctx.instanceDeclarationsMap[t.file]?[t.name]?['call'] != null) {
          return true;
        }
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
    if (typeParams != null) {
      for (var index = 0; index < typeParams.length; index++) {
        final param = typeParams[index];
        ctx.temporaryTypes[library ?? ctx.library] ??= {};
        final bound = param.bound;
        final name = param.name.lexeme;
        final resolvedBound = bound == null
            ? CoreTypes.dynamic.ref(ctx)
            : TypeRef.fromAnnotation(ctx, library ?? ctx.library, bound);
        ctx.temporaryTypes[library ?? ctx.library]![name] = TypeRef(
          library ?? ctx.library,
          name,
          resolved: true,
          typeParameterOwner:
              owner ?? 'function:${ctx.currentFunctionId ?? -1}',
          typeParameterIndex: index,
          typeParameterBound: resolvedBound,
        );
      }
    }
  }
}

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
  final prefix = type.importPrefix;
  if (prefix != null &&
      ctx.visibleDeclarations[library]?[prefix.name.lexeme]?.children !=
          null) {
    return ('${prefix.name.lexeme}.${type.name.lexeme}', trailingSelector ?? '');
  }
  if (prefix != null) {
    return (prefix.name.lexeme, type.name.lexeme);
  }
  return (type.name.lexeme, trailingSelector ?? '');
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

class AlwaysReturnType implements ReturnType {
  const AlwaysReturnType(this.type, this.nullable);

  factory AlwaysReturnType.fromAnnotation(
    CompilerContext ctx,
    int library,
    TypeAnnotation? typeAnnotation,
    TypeRef? fallback,
  ) {
    final rt = typeAnnotation;
    if (rt != null) {
      return AlwaysReturnType(
        TypeRef.fromAnnotation(ctx, library, rt),
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
    return AlwaysReturnType.fromAnnotation(
      ctx,
      type.file,
      d.returnType,
      fallback,
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
    final lookupType = type.isTypeParameter
        ? type.typeParameterBound ?? CoreTypes.dynamic.ref(ctx)
        : type;
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
    return AlwaysReturnType.fromAnnotation(
      ctx,
      lookupType.file,
      d.returnType,
      CoreTypes.dynamic.ref(ctx),
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
    return this;
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

/// Resolves a `typedef` use to the type it aliases. Function-type aliases
/// (`typedef void F()`, `typedef F = void Function()`) map to `Function`;
/// named-type aliases (`typedef X = List<int>`) resolve recursively. Type
/// parameters on the alias are not substituted — the underlying annotation is
/// resolved as-is.
TypeRef resolveTypeAlias(
  CompilerContext ctx,
  int library,
  TypeAlias alias, {
  bool nullable = false,
}) {
  final TypeRef target;
  if (alias is GenericTypeAlias && alias.functionType == null) {
    target = TypeRef.fromAnnotation(ctx, library, alias.type);
  } else {
    target = CoreTypes.function.ref(ctx);
  }
  return target.copyWith(nullable: nullable || target.nullable);
}
