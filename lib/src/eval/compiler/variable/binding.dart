import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/helpers/captures.dart';
import 'package:dart_eval/src/eval/compiler/helpers/conversion.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/backend/representation.dart';
import 'package:dart_eval/src/eval/compiler/values/value_rep.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/exception.dart';
import 'package:dart_eval/src/eval/ir/closures.dart';
import 'package:dart_eval/src/eval/shared/types.dart';
import 'package:control_flow_graph/control_flow_graph.dart';

/// How a local binding's value is stored at runtime: directly in its SSA
/// slot, behind a capture cell, or in an exception-handler slot.
sealed class BindingStorage {}

/// The value lives directly in the SSA slot it was last assigned.
final class SsaStorage extends BindingStorage {}

/// The value lives behind a capture cell shared with closures.
final class CaptureCellStorage extends BindingStorage {
  CaptureCellStorage(this.cell);
  final SSA cell;
}

/// The value is preserved in an exception-handler slot while control may
/// leave the `try` body. A captured binding preserves its cell instead —
/// [cell] is then non-null and [slot] holds the cell.
final class ExceptionSlotStorage extends BindingStorage {
  ExceptionSlotStorage(this.slot, {this.cell});
  final ExceptionSlot slot;
  final SSA? cell;
}

/// A source-level local (`x`, `#this`, a pattern variable): name, declared
/// type, finality, storage, and its current flow-typed [Variable].
///
/// The binding is the stable identity of a local across flow merges,
/// promotion, and in-place boxing; the [current] variable is a snapshot
/// with a back-reference to this binding.
final class LocalBinding {
  LocalBinding(
    this.name,
    Variable current, {
    required this.declaredType,
    this.isFinal = false,
    this.frameIndex = -1,
    this.initialized = true,
  }) : storage = SsaStorage(),
       _current = current {
    current.binding = this;
  }

  final String name;

  /// Scope frame the binding was declared in — -1 until [setLocal] assigns it.
  final int frameIndex;
  Variable _current;

  /// Where the binding's value is stored at runtime.
  BindingStorage storage;

  /// The binding's current flow-typed value.
  Variable get current => _current;

  /// The stable source-level type of the binding.
  final TypeRef declaredType;

  /// Whether reassignment of this binding is forbidden.
  final bool isFinal;

  /// Whether the binding has received its first value. Only meaningful
  /// alongside [isFinal]: an uninitialized `final` binding accepts exactly
  /// one write, which flips this to true.
  bool initialized;

  /// Types this binding has been promoted to by `is`/`as` — the flow
  /// analysis "types of interest". An assignment to the local promotes it to
  /// the stored type only when that type is a subtype of a type of interest
  /// (`x as num; x = 0` promotes `x` to `int`; `x = ''` does not promote it
  /// to `String`).
  final Set<TypeRef> typesOfInterest = {};

  /// The capture cell SSA, when the binding is cell-captured.
  SSA? get captureCell => switch (storage) {
    CaptureCellStorage s => s.cell,
    ExceptionSlotStorage s => s.cell,
    _ => null,
  };

  /// Whether a nested closure writes to this binding — such writes can
  /// happen at any time, so flow promotions on the local are unsound.
  bool writeCaptured = false;

  /// Replaces the binding's current value — assignment, reconciliation at
  /// flow joins, and in-place box/unbox updates. Storage is unchanged:
  /// rebinding never moves the value in or out of a cell or slot.
  void rebind(Variable value) {
    _current = value..binding = this;
  }

  /// An unknown replacement invalidates allocation proofs and callable
  /// metadata. The local's SSA slot, flow type, and representation stay put.
  void clearValueFacts() {
    final value = current;
    rebind(value.withFacts(value.facts.cleared()));
    _current.writeEpoch = value.writeEpoch + 1;
  }

