import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/bridge/declaration.dart';
import 'package:dart_eval/src/eval/bridge/declaration/type.dart';
import 'package:dart_eval/src/eval/compiler/expression/method_invocation.dart';
import 'package:dart_eval/src/eval/runtime/type.dart';

import 'builtins.dart';
import 'context.dart';
import 'errors.dart';

class TypeRef {
  const TypeRef(
    this.file,
    this.name, {
    this.extendsType,
    this.implementsType = const [],
    this.withType = const [],
    this.genericParams = const [],
    this.specifiedTypeArgs = const [],
    this.resolved = false,
    this.boxed = true,
  });

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
    final chains = types.map((e) => e.getTypeChain(ctx)).toList();

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
    if (!(typeAnnotation is NamedType)) {
      throw CompileError('No support for generic function types yet');
    }
    final unspecifiedType = ctx.visibleTypes[library]![typeAnnotation.name.name]!;
    final typeArgs = typeAnnotation.typeArguments;
    if (typeArgs != null) {
      final _resolved = <TypeRef>[];
      for (final arg in typeArgs.arguments) {
        _resolved.add(TypeRef.fromAnnotation(ctx, library, arg));
      }
      return unspecifiedType.copyWith(specifiedTypeArgs: _resolved);
    }
    return unspecifiedType;
  }

  factory TypeRef.fromBridgeAnnotation(CompilerContext ctx, BridgeTypeAnnotation typeAnnotation) {
    final nullable = typeAnnotation.nullable;
    final type = typeAnnotation.type;
    final cacheId = type.cacheId;
    if (cacheId != null) {
      return ctx.runtimeTypeList[cacheId];
    }
    final unresolved = type.unresolved;
    if (unresolved != null) {
      return ctx.visibleTypes[ctx.libraryMap[unresolved.library]!]![unresolved.name]!;
    }
    throw CompileError('No support for looking up types by other bridge annotation types');
  }

  factory TypeRef.lookupClassDeclaration(CompilerContext ctx, int library, ClassDeclaration cls) {
    return ctx.visibleTypes[library]![cls.name.name] ?? (throw CompileError('Class ${cls.name.name} not found'));
  }

  static TypeRef? lookupFieldType(CompilerContext ctx, TypeRef $class, String field) {
    if ($class.file == dartCoreFile) {
      final _f = knownFields[$class];
      if (_f != null) {
        final _d = _f[field];
        if (_d != null) {
          return _d.fieldType?.toAlwaysReturnType($class, [], {})?.type ?? EvalTypes.dynamicType;
        }
      }
      throw CompileError('Property does not exist: $field on ${$class}');
    }
    if (ctx.instanceDeclarationsMap[$class.file]!.containsKey($class.name) &&
        ctx.instanceDeclarationsMap[$class.file]![$class.name]!.containsKey(field)) {
      final _f = ctx.instanceDeclarationsMap[$class.file]![$class.name]![field];
      if (!(_f is VariableDeclaration)) {
        throw CompileError('Cannot query field type of F${$class.file}:${$class.name}.$field, which is not a field');
      }
      final annotation = (_f.parent as VariableDeclarationList).type;
      if (annotation == null) {
        return null;
      }
      return TypeRef.fromAnnotation(ctx, $class.file, annotation);
    }
    final dec = ctx.topLevelDeclarationsMap[$class.file]![$class.name] as ClassDeclaration;
    final $extends = dec.extendsClause;
    if ($extends == null) {
      throw CompileError('Field "$field" not found in class ${$class}');
    } else {
      final $super = ctx.visibleTypes[$class.file]![$extends.superclass2.name.name]!;
      return TypeRef.lookupFieldType(ctx, $super, field);
    }
  }

  TypeRef resolveTypeChain(CompilerContext ctx) {
    final _resolvedSpecifiedTypeArgs = specifiedTypeArgs.map((e) => e.resolveTypeChain(ctx)).toList();
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

    String? superName;
    List<String> implementsNames;
    List<String> withNames;

    if (declaration.isBridge) {
      implementsNames = [];
      withNames = [];
      /*
      final br = declaration.bridge as BridgeClassDeclaration;
      final type = br.type;

      if (type.$extends?.builtin != null) {
        $super = type.$extends!.builtin!.resolveTypeChain(ctx);
      } else {
        superName = type.$extends?.name;
      }



      for (final $i in type.$implements) {
        if ($i.builtin != null) {
          $implements.add($i.builtin!.resolveTypeChain(ctx));
        } else {
          implementsNames.add($i.name!);
        }
      }

      for (final $i in type.$with) {
        if ($i.builtin != null) {
          $with.add($i.builtin!.resolveTypeChain(ctx));
        } else {
          withNames.add($i.name!);
        }
      }*/
    } else {
      final dec = declaration.declaration! as ClassDeclaration;
      superName = dec.extendsClause?.superclass2.name.name;
      withNames = dec.withClause?.mixinTypes2.map((e) => e.name.name).toList() ?? [];
      implementsNames = dec.implementsClause?.interfaces2.map((e) => e.name.name).toList() ?? [];
    }

    if (superName != null) {
      $super = ctx.visibleTypes[file]![superName]!.resolveTypeChain(ctx);
    }

    for (final withName in withNames) {
      $with.add(ctx.visibleTypes[file]![withName]!.resolveTypeChain(ctx));
    }

    for (final implementsName in implementsNames) {
      $implements.add(ctx.visibleTypes[file]![implementsName]!.resolveTypeChain(ctx));
    }

    final _resolved = TypeRef(file, name,
        extendsType: $super,
        withType: $with,
        implementsType: $implements,
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
    return {ctx.typeRefIndexMap[this]!, for (final a in allSupertypes) ...a.getRuntimeIndices(ctx)};
  }

  RuntimeType toRuntimeType(CompilerContext ctx) {
    final ta = [for (final t in specifiedTypeArgs) t.toRuntimeType(ctx)];
    return RuntimeType(ctx.typeRefIndexMap[this]!, ta);
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

  bool isAssignableTo(TypeRef slot, {List<TypeRef>? overrideGenerics, bool forceAllowDynamic = true}) {
    if (forceAllowDynamic && this == EvalTypes.dynamicType) {
      return true;
    }

    final generics = overrideGenerics ?? specifiedTypeArgs;

    if (this == slot) {
      for (var i = 0; i < generics.length; i++) {
        if (slot.specifiedTypeArgs.length - 1 > i) {
          if (!generics[i].isAssignableTo(slot.specifiedTypeArgs[i])) {
            return false;
          }
        }
      }
      return true;
    }

    for (final type in allSupertypes) {
      if (type.isAssignableTo(slot, overrideGenerics: generics, forceAllowDynamic: false)) {
        return true;
      }
    }
    return false;
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
      bool? resolved}) {
    return TypeRef(file ?? this.file, name ?? this.name,
        extendsType: extendsType ?? this.extendsType,
        implementsType: implementsType ?? this.implementsType,
        withType: withType ?? this.withType,
        genericParams: genericParams ?? this.genericParams,
        specifiedTypeArgs: specifiedTypeArgs ?? this.specifiedTypeArgs,
        boxed: boxed ?? this.boxed,
        resolved: resolved ?? this.resolved);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TypeRef && runtimeType == other.runtimeType && file == other.file && name == other.name;

  @override
  int get hashCode => file.hashCode ^ name.hashCode;

  @override
  String toString() {
    return 'F$file:$name${extendsType != null ? ' extends ' + extendsType!.name : ''}';
  }
}

abstract class ReturnType {
  AlwaysReturnType? toAlwaysReturnType(
      TypeRef? targetType, List<TypeRef?> argTypes, Map<String, TypeRef?> namedArgTypes,
      {List<TypeRef> typeArgs = const []});
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
      return AlwaysReturnType(EvalTypes.dynamicType, true);
    }
    return AlwaysReturnType.fromAnnotation(ctx, type.file, _m.declaration!.returnType, fallback);
  }

  static AlwaysReturnType? fromInstanceMethodOrBuiltin(
      CompilerContext ctx, TypeRef type, String method, List<TypeRef?> argTypes, Map<String, TypeRef?> namedArgTypes,
      {List<TypeRef> typeArgs = const []}) {
    if (knownMethods[type] != null && knownMethods[type]!.containsKey(method)) {
      final knownMethod = knownMethods[type]![method]!;
      final returnType = knownMethod.returnType;
      if (returnType == null) {
        return null;
      }
      return returnType.toAlwaysReturnType(type, argTypes, namedArgTypes, typeArgs: typeArgs);
    }

    if (type == EvalTypes.dynamicType) {
      return AlwaysReturnType(EvalTypes.dynamicType, true);
    }

    return AlwaysReturnType.fromInstanceMethod(ctx, type, method, EvalTypes.dynamicType);
  }

  final TypeRef? type;
  final bool nullable;

  @override
  AlwaysReturnType? toAlwaysReturnType(
      TypeRef? targetType, List<TypeRef?> argTypes, Map<String, TypeRef?> namedArgTypes,
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
      TypeRef? targetType, List<TypeRef?> argTypes, Map<String, TypeRef?> namedArgTypes,
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
      TypeRef? targetType, List<TypeRef?> argTypes, Map<String, TypeRef?> namedArgTypes,
      {List<TypeRef> typeArgs = const []}) {
    return AlwaysReturnType(targetType!.specifiedTypeArgs[typeArgIndex], false);
  }
}

class TypeArgDependentReturnType implements ReturnType {
  const TypeArgDependentReturnType(this.typeArgIndex);

  final int typeArgIndex;

  @override
  AlwaysReturnType? toAlwaysReturnType(
      TypeRef? targetType, List<TypeRef?> argTypes, Map<String, TypeRef?> namedArgTypes,
      {List<TypeRef> typeArgs = const []}) {
    return AlwaysReturnType(typeArgs[typeArgIndex], false);
  }
}

class GenericParam {
  const GenericParam(this.name, this.extendsType);

  final String name;
  final TypeRef? extendsType;
}
