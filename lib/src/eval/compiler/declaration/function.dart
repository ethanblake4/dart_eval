import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:collection/collection.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/helpers/async.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/helpers/fpl.dart';
import 'package:dart_eval/src/eval/compiler/model/function_type.dart';
import 'package:dart_eval/src/eval/compiler/helpers/return.dart';
import 'package:dart_eval/src/eval/compiler/model/override_spec.dart';

import 'package:dart_eval/src/eval/compiler/statement/block.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';

import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/ir/representation.dart';
import '../values/abi.dart';

void compileFunctionDeclaration(FunctionDeclaration d, CompilerContext ctx) {
  final pos = ctx.beginFunction('${d.name.lexeme}()');
  // Top-level accessors register under `*g`/`*s` like class members, so a
  // getter and setter of the same name don't collide.
  ctx.topLevelDeclarationPositions[ctx.library]![d.isGetter
          ? '${d.name.lexeme}*g'
          : d.isSetter
          ? '${d.name.lexeme}*s'
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
          ctx
                  .typeScopes[ctx.library]![parameter.name.lexeme]!
                  .typeParameterBound ??
              CoreTypes.dynamic.ref(ctx),
      ];

      final resolvedParams = resolveFPLDefaults(
        ctx,
        d.functionExpression.parameters,
        false,
        allowUnboxed: true,
      );

      var i = 0;
      final parameterRepresentations = <MachineRepresentation>[];

      for (final p in resolvedParams) {
        Variable vRep;

        var type = CoreTypes.dynamic.ref(ctx);
        if (p.type != null) {
          type = formalParameterAnnotationType(ctx, ctx.library, p);
        }
        vRep = Variable.of(
          ctx,
          SSA('arg_$i'),
          type,
          rep: Abi.parameter(type, CallableKind.function),
        );

        // `_` parameters are wildcards: non-binding and repeatable.
        if (p.name!.lexeme != '_') {
          ctx.setLocal(p.name!.lexeme, vRep.captureBinding(ctx, p));
        }
        parameterRepresentations.add(vRep.rep.bank);

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

      final expectedReturnType = AlwaysReturnType.fromAnnotation(
        ctx,
        ctx.library,
        d.returnType,
        CoreTypes.dynamic.ref(ctx),
      );
      final returnType = expectedReturnType.type;
      ctx.functionSignatures[pos] = MachineFunctionSignature(
        parameterRepresentations,
        returnType != null &&
                returnType.isSpec(CoreTypes.voidType) &&
                !b.isAsynchronous
            ? null
            : Abi.result(
                returnType ?? CoreTypes.dynamic.ref(ctx),
                CallableKind.function,
                isAsync: b.isAsynchronous,
              ).bank,
      );
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
            b.isAsynchronous && expectedReturnType.type != null
                ? ctx.typeSystem.flatten(expectedReturnType.type!)
                : expectedReturnType.type,
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
