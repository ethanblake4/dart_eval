import 'package:collection/collection.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';

import '../context.dart';
import '../helpers/fpl.dart';
import '../type.dart';


/// How a parameter's default is spelled at its declaration.
sealed class DefaultSource {
  const DefaultSource();
}

/// A source default expression, compiled in the declaring library —
/// including defaults inherited by super formals (`superFormalDefault`
/// already resolved it to the ultimate source).
final class SourceDefault extends DefaultSource {
  const SourceDefault(this.expression, this.library);

  final Expression expression;
  final int library;
}

/// A bridge parameter's implicit default — bridged defaults are host-side,
/// so the compiler only sees "optional".
final class BridgeNullDefault extends DefaultSource {
  const BridgeNullDefault();
}

/// One parameter of a [CallSignature] — name, declared type, optionality,
/// and the pieces needed to bind and box an argument.
final class ParameterSpec {
  const ParameterSpec(
    this.name,
    this.type, {
    required this.isRequired,
    this.defaultValue,
    this.erased = false,
    this.node,
  });

  final String name;
  final TypeRef type;
  final bool isRequired;
  final DefaultSource? defaultValue;

  /// The annotation names a type parameter: the ABI boxes the argument
  /// (coerceArgumentForParameter's `genericParameter`).
  final bool erased;

  /// Field formals, super formals, and legacy function-typed parameters
  /// need the node for their type and default rules.
  final FormalParameter? node;

  ParameterSpec substitute(Substitution substitution) => ParameterSpec(
    name,
    type.substituteTypeParameters(substitution),
    isRequired: isRequired,
    defaultValue: defaultValue,
    erased: erased,
    node: node,
  );
}

/// The full calling shape of a member: its own type parameters, positional
/// and named parameter specs, and return type. In the owner's type-parameter
/// space — instantiate through [substitute] for a receiver's view.
final class CallSignature {
  const CallSignature({
    this.typeParameters = const [],
    required this.positional,
    required this.requiredPositional,
    this.named = const [],
    required this.returnType,
    this.returnOverride,
  });

  /// The member's own type parameters (`m<T>`), in declaration order.
  final List<TypeParameterDef> typeParameters;

  /// Positional parameters (required first).
  final List<ParameterSpec> positional;
  final int requiredPositional;

  /// Named parameters in declaration order.
  final List<ParameterSpec> named;
  final TypeRef returnType;

  /// Only for bridge `returnTypeDependency`: the return type chosen by the
  /// static type of one argument.
  final TypeRef? Function(
    List<TypeRef> positionalTypes,
    Map<String, TypeRef> namedTypes,
  )?
  returnOverride;

  /// The signature of a source method, getter, setter, or function —
  /// parameter types resolve with the owner's parameter space plus the
  /// member's own declared parameters in scope.
  factory CallSignature.source(
    CompilerContext ctx,
    int library,
    TypeParameterList? typeParameterList,
    FormalParameterList? parameterList, {
    required TypeParameterOwner owner,
    required TypeAnnotation? returnAnnotation,
    required TypeRef returnFallback,
    Map<String, TypeRef> typeParameters = const {},
    Declaration? parameterHost,
  }) {
    final ownParams =
        typeParameterList?.typeParameters ?? const <TypeParameter>[];
    final allTypeParams = <String, TypeRef>{...typeParameters};
    final ownDefs = declareTypeParameters(ctx, owner, ownParams, allTypeParams, (
      bound,
    ) {
      return TypeRef.fromAnnotation(
        ctx,
        library,
        bound,
        typeParameters: allTypeParams,
      );
    });

    final positional = <ParameterSpec>[];
    final named = <ParameterSpec>[];
    var requiredCount = 0;
    for (final param in parameterList?.parameters ?? const <FormalParameter>[]) {
      final (type, _) = getFormalParameterType(
        ctx,
        param,
        library,
        parameterHost,
        typeParameters: allTypeParams,
      );
      final resolved = type ?? CoreTypes.dynamic.ref(ctx);
      final defaultExpr = param.defaultClause?.value;
      final spec = ParameterSpec(
        param.name?.lexeme ?? '',
        resolved,
        isRequired: param.isRequired,
        defaultValue: defaultExpr == null
            ? null
            : SourceDefault(defaultExpr, library),
        erased: resolved.isTypeParameter,
        node: param,
      );
      if (param.isNamed) {
        named.add(spec);
      } else {
        positional.add(spec);
        if (param.isRequired) requiredCount++;
      }
    }

    final returnType = returnAnnotation == null
        ? returnFallback
        : TypeRef.fromAnnotation(
            ctx,
            library,
            returnAnnotation,
            typeParameters: allTypeParams,
          );
    return CallSignature(
      typeParameters: ownDefs,
      positional: positional,
      requiredPositional: requiredCount,
      named: named,
      returnType: returnType,
    );
  }

