import '../../ir/string.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/expression/function.dart';
import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/dispatch.dart';
import 'package:dart_eval/src/eval/compiler/expression/method_invocation.dart';
import 'package:dart_eval/src/eval/compiler/helpers/closure.dart';
import 'package:dart_eval/src/eval/compiler/helpers/conversion.dart';
import 'package:dart_eval/src/eval/compiler/helpers/argument_list.dart';
import 'package:dart_eval/src/eval/compiler/helpers/extension.dart';
import 'package:dart_eval/src/eval/compiler/model/function_type.dart';
import 'package:dart_eval/src/eval/compiler/helpers/tearoff.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/alu.dart';
import 'package:dart_eval/src/eval/ir/numeric.dart';
import 'package:dart_eval/src/eval/ir/representation.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/ir/logic.dart';
import 'package:dart_eval/src/eval/ir/objects.dart';
import 'package:dart_eval/src/eval/shared/types.dart';
import '../values/abi.dart';

extension Invoke on Variable {
  InvokeResult invoke(
    CompilerContext ctx,
    String? method,
    List<Variable> args, {
    Map<String, Variable>? namedArgs,
  }) {
    if (method == null) return _invokeAsFunction(ctx, args, namedArgs);
    final boolType = CoreTypes.bool.ref(ctx);
    if ((namedArgs == null || namedArgs.isEmpty) &&
        args.length == 1 &&
        type.isAssignableTo(
          ctx,
          CoreTypes.string.ref(ctx),
          forceAllowDynamic: false,
        ) &&
        ((method == '+' &&
                args.single.type.isAssignableTo(
                  ctx,
                  CoreTypes.string.ref(ctx),
                  forceAllowDynamic: false,
                )) ||
            ((method == 'codeUnitAt' || method == '[]') &&
                args.single.type.isAssignableTo(
                  ctx,
                  CoreTypes.int.ref(ctx),
                  forceAllowDynamic: false,
                )))) {
      final receiver = unboxIfNeeded(ctx, false);
      final argument = args.single.ssa == ssa
          ? receiver
          : args.single.unboxIfNeeded(ctx, false);
      final operator = switch (method) {
        '+' => StringOperator.concatenate,
        'codeUnitAt' => StringOperator.codeUnitAt,
        _ => StringOperator.indexAt,
      };
      return InvokeResult(
        receiver,
        Variable.ssa(
          ctx,
          StringOperation(
            ctx.svar('string_result'),
            operator,
            receiver.ssa,
            argument.ssa,
          ),
          (operator == StringOperator.codeUnitAt
                  ? CoreTypes.int
                  : CoreTypes.string)
              .ref(ctx),
          rep: operator == StringOperator.codeUnitAt
              ? ValueRep.int
              : ValueRep.string,
        ),
        [argument],
      );
    }

    if (method == '!' &&
        type.isAssignableTo(
          ctx,
          CoreTypes.bool.ref(ctx),
          forceAllowDynamic: false,
        )) {
      final receiver = unboxIfNeeded(ctx);
      return InvokeResult(
        receiver,
        Variable.ssa(
          ctx,
          LogicalNot(ctx.svar('not_result'), receiver.ssa),
          boolType,
          rep: ValueRep.bool,
        ),
        [],
      );
    }
    if (args.length == 1 &&
        type.isAssignableTo(
          ctx,
          CoreTypes.int.ref(ctx),
          forceAllowDynamic: false,
        ) &&
        args.single.type.isAssignableTo(
          ctx,
          CoreTypes.int.ref(ctx),
          forceAllowDynamic: false,
        ) &&
        {'+', '-', '<', '>', '<=', '>='}.contains(method)) {
      final receiver = unboxIfNeeded(ctx);
      final right = args.single.ssa == ssa
          ? receiver
          : args.single.unboxIfNeeded(ctx);
      final target = ctx.svar('numeric_result');
      final Operation operation = switch (method) {
        '+' => IntAdd(target, receiver.ssa, right.ssa),
        '-' => IntSub(target, receiver.ssa, right.ssa),
        '<' => IntLessThan(target, receiver.ssa, right.ssa),
        '>' => IntGreaterThan(target, receiver.ssa, right.ssa),
        '<=' => IntLessThanOrEqual(target, receiver.ssa, right.ssa),
        '>=' => IntGreaterThanOrEqual(target, receiver.ssa, right.ssa),
        _ => throw StateError('Unknown numeric intrinsic $method'),
      };
      return InvokeResult(
        receiver,
        Variable.ssa(
          ctx,
          operation,
          method == '+' || method == '-' ? CoreTypes.int.ref(ctx) : boolType,
          rep: method == '+' || method == '-' ? ValueRep.int : ValueRep.bool,
        ),
        [right],
      );
    }
    const numericOperators = {
      '+': NumericOperator.add,
      '-': NumericOperator.subtract,
      '*': NumericOperator.multiply,
      '/': NumericOperator.divide,
      '~/': NumericOperator.truncatingDivide,
      '%': NumericOperator.modulo,
      '&': NumericOperator.bitAnd,
      '|': NumericOperator.bitOr,
      '^': NumericOperator.bitXor,
      '<<': NumericOperator.shiftLeft,
      '>>': NumericOperator.shiftRight,
      '>>>': NumericOperator.unsignedShiftRight,
      '<': NumericOperator.lessThan,
      '<=': NumericOperator.lessThanOrEqual,
      '>': NumericOperator.greaterThan,
      '>=': NumericOperator.greaterThanOrEqual,
      '==': NumericOperator.equal,
      '!=': NumericOperator.notEqual,
    };
    final numericOperator = numericOperators[method];
    if (args.length == 1 && numericOperator != null) {
      final integerOperands =
          type.isAssignableTo(
            ctx,
            CoreTypes.int.ref(ctx),
            forceAllowDynamic: false,
          ) &&
          args.single.type.isAssignableTo(
            ctx,
            CoreTypes.int.ref(ctx),
            forceAllowDynamic: false,
          );
      // `int` counts as a double operand through the implicit int → double
      // conversion; [widen] emits the IntToDouble op below. TypeRef equality
      // ignores nullability, so `int?` must be excluded explicitly — a nullable
      // value has object representation and may hold null.
      bool isDoubleOperand(TypeRef t) =>
          !t.nullable &&
          (t.isAssignableTo(
                ctx,
                CoreTypes.double.ref(ctx),
                forceAllowDynamic: false,
              ) ||
              t.isSpec(CoreTypes.int));
      final doubleOperands =
          isDoubleOperand(type) && isDoubleOperand(args.single.type);
      final integerOperation = integerOperands && method != '/';
      if (integerOperation ||
          (doubleOperands &&
              !numericOperator.isIntegerOnly &&
              method != '~/' &&
              method != '%')) {
        final operandRepresentation = integerOperation
            ? MachineRepresentation.integer
            : MachineRepresentation.doublePrecision;
        Variable widen(Variable v) =>
            operandRepresentation == MachineRepresentation.doublePrecision &&
                v.type.isSpec(CoreTypes.int)
            ? Variable.ssa(
                ctx,
                IntToDouble(ctx.svar('widen'), v.ssa),
                CoreTypes.double.ref(ctx),
                rep: ValueRep.double,
              )
            : v;
        final receiver = widen(unboxIfNeeded(ctx));
        final right = args.single.ssa == ssa
            ? receiver
            : widen(args.single.unboxIfNeeded(ctx));
        final operation = NumericBinary(
          ctx.svar('numeric_result'),
          receiver.ssa,
          right.ssa,
          operandRepresentation,
          numericOperator,
        );
        final resultType = numericOperator.isComparison
            ? CoreTypes.bool.ref(ctx)
            : operandRepresentation == MachineRepresentation.integer
            ? CoreTypes.int.ref(ctx)
            : CoreTypes.double.ref(ctx);
        return InvokeResult(
          receiver,
          Variable.ssa(
            ctx,
            operation,
            resultType,
            rep: unboxedRepOf(resultType),
          ),
          [right],
        );
      }
    }
    var receiver = this;
    if ((namedArgs == null || namedArgs.isEmpty) &&
        !type.isSpec(CoreTypes.dynamic)) {
      // Emits a static call `E.m(receiver, args...)` for an extension member.
      InvokeResult invokeExt(
        EvalExtension ext,
        MethodDeclaration member,
        List<TypeRef> bindings,
        Map<String, TypeRef> typeParams,
      ) {
        final formals = member.parameters?.parameters ?? const [];
        final convertedArgs = [
          for (var i = 0; i < args.length; i++)
            i < formals.length && formals[i].type != null
                ? convertForAssignment(
                    ctx,
                    args[i],
                    formalParameterAnnotationType(
                      ctx,
                      ext.library,
                      formals[i],
                      typeParameters: typeParams,
                    ),
                    representation: MachineRepresentation.object,
                  )
                : args[i],
        ];
        // Pad omitted optional positionals with their declared defaults —
        // extension members are static calls, so the full declared argument
        // vector is always passed.
        final positionalFormals = formals.where((f) => f.isPositional).toList();
        for (var i = convertedArgs.length; i < positionalFormals.length; i++) {
          convertedArgs.add(
            compileOmittedArgument(
              ctx,
              ext.library,
              positionalFormals[i],
              member,
              typeParameters: typeParams,
            ),
          );
        }
        final target = ctx.svar('method_result');
        ctx.pushOp(
          Call(
            DeferredOrOffset(file: ext.library, name: ext.memberKey(member)),
            [
              receiver.boxIfNeeded(ctx).ssa,
              for (final a in convertedArgs) a.boxIfNeeded(ctx).ssa,
            ],
            result: target,
            typeArguments:
                extensionCallTypeArguments(
                  ctx,
                  ext,
                  member,
                  bindings,
                  const {},
                ) ??
                const [],
          ),
        );
        final returnType =
            AlwaysReturnType.fromAnnotation(
              ctx,
              ext.library,
              member.returnType,
              CoreTypes.dynamic.ref(ctx),
              typeParameters: typeParams,
            ).type ??
            CoreTypes.dynamic.ref(ctx);
        return InvokeResult(
          receiver,
          Variable.of(ctx, target, returnType, rep: ValueRep.boxed),
          convertedArgs,
        );
      }

      // `E(x).m(...)` — explicit application pins member resolution to E.
      final bound = boundExtension;
      if (bound != null) {
        final member = extensionMember(bound.ext, method);
        if (member == null) {
          throw CompileError(
            'Extension ${bound.ext.name} has no member $method',
          );
        }
        return invokeExt(
          bound.ext,
          member,
          bound.onBindings,
          extBindingsMap(bound.ext, bound.onBindings),
        );
      }
      // A member the class doesn't declare may be an extension method (e.g.
      // `operator []=` defined in `extension on T`). Instance members win —
      // the extension only applies when instance lookup fails.
      if (!hasInstanceMethod(ctx, type, method)) {
        // `unary-` maps to the extension member `-` of positional arity 0.
        final found = resolveExtensionMember(
          ctx,
          type,
          method == 'unary-' ? '-' : method,
          arity: args.length,
        );
        if (found != null) {
          final (ext, member, bindings) = found;
          return invokeExt(
            ext,
            member,
            bindings,
            extBindingsMap(ext, bindings),
          );
        }
      }
    }
    final values = [...args];
    final equality = (method == '==' || method == '!=') && values.length == 1;
    if (equality &&
        receiver.name == null &&
        receiver.methodOffset != null &&
        values.single.name == null &&
        values.single.methodOffset != null) {
      final equal = receiver.methodOffset == values.single.methodOffset;
      return InvokeResult(
        receiver,
        BuiltinValue(boolval: method == '!=' ? !equal : equal).push(ctx),
        values,
      );
    }
    if (receiver.name == null && receiver.methodOffset != null) {
      receiver = receiver.tearOff(ctx);
    }
    for (var i = 0; i < values.length; i++) {
      if (values[i].name == null && values[i].methodOffset != null) {
        values[i] = values[i].tearOff(ctx);
      }
    }
    final boxed = Variable.boxUnboxMultiple(ctx, [receiver, ...values], true);
    receiver = boxed.first;
    final prepared = boxed.sublist(1);
    var result = ctx.svar(equality ? 'equals_result' : 'invoke_result');
    if (equality) {
      ctx.pushOp(DynamicEquals(result, receiver.ssa, prepared.single.ssa));
      if (method == '!=') {
        final negated = ctx.svar('not_equal_result');
        ctx.pushOp(LogicalNot(negated, result));
        result = negated;
      }
    } else {
      ctx.pushOp(
        InvokeDynamic(
          result,
          receiver.ssa,
          method,
          [
            ...prepared.map((arg) => arg.ssa),
            ...?namedArgs?.values.map((arg) => arg.boxIfNeeded(ctx).ssa),
          ],
          positionalCount: prepared.length,
          namedNames: namedArgs?.keys.toList() ?? const [],
          callerLibrary: ctx.library,
        ),
      );
    }
    final argTypes = prepared.map((arg) => arg.type).toList();
    final namedArgTypes =
        namedArgs?.map((key, arg) => MapEntry(key, arg.type)) ?? {};
    // The '.call' member on a bare Function-typed receiver can't resolve an
    // instance method; the callee's own signature carries the result type.
    final isBareCall =
        receiver.type.isFunctionLike && method == 'call';
    final TypeRef returnType;
    if (equality) {
      returnType = boolType;
    } else if (isBareCall) {
      returnType =
          resolveCallResultType(
            ctx,
            callee: receiver,
            dispatch: null,
            argTypes: argTypes,
            namedArgTypes: namedArgTypes,
          ) ??
          CoreTypes.dynamic.ref(ctx);
    } else {
      returnType =
          AlwaysReturnType.fromInstanceMethodOrBuiltin(
            ctx,
            receiver.type,
            method,
            argTypes,
            namedArgTypes,
          )?.type ??
          CoreTypes.dynamic.ref(ctx);
    }
    return InvokeResult(
      receiver,
      Variable.of(
        ctx,
        result,
        returnType,
        rep: equality ? unboxedRepOf(returnType) : ValueRep.boxed,
      ),
      prepared,
      namedArgs: namedArgs ?? {},
    );
  }

