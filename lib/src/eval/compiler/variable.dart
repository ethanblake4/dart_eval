import 'backend/representation.dart'
    show MachineRepresentation, representationForType;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/function.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable/value_facts.dart';
import 'package:dart_eval/src/eval/compiler/variable/binding.dart';
import 'package:dart_eval/src/eval/ir/primitives.dart';

import 'errors.dart';
import 'invocation/deferred.dart';
import 'member/call_signature.dart';
import 'values/abi.dart';

/// A compiler value with an SSA identity, language type and calling convention.
/// Compile-time metadata for a [Variable] denoting a statically known
/// function: the link-time [offset], the declared [returnType], the
/// [convention] used to reach it, and — for extension-method tear-offs —
/// the [implicitReceiver] prepended as the first argument. An offset-less
/// instance carries only signature hints (a dynamic member value whose type
/// is `Function`).
final class CallableValue {
  const CallableValue({
    this.offset,
    this.signature,
    this.convention = CallingConvention.static,
    this.implicitReceiver,
    this.materialized = false,
  });

  /// The known function's link target — null when only signature hints are
  /// carried (e.g. a dynamic `Function`-typed member read).
  final DeferredOrOffset? offset;

  /// The callee's calling shape — parameter specs drive binding, and
  /// [CallSignature.returnType]/[CallSignature.returnOverride] resolve the
  /// call's result type.
  final CallSignature? signature;
  final CallingConvention convention;

  /// The receiver to prepend as the first argument when this reference is
  /// materialized or invoked — set on references to a member of the
  /// enclosing extension inside its own body.
  final Variable? implicitReceiver;

  /// True once the reference's tear-off has been materialized into a
  /// closure value — unmaterialized references lack it.
  final bool materialized;
}

class Variable {
  Variable(
    TypeRef type, {
    TypeRef? declaredType,
    ValueRep? rep,
    this.callable,
    bool isFinal = false,
    ValueFacts? facts,
  }) : type = type,
       _declaredType = declaredType,
       _isFinal = isFinal,
       rep = rep ?? repForType(type, representationForType(type)),
       facts = facts ?? ValueFacts.none;

  factory Variable.ssa(
    CompilerContext ctx,
    Operation op,
    TypeRef type, {
    TypeRef? declaredType,
    ValueRep? rep,
    CallableValue? callable,
    bool isFinal = false,
    ValueFacts? facts,
  }) {
    ctx.pushOp(op);
    return Variable(
      type,
      declaredType: declaredType,
      rep: rep,
      callable: callable,
      isFinal: isFinal,
      facts: facts,
    )..name = op.writesTo!.name;
  }

  factory Variable.of(
    CompilerContext ctx,
    SSA ssa,
    TypeRef type, {
    TypeRef? declaredType,
    ValueRep? rep,
    CallableValue? callable,
    bool isFinal = false,
    ValueFacts? facts,
  }) {
    return Variable(
      type,
      declaredType: declaredType,
      rep: rep,
      callable: callable,
      isFinal: isFinal,
      facts: facts,
    )..name = ssa.name;
  }

  final TypeRef type;

  final TypeRef? _declaredType;
  final bool _isFinal;

  /// The stable source-level type of the binding — for temporaries, the
  /// declared type recorded at construction ([type] when none was given).
  /// Bound values defer to the [LocalBinding]'s copy.
  TypeRef get declaredType => binding?.declaredType ?? _declaredType ?? type;

  /// Physical representation of this SSA value — always [rep]'s bank, so
  /// the two cannot disagree.
  MachineRepresentation get representation => rep.bank;

  /// Which value representation the SSA slot holds. Owns the boxing
  /// decision that used to live on `TypeRef.boxed`.
  final ValueRep rep;

  /// Compile-time facts known about this value: provable runtime types
  /// ([ValueFacts.exact], [ValueFacts.possibleClasses]) and constness.
  /// Mutable: reassignment replaces (not merges) the allocation proofs.
  ValueFacts facts;

  /// The possible runtime classes of the value; empty means unknown.
  List<TypeRef> get concreteTypes => facts.possibleClasses;

  /// The exact runtime type of the value, when provable — an exact type
  /// can never be a subclass instance, so it justifies devirtualization
  /// even for classes that are subclassed.
  TypeRef? get exactType => facts.exact;
  set exactType(TypeRef? v) => facts = facts.copyWith(exact: v);

  /// For a `Type`-typed value, the type it denotes.
  TypeRef? get denotedType => facts.denotedType;

  /// Whether this value is a compile-time-constant int expression —
  /// enables the `int → double` literal coercion. Dropped as soon as the
  /// value is bound or transformed.
  bool get isConstInt => facts.isConstInt;

  /// Whether this value is a compile-time-constant expression.
  bool get isConst => facts.isConst;

