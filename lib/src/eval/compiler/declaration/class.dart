import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/declaration/constructor.dart';
import 'package:dart_eval/src/eval/compiler/declaration/declaration.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';

void compileClassDeclaration(
  CompilerContext ctx,
  ClassDeclaration d, {
  bool statics = false,
}) {
  final previousTypes = {...?ctx.temporaryTypes[ctx.library]};
  TypeRef.loadTemporaryTypes(
    ctx,
    d.namePart.typeParameters?.typeParameters,
    library: ctx.library,
    owner: 'class:${ctx.library}:${d.namePart.typeName.lexeme}',
  );
  final $runtimeType =
      ctx.typeRefIndexMap[TypeRef.lookupDeclaration(ctx, ctx.library, d)];
  final clsName = d.namePart.typeName.lexeme;
  ctx.instanceDeclarationPositions[ctx.library]![clsName] = [
    {},
    {},
    {},
    $runtimeType,
  ];
  ctx.instanceGetterIndices[ctx.library]![clsName] = {};
  final constructors = <ConstructorDeclaration>[];
  final fields = <FieldDeclaration>[];
  final methods = <MethodDeclaration>[];
  for (final m in d.body.members) {
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
  if (constructors.isEmpty) {
    ctx.currentClass = d;
    compileDefaultConstructor(ctx, d, fields);
  }
  for (final m in <ClassMember>[...fields, ...methods, ...constructors]) {
    ctx.currentClass = d;
    compileDeclaration(m, ctx, parent: d, fieldIndex: i, fields: fields);
    if (m is FieldDeclaration) {
      i += m.fields.variables.length;
    }
  }
  ctx.currentClass = null;
  ctx.temporaryTypes[ctx.library] = previousTypes;
}
