import 'package:analyzer/dart/ast/ast.dart';
import 'package:collection/collection.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/expression/method_invocation.dart';
import 'package:dart_eval/src/eval/compiler/model/function_type.dart';
import 'package:dart_eval/src/eval/runtime/type.dart';

import 'builtins.dart';
import 'context.dart';
import 'errors.dart';

/// Reference to a type in the compiler. Types are initially created
/// with a [file] and [name], and resolved lazily with [resolveTypeChain]
/// to fill in information such as [extendsType], [implementsType], and
/// [withType].
class TypeRef {
  const TypeRef(this.file, this.name,
      {this.extendsType,
      this.implementsType = const [],
      this.withType = const [],
      this.genericParams = const [],
      this.specifiedTypeArgs = const [],
      this.recordFields = const [],
      this.resolved = false,
      this.functionType,
      this.boxed = true,
      this.nullable = false});

  /// Cache mapping file/library IDs to type names to [TypeRef]s.
  static final _cache = <int, Map<String, TypeRef>>{};

  /// Cache mapping [TypeRef]s to file/library IDs.
  static final _inverseCache = <TypeRef, List<int>>{};

  final int file;
  final String name;
  final TypeRef? extendsType;
  final List<TypeRef> implementsType;
  final List<TypeRef> withType;
  final List<GenericParam> genericParams;
  final List<TypeRef> specifiedTypeArgs;
  final List<RecordParameterType> recordFields;
  final EvalFunctionType? functionType;
  final bool resolved;
  final bool boxed;
  final bool nullable;