  /// Writes a new value through this binding's storage and replaces the
  /// previous value's flow facts with the stored value's facts.
  Variable write(CompilerContext ctx, Variable value, {AstNode? source}) {
    final local = current;
    if (isFinal && initialized) {
      throw CompileError('Cannot modify value of final variable $name', source);
    }

    value = convertForAssignment(
      ctx,
      value,
      declaredType,
      representation: local.representation,
      source: source,
      description:
          'Cannot assign value of type ${value.type} to variable '
          '"$name" of type $declaredType',
    );

    final stored = local.representation == MachineRepresentation.object
        ? value.boxIfNeeded(ctx)
        : value.unboxIfNeeded(ctx, false);
    if (isFinal) initialized = true;

    // Assignment promotion: a store into a *nullable* local whose value is a
    // subtype of the non-nullable declared type promotes to
    // `NonNull(declared)` (`int? x; x = 0` promotes to `int`; `num? w = 0.5`
    // promotes to `num`, not `double`). Storing into a non-nullable declared
    // type never promotes (`Object y = ''` stays `Object`). A `dynamic`/`Null`
    // store instead demotes to the declared type; failing both, retain the
    // most specific promotion the new value still conforms to (`x as B;
    // x = C()` keeps `B`, and `x = D()` demotes to the declared type).
    // Candidates are supertypes of the stored value that stay within the
    // declared type (a `List<int>` store can't promote through
    // `List<int?>` when the declared type is `List<Object>`). An exact
    // match for the stored type wins outright; otherwise the unique
    // candidate that is a subtype of every other candidate is chosen —
    // when several qualify (mutual subtypes such as `List<dynamic>` and
    // `List<Object?>`) or none do, no type-of-interest promotion occurs.
    final candidates = [
      for (final type in typesOfInterest)
        if (stored.type.isAssignableTo(ctx, type, forceAllowDynamic: false) &&
            type.isAssignableTo(ctx, declaredType, forceAllowDynamic: false))
          type,
    ];
    TypeRef? retained;
    for (final type in candidates) {
      if (type == stored.type) retained = type;
    }
    if (retained == null) {
      var minimalCount = 0;
      for (final type in candidates) {
        if (candidates.every(
          (other) =>
              identical(other, type) ||
              type.isAssignableTo(ctx, other, forceAllowDynamic: false),
        )) {
          minimalCount++;
          retained = type;
        }
      }
      if (minimalCount > 1) retained = null;
    }
    final localType =
        declaredType.isSpec(CoreTypes.dynamic) ||
            stored.type.isSpec(CoreTypes.dynamic)
        ? declaredType
        : declaredType.nullable &&
              stored.type.isAssignableTo(ctx, declaredType.withNullable(false))
        ? declaredType.withNullable(false)
        : retained ?? declaredType;

    if (localType == declaredType && !ctx.soundFlowAnalysis(source)) {
      typesOfInterest.clear();
    }

    // A binding whose cell is preserved in an exception slot still writes
    // through the cell. The trampoline restores the cell itself.
    if (storage case ExceptionSlotStorage(:final cell?)) {
      ctx.pushOp(WriteCaptureCell(cell, stored.ssa, local.representation));
      _applyCellWrite(localType);
      return stored;
    }
    if (storage case ExceptionSlotStorage(:final slot)) {
      ctx.pushOp(StoreExceptionSlot(slot, stored.ssa));
      _applyCellWrite(localType);
      return stored;
    }
    if (captureCell case final cell?) {
      ctx.pushOp(WriteCaptureCell(cell, stored.ssa, local.representation));
      _applyCellWrite(localType);
      return stored;
    }

    ctx.pushOp(Assign(local.ssa, stored.ssa));
    // Build the bound value from what was stored so callable metadata is
    // replaced too, including when the new value has no known call target.
    rebind(
      stored.copyWith(
        name: local.name,
        type: localType,
        rep: local.rep,
        facts: stored.facts.forBinding(),
      ),
    );
    _current.writeEpoch = local.writeEpoch + 1;
    return stored;
  }

