import 'package:analyzer/dart/ast/ast.dart';
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
    CompilerContext ctx,
    BridgeTypeAnnotation annotation, {
    Map<String, TypeRef> typeParameters = const {},
  }) {
    final type = annotation.type;
    if (type.ref != null) {
      final resolved = typeParameters[type.ref];
      if (resolved != null) {
        return FunctionTypeAnnotation.type(
          resolved.copyWith(nullable: annotation.nullable),
        );
      }
      return FunctionTypeAnnotation.name(type.ref!);
    } else {
      return FunctionTypeAnnotation.type(
        TypeRef.fromBridgeAnnotation(
          ctx,
          annotation,
          typeParameters: typeParameters,
        ),
      );
    }
  }

  factory FunctionTypeAnnotation.fromBridgeTypeRef(
    CompilerContext ctx,
    BridgeTypeRef ref,
  ) {
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

  const EvalFunctionType(
    this.normalParameters,
    this.optionalParameters,
    this.namedParameters,
    this.returnType,
    this.generics,
  );

  factory EvalFunctionType.fromAnnotation(
    CompilerContext ctx,
    int library,
    GenericFunctionType annotation,
  ) {
    // The function type's own type parameters (`Function<A>(A x)`) are
    // resolvable inside its bounds, parameters, and return type. Their owner
    // is the annotation node so re-resolving the same alias stays canonical.
    final ownParams =
        annotation.typeParameters?.typeParameters ?? const <TypeParameter>[];
    final typeParameters = <String, TypeRef>{
      for (var i = 0; i < ownParams.length; i++)
        ownParams[i].name.lexeme: TypeRef(
          library,
          ownParams[i].name.lexeme,
          resolved: true,
          typeParameterOwner: 'functionType:$library:${annotation.offset}',
          typeParameterIndex: i,
        ),
    };

    FunctionTypeAnnotation resolve(TypeAnnotation? type) =>
        FunctionTypeAnnotation.type(
          type == null
              ? CoreTypes.dynamic.ref(ctx)
              : TypeRef.fromAnnotation(
                  ctx,
                  library,
                  type,
                  typeParameters: typeParameters,
                ),
        );

    TypeAnnotation? parameterType(FormalParameter parameter) {
      return parameter.type;
    }

    final required = <FunctionFormalParameter>[];
    final optional = <FunctionFormalParameter>[];
    final named = <String, FunctionFormalParameter>{};
    for (final parameter in annotation.parameters.parameters) {
      final model = FunctionFormalParameter(
        parameter.name?.lexeme,
        resolve(parameterType(parameter)),
        parameter.isRequired,
      );
      if (parameter.isNamed) {
        named[parameter.name!.lexeme] = model;
      } else if (parameter.isRequired) {
        required.add(model);
      } else {
        optional.add(model);
      }
    }
    final generics = [
      for (final parameter
          in annotation.typeParameters?.typeParameters ??
              const <TypeParameter>[])
        FunctionGenericParam(
          parameter.name.lexeme,
          bound: parameter.bound == null ? null : resolve(parameter.bound),
        ),
    ];
    return EvalFunctionType(
      required,
      optional,
      named,
      resolve(annotation.returnType),
      generics,
    );
  }

  String semanticKey() {
    String annotation(FunctionTypeAnnotation value) => value.type == null
        ? 'name:${value.name}'
        : 'type:${value.type!.semanticKey}';
    String parameter(FunctionFormalParameter value) =>
        '${value.name ?? ''}:${value.isRequired ? 1 : 0}:${annotation(value.type)}';
    final named = namedParameters.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return '(${normalParameters.map(parameter).join(',')})'
        '[${optionalParameters.map(parameter).join(',')}]'
        '{${named.map((entry) => '${entry.key}=${parameter(entry.value)}').join(',')}}'
        '->${annotation(returnType)}'
        '<${generics.map((value) => value.name).join(',')}>';
  }

  factory EvalFunctionType.fromBridgeFunctionDef(
    CompilerContext ctx,
    BridgeFunctionDef def, {
    Map<String, TypeRef> typeParameters = const {},
  }) {
    final fReturnType = FunctionTypeAnnotation.fromBridgeAnnotation(
      ctx,
      def.returns,
      typeParameters: typeParameters,
    );

    final fNormalParameters = <FunctionFormalParameter>[];
    final fOptionalParameters = <FunctionFormalParameter>[];
    final fNamedParameters = <String, FunctionFormalParameter>{};

    for (final param in def.params) {
      final fType = FunctionTypeAnnotation.fromBridgeAnnotation(
        ctx,
        param.type,
        typeParameters: typeParameters,
      );
      final fParam = FunctionFormalParameter(
        param.name,
        fType,
        !param.optional,
      );
      if (param.optional) {
        fOptionalParameters.add(fParam);
      } else {
        fNormalParameters.add(fParam);
      }
    }

    for (final param in def.namedParams) {
      final fType = FunctionTypeAnnotation.fromBridgeAnnotation(
        ctx,
        param.type,
        typeParameters: typeParameters,
      );
      final fParam = FunctionFormalParameter(
        param.name,
        fType,
        !param.optional,
      );
      fNamedParameters[param.name] = fParam;
    }

    final fGenerics = def.generics.entries.map(
      (entry) => FunctionGenericParam(
        entry.key,
        bound: entry.value.$extends != null
            ? FunctionTypeAnnotation.fromBridgeTypeRef(
                ctx,
                entry.value.$extends!,
              )
            : null,
      ),
    );

    return EvalFunctionType(
      fNormalParameters,
      fOptionalParameters,
      fNamedParameters,
      fReturnType,
      fGenerics.toList(),
    );
  }
}

/// Builds the structural callable type declared by a function or method.
/// Generic callables stay nominal until runtime type-parameter substitution is
/// available.
TypeRef declaredFunctionType(
  CompilerContext ctx,
  int library,
  FormalParameterList? parameters,
  TypeAnnotation? returnType,
  TypeParameterList? typeParameters,
) {
  if (typeParameters != null) return CoreTypes.function.ref(ctx);

  TypeRef parameterType(FormalParameter parameter) {
    final annotation = parameter.type;
    return annotation == null
        ? CoreTypes.dynamic.ref(ctx)
        : TypeRef.fromAnnotation(ctx, library, annotation);
  }

  final all = parameters?.parameters ?? const <FormalParameter>[];
  final positional = all.where((parameter) => parameter.isPositional);
  final named = all.where((parameter) => parameter.isNamed);
  FunctionFormalParameter model(FormalParameter parameter) =>
      FunctionFormalParameter(
        parameter.name?.lexeme,
        FunctionTypeAnnotation.type(parameterType(parameter)),
        parameter.isRequired,
      );
  return CoreTypes.function
      .ref(ctx)
      .copyWith(
        functionType: EvalFunctionType(
          [
            for (final parameter in positional)
              if (parameter.isRequired) model(parameter),
          ],
          [
            for (final parameter in positional)
              if (!parameter.isRequired) model(parameter),
          ],
          {
            for (final parameter in named)
              parameter.name!.lexeme: model(parameter),
          },
          FunctionTypeAnnotation.type(
            returnType == null
                ? CoreTypes.dynamic.ref(ctx)
                : TypeRef.fromAnnotation(ctx, library, returnType),
          ),
          const [],
        ),
      );
}