  /// The signature of a bridge function — `params`/`namedParams` become
  /// [ParameterSpec]s; `returnTypeDependency` becomes [returnOverride].
  /// Bridge annotations resolve their `E`/`K`/`V` refs against [owner]
  /// (the declaring type's `thisType`) — the owner's generic space.
  factory CallSignature.bridge(
    CompilerContext ctx,
    BridgeFunctionDef def, {
    required TypeRef returnFallback,
    TypeRef? owner,
    Map<String, TypeRef> typeParameters = const {},
  }) {
    TypeRef resolve(BridgeTypeAnnotation t) => TypeRef.fromBridgeAnnotation(
      ctx,
      t,
      specifiedType: owner,
      typeParameters: typeParameters,
    );
    final dependency = def.returnTypeDependency;
    return CallSignature(
      positional: [
        for (final param in def.params)
          ParameterSpec(
            param.name,
            resolve(param.type),
            isRequired: !param.optional,
            defaultValue: param.optional ? const BridgeNullDefault() : null,
          ),
      ],
      requiredPositional: def.params.where((p) => !p.optional).length,
      named: [
        for (final param in def.namedParams)
          ParameterSpec(
            param.name,
            resolve(param.type),
            isRequired: !param.optional,
            defaultValue: param.optional ? const BridgeNullDefault() : null,
          ),
      ],
      returnType: resolve(def.returns),
      returnOverride: dependency == null
          ? null
          : (positionalTypes, namedTypes) {
              final watched = dependency.paramName != null
                  ? namedTypes[dependency.paramName]
                  : dependency.paramIndex != null &&
                        dependency.paramIndex! < positionalTypes.length
                  ? positionalTypes[dependency.paramIndex!]
                  : null;
              if (watched == null) return null;
              for (final c in dependency.cases) {
                final when = TypeRef.fromBridgeTypeRef(ctx, c.when);
                if (sameDeclaration(watched, when)) {
                  return resolve(c.then);
                }
              }
              return null;
            },
    );
  }

  /// Substitutes type parameters through every type in the signature.
  CallSignature substitute(Substitution substitution) {
    if (substitution.isEmpty) return this;
    return CallSignature(
      typeParameters: typeParameters,
      positional: [
        for (final parameter in positional) parameter.substitute(substitution),
      ],
      requiredPositional: requiredPositional,
      named: [
        for (final parameter in named) parameter.substitute(substitution),
      ],
      returnType: returnType.substituteTypeParameters(substitution),
      returnOverride: returnOverride,
    );
  }

  /// A signature carrying only a return type — enough for a callable whose
  /// parameters aren't modeled (dynamic `Function`-typed member reads).
  factory CallSignature.returnOnly(TypeRef returnType) => CallSignature(
    positional: const [],
    requiredPositional: 0,
    returnType: returnType,
  );

  /// This signature as a [FunctionTypeRef] — parameter names are not part
  /// of the type, but arity/requiredness and types are.
  FunctionTypeRef toFunctionType(CompilerContext ctx) => FunctionTypeRef(
    FunctionSignature(
      typeParameters: typeParameters,
      positional: [for (final parameter in positional) parameter.type],
      requiredPositional: requiredPositional,
      named: {
        for (final parameter in named)
          parameter.name: (
            type: parameter.type,
            required: parameter.isRequired,
          ),
      },
      returnType: returnType,
    ),
    decl: ctx.types.bySpec(CoreTypes.function),
  );

  @override
  bool operator ==(Object other) =>
      other is CallSignature &&
      const ListEquality<TypeParameterDef>().equals(
        other.typeParameters,
        typeParameters,
      ) &&
      const ListEquality<ParameterSpec>().equals(
        other.positional,
        positional,
      ) &&
      other.requiredPositional == requiredPositional &&
      const ListEquality<ParameterSpec>().equals(other.named, named) &&
      other.returnType == returnType;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(typeParameters),
    Object.hashAll(positional),
    requiredPositional,
    Object.hashAll(named),
    returnType,
  );
}