  /// Flow update for writes that go through a cell or exception slot: the
  /// facts are cleared (any reader can observe an unknown value), and the
  /// flow type follows the assignment rules — except a write-captured
  /// local can be clobbered by a closure at any time, so it always falls
  /// back to its declared type.
  void _applyCellWrite(TypeRef localType) {
    final value = _current.withType(writeCaptured ? declaredType : localType);
    rebind(value.withFacts(value.facts.cleared()));
    _current.writeEpoch = value.writeEpoch + 1;
  }

  /// The binding's value as a read: capture-cell / exception-slot loads
  /// are materialized here. The result is a fresh unbound SSA value.
  Variable read(CompilerContext ctx) => switch (storage) {
    ExceptionSlotStorage s when s.cell == null => Variable.ssa(
      ctx,
      LoadExceptionSlot(ctx.svar('protected'), s.slot),
      _current.type,
      rep: repForType(_current.type, _current.representation),
      facts: _current.facts,
    ),
    ExceptionSlotStorage s => _readCell(ctx, s.cell!),
    CaptureCellStorage s => _readCell(ctx, s.cell),
    _ => _current,
  };

  Variable _readCell(CompilerContext ctx, SSA cell) => Variable.ssa(
    ctx,
    ReadCaptureCell(ctx.svar('captured'), cell, _current.representation),
    _current.type,
    rep: repForType(_current.type, _current.representation),
    // A read yields the value the cell holds — its facts apply. Writes
    // through the cell clear them via [clearValueFacts].
    facts: _current.facts,
  );

  /// Allocates shared storage for captured bindings that need it. Initialized
  /// final objects are captured by value; scalars use typed cells. Mutable
  /// cells lose allocation proofs because a closure can replace their value.
  void captureBinding(CompilerContext ctx, AstNode declaration) {
    final analysis = capturesFor(declaration);
    if (!analysis.captured.contains(declaration) &&
        !(declaration is SwitchMember &&
            (analysis.capturedCaseBodies[declaration]?.contains(name) ??
                false))) {
      return;
    }
    // An initialized final object can live directly in the environment.
    // Scalars still use typed cells: LoadCapture reads the object bank.
    if (isFinal &&
        initialized &&
        _current.representation == MachineRepresentation.object) {
      return;
    }
    final cell = ctx.svar('cell');
    ctx.pushOp(NewCaptureCell(cell, _current.ssa, _current.representation));
    storage = CaptureCellStorage(cell);
    if (!(isFinal && initialized)) clearValueFacts();
  }

  /// Marks the binding as written through a captured cell: any in-flight
  /// promotion is dropped back to the declared type, and the epoch bump
  /// invalidates condition records other locals hold on this one.
  void markWriteCaptured() {
    if (writeCaptured) return;
    writeCaptured = true;
    final value = _current.withType(declaredType);
    rebind(value.withFacts(value.facts.cleared()));
    _current.writeEpoch = value.writeEpoch + 1;
  }

  /// Re-initializes the capture cell from its current value — used at loop
  /// iteration boundaries so each iteration's closures see a fresh value.
  void renewCaptureCell(CompilerContext ctx) {
    final cell = captureCell;
    if (cell == null) return;
    final previous = read(ctx);
    ctx.pushOp(NewCaptureCell(cell, previous.ssa, _current.representation));
  }

  /// Preserves the binding's value in an exception slot for the duration
  /// of a `try` body — a captured binding preserves its cell instead.
  void storeInExceptionSlot(ExceptionSlot slot) {
    storage = switch (storage) {
      CaptureCellStorage s => ExceptionSlotStorage(slot, cell: s.cell),
      ExceptionSlotStorage s when s.cell != null => ExceptionSlotStorage(
        slot,
        cell: s.cell,
      ),
      _ => ExceptionSlotStorage(slot),
    };
  }

  /// Replaces the binding's current value's flow type (promotion, `is`
  /// narrowing, `inferType`).
  void promote(TypeRef type) {
    _current = _current.copyWith(type: type);
  }
}
