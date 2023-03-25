// ignore_for_file: deprecated_member_use

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/expression/method_invocation.dart';
import 'package:dart_eval/src/eval/runtime/type.dart';
import 'package:dart_eval/src/eval/shared/types.dart';

import 'builtins.dart';
import 'context.dart';
import 'errors.dart';

class TypeRef {
  const TypeRef(this.file, this.name,
      {this.extendsType,
      this.implementsType = const [],
      this.withType = const [],
      this.genericParams = const [],
      this.specifiedTypeArgs = const [],
      this.resolved = false,
      this.boxed = true,
      this.nullable = false});

  static final _cache = <int, Map<String, TypeRef>>{};
  static final _inverseCache = <TypeRef, List<int>>{};

  factory TypeRef.cache(CompilerContext ctx, int file, String name, {int? fileRef}) {
    TypeRef $type;
    if (!_cache.containsKey(file)) {
      _cache[file] = {};
    }

    final _fileCache = _cache[file]!;
    if (!_fileCache.containsKey(name)) {
      $type = (_fileCache[name] = TypeRef(file, name));
    } else {
      $type = _fileCache[name]!;
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

  factory TypeRef.commonBaseType(CompilerContext ctx, Set<TypeRef> types) {
    assert(types.isNotEmpty);
    final chains = types.map((e) => e.resolveTypeChain(ctx).getTypeChain(ctx)).toList();

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

    final sorted = refCount.keys.toList()..sort((k1, k2) => layer[k1]! - layer[k2]!);

    return sorted[0];
  }

  factory TypeRef.fromAnnotation(CompilerContext ctx, int library, TypeAnnotation typeAnnotation) {
    if (typeAnnotation is GenericFunctionType) {
      return EvalTypes.functionType;
    }
    if (typeAnnotation is RecordType) {
      throw CompileError('No support for record types yet', typeAnnotation.parent, library, ctx);
    }
    typeAnnotation as NamedType;
    final unspecifiedType = ctx.visibleTypes[library]![typeAnnotation.name.name]!;
    final typeArgs = typeAnnotation.typeArguments;
    if (typeArgs != null) {
      final _resolved = <TypeRef>[];
      for (final arg in typeArgs.arguments) {
        _resolved.add(TypeRef.fromAnnotation(ctx, library, arg));
      }
      return unspecifiedType.copyWith(specifiedTypeArgs: _resolved, nullable: typeAnnotation.question != null);
    }
    return unspecifiedType.copyWith(nullable: typeAnnotation.question != null);
  }

  factory TypeRef.fromBridgeAnnotation(CompilerContext ctx, BridgeTypeAnnotation typeAnnotation,
      {TypeRef? specifyingType, TypeRef? specifiedType}) {
    return TypeRef.fromBridgeTypeRef(ctx, typeAnnotation.type,
        specifyingType: specifyingType, specifiedType: specifiedType);
  }

  factory TypeRef.fromBridgeTypeRef(CompilerContext ctx, BridgeTypeRef typeReference,
      {bool staticSource = true, TypeRef? specifyingType, TypeRef? specifiedType}) {
    final cacheId = typeReference.cacheId;
    if (cacheId != null) {
      final t = inverseRuntimeTypeMap[cacheId] ?? ctx.runtimeTypeList[cacheId];
      if (staticSource) {
        return t.isUnboxedAcrossFunctionBoundaries ? t.copyWith(boxed: false) : t.copyWith(boxed: true);
      }
      return t.copyWith(boxed: true);
    }
    final spec = typeReference.spec;
    if (spec != null) {
      final specifiedTypeArgs = <TypeRef>[];
      for (final arg in typeReference.typeArgs) {
        specifiedTypeArgs
            .add(TypeRef.fromBridgeTypeRef(ctx, arg, staticSource: staticSource, specifiedType: specifiedType));
      }
      final lib = ctx.libraryMap[spec.library] ?? (throw CompileError('Bridge: cannot find library ${spec.library}'));
      return ctx.visibleTypes[lib]![spec.name]!.copyWith(specifiedTypeArgs: specifiedTypeArgs);
    }
    final ref = typeReference.ref;
    if (ref != null) {
      specifiedType ??= ctx.visibleTypes[ctx.library]![ctx.currentClass?.name2.stringValue];

      if (specifiedType == null) {
        return EvalTypes.dynamicType;
      }

      final declaration = ctx.topLevelDeclarationsMap[specifiedType.file]![specifiedType.name]!;
      if (!declaration.isBridge) {
        throw CompileError(
            'Trying to resolve bridged generic type $ref on $specifiedType, which is not a bridge class');
      }
      final _dec = declaration.bridge!;
      if (_dec is! BridgeClassDef) {
        throw CompileError(
            'Trying to resolve bridged generic type $ref on $specifiedType, which is not a bridge class');
      }

      final genericIndex = _dec.type.generics.keys.toList().indexWhere((key) => key == ref);
      if (specifiedType.specifiedTypeArgs.isNotEmpty) {
        return specifiedType.specifiedTypeArgs[genericIndex];
      }
      final generic = _dec.type.generics[ref]!;
      final $extends = generic.$extends;
      final boundType = $extends == null ? EvalTypes.dynamicType : TypeRef.fromBridgeTypeRef(ctx, $extends);

      if (specifyingType != null) {
        final syDeclaration = ctx.topLevelDeclarationsMap[specifyingType.file]![specifyingType.name]!;
        final syDec = syDeclaration.declaration!;

        if (syDec is! ClassDeclaration) {
          throw CompileError('Specifying types from bridge is not supported');
        }
        final syExtends = syDec.extendsClause;
        if (syExtends != null && syExtends.superclass.name.name == specifiedType.name) {
          final declaredType = syExtends.superclass.typeArguments?.arguments[genericIndex];
          if (declaredType != null) {
            final resolvedDeclaredType = TypeRef.fromAnnotation(ctx, specifyingType.file, declaredType);
            if (!resolvedDeclaredType.isAssignableTo(ctx, boundType)) {
              throw CompileError("Type argument $resolvedDeclaredType does not conform to type parameter $ref's"
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
      return EvalTypes.functionType;
    }
    throw CompileError('No support for looking up types by other bridge annotation types');
  }

  factory TypeRef.stdlib(CompilerContext ctx, String library, String name) {
    return TypeRef.fromBridgeTypeRef(ctx, BridgeTypeRef(BridgeTypeSpec(library, name), []));
  }

  factory TypeRef.lookupClassDeclaration(CompilerContext ctx, int library, ClassDeclaration cls) {
    return ctx.visibleTypes[library]![cls.name.value()] ?? (throw CompileError('Class ${cls.name.value()} not found'));
  }

  static TypeRef? lookupFieldType(CompilerContext ctx, TypeRef $class, String field, {bool forFieldFormal = false}) {
    if ($class == EvalTypes.dynamicType) {
      return null;
    }
    if ($class.file == dartCoreFile) {
      final _f = knownFields[$class];
      if (_f != null) {
        final _d = _f[field];
        if (_d != null) {
          return _d.fieldType?.toAlwaysReturnType(ctx, $class, [], {})?.type ?? EvalTypes.dynamicType;
        }
      }
    }
    if (ctx.instanceDeclarationsMap[$class.file]!.containsKey($class.name)) {
      if (ctx.instanceDeclarationsMap[$class.file]![$class.name]!.containsKey(field)) {
        final _f = ctx.instanceDeclarationsMap[$class.file]![$class.name]![field];
        if (_f is! VariableDeclaration) {
          throw CompileError('Cannot query field type of F${$class.file}:${$class.name}.$field, which is not a field');
        }
        final annotation = (_f.parent as VariableDeclarationList).type;
        if (annotation == null) {
          return null;
        }
        return TypeRef.fromAnnotation(ctx, $class.file, annotation);
      } else if (!forFieldFormal && ctx.instanceDeclarationsMap[$class.file]![$class.name]!.containsKey('$field*g')) {
        final _f = ctx.instanceDeclarationsMap[$class.file]![$class.name]!['$field*g'];
        if (_f is! MethodDeclaration) {
          throw CompileError(
              'Cannot query getter type of F${$class.file}:${$class.name}.$field, which is not a method');
        }
        final annotation = _f.returnType;
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
        return TypeRef.fromBridgeAnnotation(ctx, fd.type, specifiedType: $class);
      }
      final get = br.getters[field];
      if (get != null) {
        return TypeRef.fromBridgeAnnotation(ctx, get.functionDescriptor.returns, specifiedType: $class);
      }
      final set = br.getters[field];
      if (set != null) {
        return TypeRef.fromBridgeAnnotation(ctx, set.functionDescriptor.returns, specifiedType: $class);
      }
      final $extends = br.type.$extends;
      if ($extends == null) {
        throw CompileError('Field $field not found in bridge class ${$class}');
      } else {
        final $super = TypeRef.fromBridgeTypeRef(ctx, $extends);
        return TypeRef.lookupFieldType(ctx, $super.inheritTypeArgsFrom(ctx, $class), field);
      }
    } else {
      if (forFieldFormal) {
        throw CompileError('Field formals did not find field $field in class ${$class}');
      }
      final _dec = dec.declaration as ClassDeclaration;
      final $extends = _dec.extendsClause;
      if ($extends == null) {
        throw CompileError('Field "$field" not found in class ${$class}');
      } else {
        final $super = ctx.visibleTypes[$class.file]![$extends.superclass.name.name]!;
        return TypeRef.lookupFieldType(ctx, $super.inheritTypeArgsFrom(ctx, $class), field);
      }
    }
  }

  TypeRef resolveTypeChain(CompilerContext ctx, {int recursionGuard = 0}) {
    if (recursionGuard > 500) {
      throw CompileError(
          'Reached max limit on recursion while resolving types. Your type hierarchy is probably recursive (caught while resolving $this)');
    }
    final rg = recursionGuard + 1;
    final _resolvedSpecifiedTypeArgs =
        specifiedTypeArgs.map((e) => e.resolveTypeChain(ctx, recursionGuard: rg)).toList();
    if (resolved) {
      return copyWith(specifiedTypeArgs: _resolvedSpecifiedTypeArgs);
    }

    final $cached = _cache[file]![name]!;
    if ($cached.resolved) {
      return $cached.copyWith(boxed: boxed, specifiedTypeArgs: _resolvedSpecifiedTypeArgs);
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
        $super = EvalTypes.enumType;
      } else {
        final br = declaration.bridge as BridgeClassDef;
        final type = br.type;

        if (type.$extends != null) {
          $super = TypeRef.fromBridgeTypeRef(ctx, type.$extends!, specifiedType: this)
              .resolveTypeChain(ctx, recursionGuard: rg);
        }

        for (final $i in type.$implements) {
          $implements
              .add(TypeRef.fromBridgeTypeRef(ctx, $i, specifiedType: this).resolveTypeChain(ctx, recursionGuard: rg));
        }

        for (final $i in type.$with) {
          $with.add(TypeRef.fromBridgeTypeRef(ctx, $i, specifiedType: this).resolveTypeChain(ctx, recursionGuard: rg));
        }

        for (final $g in type.generics.entries) {
          final _extends = $g.value.$extends;
          final _type = _extends == null ? null : TypeRef.fromBridgeTypeRef(ctx, _extends);
          generics.add(GenericParam($g.key, _type?.resolveTypeChain(ctx, recursionGuard: rg)));
        }
      }
    } else {
      final dec = declaration.declaration! as ClassDeclaration;
      superName = dec.extendsClause?.superclass;
      withNames = dec.withClause?.mixinTypes.toList() ?? [];
      implementsNames = dec.implementsClause?.interfaces.toList() ?? [];
      generics = dec.typeParameters?.typeParameters
              .map((t) => GenericParam(
                  t.name.value() as String, t.bound == null ? null : TypeRef.fromAnnotation(ctx, file, t.bound!)))
              .toList() ??
          [];
    }

    if (superName != null) {
      final typeParams = superName.typeArguments?.arguments
              .map((a) => TypeRef.fromAnnotation(ctx, file, a).resolveTypeChain(ctx))
              .toList() ??
          [];
      $super = ctx.visibleTypes[file]![superName.name.name]!
          .copyWith(specifiedTypeArgs: typeParams)
          .resolveTypeChain(ctx, recursionGuard: rg);
    }

    for (final withName in withNames) {
      final typeParams = withName.typeArguments?.arguments
              .map((a) => TypeRef.fromAnnotation(ctx, file, a).resolveTypeChain(ctx))
              .toList() ??
          [];
      $with.add(ctx.visibleTypes[file]![withName]!
          .copyWith(specifiedTypeArgs: typeParams)
          .resolveTypeChain(ctx, recursionGuard: rg));
    }

    for (final implementsName in implementsNames) {
      final typeParams = implementsName.typeArguments?.arguments
              .map((a) => TypeRef.fromAnnotation(ctx, file, a).resolveTypeChain(ctx))
              .toList() ??
          [];
      $implements.add(ctx.visibleTypes[file]![implementsName]!
          .copyWith(specifiedTypeArgs: typeParams)
          .resolveTypeChain(ctx, recursionGuard: rg));
    }

    final _resolved = TypeRef(file, name,
        extendsType: $super ?? EvalTypes.objectType,
        withType: $with,
        implementsType: $implements,
        genericParams: generics,
        resolved: true,
        boxed: boxed,
        specifiedTypeArgs: _resolvedSpecifiedTypeArgs);

    for (final $file in _inverseCache[this]!) {
      ctx.visibleTypes[$file]![name] = _resolved;
    }

    _cache[file]![name] = _resolved;
    return _resolved;
  }

  Set<int> getRuntimeIndices(CompilerContext ctx) {
    return {
      runtimeTypeMap[this] ?? ctx.typeRefIndexMap[this]!,
      for (final a in allSupertypes) ...a.getRuntimeIndices(ctx)
    };
  }

  RuntimeType toRuntimeType(CompilerContext ctx) {
    final ta = [for (final t in specifiedTypeArgs) t.toRuntimeType(ctx)];
    return RuntimeType(runtimeTypeMap[this] ?? ctx.typeRefIndexMap[this]!, ta);
  }

  final int file;
  final String name;
  final TypeRef? extendsType;
  final List<TypeRef> implementsType;
  final List<TypeRef> withType;
  final List<GenericParam> genericParams;
  final List<TypeRef> specifiedTypeArgs;
  final bool resolved;
  final bool boxed;
  final bool nullable;

  List<TypeRef> get allSupertypes => [if (extendsType != null) extendsType!, ...implementsType, ...withType];

  List<TypeRef> get extendsChain =>
      [if (extendsType != null) extendsType!, if (extendsType != null) ...extendsType!.extendsChain];

  List<List<TypeRef>> getTypeChain(CompilerContext ctx) {
    final l1extends = extendsType;
    final l2extends = extendsType?.resolveTypeChain(ctx).getTypeChain(ctx) ?? [];
    final chain = <List<TypeRef>>[
      if (l1extends != null) [l1extends],
      ...l2extends
    ];

    for (final imp in implementsType.reversed) {
      if (chain.isEmpty) {
        chain.add([]);
      }
      chain[0].add(imp);
      final tc = imp.resolveTypeChain(ctx).getTypeChain(ctx);
      for (var i = 0; i < tc.length; i++) {
        if (chain.length < i + 1) {
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

  bool get isUnboxedAcrossFunctionBoundaries => unboxedAcrossFunctionBoundaries.contains(this) && !nullable;

  bool isAssignableTo(CompilerContext ctx, TypeRef slot,
      {List<TypeRef>? overrideGenerics, bool forceAllowDynamic = true}) {
    if (forceAllowDynamic && this == EvalTypes.dynamicType) {
      return true;
    }

    if (this == EvalTypes.nullType) {
      return slot.nullable || slot == EvalTypes.nullType;
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
      if (type.isAssignableTo(ctx, slot, overrideGenerics: generics, forceAllowDynamic: false)) {
        return true;
      }
    }
    return false;
  }

  TypeRef inheritTypeArgsFrom(CompilerContext ctx, TypeRef prototype) {
    final _prototype = prototype.resolveTypeChain(ctx);
    var i = 0;
    var gmap = <String, int>{};
    for (final generic in genericParams) {
      gmap[generic.name] = i;
      i++;
    }
    var j = 0;
    var resolvedGenerics = List<TypeRef>.filled(i, EvalTypes.dynamicType);
    for (final generic in _prototype.genericParams) {
      if (gmap.containsKey(generic.name)) {
        resolvedGenerics[gmap[generic.name]!] = _prototype.specifiedTypeArgs[j];
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
      bool? boxed,
      bool? resolved,
      bool? nullable}) {
    return TypeRef(file ?? this.file, name ?? this.name,
        extendsType: extendsType ?? this.extendsType,
        implementsType: implementsType ?? this.implementsType,
        withType: withType ?? this.withType,
        genericParams: genericParams ?? this.genericParams,
        specifiedTypeArgs: specifiedTypeArgs ?? this.specifiedTypeArgs,
        boxed: boxed ?? this.boxed,
        resolved: resolved ?? this.resolved,
        nullable: nullable ?? this.nullable);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TypeRef && runtimeType == other.runtimeType && file == other.file && name == other.name;

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
      String? _library;
      for (final entry in ctx.libraryMap.entries) {
        if (entry.value == file) {
          _library = entry.key;
        }
      }
      return '$name (from "$_library")';
    } else {
      return name;
    }
  }
}

abstract class ReturnType {
  AlwaysReturnType? toAlwaysReturnType(
      CompilerContext ctx, TypeRef? targetType, List<TypeRef?> argTypes, Map<String, TypeRef?> namedArgTypes,
      {List<TypeRef> typeArgs = const []});
}

class BridgedReturnType implements ReturnType {
  final BridgeTypeSpec spec;
  final bool nullable;

  BridgedReturnType(this.spec, this.nullable);

  @override
  AlwaysReturnType? toAlwaysReturnType(
      CompilerContext ctx, TypeRef? targetType, List<TypeRef?> argTypes, Map<String, TypeRef?> namedArgTypes,
      {List<TypeRef> typeArgs = const []}) {
    final rt = TypeRef.fromBridgeTypeRef(ctx, BridgeTypeRef(spec));
    return AlwaysReturnType(rt, nullable);
  }
}

class AlwaysReturnType implements ReturnType {
  const AlwaysReturnType(this.type, this.nullable);

  factory AlwaysReturnType.fromAnnotation(
      CompilerContext ctx, int library, TypeAnnotation? typeAnnotation, TypeRef? fallback) {
    final rt = typeAnnotation;
    if (rt != null) {
      return AlwaysReturnType(TypeRef.fromAnnotation(ctx, ctx.library, rt), rt.question != null);
    } else {
      return AlwaysReturnType(fallback, true);
    }
  }

  factory AlwaysReturnType.fromInstanceMethod(CompilerContext ctx, TypeRef type, String method, TypeRef? fallback) {
    final _m = resolveInstanceMethod(ctx, type, method);
    if (_m.isBridge) {
      return AlwaysReturnType(TypeRef.fromBridgeAnnotation(ctx, _m.bridge!.functionDescriptor.returns), true);
    }
    return AlwaysReturnType.fromAnnotation(ctx, type.file, _m.declaration!.returnType, fallback);
  }

  factory AlwaysReturnType.fromStaticMethod(CompilerContext ctx, TypeRef type, String method, TypeRef? fallback) {
    final _m = resolveStaticMethod(ctx, type, method);
    if (_m.isBridge) {
      if (_m.bridge is! BridgeMethodDef) {
        return AlwaysReturnType(EvalTypes.dynamicType, true);
      }
      final fn = (_m.bridge as BridgeMethodDef).functionDescriptor;
      return AlwaysReturnType(TypeRef.fromBridgeAnnotation(ctx, fn.returns), fn.returns.nullable);
    }
    return AlwaysReturnType.fromAnnotation(ctx, type.file, _m.declaration!.returnType, fallback);
  }

  static AlwaysReturnType? fromInstanceMethodOrBuiltin(
      CompilerContext ctx, TypeRef type, String method, List<TypeRef?> argTypes, Map<String, TypeRef?> namedArgTypes,
      {List<TypeRef> typeArgs = const [], bool $static = false}) {
    if (!$static && knownMethods[type] != null && knownMethods[type]!.containsKey(method)) {
      final knownMethod = knownMethods[type]![method]!;
      final returnType = knownMethod.returnType;
      if (returnType == null) {
        return null;
      }
      return returnType.toAlwaysReturnType(ctx, type, argTypes, namedArgTypes, typeArgs: typeArgs);
    }

    if (type == EvalTypes.dynamicType) {
      return AlwaysReturnType(EvalTypes.dynamicType, true);
    }

    return $static
        ? AlwaysReturnType.fromStaticMethod(ctx, type, method, EvalTypes.dynamicType)
        : AlwaysReturnType.fromInstanceMethod(ctx, type, method, EvalTypes.dynamicType);
  }

  final TypeRef? type;
  final bool nullable;

  @override
  AlwaysReturnType? toAlwaysReturnType(
      CompilerContext ctx, TypeRef? targetType, List<TypeRef?> argTypes, Map<String, TypeRef?> namedArgTypes,
      {List<TypeRef> typeArgs = const []}) {
    return this;
  }
}

class ParameterTypeDependentReturnType implements ReturnType {
  const ParameterTypeDependentReturnType(this.map, {this.paramIndex, this.paramName, this.fallback});

  final int? paramIndex;
  final String? paramName;
  final Map<TypeRef, AlwaysReturnType> map;
  final AlwaysReturnType? fallback;

  @override
  AlwaysReturnType? toAlwaysReturnType(
      CompilerContext ctx, TypeRef? targetType, List<TypeRef?> argTypes, Map<String, TypeRef?> namedArgTypes,
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
  AlwaysReturnType? toAlwaysReturnType(
      CompilerContext ctx, TypeRef? targetType, List<TypeRef?> argTypes, Map<String, TypeRef?> namedArgTypes,
      {List<TypeRef> typeArgs = const []}) {
    return AlwaysReturnType(targetType!.specifiedTypeArgs[typeArgIndex], false);
  }
}

class TypeArgDependentReturnType implements ReturnType {
  const TypeArgDependentReturnType(this.typeArgIndex);

  final int typeArgIndex;

  @override
  AlwaysReturnType? toAlwaysReturnType(
      CompilerContext ctx, TypeRef? targetType, List<TypeRef?> argTypes, Map<String, TypeRef?> namedArgTypes,
      {List<TypeRef> typeArgs = const []}) {
    return AlwaysReturnType(typeArgs[typeArgIndex], false);
  }
}

class GenericParam {
  const GenericParam(this.name, this.extendsType);

  final String name;
  final TypeRef? extendsType;
}

class C<T extends R, R extends int> {
  const C();
}
