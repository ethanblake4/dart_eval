import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';

/// Represents either a real [TypeRef] or an unresolved type name e.g. "T"
class FunctionTypeAnnotation {
  final TypeRef? type;
  final String? name;

  const FunctionTypeAnnotation.type(this.type) : name = null;

  const FunctionTypeAnnotation.name(this.name) : type = null;

  factory FunctionTypeAnnotation.fromBridgeAnnotation(
      CompilerContext ctx, BridgeTypeAnnotation annotation) {
    final type = annotation.type;
    if (type.ref != null) {
      return FunctionTypeAnnotation.name(type.ref!);
    } else {
      return FunctionTypeAnnotation.type(
          TypeRef.fromBridgeAnnotation(ctx, annotation));
    }
  }

  factory FunctionTypeAnnotation.fromBridgeTypeRef(
      CompilerContext ctx, BridgeTypeRef ref) {
    return FunctionTypeAnnotation.type(TypeRef.fromBridgeTypeRef(ctx, ref));
  }
}

class FunctionFormalParameter {
  final String? name;
  final FunctionTypeAnnotation type;
  final bool isRequired;

  const FunctionFormalParameter(this.name, this.type, this.isRequired);
}

class FunctionGenericParam {
  final String name;
  final FunctionTypeAnnotation? bound;

  const FunctionGenericParam(this.name, {this.bound});
}

class EvalFunctionType {
  final List<FunctionFormalParameter> normalParameters;
  final List<FunctionFormalParameter> optionalParameters;
  final Map<String, FunctionFormalParameter> namedParameters;
  final FunctionTypeAnnotation returnType;
  final List<FunctionGenericParam> generics;

  const EvalFunctionType(this.normalParameters, this.optionalParameters,
      this.namedParameters, this.returnType, this.generics);

  factory EvalFunctionType.fromBridgeFunctionDef(
      CompilerContext ctx, BridgeFunctionDef def) {
    final fReturnType =
        FunctionTypeAnnotation.fromBridgeAnnotation(ctx, def.returns);

    final fNormalParameters = <FunctionFormalParameter>[];
    final fOptionalParameters = <FunctionFormalParameter>[];
    final fNamedParameters = <String, FunctionFormalParameter>{};

    for (final param in def.params) {
      final fType =
          FunctionTypeAnnotation.fromBridgeAnnotation(ctx, param.type);
      final fParam =
          FunctionFormalParameter(param.name, fType, !param.optional);
      if (param.optional) {
        fOptionalParameters.add(fParam);
      } else {
        fNormalParameters.add(fParam);
      }
    }

    for (final param in def.namedParams) {
      final fType =
          FunctionTypeAnnotation.fromBridgeAnnotation(ctx, param.type);
      final fParam =
          FunctionFormalParameter(param.name, fType, !param.optional);
      fNamedParameters[param.name] = fParam;
    }

    final fGenerics = def.generics.entries.map((entry) => FunctionGenericParam(
        entry.key,
        bound: entry.value.$extends != null
            ? FunctionTypeAnnotation.fromBridgeTypeRef(
                ctx, entry.value.$extends!)
            : null));

    return EvalFunctionType(fNormalParameters, fOptionalParameters,
        fNamedParameters, fReturnType, fGenerics.toList());
  }
}
