import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/expression/invocation.dart';

import 'builtins.dart';
import 'context.dart';
import 'errors.dart';

class TypeRef {
  const TypeRef(this.file, this.name,
      {this.extendsType,
      this.implementsType = const [],
      this.withType = const [],
      this.genericParams = const [],
      this.specifiedTypeArgs = const []});

  factory TypeRef.fromAnnotation(CompilerContext ctx, int library, TypeAnnotation typeAnnotation) {
    if (!(typeAnnotation is NamedType)) {
      throw CompileError('No support for generic function types yet');
    }
    return ctx.visibleTypes[library]![typeAnnotation.name.name]!;
  }

  factory TypeRef.lookupClassDeclaration(CompilerContext ctx, int library, ClassDeclaration cls) {
    return ctx.visibleTypes[library]![cls.name.name] ?? (throw CompileError('Class ${cls.name.name} not found'));
  }

  static TypeRef? lookupFieldType(CompilerContext ctx, TypeRef $class, String field) {
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

  final int file;
  final String name;
  final TypeRef? extendsType;
  final List<TypeRef> implementsType;
  final List<TypeRef> withType;
  final List<GenericParam> genericParams;
  final List<TypeRef> specifiedTypeArgs;

  List<TypeRef> get allSupertypes => [if (extendsType != null) extendsType!, ...implementsType, ...withType];

  bool isAssignableTo(TypeRef slot, {List<TypeRef>? overrideGenerics}) {
    if (this == EvalTypes.dynamicType) {
      return true;
    }

    final generics = overrideGenerics ?? specifiedTypeArgs;

    if (this == slot) {
      for (var i = 0; i < generics.length; i++) {
        if (slot.specifiedTypeArgs.length >= i - 1) {
          if (!generics[i].isAssignableTo(slot.specifiedTypeArgs[i])) {
            return false;
          }
        }
      }
      return true;
    }

    for (final type in allSupertypes) {
      if (type.isAssignableTo(slot, overrideGenerics: generics)) {
        return true;
      }
    }
    return false;
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
  AlwaysReturnType? toAlwaysReturnType(List<TypeRef?> argTypes, Map<String, TypeRef?> namedArgTypes);
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

  factory AlwaysReturnType.fromInstanceMethod(CompilerContext ctx, TypeRef type, String method, List<TypeRef?> argTypes,
      Map<String, TypeRef?> namedArgTypes, TypeRef? fallback) {
    final _m = resolveInstanceMethod(ctx, type, method);
    if (_m.isBridge) {
      return AlwaysReturnType(EvalTypes.dynamicType, true);
    }
    return AlwaysReturnType.fromAnnotation(ctx, type.file, _m.declaration!.returnType, fallback);
  }

  static AlwaysReturnType? fromInstanceMethodOrBuiltin(
      CompilerContext ctx, TypeRef type, String method, List<TypeRef?> argTypes, Map<String, TypeRef?> namedArgTypes) {
    if (knownMethods[type] != null && knownMethods[type]!.containsKey(method)) {
      final knownMethod = knownMethods[type]![method]!;
      final returnType = knownMethod.returnType;
      if (returnType == null) {
        return null;
      }
      return returnType.toAlwaysReturnType(argTypes, namedArgTypes);
    }

    if (type == EvalTypes.dynamicType) {
      return AlwaysReturnType(EvalTypes.dynamicType, true);
    }

    return AlwaysReturnType.fromInstanceMethod(ctx, type, method, argTypes, namedArgTypes, EvalTypes.dynamicType);
  }

  final TypeRef? type;
  final bool nullable;

  @override
  AlwaysReturnType? toAlwaysReturnType(List<TypeRef?> argTypes, Map<String, TypeRef?> namedArgTypes) {
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
  AlwaysReturnType? toAlwaysReturnType(List<TypeRef?> argTypes, Map<String, TypeRef?> namedArgTypes) {
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

class GenericParam {
  const GenericParam(this.name, this.extendsType);

  final String name;
  final TypeRef? extendsType;
}
