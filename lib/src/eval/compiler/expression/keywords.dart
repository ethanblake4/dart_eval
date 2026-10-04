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
    )..binding = anonymousThis.binding;
  }
  if (anonymousReceiver != null) {
    return Variable.ssa(
      ctx,
      Assign(ctx.svar('this'), anonymousReceiver.ssa),
      anonymousReceiver.type,
      rep: anonymousReceiver.rep,
    )..binding = anonymousReceiver.binding;
  }
  // Extensions may use `this` for the receiver without a class context.
  if (ctx.lookupLocal('#this') == null) {
    throw CompileError("Cannot use 'this' outside of a class context");
  }
  final receiver = ctx.lookupLocal('#this')!;
  // In an extension or anonymous-method body, `this` is the receiver value
  // itself; LoadThis only exists to resolve the dispatch root of a class
  // instance.
  final operation =
      ctx.currentExtension == null &&
          ctx.currentClass is! ExtensionTypeDeclaration
      ? LoadThis(ctx.svar('this'), receiver.ssa)
      : Assign(ctx.svar('this'), receiver.ssa);
  final value = Variable.ssa(
    ctx,
    operation,
    receiver.type,
    rep: receiver.rep,
    facts: receiver.facts,
  );
  // LoadThis produces the dispatch root, not #this's lexical storage link.
  // A binding would let boxing replace that result with the lexical link.
  // Copy the flow facts so this-member promotions still apply to the root.
  if (operation is! LoadThis) value.binding = receiver.binding;
  return value;
}

Variable compileSuperExpression(SuperExpression e, CompilerContext ctx) {
  if (ctx.currentClass is! ClassDeclaration &&
      ctx.currentClass is! ClassTypeAlias &&
      ctx.currentClass is! EnumDeclaration) {
    throw CompileError("Cannot use 'super' outside of a class context");
  }

  TypeRef type = ctx.currentClass is EnumDeclaration
      ? CoreTypes.enumType.ref(ctx)
      : CoreTypes.object.ref(ctx);
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
  // Enum protocol fields share the enum's own storage; there is no guest
  // superclass object to load.
  if (ctx.currentClass is EnumDeclaration) {
    return Variable.of(ctx, $this.ssa, type, rep: $this.rep);
  }
  return Variable.ssa(
    ctx,
    LoadSuper(ctx.svar('super'), $this.ssa),
    type,
    facts: ValueFacts(possibleClasses: [type]),
  );
}
