import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/scope.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

void compileFieldDeclaration(int fieldIndex, FieldDeclaration d, CompilerContext ctx, ClassDeclaration parent) {
  var _fieldIndex = fieldIndex;
  for (final field in d.fields.variables) {
    final pos = beginMethod(ctx, d, d.offset, parent.name.name + '.' + field.name.name + ' (get)');
    ctx.pushOp(PushObjectPropertyImpl.make(0, _fieldIndex), PushObjectPropertyImpl.LEN);
    ctx.pushOp(Return.make(1), Return.LEN);
    ctx.instanceDeclarationPositions[ctx.library]![parent.name.name]![0][field.name.name] = pos;

    if (!(field.isFinal || field.isConst)) {
      final setterPos = beginMethod(ctx, d, d.offset, parent.name.name + '.' + field.name.name + ' (set)');
      ctx.pushOp(SetObjectPropertyImpl.make(0, _fieldIndex, 1), SetObjectPropertyImpl.LEN);
      ctx.pushOp(Return.make(1), Return.LEN);
      ctx.instanceDeclarationPositions[ctx.library]![parent.name.name]![1][field.name.name] = setterPos;
    }

    _fieldIndex++;
  }
}