  /// Create and cache a [TypeRef] given a [file] and [name].
  /// This type ref contains only basic info and can be resolved later.
  factory TypeRef.cache(CompilerContext ctx, int file, String name,
      {int? fileRef}) {
    TypeRef $type;
    if (!_cache.containsKey(file)) {
      _cache[file] = {};
    }

    final fileCache = _cache[file]!;
    if (!fileCache.containsKey(name)) {
      $type = (fileCache[name] = TypeRef(file, name));
    } else {
      $type = fileCache[name]!;
    }

    if (fileRef != null) {
      if (!_inverseCache.containsKey($type)) {
        _inverseCache[$type] = [];
      }
      _inverseCache[$type]!.add(fileRef);
    }

    ctx.typeRefIndexMap[$type] = ctx.typeNames.length;
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
    final chains =
        types.map((e) => e.resolveTypeChain(ctx).getTypeChain(ctx)).toList();

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
      CompilerContext ctx, int library, TypeAnnotation typeAnnotation) {
    if (typeAnnotation is GenericFunctionType) {
      return CoreTypes.function.ref(ctx);
    }
    if (typeAnnotation is RecordTypeAnnotation) {
      final fields = <RecordParameterType>[];

      var name = '@record<';
      var positionalFields = 1;
      for (var i = 0; i < typeAnnotation.positionalFields.length; i++) {
        final field = typeAnnotation.positionalFields[i];
        final fType = TypeRef.fromAnnotation(ctx, library, field.type);
        fields
            .add(RecordParameterType('\$${positionalFields++}', fType, false));
        name += '$fType';
        if (i < typeAnnotation.positionalFields.length - 1) {
          name += ',';
        }
      }

      final namedFields = typeAnnotation.namedFields?.fields ??
          <RecordTypeAnnotationNamedField>[];
      if (namedFields.isNotEmpty) {
        name += ',{';
      }
      for (var i = 0; i < namedFields.length; i++) {
        final field = namedFields[i];
        final fType = TypeRef.fromAnnotation(ctx, library, field.type);
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
      return TypeRef(-1, name,
          recordFields: fields,
          extendsType: CoreTypes.record.ref(ctx),
          resolved: true,
          boxed: false,
          nullable: typeAnnotation.question != null);
    }
    typeAnnotation as NamedType;
    final n = typeAnnotation.name2.stringValue ?? typeAnnotation.name2.value();
    final unspecifiedType =
        ctx.temporaryTypes[library]?[n] ?? ctx.visibleTypes[library]?[n];
    if (unspecifiedType == null) {
      throw CompileError(
          'Unknown type $n', typeAnnotation.parent, library, ctx);
    }
    final typeArgs = typeAnnotation.typeArguments;
    if (typeArgs != null) {
      final resolved = <TypeRef>[];
      for (final arg in typeArgs.arguments) {
        resolved.add(TypeRef.fromAnnotation(ctx, library, arg));
      }
      return unspecifiedType.copyWith(
          specifiedTypeArgs: resolved,
          nullable: typeAnnotation.question != null);
    }
    return unspecifiedType.copyWith(nullable: typeAnnotation.question != null);
  }

  /// Create a [TypeRef] from a [BridgeTypeAnnotation].
  factory TypeRef.fromBridgeAnnotation(
      CompilerContext ctx, BridgeTypeAnnotation typeAnnotation,
      {TypeRef? specifyingType,
      TypeRef? specifiedType,
      bool staticSource = true}) {
    return TypeRef.fromBridgeTypeRef(ctx, typeAnnotation.type,
            staticSource: staticSource,
            specifyingType: specifyingType,
            specifiedType: specifiedType)
        .copyWith(nullable: typeAnnotation.nullable);
  }

  factory TypeRef.fromBridgeTypeRef(
      CompilerContext ctx, BridgeTypeRef typeReference,
      {bool staticSource = true,
      TypeRef? specifyingType,
      TypeRef? specifiedType}) {
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
        specifiedTypeArgs.add(TypeRef.fromBridgeAnnotation(ctx, arg,
            staticSource: staticSource, specifiedType: specifiedType));
      }
      final lib = ctx.libraryMap[spec.library] ??
          (throw CompileError('Bridge: cannot find library ${spec.library}'));
      return ctx.visibleTypes[lib]![spec.name]!
          .copyWith(specifiedTypeArgs: specifiedTypeArgs, boxed: true);
    }
    final ref = typeReference.ref;
    if (ref != null) {
      specifiedType ??=
          ctx.visibleTypes[ctx.library]![ctx.currentClass?.name.stringValue];

      if (specifiedType == null) {
        return CoreTypes.dynamic.ref(ctx);
      }

      final declaration =
          ctx.topLevelDeclarationsMap[specifiedType.file]![specifiedType.name]!;
      if (!declaration.isBridge) {
        throw CompileError(
            'Trying to resolve bridged generic type $ref on $specifiedType, which is not a bridge class');
      }
      final dec = declaration.bridge!;
      if (dec is! BridgeClassDef) {
        throw CompileError(
            'Trying to resolve bridged generic type $ref on $specifiedType, which is not a bridge class');
      }

      final genericIndex =
          dec.type.generics.keys.toList().indexWhere((key) => key == ref);
      if (specifiedType.specifiedTypeArgs.isNotEmpty) {
        return specifiedType.specifiedTypeArgs[genericIndex];
      }
      final generic = dec.type.generics[ref]!;
      final $extends = generic.$extends;
      final boundType = $extends == null
          ? CoreTypes.dynamic.ref(ctx)
          : TypeRef.fromBridgeTypeRef(ctx, $extends);

      if (specifyingType != null) {
        final syDeclaration = ctx.topLevelDeclarationsMap[specifyingType.file]![
            specifyingType.name]!;
        final syDec = syDeclaration.declaration!;

        if (syDec is! ClassDeclaration) {
          throw CompileError('Specifying types from bridge is not supported');
        }
        final syExtends = syDec.extendsClause;
        if (syExtends != null &&
            syExtends.superclass.name2.stringValue == specifiedType.name) {
          final declaredType =
              syExtends.superclass.typeArguments?.arguments[genericIndex];
          if (declaredType != null) {
            final resolvedDeclaredType =
                TypeRef.fromAnnotation(ctx, specifyingType.file, declaredType);
            if (!resolvedDeclaredType.isAssignableTo(ctx, boundType)) {
              throw CompileError(
                  "Type argument $resolvedDeclaredType does not conform to type parameter $ref's"
                  "bound ($boundType)");
            }
            return resolvedDeclaredType;
          }
        }
      }

      return boundType;
    }
    final gft = typeReference.gft;
    if (gft != null) {
      return CoreTypes.function.ref(ctx).copyWith(
          functionType: EvalFunctionType.fromBridgeFunctionDef(ctx, gft));
    }
    throw CompileError(
        'No support for looking up types by other bridge annotation types');
  }

  static TypeRef? $this(CompilerContext ctx) {
    if (ctx.currentClass == null) {
      return null;
    }
    return TypeRef.lookupDeclaration(ctx, ctx.library, ctx.currentClass!);
  }

  factory TypeRef.lookupDeclaration(
      CompilerContext ctx, int library, NamedCompilationUnitMember dec,
      {String? prefix}) {
    return ctx.visibleTypes[library]![
            '${prefix != null ? '$prefix.' : ''}${dec.name.lexeme}'] ??
        (throw CompileError('Class/enum ${dec.name.value()} not found'));
  }

  static TypeRef? lookupFieldType(
      CompilerContext ctx, TypeRef $class, String field,
      {bool forFieldFormal = false, bool forSet = false, AstNode? source}) {
    if ($class == CoreTypes.dynamic.ref(ctx)) {
      return null;
    }
    final f = getKnownFields(ctx)[$class];
    if (f != null) {
      final d = f[field];
      if (d != null) {
        return d.fieldType?.toAlwaysReturnType(ctx, $class, [], {})?.type ??
            CoreTypes.dynamic.ref(ctx);
      }
    }

    if ($class.recordFields.isNotEmpty) {
      final field0 =
          $class.recordFields.firstWhereOrNull((f) => f.name == field);
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
                source);
          }
          final parameter =
              f.parameters!.parameters.first as SimpleFormalParameter;
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
              source);
        }
        final annotation = (f.parent as VariableDeclarationList).type;
        if (annotation != null) {
          return TypeRef.fromAnnotation(ctx, $class.file, annotation)
              .copyWith(boxed: true);
        }
        if (ctx.inferredFieldTypes.containsKey($class.file) &&
            ctx.inferredFieldTypes[$class.file]!.containsKey($class.name) &&
            ctx.inferredFieldTypes[$class.file]![$class.name]!
                .containsKey(field)) {
          return ctx.inferredFieldTypes[$class.file]![$class.name]![field]!;
        }
        return null;
      } else if (!forFieldFormal && $declarations.containsKey('$field*g')) {
        final f = $declarations['$field*g'];
        if (f is! MethodDeclaration) {
          throw CompileError(
              'Cannot query getter type of F${$class.file}:${$class.name}.$field, which is not a method',
              source);
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
      final br = dec.bridge as BridgeClassDef;
      final fd = br.fields[field];
      if (fd != null) {
        return TypeRef.fromBridgeAnnotation(ctx, fd.type,
            specifiedType: $class);
      }
      final get = br.getters[field];
      if (get != null) {
        return TypeRef.fromBridgeAnnotation(ctx, get.functionDescriptor.returns,
            specifiedType: $class);
      }
      final set = br.getters[field];
      if (set != null) {
        return TypeRef.fromBridgeAnnotation(ctx, set.functionDescriptor.returns,
            specifiedType: $class);
      }
      final $extends = br.type.$extends;
      if ($extends == null) {
        throw CompileError(
            'Field $field not found in bridge class ${$class}', source);
      } else {
        final $super = TypeRef.fromBridgeTypeRef(ctx, $extends);
        return TypeRef.lookupFieldType(
            ctx, $super.inheritTypeArgsFrom(ctx, $class), field,
            source: source);
      }
    } else if (dec.declaration is EnumDeclaration && field == 'index') {
      return CoreTypes.int.ref(ctx);
    } else {
      if (forFieldFormal) {
        throw CompileError(
            'Field formals did not find field $field in class ${$class}',
            source);
      }
      final dec0 = dec.declaration as NamedCompilationUnitMember;
      final $extends = dec0 is ClassDeclaration ? dec0.extendsClause : null;
      if ($extends == null) {
        if ($class == CoreTypes.object.ref(ctx)) {
          throw CompileError(
              'Field $field not found in class ${$class} or its superclasses',
              source);
        }
        return TypeRef.lookupFieldType(ctx, CoreTypes.object.ref(ctx), field);
      } else {
        final $super = ctx.visibleTypes[$class.file]![
            $extends.superclass.name2.stringValue ??
                $extends.superclass.name2.value()]!;
        return TypeRef.lookupFieldType(
            ctx, $super.inheritTypeArgsFrom(ctx, $class), field);
      }
    }
  }

  /// Resolve the full type chain of this [TypeRef]. If it or its supertypes
  /// have already been resolved, it will return a copy of the resolved type
  /// from the cache.
  TypeRef resolveTypeChain(CompilerContext ctx,
      {int recursionGuard = 0,
      Set<TypeRef> stack = const {},
      AstNode? source}) {
    if (recursionGuard > 500) {
      throw CompileError(
          'Reached max limit on recursion while resolving types. '
          'Your type hierarchy is probably recursive (caught while resolving $this)');
    }
    final stack0 = {...stack, this};
    final rg = recursionGuard + 1;
    final resolvedSpecifiedTypeArgs = specifiedTypeArgs
        .map((e) => stack.contains(e)
            ? e
            : e.resolveTypeChain(ctx, recursionGuard: rg, stack: stack0))
        .toList();
    if (resolved) {
      return copyWith(specifiedTypeArgs: resolvedSpecifiedTypeArgs);
    }

    if (recordFields.isNotEmpty) {
      return copyWith(
          resolved: true,
          extendsType: CoreTypes.record.ref(ctx),
          specifiedTypeArgs: resolvedSpecifiedTypeArgs,
          boxed: false);
    }

    final $cached = _cache[file]![name]!;
    if ($cached.resolved) {
      return $cached.copyWith(
          boxed: boxed, specifiedTypeArgs: resolvedSpecifiedTypeArgs);
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
          $super = TypeRef.fromBridgeTypeRef(ctx, type.$extends!,
                  specifiedType: this)
              .resolveTypeChain(ctx,
                  recursionGuard: rg, stack: stack0, source: source);
        }

        for (final $i in type.$implements) {
          $implements.add(
              TypeRef.fromBridgeTypeRef(ctx, $i, specifiedType: this)
                  .resolveTypeChain(ctx,
                      recursionGuard: rg, stack: stack0, source: source));
        }

        for (final $i in type.$with) {
          $with.add(TypeRef.fromBridgeTypeRef(ctx, $i, specifiedType: this)
              .resolveTypeChain(ctx,
                  recursionGuard: rg, stack: stack0, source: source));
        }

        for (final $g in type.generics.entries) {
          final gExtends = $g.value.$extends;
          final type0 = gExtends == null
              ? null
              : TypeRef.fromBridgeTypeRef(ctx, gExtends);
          generics.add(GenericParam(
              $g.key,
              type0?.resolveTypeChain(ctx,
                  recursionGuard: rg, stack: stack0, source: source)));
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
          ? dec.typeParameters
          : (dec as EnumDeclaration).typeParameters;
      superName = extendsClause?.superclass;
      withNames = withClause?.mixinTypes.toList() ?? [];
      implementsNames = implementsClause?.interfaces.toList() ?? [];
      generics = typeParameters?.typeParameters
              .map((t) => GenericParam(
                  t.name.lexeme,
                  t.bound == null
                      ? null
                      : TypeRef.fromAnnotation(ctx, file, t.bound!)))
              .toList() ??
          [];
    }

    if (superName != null) {
      final typeParams = superName.typeArguments?.arguments
              .map((a) => TypeRef.fromAnnotation(ctx, file, a))
              .map((a) => stack.contains(a)
                  ? a
                  : a.resolveTypeChain(ctx,
                      recursionGuard: rg, stack: stack0, source: source))
              .toList() ??
          [];
      final prefix = superName.importPrefix;
      final superPrefix = prefix != null ? '${prefix.name.value()}.' : '';
      $super =
          (ctx.visibleTypes[file]!['$superPrefix${superName.name2.lexeme}'] ??
                  (throw CompileError(
                      'Superclass ${superName.name2.lexeme} not found',
                      source)))
              .copyWith(specifiedTypeArgs: typeParams)
              .resolveTypeChain(ctx,
                  recursionGuard: rg, stack: stack0, source: source);
    } else if (declaration.declaration is EnumDeclaration) {
      $super = CoreTypes.enumType.ref(ctx);
    } else if (!declaration.isBridge) {
      $super = CoreTypes.object.ref(ctx);
    }

    for (final withName in withNames) {
      final typeParams = withName.typeArguments?.arguments
              .map((a) => TypeRef.fromAnnotation(ctx, file, a))
              .map((a) => stack.contains(a)
                  ? a
                  : a.resolveTypeChain(ctx,
                      recursionGuard: rg, stack: stack0, source: source))
              .toList() ??
          [];
      $with.add(ctx.visibleTypes[file]![withName.name2.value()]!
          .copyWith(specifiedTypeArgs: typeParams)
          .resolveTypeChain(ctx,
              recursionGuard: rg, stack: stack0, source: source));
    }

    for (final implementsName in implementsNames) {
      final typeParams = implementsName.typeArguments?.arguments
              .map((a) => TypeRef.fromAnnotation(ctx, file, a))
              .map((a) => stack.contains(a)
                  ? a
                  : a.resolveTypeChain(ctx,
                      recursionGuard: rg, stack: stack0, source: source))
              .toList() ??
          [];
      $implements.add(ctx.visibleTypes[file]![implementsName.name2.value()]!
          .copyWith(specifiedTypeArgs: typeParams)
          .resolveTypeChain(ctx,
              recursionGuard: rg, stack: stack0, source: source));
    }

    final resolvedRef = TypeRef(file, name,
        extendsType: $super,
        withType: $with,
        implementsType: $implements,
        genericParams: generics,
        resolved: true,
        boxed: boxed,
        specifiedTypeArgs: resolvedSpecifiedTypeArgs);

    for (final $file in _inverseCache[this]!) {
      ctx.visibleTypes[$file]![name] ??= resolvedRef;
    }

    final fileCache = _cache[file]!;
    if (fileCache[name] == null || !fileCache[name]!.resolved) {
      fileCache[name] = resolvedRef.copyWith(boxed: true);
    }

    return resolvedRef;
  }

  Set<int> getRuntimeIndices(CompilerContext ctx) {
    return {
      ctx.typeRefIndexMap[this]!,
      for (final a in allSupertypes) ...a.getRuntimeIndices(ctx)
    };
  }

  RuntimeType toRuntimeType(CompilerContext ctx) {
    final ta = [for (final t in specifiedTypeArgs) t.toRuntimeType(ctx)];
    return RuntimeType(ctx.typeRefIndexMap[this]!, ta);
  }

  List<TypeRef> get allSupertypes =>
      [if (extendsType != null) extendsType!, ...implementsType, ...withType];

  List<TypeRef> get extendsChain => [
        if (extendsType != null) extendsType!,
        if (extendsType != null) ...extendsType!.extendsChain
      ];

  List<List<TypeRef>> getTypeChain(CompilerContext ctx) {
    final l1extends = extendsType;
    final l2extends =
        extendsType?.resolveTypeChain(ctx).getTypeChain(ctx) ?? [];
    final chain = <List<TypeRef>>[
      if (l1extends != null && l2extends.isEmpty) [l1extends],
      ...l2extends
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
      ...chain
    ];
  }

  bool get isUnboxedAcrossFunctionBoundaries =>
      unboxedAcrossFunctionBoundaries.contains(this) && !nullable;

  bool isAssignableTo(CompilerContext ctx, TypeRef slot,
      {List<TypeRef>? overrideGenerics, bool forceAllowDynamic = true}) {
    if (forceAllowDynamic &&
        (this == CoreTypes.dynamic.ref(ctx) ||
            slot == CoreTypes.dynamic.ref(ctx))) {
      return true;
    }

    if (this == CoreTypes.nullType.ref(ctx)) {
      return slot.nullable || slot == CoreTypes.nullType.ref(ctx);
    }

    final generics = overrideGenerics ?? specifiedTypeArgs;

    if (this == slot) {
      for (var i = 0; i < generics.length; i++) {
        if (slot.specifiedTypeArgs.length - 1 > i) {
          if (!generics[i].isAssignableTo(ctx, slot.specifiedTypeArgs[i])) {
            return false;
          }
        }
      }
      return true;
    }

    for (final type in resolveTypeChain(ctx).allSupertypes) {
      if (type.isAssignableTo(ctx, slot,
          overrideGenerics: generics, forceAllowDynamic: false)) {
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

  TypeRef copyWith(
      {int? file,
      String? name,
      TypeRef? extendsType,
      List<TypeRef>? implementsType,
      List<TypeRef>? withType,
      List<GenericParam>? genericParams,
      List<TypeRef>? specifiedTypeArgs,
      List<RecordParameterType>? recordFields,
      EvalFunctionType? functionType,
      bool? boxed,
      bool? resolved,
      bool? nullable}) {
    return TypeRef(file ?? this.file, name ?? this.name,
        extendsType: extendsType ?? this.extendsType,
        implementsType: implementsType ?? this.implementsType,
        withType: withType ?? this.withType,
        genericParams: genericParams ?? this.genericParams,
        specifiedTypeArgs: specifiedTypeArgs ?? this.specifiedTypeArgs,
        functionType: functionType ?? this.functionType,
        recordFields: recordFields ?? this.recordFields,
        boxed: boxed ?? this.boxed,
        resolved: resolved ?? this.resolved,
        nullable: nullable ?? this.nullable);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TypeRef &&
          runtimeType == other.runtimeType &&
          (file == other.file || name.startsWith('@record')) &&
          name == other.name;

  @override
  int get hashCode => file.hashCode ^ name.hashCode;

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
      CompilerContext ctx, List<TypeParameter>? typeParams,
      [int? library]) {
    if (typeParams != null) {
      for (final param in typeParams) {
        ctx.temporaryTypes[library ?? ctx.library] ??= {};
        final bound = param.bound;
        final name = param.name.lexeme;
        if (bound != null) {
          ctx.temporaryTypes[library ?? ctx.library]![name] =
              TypeRef.fromAnnotation(ctx, library ?? ctx.library, bound);
        } else {
          ctx.temporaryTypes[library ?? ctx.library]![name] =
              CoreTypes.dynamic.ref(ctx);
        }
      }
    }
  }
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

abstract class ReturnType {
  AlwaysReturnType? toAlwaysReturnType(CompilerContext ctx, TypeRef? targetType,
      List<TypeRef?> argTypes, Map<String, TypeRef?> namedArgTypes,
      {List<TypeRef> typeArgs = const []});
}

class BridgedReturnType implements ReturnType {
  final BridgeTypeSpec spec;
  final bool nullable;

  BridgedReturnType(this.spec, this.nullable);

  @override
  AlwaysReturnType? toAlwaysReturnType(CompilerContext ctx, TypeRef? targetType,
      List<TypeRef?> argTypes, Map<String, TypeRef?> namedArgTypes,
      {List<TypeRef> typeArgs = const []}) {
    final rt = TypeRef.fromBridgeTypeRef(ctx, BridgeTypeRef(spec));
    return AlwaysReturnType(rt, nullable);
  }
}

class AlwaysReturnType implements ReturnType {
  const AlwaysReturnType(this.type, this.nullable);

  factory AlwaysReturnType.fromAnnotation(CompilerContext ctx, int library,
      TypeAnnotation? typeAnnotation, TypeRef? fallback) {
    final rt = typeAnnotation;
    if (rt != null) {
      return AlwaysReturnType(
          TypeRef.fromAnnotation(ctx, library, rt), rt.question != null);
    } else {
      return AlwaysReturnType(fallback, true);
    }
  }

  factory AlwaysReturnType.fromInstanceMethod(
      CompilerContext ctx, TypeRef type, String method, TypeRef? fallback) {
    final m = resolveInstanceMethod(ctx, type, method);
    if (m.isBridge) {
      return AlwaysReturnType(
          TypeRef.fromBridgeAnnotation(
              ctx, m.bridge!.functionDescriptor.returns),
          true);
    }
    return AlwaysReturnType.fromAnnotation(
        ctx, type.file, m.declaration!.returnType, fallback);
  }

  factory AlwaysReturnType.fromStaticMethod(
      CompilerContext ctx, TypeRef type, String method, TypeRef? fallback) {
    final m = resolveStaticMethod(ctx, type, method);
    if (m.isBridge) {
      if (m.bridge is! BridgeMethodDef) {
        return AlwaysReturnType(CoreTypes.dynamic.ref(ctx), true);
      }
      final fn = (m.bridge as BridgeMethodDef).functionDescriptor;
      return AlwaysReturnType(
          TypeRef.fromBridgeAnnotation(ctx, fn.returns), fn.returns.nullable);
    }
    final d = m.declaration!;
    if (d is ConstructorDeclaration) {
      return AlwaysReturnType(type, false);
    }
    return AlwaysReturnType.fromAnnotation(
        ctx, type.file, (d as MethodDeclaration).returnType, fallback);
  }

  static AlwaysReturnType? fromInstanceMethodOrBuiltin(
      CompilerContext ctx,
      TypeRef type,
      String method,
      List<TypeRef?> argTypes,
      Map<String, TypeRef?> namedArgTypes,
      {List<TypeRef> typeArgs = const [],
      bool $static = false}) {
    final resolvedType = type.resolveTypeChain(ctx);
    final knownType = resolvedType.extendsType == CoreTypes.enumType.ref(ctx)
        ? CoreTypes.enumType.ref(ctx)
        : resolvedType;
    if (!$static &&
        getKnownMethods(ctx)[knownType] != null &&
        getKnownMethods(ctx)[knownType]!.containsKey(method)) {
      final knownMethod = getKnownMethods(ctx)[knownType]![method]!;
      final returnType = knownMethod.returnType;
      if (returnType == null) {
        return null;
      }
      return returnType.toAlwaysReturnType(
          ctx, knownType, argTypes, namedArgTypes,
          typeArgs: typeArgs);
    }

    if (type == CoreTypes.dynamic.ref(ctx)) {
      return AlwaysReturnType(CoreTypes.dynamic.ref(ctx), true);
    }

    return $static
        ? AlwaysReturnType.fromStaticMethod(
            ctx, type, method, CoreTypes.dynamic.ref(ctx))
        : AlwaysReturnType.fromInstanceMethod(
            ctx, type, method, CoreTypes.dynamic.ref(ctx));
  }

  final TypeRef? type;
  final bool nullable;

  @override
  AlwaysReturnType? toAlwaysReturnType(CompilerContext ctx, TypeRef? targetType,
      List<TypeRef?> argTypes, Map<String, TypeRef?> namedArgTypes,
      {List<TypeRef> typeArgs = const []}) {
    return this;
  }
}

class ParameterTypeDependentReturnType implements ReturnType {
  const ParameterTypeDependentReturnType(this.map,
      {this.paramIndex, this.paramName, this.fallback});

  final int? paramIndex;
  final String? paramName;
  final Map<TypeRef, AlwaysReturnType> map;
  final AlwaysReturnType? fallback;

  @override
  AlwaysReturnType? toAlwaysReturnType(CompilerContext ctx, TypeRef? targetType,
      List<TypeRef?> argTypes, Map<String, TypeRef?> namedArgTypes,
      {List<TypeRef> typeArgs = const []}) {
    AlwaysReturnType? resolvedType;
    if (paramIndex != null) {
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
  AlwaysReturnType? toAlwaysReturnType(CompilerContext ctx, TypeRef? targetType,
      List<TypeRef?> argTypes, Map<String, TypeRef?> namedArgTypes,
      {List<TypeRef> typeArgs = const []}) {
    return AlwaysReturnType(targetType!.specifiedTypeArgs[typeArgIndex], false);
  }
}

class TypeArgDependentReturnType implements ReturnType {
  const TypeArgDependentReturnType(this.typeArgIndex);

  final int typeArgIndex;

  @override
  AlwaysReturnType? toAlwaysReturnType(CompilerContext ctx, TypeRef? targetType,
      List<TypeRef?> argTypes, Map<String, TypeRef?> namedArgTypes,
      {List<TypeRef> typeArgs = const []}) {
    return AlwaysReturnType(typeArgs[typeArgIndex], false);
  }
}

class GenericParam {
  const GenericParam(this.name, this.extendsType);

  final String name;
  final TypeRef? extendsType;
}

extension Refify on BridgeTypeSpec {
  TypeRef ref(CompilerContext ctx,
      [List<BridgeTypeAnnotation> typeArgs = const []]) {
    final res = TypeRef.fromBridgeTypeRef(ctx, BridgeTypeRef(this, typeArgs));
    if (library == 'dart:core') {
      dartCoreFile = res.file;
    }
    return res;
  }
}