  /// Compile-known function this value denotes, if any — an unmaterialized
  /// function reference when [CallableValue.materialized] is false.
  final CallableValue? callable;

  /// Whether reassignment of this value's binding is forbidden — bound
  /// values read the [LocalBinding]'s flag; temporaries keep their own.
  bool get isFinal => binding?.isFinal ?? _isFinal;

  /// The dispatch convention for invoking this value as a function:
  /// [CallableValue.convention] when callable metadata exists, otherwise
  /// dynamic for function-typed values and static for the rest.
  CallingConvention get callingConvention =>
      callable?.convention ??
      (type.isFunctionLike
          ? CallingConvention.dynamic
          : CallingConvention.static);

  /// Convenience accessors into [callable] for the sites that only read.
  DeferredOrOffset? get methodOffset => callable?.offset;
  CallSignature? get methodSignature => callable?.signature;
  Variable? get implicitReceiver => callable?.implicitReceiver;

  /// Non-null when this value is an unmaterialized function reference
  /// (compile-known target whose closure has not been built). Requires the
  /// variable to lack an SSA slot — SSA-backed values carrying a callable
  /// (type literals, method tear-offs after materialization) are already
  /// runtime values.
  CallableValue? get unmaterializedCallable {
    final c = callable;
    return c != null && c.offset != null && !c.materialized && name == null
        ? c
        : null;
  }

  bool get boxed => rep.isBoxed;

  /// Returns this variable with the allocation proofs that do not survive a
  /// value change dropped: [exactType], [concreteTypes], and method tear-off
  /// info are cleared. All SSA identity and binding metadata is preserved.
  Variable widened() {
    return Variable(
        type,
        declaredType: _declaredType,
        rep: rep,
        isFinal: _isFinal,
        facts: facts.cleared(),
      )
      ..name = name
      ..binding = binding;
  }

  /// Widens this variable's allocation proofs for a control-flow join.
  /// [incoming] are the variable's counterparts on other incoming edges.
  /// [exactType] survives only when every edge proves the same one;
  /// [concreteTypes] become the union across edges (empty on any edge means
  /// unknown); method tear-off info is dropped when it differs. Returns
  /// `this` when every edge holds this same variable.
  Variable joinedWith(Iterable<Variable> incoming) {
    var merged = facts;
    var c = callable;
    var changed = false;
    for (final other in incoming) {
      if (identical(other, this)) continue;
      changed = true;
      merged = merged.join(other.facts);
      if (other.callable?.offset != c?.offset ||
          other.callable?.signature != c?.signature) {
        c = null;
      }
    }
    if (!changed) return this;
    return Variable(
        type,
        declaredType: _declaredType,
        rep: rep,
        callable: c,
        isFinal: _isFinal,
        facts: merged,
      )
      ..name = name
      ..binding = binding;
  }

  String? name;

  /// The [LocalBinding] this value is the current value of, if any —
  /// in-place boxing/unboxing of a bound local must rebind through it
  /// rather than writing back through `ctx.locals`.
  LocalBinding? binding;

  SSA get ssa => SSA(name!);

  /// Converts this value to [target] rep.
  ///
  /// Emits the needed op into [into] (a fresh SSA leaving this slot
  /// intact) or into this SSA in place when [into] is null. A same-rep
  /// conversion is a no-op unless [into] is given, which emits an [Assign].
  Variable toRep(
    CompilerContext ctx,
    ValueRep target, {
    SSA? into,
    AstNode? source,
  }) {
    if (rep == target) {
      if (into == null) return this;
      return Variable.ssa(
        ctx,
        Assign(into, ssa),
        type,
        rep: target,
        callable: callable,
        facts: facts.copyWith(isConst: false),
      );
    }
    // A bound local converts in place: the binding's SSA name is its
    // stable identity across edges — moving it to a conversion's temp
    // name would leave the old name with a single def and no phi. An
    // unbound temp gets a fresh slot: in-place redefinition of a temp
    // name constrains one SSA version to two representations.
    final dest =
        into ??
        (binding != null
            ? ssa
            : ctx.svar(target == ValueRep.boxed ? 'boxed' : 'unboxed'));
    if (target == ValueRep.boxed) {
      _emitBox(ctx, dest, source);
    } else if (rep == ValueRep.boxed) {
      ctx.pushOp(Unbox(dest, ssa, target.bank));
    } else {
      throw CompileError('Cannot convert $rep to $target', source);
    }
    return Variable.of(
      ctx,
      dest,
      type,
      rep: target,
      declaredType: declaredType,
      callable: callable,
      facts: facts.copyWith(isConst: false),
    );
  }

