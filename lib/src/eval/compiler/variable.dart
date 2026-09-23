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
import 'package:dart_eval/src/eval/compiler/dispatch.dart';
import 'package:dart_eval/src/eval/compiler/helpers/extension.dart';
import 'values/abi.dart';

/// A compiler value with an SSA identity, language type and calling convention.
class Variable {
  Variable(
    TypeRef type, {
    TypeRef? declaredType,
    MachineRepresentation? representation,
    ValueRep? rep,
    this.methodOffset,
    this.methodReturnType,
    this.isFinal = false,
    List<TypeRef> concreteTypes = const [],
    TypeRef? exactType,
    bool isConstInt = false,
    bool isConst = false,
    ValueFacts? facts,
    CallingConvention? callingConvention,
  }) : type = type,
       declaredType = declaredType ?? type,
       representation =
           representation ?? rep?.bank ?? representationForType(type),
       rep =
           rep ??
           repForType(
             type,
             representation ?? rep?.bank ?? representationForType(type),
           ),
       facts =
           facts ??
           ValueFacts(
             exact: exactType,
             possibleClasses: concreteTypes,
             isConst: isConst,
             isConstInt: isConstInt,
           ),
       callingConvention =
           callingConvention ??
           ((type.isFunctionLike && methodOffset == null)
               ? CallingConvention.dynamic
               : CallingConvention.static) {
    assert(
      facts == null ||
          (concreteTypes.isEmpty &&
              exactType == null &&
              !isConst &&
              !isConstInt),
      'pass facts or the legacy fact fields, not both',
    );
  }

  factory Variable.ssa(
    CompilerContext ctx,
    Operation op,
    TypeRef type, {
    TypeRef? declaredType,
    MachineRepresentation? representation,
    ValueRep? rep,
    DeferredOrOffset? methodOffset,
    ReturnType? methodReturnType,
    bool isFinal = false,
    List<TypeRef> concreteTypes = const [],
    TypeRef? exactType,
    bool isConstInt = false,
    bool isConst = false,
    ValueFacts? facts,
    CallingConvention callingConvention = CallingConvention.static,
  }) {
    ctx.pushOp(op);
    return Variable(
      type,
      declaredType: declaredType,
      representation: representation,
      rep: rep,
      methodOffset: methodOffset,
      methodReturnType: methodReturnType,
      isFinal: isFinal,
      concreteTypes: concreteTypes,
      exactType: exactType,
      isConstInt: isConstInt,
      isConst: isConst,
      facts: facts,
      callingConvention: callingConvention,
    )..name = op.writesTo!.name;
  }

  factory Variable.of(
    CompilerContext ctx,
    SSA ssa,
    TypeRef type, {
    TypeRef? declaredType,
    MachineRepresentation? representation,
    ValueRep? rep,
    DeferredOrOffset? methodOffset,
    ReturnType? methodReturnType,
    bool isFinal = false,
    List<TypeRef> concreteTypes = const [],
    TypeRef? exactType,
    bool isConstInt = false,
    bool isConst = false,
    ValueFacts? facts,
    CallingConvention callingConvention = CallingConvention.static,
  }) {
    return Variable(
      type,
      declaredType: declaredType,
      representation: representation,
      rep: rep,
      methodOffset: methodOffset,
      methodReturnType: methodReturnType,
      isFinal: isFinal,
      concreteTypes: concreteTypes,
      exactType: exactType,
      isConstInt: isConstInt,
      isConst: isConst,
      facts: facts,
      callingConvention: callingConvention,
    )..name = ssa.name;
  }

  final TypeRef type;

  /// The stable source-level type of a binding. For temporaries this is the
  /// same as [type]; local reads may carry a narrower flow type.
  final TypeRef declaredType;

  /// Physical representation of this SSA value.
  final MachineRepresentation representation;

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
  final DeferredOrOffset? methodOffset;
  final ReturnType? methodReturnType;
  final bool isFinal;
  final CallingConvention callingConvention;

  /// The receiver to prepend as the first argument when this variable is
  /// invoked as a function — set on references to a member of the enclosing
  /// extension inside its own body.
  Variable? implicitReceiver;

  /// Non-null when this value came from explicit extension application
  /// `E(x)`: member lookups on it resolve only within that extension.
  BoundExtension? boundExtension;

  bool get boxed => rep.isBoxed;

  /// Returns this variable with the allocation proofs that do not survive a
  /// value change dropped: [exactType], [concreteTypes], and method tear-off
  /// info are cleared. All SSA identity and binding metadata is preserved.
  Variable widened() {
    return Variable(
        type,
        declaredType: declaredType,
        representation: representation,
        rep: rep,
        isFinal: isFinal,
        facts: facts.cleared(),
        callingConvention: callingConvention,
      )
      ..name = name
      ..binding = binding
      ..implicitReceiver = implicitReceiver;
  }

