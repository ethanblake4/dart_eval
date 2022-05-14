import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/declaration/declaration.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';

void compileClassDeclaration(CompilerContext ctx, ClassDeclaration d, {bool statics = false}) {
  final $runtimeType = ctx.typeRefIndexMap[TypeRef.lookupClassDeclaration(ctx, ctx.library, d)];
  ctx.instanceDeclarationPositions[ctx.library]![d.name.name] = [{}, {}, {}, $runtimeType];
  final constructors = <ConstructorDeclaration>[];
  final fields = <FieldDeclaration>[];
  final methods = <MethodDeclaration>[];
  for (final m in d.members) {
    if (m is ConstructorDeclaration) {
      constructors.add(m);
    } else if (m is FieldDeclaration) {
      if (!m.isStatic) {
        fields.add(m);
      }
    } else {
      m as MethodDeclaration;
      methods.add(m);
    }
  }
  var i = 0;
  for (final m in <ClassMember>[...fields, ...methods, ...constructors]) {
    ctx.resetStack(position: m is ConstructorDeclaration || (m is MethodDeclaration && m.isStatic) ? 0 : 1);
    ctx.currentClass = d;
    compileDeclaration(m, ctx, parent: d, fieldIndex: i, fields: fields);
    if (m is FieldDeclaration) {
      i += m.fields.variables.length;
    }
  }
  ctx.currentClass = null;
  ctx.resetStack();
}