  /// Emits the op that wraps this non-boxed value into its `$Value` at
  /// [dest]. `Object`/`dynamic` in the object bank are relabels — the
  /// object bank is the uniform representation and the raw reference is
  /// already a valid boxed value; other unboxable types emit their op;
  /// the rest have no boxing path and throw (same as the old
  /// `Cannot box` CompileError).
  void _emitBox(CompilerContext ctx, SSA dest, AstNode? source) {
    switch (rep) {
      case ValueRep.int:
        ctx.pushOp(BoxInt(dest, ssa));
      case ValueRep.double:
        ctx.pushOp(BoxDouble(dest, ssa));
      case ValueRep.bool:
        ctx.pushOp(BoxBool(dest, ssa));
      case ValueRep.string:
        ctx.pushOp(BoxString(dest, ssa));
      case ValueRep.nativeNull:
        ctx.pushOp(BoxNull(dest));
      case ValueRep.nativeList:
        // Collection elements are always boxed (Abi.collectionElement), so a
        // native list's contents never need re-boxing on the way out.
        ctx.pushOp(
          BoxList(dest, ssa, runtimeTypeId: ctx.runtimeTypes.idOf(type)),
        );
      case ValueRep.nativeMap:
        ctx.pushOp(
          BoxMap(dest, ssa, runtimeTypeId: ctx.runtimeTypes.idOf(type)),
        );
      case ValueRep.nativeSet:
        ctx.pushOp(
          BoxSet(dest, ssa, runtimeTypeId: ctx.runtimeTypes.idOf(type)),
        );
      case ValueRep.nativeObject:
        // The object bank is already the uniform representation, so boxing
        // is a relabel. A distinct [dest] slot still needs a definition.
        if (dest != ssa) ctx.pushOp(Assign(dest, ssa));
      case ValueRep.boxed:
        break;
    }
  }

  /// Boxes the variable, if it isn't yet. Does nothing with a dynamic
  /// type. Pushes a proper operator to box this value on the frame, and
  /// returns this instance with the type marked as boxed.
  Variable boxIfNeeded(ScopeContext ctx, [AstNode? source]) {
    if (boxed) return this;
    final converted = toRep(
      ctx as CompilerContext,
      ValueRep.boxed,
      source: source,
    );
    // The conversion already recomputed the value-level facts (a boxed
    // literal int is still a constant int) — keep them rather than
    // re-deriving through copyWith.
    if (binding == null) {
      return copyWith(
        name: converted.name,
        type: converted.type,
        rep: converted.rep,
        facts: converted.facts,
      );
    }
    return copyWithUpdate(
      ctx,
      type: converted.type,
      rep: converted.rep,
      facts: converted.facts,
    );
  }

  /// Boxes this value into a fresh SSA slot instead of boxing the current
  /// slot in place, leaving this variable's SSA representation intact. Used
  /// when the current slot must keep its unboxed representation (e.g. a local
  /// that is read again later).
  Variable boxIntoFreshSlot(CompilerContext ctx, [AstNode? source]) {
    if (boxed) {
      return Variable.ssa(
        ctx,
        Assign(ctx.svar('box_copy'), ssa),
        type,
        rep: ValueRep.boxed,
        callable: callable,
        facts: facts.copyWith(isConst: false),
      );
    }
    if (rep == ValueRep.nativeObject &&
        (type.isSpec(CoreTypes.dynamic) || type.isSpec(CoreTypes.object))) {
      return copyWith(rep: ValueRep.boxed);
    }
    return toRep(ctx, ValueRep.boxed, into: ctx.svar('boxed'), source: source);
  }

  /// Unboxes this variable, if it isn't yet. Unlike [boxIfNeeded],
  /// pushes the [Unbox] operator also for dynamic variables.
  ///
  /// By default updates the variable in the context locals.
  /// Set [update] to false if that's not desired.
  Variable unboxIfNeeded(CompilerContext ctx, [bool update = true]) {
    // Collection instructions accept the canonical wrapper's interfaces. Keeping
    // that wrapper avoids treating a representation-preserving move as unboxing
    // and then wrapping it a second time when the value leaves this function.
    if (!boxed ||
        type.isSpec(CoreTypes.list) ||
        type.isSpec(CoreTypes.map) ||
        type.isSpec(CoreTypes.set)) {
      return this;
    }
    final converted = toRep(
      ctx,
      unboxedRepOf(type),
      into: update && binding != null ? null : ctx.svar('unboxed'),
    );
    if (!update || binding == null) {
      return copyWith(
        name: converted.name,
        type: converted.type,
        rep: converted.rep,
        facts: converted.facts,
      );
    }
    return copyWithUpdate(
      ctx,
      type: converted.type,
      rep: converted.rep,
      facts: converted.facts,
    );
  }

