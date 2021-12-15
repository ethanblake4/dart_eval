import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/declaration/declaration.dart';

void compileClassDeclaration(CompilerContext ctx, ClassDeclaration d) {
  ctx.instanceDeclarationPositions[ctx.library]![d.name.name] = [{}, {}, {}];
  final constructors = <ConstructorDeclaration>[];
  final fields = <FieldDeclaration>[];
  final methods = <MethodDeclaration>[];
  for (final m in d.members) {
    if (m is ConstructorDeclaration) {
      constructors.add(m);
    } else if (m is FieldDeclaration) {
      fields.add(m);
    } else {
      m as MethodDeclaration;
      methods.add(m);
    }
  }
  var i = 0;
  for (final m in <ClassMember>[...fields, ...methods, ...constructors]) {
    ctx.resetStack(position: m is ConstructorDeclaration ? 0 : 1);
    ctx.inInstanceCode = !(m is ConstructorDeclaration);
    compileDeclaration(m, ctx, parent: d, fieldIndex: i, fields: fields);
    if (m is FieldDeclaration) {
      i += m.fields.length - 1;
    }
    i++;
  }
  ctx.inInstanceCode = false;
  ctx.resetStack();
}