  /// Widens this variable's allocation proofs for a control-flow join.
  /// [incoming] are the variable's counterparts on other incoming edges.
  /// [exactType] survives only when every edge proves the same one;
  /// [concreteTypes] become the union across edges (empty on any edge means
  /// unknown); method tear-off info is dropped when it differs. Returns
  /// `this` when every edge holds this same variable.
  Variable joinedWith(Iterable<Variable> incoming) {
    var merged = facts;
    var mOffset = methodOffset;
    var mReturn = methodReturnType;
    var changed = false;
    for (final other in incoming) {
      if (identical(other, this)) continue;
      changed = true;
      merged = merged.join(other.facts);
      if (other.methodOffset != mOffset || other.methodReturnType != mReturn) {
        mOffset = null;
        mReturn = null;
      }
    }
    if (!changed) return this;
    return Variable(
        type,
        declaredType: declaredType,
        representation: representation,
        rep: rep,
        methodOffset: mOffset,
        methodReturnType: mReturn,
        isFinal: isFinal,
        facts: merged,
        callingConvention: callingConvention,
      )
      ..name = name
      ..binding = binding
      ..implicitReceiver = implicitReceiver;
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
        methodReturnType: methodReturnType,
        facts: facts.copyWith(isConst: false, isConstInt: false),
      );
    }
    final dest = into ?? ssa;
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
      methodReturnType: methodReturnType,
      facts: facts.copyWith(isConst: false, isConstInt: false),
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
    return copyWithUpdate(
      ctx,
      type: converted.type,
      representation: converted.representation,
      rep: converted.rep,
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
        methodReturnType: methodReturnType,
        facts: facts.copyWith(isConst: false, isConstInt: false),
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
      into: update ? null : ctx.svar('unboxed'),
    );
    return update
        ? copyWithUpdate(
            ctx,
            type: converted.type,
            representation: converted.representation,
            rep: converted.rep,
          )
        : converted;
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
      methodReturnType: methodReturnType,
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
    MachineRepresentation? representation,
    ValueRep? rep,
    DeferredOrOffset? methodOffset,
    ReturnType? methodReturnType,
    bool? isFinal,
    bool? isConst,
    String? name,
    int? frameIndex,
    List<TypeRef>? concreteTypes,
    TypeRef? exactType,
    ValueFacts? facts,
    CallingConvention? callingConvention,
  }) {
    final newFacts = facts ??
        this.facts.copyWith(
          possibleClasses: concreteTypes,
          exact: exactType,
          isConst: isConst,
          // The literal-int marker only applies to the literal expression
          // itself; any copy drops it.
          isConstInt: false,
        );
    return Variable(
        type ?? this.type,
        declaredType: declaredType ?? this.declaredType,
        representation: representation ?? this.representation,
        rep: rep ?? this.rep,
        methodOffset: methodOffset ?? this.methodOffset,
        isFinal: isFinal ?? this.isFinal,
        methodReturnType: methodReturnType ?? this.methodReturnType,
        facts: newFacts,
        callingConvention: callingConvention ?? this.callingConvention,
      )
      ..name = name ?? this.name
      ..binding = binding
      ..implicitReceiver = implicitReceiver
      ..boundExtension = boundExtension;
  }

  /// Makes a copy of the variable with some fields updated, and also
  /// updates the reference on the context frame.
  Variable copyWithUpdate(
    ScopeContext? ctx, {
    TypeRef? type,
    TypeRef? declaredType,
    MachineRepresentation? representation,
    ValueRep? rep,
    DeferredOrOffset? methodOffset,
    ReturnType? methodReturnType,
    String? name,
    int? frameIndex,
    List<TypeRef>? concreteTypes,
    ValueFacts? facts,
  }) {
    var uV = copyWith(
      type: type,
      declaredType: declaredType,
      representation: representation,
      rep: rep,
      methodOffset: methodOffset,
      methodReturnType: methodReturnType,
      name: name,
      frameIndex: frameIndex,
      concreteTypes: concreteTypes,
      facts: facts,
    );

    if (ctx != null) {
      final b = uV.binding;
      // The back-reference can point at a binding a save/restore cycle has
      // since replaced in the locals map — rebind whichever binding
      // actually occupies the slot.
      if (b != null) {
        final live =
            b.frameIndex >= 0 && b.frameIndex < ctx.locals.length
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
        '${methodOffset == null ? '' : 'method: $methodReturnType $methodOffset, '}'
        '${boxed ? 'boxed' : 'unboxed'}, F[${binding?.frameIndex}]}';
  }
}

/// The operator call's reified results: [result], the post-coercion
/// receiver [target] for writeback, and the prepared operand [args].
typedef InvokeResult = ({
  Variable? target,
  Variable result,
  List<Variable> args,
  Map<String, Variable> namedArgs,
});
