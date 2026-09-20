import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/declaration/constructor.dart';
import 'package:dart_eval/src/eval/compiler/declaration/declaration.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';

void compileClassDeclaration(CompilerContext ctx, ClassDeclaration d) {
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
  final (constructors, fields, methods) = partitionClassMembers(d.body.members);
  if (constructors.isEmpty) {
    ctx.currentClass = d;
    compileDefaultConstructor(ctx, d, fields);
  }
  compileClassMembers(
    ctx,
    d,
    constructors: constructors,
    fields: fields,
    methods: methods,
  );
  ctx.currentClass = null;
  ctx.temporaryTypes[ctx.library] = previousTypes;
}
