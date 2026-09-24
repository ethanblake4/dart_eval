// ignore_for_file: body_might_complete_normally_nullable

import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/helpers/mixin_application.dart';
import 'package:dart_eval/src/eval/compiler/declaration/class.dart';
import 'package:dart_eval/src/eval/compiler/declaration/constructor.dart';
import 'package:dart_eval/src/eval/compiler/declaration/enum.dart';
import 'package:dart_eval/src/eval/compiler/declaration/field.dart';
import 'package:dart_eval/src/eval/compiler/declaration/function.dart';
import 'package:dart_eval/src/eval/compiler/declaration/method.dart';
import 'package:dart_eval/src/eval/compiler/declaration/variable.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/member/member_name.dart';

int? compileDeclaration(
  Declaration d,
  CompilerContext ctx, {
  Declaration? parent,
  int? fieldIndex,
  List<FieldDeclaration>? fields,
  Map<ClassMember, int> memberLibraries = const {},
}) {
  if (d is ClassDeclaration) {
    compileClassDeclaration(ctx, d);
  } else if (d is EnumDeclaration) {
    compileEnumDeclaration(ctx, d);
  } else if (d is MixinDeclaration) {
    compileMixinDeclaration(ctx, d);
  } else if (d is ClassTypeAlias) {
    compileClassTypeAlias(ctx, d);
  } else if (d is MethodDeclaration) {
    return compileMethodDeclaration(d, ctx, parent!);
  } else if (d is FunctionDeclaration) {
    compileFunctionDeclaration(d, ctx);
  } else if (d is FieldDeclaration) {
    compileFieldDeclaration(fieldIndex!, d, ctx, parent!);
  } else if (d is ConstructorDeclaration) {
    compileConstructorDeclaration(
      ctx,
      d,
      parent!,
      fields!,
      memberLibraries: memberLibraries,
    );
  } else if (d is VariableDeclaration) {
    compileTopLevelVariableDeclaration(d, ctx);
  } else if (d is EnumConstantDeclaration) {
    // do nothing
  } else if (d is TypeAlias) {
    // Typedefs are compile-time-only; resolved lazily in TypeRef.fromAnnotation.
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
  // For members folded in from a mixin: the member's declaring library, so
  // its body resolves identifiers and types where it was written.
  Map<ClassMember, int> memberLibraries = const {},
}) {
  var fieldIndex = firstFieldIndex;
  final foldedBodies = <FoldedMemberBody>[];
  Declaration? layerOwner;
  final layerMembers = <MethodDeclaration>{};
  var layer = 0;
  for (final m in <ClassMember>[...fields, ...methods, ...constructors]) {
    ctx.currentClass = parent;
    final previousLibrary = ctx.library;
    final previousSuperMembers = ctx.lexicalSuperMembers;
    final memberLibrary = memberLibraries[m];
    ctx.library = memberLibrary ?? previousLibrary;
    final memberOwner = m.parent?.parent;
    ctx.memberDeclaringClass =
        memberLibrary != null && memberOwner is Declaration
        ? memberOwner
        : null;
    if (m is MethodDeclaration) {
      // The same AST member can be folded more than once (for example
      // `with B, B`). A repeated declaration starts a new application
      // layer, while sibling members in one layer share its identity.
      if (!identical(layerOwner, memberOwner) || !layerMembers.add(m)) {
        layer++;
        layerOwner = memberOwner is Declaration ? memberOwner : null;
        layerMembers
          ..clear()
          ..add(m);
      }
      // `super` in a mixin body starts below that mixin's entire layer;
      // `super` in an applying class starts at the last folded layer.
      ctx.lexicalSuperMembers = {
        for (final body in foldedBodies)
          if (body.layer < layer &&
              (!body.declaration.name.lexeme.startsWith('_') ||
                  body.library == ctx.library))
            MemberName(
              body.declaration.name.lexeme,
              body.declaration.isGetter
                  ? MemberKind.getter
                  : body.declaration.isSetter
                  ? MemberKind.setter
                  : MemberKind.method,
            ).key: body,
      };
    }
    int? position;
    try {
      if (memberLibrary == null) {
        position = compileDeclaration(
          m,
          ctx,
          parent: parent,
          fieldIndex: fieldIndex,
          fields: fields,
          memberLibraries: memberLibraries,
        );
      } else {
        // A member folded in from a mixin (possibly through a chain of
        // mixin applications) rebinds the declaring mixin's type
        // parameters to this application's arguments, so `T` in its body
        // resolves against the applying class's type environment. The
        // seed lives in a pushed frame of the member's declaring-library
        // scope — it pops when the member finishes compiling.
        position = ctx.withTypeParameters(memberLibrary, null, const [], () {
          ctx
              .typeParameterScope(memberLibrary)
              .addAll(
                foldedMemberTypeParams(
                      ctx,
                      parent,
                      m,
                      memberLibrary,
                      previousLibrary,
                    ) ??
                    const {},
              );
          return compileDeclaration(
            m,
            ctx,
            parent: parent,
            fieldIndex: fieldIndex,
            fields: fields,
            memberLibraries: memberLibraries,
          );
        });
      }
    } finally {
      ctx.library = previousLibrary;
      ctx.memberDeclaringClass = null;
      ctx.lexicalSuperMembers = previousSuperMembers;
    }
    if (m is MethodDeclaration &&
        memberLibrary != null &&
        !m.isStatic &&
        m.isComplete &&
        position != null &&
        position >= 0) {
      foldedBodies.add((
        declaration: m,
        library: memberLibrary,
        offset: position,
        layer: layer,
      ));
    }
    if (m is FieldDeclaration) {
      fieldIndex += m.fields.variables.length;
    }
  }
}
