import 'package:control_flow_graph/control_flow_graph.dart' show Assign;
import 'package:dart_eval/src/eval/ir/objects.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/identifier.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import '../variable/value_facts.dart';

Variable compileThisExpression(ThisExpression e, CompilerContext ctx) {
  // In an anonymous-method body `this` is the anonymous receiver itself.
  // It is read through the `#this` local so that closures nested in the
  // body capture it like any other enclosing local.
  final anonymousReceiver = ctx.anonymousThisReceiver;
  final anonymousThis = anonymousReceiver == null
      ? null
      : ctx.lookupLocal('#this');
  if (anonymousThis != null) {
    return Variable.ssa(
      ctx,
      Assign(ctx.svar('this'), anonymousThis.ssa),
      anonymousThis.type,
      rep: anonymousThis.rep,
    );
  }
  if (anonymousReceiver != null) {
    return Variable.ssa(
      ctx,
      Assign(ctx.svar('this'), anonymousReceiver.ssa),
      anonymousReceiver.type,
      rep: anonymousReceiver.rep,
    );
  }
  // Extensions may use `this` for the receiver without a class context.
  if (ctx.lookupLocal('#this') == null) {
    throw CompileError("Cannot use 'this' outside of a class context");
  }
  final receiver = ctx.lookupLocal('#this')!;
  // In an extension or anonymous-method body, `this` is the receiver value
  // itself; LoadThis only exists to resolve the dispatch root of a class
  // instance.
  final operation = ctx.currentExtension == null
      ? LoadThis(ctx.svar('this'), receiver.ssa)
      : Assign(ctx.svar('this'), receiver.ssa);
  return Variable.ssa(ctx, operation, receiver.type, rep: receiver.rep);
}

Variable compileSuperExpression(SuperExpression e, CompilerContext ctx) {
  if (ctx.currentClass is! ClassDeclaration &&
      ctx.currentClass is! ClassTypeAlias) {
    throw CompileError("Cannot use 'super' outside of a class context");
  }

  TypeRef type = CoreTypes.object.ref(ctx);
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
    facts: ValueFacts(possibleClasses: [type]),
  );
  return v;
}