  /// Emits [Assign] copying this value into a fresh SSA slot, preserving its
  /// type, representation and facts. Used when evaluating a following
  /// operand may change a local's slot or representation. The copy is
  /// detached from this variable's binding — boxing/unboxing it must not
  /// rewrite the binding it was copied from.
  Variable copyIntoFreshSlot(CompilerContext ctx, String svar) {
    return Variable.ssa(
      ctx,
      Assign(ctx.svar(svar), ssa),
      type,
      rep: rep,
      callable: callable,
      facts: facts.copyWith(isConst: false, isConstInt: false),
    );
  }

  /// Returns a copy of this variable whose static type is [type], keeping
  /// the same physical representation. Used by promotion and `as` casts —
  /// the representation never changes when only the type view narrows.
  Variable withType(TypeRef type, {ValueRep? rep}) {
    return copyWith(type: type, rep: rep ?? this.rep);
  }

  /// Returns a copy of this variable carrying [facts] instead of its own.
  Variable withFacts(ValueFacts facts) => copyWith(facts: facts);

  /// Returns a variable with the same name from the context locals.
  /// Iterates over all frames and returns the first found one.
  /// If not found, returns this instance.
  Variable updated(ScopeContext ctx) {
    final b = binding;
    if (b == null) return this;
    return ctx.lookupLocal(b.name) ?? this;
  }

  /// Makes a copy of the variable with some fields updated.
  Variable copyWith({
    TypeRef? type,
    TypeRef? declaredType,
    ValueRep? rep,
    CallableValue? callable,
    bool? isFinal,
    bool? isConst,
    String? name,
    List<TypeRef>? possibleClasses,
    TypeRef? exact,
    ValueFacts? facts,
  }) {
    final newFacts =
        facts ??
        this.facts.copyWith(
          possibleClasses: possibleClasses,
          exact: exact,
          isConst: isConst,
          // The literal-int marker only applies to the literal expression
          // itself; any copy drops it.
          isConstInt: false,
        );
    return Variable(
        type ?? this.type,
        declaredType: declaredType ?? _declaredType,
        rep: rep ?? this.rep,
        callable: callable ?? this.callable,
        isFinal: isFinal ?? _isFinal,
        facts: newFacts,
      )
      ..name = name ?? this.name
      ..binding = binding;
  }

  /// Makes a copy of the variable with some fields updated, and also
  /// updates the reference on the context frame.
  Variable copyWithUpdate(
    ScopeContext? ctx, {
    TypeRef? type,
    TypeRef? declaredType,
    ValueRep? rep,
    CallableValue? callable,
    String? name,
    List<TypeRef>? possibleClasses,
    ValueFacts? facts,
  }) {
    var uV = copyWith(
      type: type,
      declaredType: declaredType,
      rep: rep,
      callable: callable,
      name: name,
      possibleClasses: possibleClasses,
      facts: facts,
    );

    if (ctx != null) {
      final b = uV.binding;
      // The back-reference can point at a binding a save/restore cycle has
      // since replaced in the locals map — rebind whichever binding
      // actually occupies the slot.
      if (b != null) {
        final live = b.frameIndex >= 0 && b.frameIndex < ctx.locals.length
            ? ctx.locals[b.frameIndex][b.name] ?? b
            : b;
        live.rebind(uV);
      }
    }
    return uV;
  }

  void inferType(CompilerContext ctx, TypeRef type) {
    final b = binding;
    if (b != null && ctx.typeInferenceSaveStates.isNotEmpty) {
      final locals = ctx.typeInferenceSaveStates.last.locals;
      locals[b.frameIndex][b.name]?.promote(type);
    }
  }

  static List<Variable> boxUnboxMultiple(
    CompilerContext ctx,
    List<Variable> variables,
    bool boxed,
  ) {
    final vlist = [...variables];
    final out = <Variable>[];

    for (var i = 0; i < vlist.length; i++) {
      final v = vlist[i];
      final set = boxed ? v.boxIfNeeded(ctx) : v.unboxIfNeeded(ctx);
      out.add(set);
      for (var j = i + 1; j < vlist.length; j++) {
        final v2 = vlist[j];
        // not great for large variable lists, but since most variable lists are small...
        if (v2.name == v.name) {
          vlist[j] = set;
        }
      }
    }

    return out;
  }

  @override
  String toString() {
    final varName = name == null ? 'unnamed' : '"$name"';
    return 'Variable{$varName, $type, '
        '${callable == null ? '' : 'method: ${callable!.signature?.returnType} ${callable!.offset}, '}'
        '${boxed ? 'boxed' : 'unboxed'}, F[${binding?.frameIndex}]}';
  }
}

/// The operator call's reified results: [result], the post-coercion
/// receiver [target] for writeback, and the prepared operand [args].
typedef OperatorResult = ({
  Variable? target,
  Variable result,
  List<Variable> args,
  Map<String, Variable> namedArgs,
});