  InvokeResult _invokeAsFunction(
    CompilerContext ctx,
    List<Variable> args,
    Map<String, Variable>? namedArgs,
  ) {
    if (!type.isAssignableTo(ctx, CoreTypes.function.ref(ctx))) {
      // `x(...)` on a non-function is an implicit `x.call(...)`, which may
      // resolve to an extension `call` member.
      if (resolveExtensionMember(ctx, type, 'call', arity: args.length) !=
          null) {
        return invoke(ctx, 'call', args, namedArgs: namedArgs);
      }
      throw CompileError(
        'Cannot invoke variable of type $type as it is not a function',
      );
    }
    if (callingConvention == CallingConvention.dynamic ||
        methodOffset == null) {
      return invokeClosure(
        ctx,
        null,
        this,
        null,
        positional: args,
        named: namedArgs,
      );
    }
    final target = ctx.svar('call_result');
    final returnType =
        methodReturnType
            ?.toAlwaysReturnType(
              ctx,
              type,
              args.map((arg) => arg.type).toList(),
              namedArgs?.map((key, arg) => MapEntry(key, arg.type)) ?? {},
            )
            ?.type ??
        CoreTypes.dynamic.ref(ctx);
    ctx.pushOp(
      Call(methodOffset!, [
        ...args.map((arg) => arg.ssa),
        ...?namedArgs?.values.map((arg) => arg.ssa),
      ], result: target),
    );
    return InvokeResult(
      this,
      Variable.of(
        ctx,
        target,
        returnType,
        rep: Abi.unboxedAcrossCalls(returnType),
      ),
      args,
      namedArgs: namedArgs ?? {},
    );
  }
}
