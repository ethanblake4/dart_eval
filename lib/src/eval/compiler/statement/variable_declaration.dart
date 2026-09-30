import 'package:control_flow_graph/control_flow_graph.dart' show Assign;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/helpers/conversion.dart';
import 'package:dart_eval/src/eval/compiler/helpers/promotion.dart';

import '../errors.dart';
import '../type.dart';
import '../variable.dart';
import 'statement.dart';
import '../values/abi.dart';

StatementInfo compileVariableDeclarationStatement(
  VariableDeclarationStatement s,
  CompilerContext ctx,
) {
  compileVariableDeclarationList(s.variables, ctx);
  return StatementInfo();
}

void compileVariableDeclarationList(
  VariableDeclarationList l,
  CompilerContext ctx,
) {
  TypeRef? type;
  if (l.type != null) {
    type = TypeRef.fromAnnotation(ctx, ctx.library, l.type!);
  }

  for (final li in l.variables) {
    // A local `_` is a wildcard: non-binding and repeatable in one scope.
    // (Top-level and member `_` declarations are still binding.)
    final isWildcard = li.name.lexeme == '_';
    if (ctx.locals.last.containsKey(li.name.lexeme) && !isWildcard) {
      throw CompileError(
        'Cannot declare variable ${li.name.lexeme}'
        ' multiple times in the same scope',
      );
    }
    final init = li.initializer;

    if (init != null) {
      // A `late` initializer evaluates after the declaration — recorded
      // condition promotions can't apply inside it.
      if (l.lateKeyword != null) ctx.lateInitializerDepth++;
      Variable res;
      try {
        res = compileExpression(init, ctx, type);
      } finally {
        if (l.lateKeyword != null) ctx.lateInitializerDepth--;
      }
      // The initializer's own type — conversion may widen it to the declared
      // type, but promotion uses the value's type.
      final initType = res.type;
      if (type != null) {
        res = convertForAssignment(
          ctx,
          res,
          type,
          representation: Abi.unboxedAcrossCalls(type).bank,
          source: li,
          description:
              'Type mismatch: variable "${li.name.lexeme}" is specified as '
              'type $type, but is initialized to ${res.type}',
        );
      }
      if (Abi.unboxedAcrossCalls(type ?? res.type).isBoxed) {
        // Box into a fresh slot: the producer's SSA keeps its unboxed rep
        // (in-place boxing would redefine it).
        res = res.boxIntoFreshSlot(ctx);
      }
      if (isWildcard) {
        // Evaluate for side effects only; the wildcard binds nothing.
        continue;
      }
      final local = res.copyWith(
        name: ctx.svar(li.name.lexeme).name,
        type: type ?? ctx.typeFactory.widenedInferredType(res.type),
        isConst: l.isConst,
      );
      ctx.pushOp(Assign(local.ssa, res.ssa));
      ctx
          .setLocal(
            li.name.lexeme,
            local,
            declaredType: type ?? ctx.typeFactory.widenedInferredType(res.type),
            isFinal: l.isFinal || l.isConst,
          )
          .captureBinding(ctx, li);
      // Initialization promotes like an assignment: only a *nullable*
      // declared type promotes, to `NonNull(declared)` — `int? x = 0` leaves
      // `x` promoted to `int`, `num? w = 0.5` to `num`, and `Object x = 0`
      // stays `Object`. `late` and captured locals never promote.
      final binding = ctx.lookupBinding(li.name.lexeme);
      if (binding != null &&
          type != null &&
          type.nullable &&
          l.lateKeyword == null &&
          !binding.writeCaptured &&
          !initType.isSpec(CoreTypes.dynamic) &&
          initType.isAssignableTo(ctx, type.withNullable(false))) {
        binding.rebind(
          binding.current.withType(type.withNullable(false)),
        );
      }
      // `b = cond` records the condition's promotions on `b` — `if (b)`
      // then applies them (promotion through bool locals). Before
      // dart-lang/language#1785 (Dart 2.14) the record required a
      // `bool`/`dynamic` annotation; since then any declaration records
      // when the initializer is bool-typed — even `Object b = cond` —
      // so `b is bool && b` can promote. `late` initializers defer
      // evaluation and never record.
      final recordsBool = initType.isSpec(CoreTypes.bool) &&
          (ctx.languageVersionAtLeast(li, 2, 14) ||
              (type != null &&
                  (type.isSpec(CoreTypes.bool) ||
                      type.isSpec(CoreTypes.dynamic))));
      if (binding != null &&
          l.lateKeyword == null &&
          !binding.writeCaptured &&
          recordsBool) {
        final (whenTrue, whenFalse) = conditionPromotions(ctx, init);
        if (whenTrue.isNotEmpty || whenFalse.isNotEmpty) {
          binding.rebind(
            binding.current.withFacts(
              binding.current.facts.copyWith(
                truePromotions: whenTrue,
                falsePromotions: whenFalse,
              ),
            ),
          );
        }
      }
    } else {
      if (isWildcard) continue;
      ctx
          .setLocal(
            li.name.lexeme,
            BuiltinValue()
                .push(ctx)
                .boxIfNeeded(ctx)
                .copyWith(
                  type: type ?? CoreTypes.dynamic.ref(ctx),
                  rep: ValueRep.boxed,
                ),
            declaredType: type ?? CoreTypes.dynamic.ref(ctx),
            isFinal: l.isFinal || l.isConst,
            // An uninitialized `final`/`const` binding accepts its first
            // write through the initialized flag, not allocation facts.
            initialized: !(l.isFinal || l.isConst),
          )
          .captureBinding(ctx, li);
    }
  }
}
