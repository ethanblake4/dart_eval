import 'package:analyzer/dart/ast/ast.dart';

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

  final int file;
  final String name;
  final TypeRef? extendsType;
  final List<TypeRef> implementsType;
  final List<TypeRef> withType;
  final List<GenericParam> genericParams;
  final List<TypeRef> specifiedTypeArgs;

  List<TypeRef> get allSupertypes => [if (extendsType != null) extendsType!, ...implementsType, ...withType];

  bool isAssignableTo(TypeRef slot, {List<TypeRef>? overrideGenerics}) {
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
    return name;
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
    if (ctx.instanceDeclarationsMap[type.file]!.containsKey(type.name) &&
        ctx.instanceDeclarationsMap[type.file]![type.name]!.containsKey(method)) {
      final _m = ctx.instanceDeclarationsMap[type.file]![type.name]![method];
      if (!(_m is MethodDeclaration)) {
        throw CompileError(
            'Cannot query method return type of F${type.file}:${type.name}.$method, which is not a method');
      }
      return AlwaysReturnType.fromAnnotation(ctx, type.file, _m.returnType, fallback);
    }

    throw CompileError("Type not found");
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

