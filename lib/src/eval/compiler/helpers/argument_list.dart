import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/src/eval/compiler/helpers/conversion.dart';
import 'default_value.dart';

import '../../../../dart_eval_bridge.dart';
import '../builtins.dart';
import '../context.dart';
import '../errors.dart';
import '../member/call_signature.dart' show ParameterSpec, SourceDefault;
import '../type.dart';

import '../variable.dart';
import '../values/abi.dart';
import '../../ir/types.dart' show ResolveTypeId;

/// Converts an already-compiled argument to the representation the callee's
/// ABI expects for [param]: boxed unless the parameter type crosses the
/// function boundary unboxed (never for [MethodDeclaration] hosts, whose
/// dynamic dispatch ABI is always boxed). Tear-offs materialize last.
Variable coerceArgumentForParameter(
  CompilerContext ctx,
  Variable arg0,
  TypeRef paramType,
  FormalParameter param,
  Declaration parameterHost, {
  bool genericParameter = false,
  AstNode? source,
}) {
  final paramRep = Abi.parameter(
    paramType,
    parameterHost is MethodDeclaration
        ? CallableKind.method
        : CallableKind.function,
    erased: genericParameter,
  );
  arg0 = convertForAssignment(
    ctx,
    arg0,
    paramType,
    representation: paramRep.bank,
    source: source ?? parameterHost,
    description:
        'Cannot assign argument of type ${arg0.type.toStringClear(ctx, paramType)} '
        'to parameter "${param.name!.lexeme}" of type '
        '${paramType.toStringClear(ctx, arg0.type)}',
  );
  arg0 = paramRep == ValueRep.boxed
      ? arg0.boxIfNeeded(ctx)
      : arg0.unboxIfNeeded(ctx);

  return arg0;
}

/// Pushes an integer carrying [type]'s runtime type id, resolving embedded
/// type parameters against the frame's type environment at runtime.
SSA pushRuntimeTypeId(CompilerContext ctx, TypeRef type) {
  final typeId = ctx.runtimeTypes.idOf(type);
  if (!type.requiresTypeEnvironment) {
    return BuiltinValue(intval: typeId).push(ctx).ssa;
  }
  final ssa = ctx.svar('typeId');
  ctx.pushOp(ResolveTypeId(ssa, typeId));
  return ssa;
}

/// Compiles an omitted source argument from its resolved signature. The
/// signature owns the formal type and the library of any default expression.
Variable compileOmittedArgument(
  CompilerContext ctx,
  ParameterSpec parameter,
  Declaration host,
  TypeRef type,
) {
  if (parameter.isRequired) {
    throw CompileError(
      'Missing required argument ${parameter.name}',
      parameter.node,
    );
  }
  // Scalar defaults push as native constants; anything else (tear-offs, const
  // objects) compiles the constant expression normally. SourceDefault records
  // the declaring library, including defaults inherited by super formals.
  final defaultSource = parameter.defaultValue;
  final defaultExpr = defaultSource is SourceDefault
      ? defaultSource.expression
      : null;
  final library = defaultSource is SourceDefault
      ? defaultSource.library
      : ctx.library;
  Object? value;
  var useExpression = false;
  if (defaultExpr == null) {
    value = null;
  } else {
    try {
      value = evaluateDefaultValue(ctx, library, defaultExpr);
    } on CompileError {
      useExpression = true;
    }
  }
  Variable variable;
  if (useExpression) {
    // The default expression resolves in the declaring library — its private
    // names aren't visible in the caller's library.
    final previousLibrary = ctx.library;
    ctx.library = library;
    try {
      variable = compileExpression(defaultExpr!, ctx, type);
    } finally {
      ctx.library = previousLibrary;
    }
  } else {
    if (value is int && type.isSpec(CoreTypes.double)) {
      value = value.toDouble();
    }
    variable = pushDefaultValue(ctx, value);
  }
  return host is MethodDeclaration || Abi.unboxedAcrossCalls(type).isBoxed
      ? variable.boxIfNeeded(ctx)
      : variable.unboxIfNeeded(ctx);
}

/// A constructor's `super` parameters split for forwarding: positional super
/// parameters bind the superclass constructor's positional parameters in
/// order (their local names need not match the callee's), named ones by name.
typedef SuperParams = ({List<String> positional, Set<String> named});

TypeRef resolveFieldFormalType(
  CompilerContext ctx,
  int decLibrary,
  FieldFormalParameter param,
  Declaration parameterHost,
) {
  if (parameterHost is! ConstructorDeclaration) {
    throw CompileError('Field formals can only occur in constructors');
  }
  final $class = parameterHost.parent!.parent as Declaration;
  return ctx.memberLookup.fieldType(
        TypeRef.lookupDeclaration(ctx, decLibrary, $class),
        param.name.lexeme,
        forFieldFormal: true,
        source: param,
      ) ??
      CoreTypes.dynamic.ref(ctx);
}

TypeRef resolveSuperFormalType(
  CompilerContext ctx,
  int decLibrary,
  SuperFormalParameter param,
  Declaration parameterHost,
) {
  if (parameterHost is! ConstructorDeclaration) {
    throw CompileError('Super formals can only occur in constructors');
  }
  final (superCstr, target) = superFormalTarget(
    ctx,
    decLibrary,
    param,
    parameterHost,
  );
  if (superCstr.isBridge) {
    if (target is BridgeParameter) {
      return TypeRef.fromBridgeAnnotation(ctx, target.type);
    }
  } else if (target is RegularFormalParameter) {
    final type0 = target.type;
    if (type0 == null) {
      return CoreTypes.dynamic.ref(ctx);
    }
    return TypeRef.fromAnnotation(ctx, superCstr.sourceLib, type0);
  } else if (target is FieldFormalParameter) {
    return resolveFieldFormalType(
      ctx,
      decLibrary,
      target,
      superCstr.declaration as ConstructorDeclaration,
    );
  } else if (target is SuperFormalParameter) {
    return resolveSuperFormalType(
      ctx,
      decLibrary,
      target,
      superCstr.declaration as ConstructorDeclaration,
    );
  } else if (target != null) {
    throw CompileError('Unknown parameter type ${target.runtimeType}', param);
  }

  throw CompileError(
    'Could not find parameter ${param.name.value()} in the referenced superclass constructor',
    param,
    decLibrary,
  );
}
