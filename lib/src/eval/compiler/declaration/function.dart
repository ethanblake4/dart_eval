import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:collection/collection.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/helpers/async.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/helpers/fpl.dart';
import 'package:dart_eval/src/eval/compiler/helpers/return.dart';
import 'package:dart_eval/src/eval/compiler/model/override_spec.dart';

import 'package:dart_eval/src/eval/compiler/statement/block.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';

import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import '../values/abi.dart';
import '../member/member_name.dart';

void compileFunctionDeclaration(FunctionDeclaration d, CompilerContext ctx) {
  final pos = ctx.beginFunction('${d.name.lexeme}()');
  // Top-level accessors register under `*g`/`*s` like class members, so a
  // getter and setter of the same name don't collide.
  ctx.topLevelDeclarationPositions[ctx.library]![d.isGetter
          ? MemberName.getter(d.name.lexeme).key
          : d.isSetter
          ? MemberName.setter(d.name.lexeme).key
          : d.name.lexeme] =
      pos;

  final overrideAnno = d.metadata.firstWhereOrNull(
    (element) => element.name.name == 'RuntimeOverride',
  );
  if (overrideAnno != null) {
    final oArgs = overrideAnno.arguments!.arguments;
    final name = oArgs.first as StringLiteral;
    String? version;
    if (oArgs.length == 2) {
      final exp = (oArgs[1] as NamedArgument);
      if (exp.name.lexeme != 'version') {
        throw CompileError(
          'Invalid @RuntimeOverride annotation',
          d,
          ctx.library,
          ctx,
        );
      }
      final version0 = exp.argumentExpression as StringLiteral;
      version = version0.stringValue;
    }
    final overrideName = name.stringValue!;
    ctx.runtimeOverrideMap[overrideName] = OverrideSpec(
      pos,
      version ?? '<${ctx.version}',
    );
  }

  ctx.beginScope();
  final typeParameters =
      d.functionExpression.typeParameters?.typeParameters ??
      const <TypeParameter>[];
  final b = d.functionExpression.body;
  final stInfo = ctx.withTypeParameters(
    ctx.library,
    TypeParameterOwner(
      TypeParameterOwnerKind.function,
      ctx.library,
      d.name.lexeme,
      pos,
    ),
    typeParameters,
    () {
      ctx.functionTypeParameterBounds[pos] = [
        for (final parameter in typeParameters)
          (ctx.typeScopes[ctx.library]![parameter.name.lexeme]!
                      as TypeParameterTypeRef)
                  .parameter
                  .bound ??
              CoreTypes.dynamic.ref(ctx),
      ];

      final resolvedParams = resolveFPLDefaults(
        ctx,
        d.functionExpression.parameters,
        false,
        allowUnboxed: true,
      );

      final expectedReturnType = d.returnType == null
          ? CoreTypes.dynamic.ref(ctx)
          : TypeRef.fromAnnotation(ctx, ctx.library, d.returnType!);
      final parameterTypes = ctx.functionParameterTypes[pos]!;
      final abi = CallableAbi.fromParameterTypes(
        parameterTypes,
        expectedReturnType,
        CallableKind.function,
        isAsync: b.isAsynchronous,
        returnsVoid: expectedReturnType.isSpec(CoreTypes.voidType),
      );
      var i = 0;

      for (final p in resolvedParams) {
        final type = parameterTypes[i];
        final vRep = Variable.of(
          ctx,
          SSA('arg_$i'),
          type,
          rep: abi.parameters[i],
        );

        // `_` parameters are wildcards: non-binding and repeatable.
        if (p.name!.lexeme != '_') {
          ctx.setLocal(p.name!.lexeme, vRep).captureBinding(ctx, p);
        }
        i++;
      }

      if (b.isAsynchronous) {
        setupAsyncFunction(
          ctx,
          returnType: d.returnType == null
              ? null
              : TypeRef.fromAnnotation(ctx, ctx.library, d.returnType!),
        );
      }

      ctx.functionSignatures[pos] = abi.machine;
      StatementInfo? stInfo;
      if (b is BlockFunctionBody) {
        stInfo = compileBlock(
          b.block,
          expectedReturnType,
          ctx,
          name: '${d.name.lexeme}()',
        );
      } else if (b is ExpressionFunctionBody) {
        ctx.beginScope();
        stInfo = doReturn(
          ctx,
          expectedReturnType,
          compileExpression(
            b.expression,
            ctx,
            // An async body's context type is the *flattened* return type.
            b.isAsynchronous
                ? ctx.typeSystem.flatten(expectedReturnType)
                : expectedReturnType,
          ),
          isAsync: b.isAsynchronous,
        );
        stInfo = StatementInfo(willAlwaysReturn: true);
        ctx.endScope();
      } else {
        throw CompileError('Unsupported function body type: ${b.runtimeType}');
      }
      return stInfo;
    },
  );

  if (!(stInfo.willAlwaysReturn || stInfo.willAlwaysThrow)) {
    if (b.isAsynchronous) {
      asyncComplete(ctx, null);
      ctx.endScope();
      return;
    }
  }

  ctx.endScope();

  if (!(stInfo.willAlwaysReturn || stInfo.willAlwaysThrow)) {
    ctx.pushOp(Return(null));
  }
}
