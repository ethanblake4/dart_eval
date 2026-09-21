import 'package:dart_eval/src/eval/ir/objects.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/identifier.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

Variable compileThisExpression(ThisExpression e, CompilerContext ctx) {
  if (ctx.currentClass == null) {
    throw CompileError("Cannot use 'this' outside of a class context");
  }
  final receiver = ctx.lookupLocal('#this')!;
  return Variable.ssa(
    ctx,
    LoadThis(ctx.svar('this'), receiver.ssa),
    receiver.type,
  );
}

Variable compileSuperExpression(SuperExpression e, CompilerContext ctx) {
  if (ctx.currentClass is! ClassDeclaration &&
      ctx.currentClass is! ClassTypeAlias) {
    throw CompileError("Cannot use 'super' outside of a class context");
  }

  var type = CoreTypes.object.ref(ctx);
  // `super` binds below the member's own layer: for a member folded in from a
  // mixin that's the earlier `with` mixins then the applying class's
  // superclass, so the static type here is that superclass.
  final lib = ctx.enclosingLibrary ?? ctx.library;
  final extendsNamed = classLikeClauses(ctx.currentClass).$1;
  if (extendsNamed != null) {
    type =
        clauseNamedType(ctx, lib, extendsNamed) ??
        (throw CompileError(
          'Unknown supertype ${extendsNamed.name.value()}',
          extendsNamed,
        ));
  }

  final $this = ctx.lookupLocal('#this')!;
  final v = Variable.ssa(
    ctx,
    LoadSuper(ctx.svar('super'), $this.ssa),
    type,
    concreteTypes: [type],
  );
  return v;
}
