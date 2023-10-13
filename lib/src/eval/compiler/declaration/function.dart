import 'package:analyzer/dart/ast/ast.dart';
import 'package:collection/collection.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/helpers/fpl.dart';
import 'package:dart_eval/src/eval/compiler/helpers/return.dart';
import 'package:dart_eval/src/eval/compiler/model/override_spec.dart';
import 'package:dart_eval/src/eval/compiler/scope.dart';
import 'package:dart_eval/src/eval/compiler/statement/block.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/util.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

void compileFunctionDeclaration(FunctionDeclaration d, CompilerContext ctx) {
  ctx.runPrescan(d);
  final pos = beginMethod(ctx, d, d.offset, '${d.name.value() as String}()');
  ctx.topLevelDeclarationPositions[ctx.library]![d.name.value() as String] =
      pos;

  final overrideAnno = d.metadata
      .firstWhereOrNull((element) => element.name.name == 'RuntimeOverride');
  if (overrideAnno != null) {
    final oArgs = overrideAnno.arguments!.arguments;
    final name = oArgs.first as StringLiteral;
    String? version;
    if (oArgs.length == 2) {
      final exp = (oArgs[1] as NamedExpression);
      if (exp.name.label.name != 'version') {
        throw CompileError(
            'Invalid @RuntimeOverride annotation', d, ctx.library, ctx);
      }
      final _version = exp.expression as StringLiteral;
      version = _version.stringValue;
    }
    final overrideName = name.stringValue!;
    ctx.runtimeOverrideMap[overrideName] =
        OverrideSpec(pos, version ?? '<${ctx.version}');
  }

  final _existingAllocs =
      d.functionExpression.parameters?.parameters.length ?? 0;
  ctx.beginAllocScope(existingAllocLen: _existingAllocs);
  ctx.scopeFrameOffset += _existingAllocs;
  final resolvedParams = resolveFPLDefaults(
      ctx, d.functionExpression.parameters!, false,
      allowUnboxed: true);

  var i = 0;

  for (final param in resolvedParams) {
    final p = param.parameter;
    Variable Vrep;

    p as SimpleFormalParameter;
    var type = CoreTypes.dynamic.ref(ctx);
    if (p.type != null) {
      type = TypeRef.fromAnnotation(ctx, ctx.library, p.type!);
    }
    Vrep = Variable(
        i, type.copyWith(boxed: !type.isUnboxedAcrossFunctionBoundaries))
      ..name = p.name!.value() as String;

    ctx.setLocal(Vrep.name!, Vrep);

    i++;
  }

  final b = d.functionExpression.body;

  if (b.isAsynchronous) {
    setupAsyncFunction(ctx);
  }

  final expectedReturnType = AlwaysReturnType.fromAnnotation(
      ctx, ctx.library, d.returnType, CoreTypes.dynamic.ref(ctx));
  StatementInfo? stInfo;
  if (b is BlockFunctionBody) {
    stInfo = compileBlock(b.block, expectedReturnType, ctx,
        name: '${d.name.value() as String}()');
  } else if (b is ExpressionFunctionBody) {
    ctx.beginAllocScope();
    stInfo = doReturn(ctx, expectedReturnType,
        compileExpression(b.expression, ctx, expectedReturnType.type),
        isAsync: b.isAsynchronous);
    stInfo = StatementInfo(-1, willAlwaysReturn: true);
    ctx.endAllocScope(popValues: false);
  } else {
    throw CompileError('Unsupported function body type: ${b.runtimeType}');
  }

  if (!(stInfo.willAlwaysReturn || stInfo.willAlwaysThrow)) {
    if (b.isAsynchronous) {
      asyncComplete(ctx, -1);
      return;
    }
  }

  ctx.endAllocScope();

  if (!(stInfo.willAlwaysReturn || stInfo.willAlwaysThrow)) {
    ctx.pushOp(Return.make(-1), Return.LEN);
  }
}
