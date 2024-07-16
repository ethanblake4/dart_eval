import 'package:analyzer/dart/ast/ast.dart';
import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/helpers/argument_list.dart';
import 'package:dart_eval/src/eval/compiler/macros/branch.dart';
import 'package:dart_eval/src/eval/compiler/model/registers.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/ir/memory.dart';
import 'package:dart_eval/src/eval/ir/primitives.dart';

List<PossiblyValuedParameter> resolveFPLDefaults(
    CompilerContext ctx, FormalParameterList? fpl, bool isInstanceMethod,
    {bool allowUnboxed = true,
    bool sortNamed = false,
    bool ignoreDefaults = false,
    bool isEnum = false}) {
  final normalized = <PossiblyValuedParameter>[];
  var hasEncounteredOptionalPositionalParam = false;
  var hasEncounteredNamedParam = false;
  var _paramIndex = isEnum ? 2 : (isInstanceMethod || sortNamed ? 1 : 0);

  final named = <FormalParameter>[];
  final positional = <FormalParameter>[];

  for (final param in fpl?.parameters ?? <FormalParameter>[]) {
    if (param.isNamed) {
      if (hasEncounteredOptionalPositionalParam) {
        throw CompileError(
            'Cannot mix named and optional positional parameters');
      }
      hasEncounteredNamedParam = true;
      named.add(param);
    } else {
      if (param.isOptionalPositional) {
        if (hasEncounteredNamedParam) {
          throw CompileError(
              'Cannot mix named and optional positional parameters');
        }
        hasEncounteredOptionalPositionalParam = true;
      }
      positional.add(param);
    }
  }

  if (sortNamed) {
    named.sort((a, b) => (a.name!.lexeme).compareTo(b.name!.lexeme));
  }

  // parameter layout:
  // 1st int: regALUAcc, 2nd int: regALU2
  // 1st double: regFPUAcc, 2nd float: regFPU2
  // 1st string: regStringAcc, 2nd string: regString2
  // 1st bool: regBoolAcc, 2nd bool: regBool2
  // 1st collection: regGPR3
  // next: regGPR1, regGPR2, regGPR3
  // remaining: pushed in order to stack

  final types = <TypeRef>[];

  for (final param in [...positional, ...named]) {
    types.add(
        getFormalParameterType(ctx, param, ctx.library, ctx.currentClass).$1 ??
            CoreTypes.dynamic.ref(ctx));
  }

  final paramLayout = mapParameterLayout(ctx, types);

  var i = 0;
  for (final param in [...positional, ...named]) {
    final name = param.name?.lexeme ?? 'param_$i';
    final paramVar = ctx.svar(name);
    ctx.pushOp(AssignRegister(paramVar, paramLayout[i]));
    if (param is DefaultFormalParameter) {
      if (param.defaultValue != null && !ignoreDefaults) {
        ctx.beginAllocScope();
        macroBranch(ctx, null, condition: (_ctx) {
          return Variable.of(_ctx, paramVar, types[i]);
        }, thenBranch: (_ctx, rt) {
          var V = compileExpression(param.defaultValue!, ctx);
          if (!allowUnboxed || !V.type.isUnboxedAcrossFunctionBoundaries) {
            V = V.boxIfNeeded(ctx);
          } else if (allowUnboxed && V.type.isUnboxedAcrossFunctionBoundaries) {
            V = V.unboxIfNeeded(ctx);
          }
          ctx.pushOp(Assign(paramVar, V.ssa));
          normalized
              .add(PossiblyValuedParameter(param.parameter, paramVar.name, V));
          return StatementInfo(-1);
        }, testNullish: true);
      } else {
        if (param.defaultValue == null /* todo && param.type.nullable */) {
          ctx.pushOp(MaybeBoxNull(paramVar.copy(), paramVar));
        }
        normalized
            .add(PossiblyValuedParameter(param.parameter, paramVar.name, null));
      }
    } else {
      param as NormalFormalParameter;
      normalized.add(PossiblyValuedParameter(param, paramVar.name, null));
    }

    _paramIndex++;
    i++;
  }
  return normalized;
}

(TypeRef?, TypeAnnotation?) getFormalParameterType(CompilerContext ctx,
    FormalParameter param, int decLibrary, Declaration? parameterHost) {
  if (param is SimpleFormalParameter) {
    final _type = param.type;
    return _type == null
        ? (null, null)
        : (TypeRef.fromAnnotation(ctx, decLibrary, _type), _type);
  } else if (param is FieldFormalParameter) {
    return (
      resolveFieldFormalType(ctx, decLibrary, param, parameterHost!),
      null
    );
  } else if (param is SuperFormalParameter) {
    return (
      resolveSuperFormalType(ctx, decLibrary, param, parameterHost!),
      null
    );
  } else if (param is DefaultFormalParameter) {
    final p = param.parameter;
    if (p is! SimpleFormalParameter) {
      return (null, null);
    }
    final _type = p.type;
    return _type == null
        ? (null, null)
        : (TypeRef.fromAnnotation(ctx, decLibrary, _type), _type);
  } else {
    throw CompileError('Unknown formal type ${param.runtimeType}');
  }
}
