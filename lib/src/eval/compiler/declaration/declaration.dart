// ignore_for_file: body_might_complete_normally_nullable

import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/declaration/class.dart';
import 'package:dart_eval/src/eval/compiler/declaration/constructor.dart';
import 'package:dart_eval/src/eval/compiler/declaration/enum.dart';
import 'package:dart_eval/src/eval/compiler/declaration/field.dart';
import 'package:dart_eval/src/eval/compiler/declaration/function.dart';
import 'package:dart_eval/src/eval/compiler/declaration/method.dart';
import 'package:dart_eval/src/eval/compiler/declaration/variable.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';

int? compileDeclaration(
  Declaration d,
  CompilerContext ctx, {
  Declaration? parent,
  int? fieldIndex,
  List<FieldDeclaration>? fields,
}) {
  if (d is ClassDeclaration) {
    compileClassDeclaration(ctx, d);
  } else if (d is EnumDeclaration) {
    compileEnumDeclaration(ctx, d);
  } else if (d is MethodDeclaration) {
    return compileMethodDeclaration(d, ctx, parent!);
  } else if (d is FunctionDeclaration) {
    compileFunctionDeclaration(d, ctx);
  } else if (d is FieldDeclaration) {
    compileFieldDeclaration(fieldIndex!, d, ctx, parent!);
  } else if (d is ConstructorDeclaration) {
    compileConstructorDeclaration(ctx, d, parent!, fields!);
  } else if (d is VariableDeclaration) {
    compileTopLevelVariableDeclaration(d, ctx);
  } else if (d is EnumConstantDeclaration) {
    // do nothing
  } else {
    throw CompileError('No support for ${d.runtimeType}');
  }
}

/// Partitions a class-like body's members into constructors, instance fields,
/// and methods (static fields are handled as globals, not instance members).
(List<ConstructorDeclaration>, List<FieldDeclaration>, List<MethodDeclaration>)
partitionClassMembers(List<ClassMember> members) {
  final constructors = <ConstructorDeclaration>[];
  final fields = <FieldDeclaration>[];
  final methods = <MethodDeclaration>[];
  for (final m in members) {
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
  return (constructors, fields, methods);
}

/// Compiles members in declaration order — fields first, then methods, then
/// constructors — tracking [fieldIndex] across field declarations so each
/// instance field lands at a stable slot.
void compileClassMembers(
  CompilerContext ctx,
  Declaration parent, {
  required List<ConstructorDeclaration> constructors,
  required List<FieldDeclaration> fields,
  required List<MethodDeclaration> methods,
  int firstFieldIndex = 0,
}) {
  var fieldIndex = firstFieldIndex;
  for (final m in <ClassMember>[...fields, ...methods, ...constructors]) {
    ctx.currentClass = parent;
    compileDeclaration(
      m,
      ctx,
      parent: parent,
      fieldIndex: fieldIndex,
      fields: fields,
    );
    if (m is FieldDeclaration) {
      fieldIndex += m.fields.variables.length;
    }
  }
}
