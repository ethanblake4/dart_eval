import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/declaration/constructor.dart';
import 'package:dart_eval/src/eval/compiler/declaration/declaration.dart';
import 'package:dart_eval/src/eval/compiler/declaration/field.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';

void compileClassDeclaration(CompilerContext ctx, ClassDeclaration d,
    {bool statics = false}) {
  final $runtimeType =
      ctx.typeRefIndexMap[TypeRef.lookupDeclaration(ctx, ctx.library, d)];
  final clsName = d.name.lexeme;
  ctx.instanceDeclarationPositions[ctx.library]![clsName] = [
    {},
    {},
    {},
    $runtimeType
  ];
  ctx.instanceGetterIndices[ctx.library]![clsName] = {};
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
  if (constructors.isEmpty) {
    ctx.resetStack(position: 0);
    ctx.currentClass = d;
    compileDefaultConstructor(ctx, d, fields);
  }
  for (final m in <ClassMember>[...fields, ...methods, ...constructors]) {
    ctx.resetStack(
        position: m is ConstructorDeclaration ||
                (m is MethodDeclaration && m.isStatic)
            ? 0
            : 1);
    ctx.currentClass = d;
    compileDeclaration(m, ctx, parent: d, fieldIndex: i, fields: fields);
    if (m is FieldDeclaration) {
      i += m.fields.variables.length;
    }
  }
  ctx.currentClass = null;
  ctx.resetStack();
}

/// Compiles only the class structure (type registration and static fields)
/// without compiling methods, constructors, or instance fields
void compileClassStructure(ClassDeclaration d, CompilerContext ctx) {
  // PRIMEIRO: Registrar tipos genéricos se existirem
  ctx.temporaryTypes[ctx.library] ??= {};

  // SEGUNDO: Criar e registrar o tipo básico nos visibleTypes
  final basicTypeRef = TypeRef.cache(ctx, ctx.library, d.name.lexeme);
  ctx.visibleTypes[ctx.library] ??= {};
  ctx.visibleTypes[ctx.library]![d.name.lexeme] = basicTypeRef;

  // TERCEIRO: Resolver a cadeia de tipos (agora que tipos genéricos estão registrados)
  final resolvedType = basicTypeRef.resolveTypeChain(ctx);

  // QUARTO: Atualizar com o tipo resolvido
  ctx.visibleTypes[ctx.library]![d.name.lexeme] = resolvedType;

  final $runtimeType = ctx.typeRefIndexMap[basicTypeRef];
  final clsName = d.name.lexeme;
  ctx.instanceDeclarationPositions[ctx.library]![clsName] = [
    {},
    {},
    {},
    $runtimeType
  ];
  ctx.instanceGetterIndices[ctx.library]![clsName] = {};

  // Compile only static fields
  ctx.currentClass = d;
  for (final member in d.members) {
    if (member is FieldDeclaration && member.isStatic) {
      compileFieldDeclaration(-1, member, ctx, d);
      ctx.resetStack();
    }
  }
  ctx.currentClass = null;
}

/// Compiles all methods, constructors, and instance fields of a class
/// This should be called after all enums and class structures are compiled
void compileClassMethods(ClassDeclaration d, CompilerContext ctx) {
  // Carregar tipos temporários para suporte a generics de classes ANTES de qualquer processamento
  // Isso deve acontecer antes de qualquer análise de tipos
  if (d.typeParameters?.typeParameters != null) {
    for (final param in d.typeParameters!.typeParameters) {
      ctx.temporaryTypes[ctx.library] ??= {};
      final name = param.name.lexeme;

      // Sempre criar um TypeRef para o tipo genérico, não o bound
      // O bound é usado para verificações de tipo, não para o tipo em si
      ctx.temporaryTypes[ctx.library]![name] =
          TypeRef.cache(ctx, ctx.library, name);
    }
  }

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
    } else if (m is MethodDeclaration) {
      methods.add(m);
    }
  }

  var i = 0;
  if (constructors.isEmpty) {
    ctx.resetStack(position: 0);
    ctx.currentClass = d;
    compileDefaultConstructor(ctx, d, fields);
  }

  for (final m in <ClassMember>[...fields, ...methods, ...constructors]) {
    ctx.resetStack(
        position: m is ConstructorDeclaration ||
                (m is MethodDeclaration && m.isStatic)
            ? 0
            : 1);
    ctx.currentClass = d;
    compileDeclaration(m, ctx, parent: d, fieldIndex: i, fields: fields);
    if (m is FieldDeclaration) {
      i += m.fields.variables.length;
    }
  }
  ctx.currentClass = null;
}
