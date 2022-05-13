import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/scope.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

void compileTopLevelVariableDeclaration(VariableDeclaration v, CompilerContext ctx) {
  final parent = v.parent!.parent! as TopLevelVariableDeclaration;

  final initializer = v.initializer;
  if (initializer != null) {
    final pos = beginMethod(ctx, v, v.offset, v.name.name + ' (init)');
    var V = compileExpression(initializer, ctx);
    TypeRef type;
    final specifiedType = parent.variables.type;
    if (specifiedType != null) {
      type = TypeRef.fromAnnotation(ctx, ctx.library, specifiedType);
      if (!V.type.isAssignableTo(ctx, type)) {
        throw CompileError('Variable ${v.name.name} of inferred type ${V.type} does not conform to type $type');
      }
    } else {
      type = V.type;
    }
    if (!unboxedAcrossFunctionBoundaries.contains(type)) {
      V = V.boxIfNeeded(ctx);
      type = type.copyWith(boxed: true);
    }
    final _index = ctx.topLevelGlobalIndices[ctx.library]![v.name.name]!;
    ctx.pushOp(SetGlobal.make(_index, V.scopeFrameOffset), SetGlobal.LEN);
    ctx.topLevelVariableInferredTypes[ctx.library]![v.name.name] = type;
    ctx.topLevelGlobalInitializers[ctx.library]![v.name.name] = pos;
    ctx.runtimeGlobalInitializerMap[_index] = pos;
    ctx.pushOp(Return.make(V.scopeFrameOffset), Return.LEN);
  }
}
