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
    this.frameIndex = -1,
    this.initialized = true,
  }) : storage = SsaStorage(),
       declaredType = current.declaredType,
       isFinal = current.isFinal,
       _current = current {
    current.binding = this;
  }

  /// A snapshot binding for a save state: a NEW binding around a copy of
  /// the current value and the same storage — copying the value keeps
  /// rebinding the live binding from rewriting the save, and gives the
  /// snapshot's value this snapshot as its back-reference.
  factory LocalBinding.snapshot(LocalBinding binding) {
    final snapshot = LocalBinding._raw(
      binding.name,
      binding.current.copyWith(),
      binding.frameIndex,
      binding.declaredType,
      binding.isFinal,
    );
    snapshot.storage = binding.storage;
    snapshot.initialized = binding.initialized;
    snapshot._current.binding = snapshot;
    return snapshot;
  }

  LocalBinding._raw(
    this.name,
    this._current,
    this.frameIndex,
    this.declaredType,
    this.isFinal,
  ) : storage = SsaStorage(),
      initialized = true;

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

  /// The capture cell SSA, when the binding is cell-captured.
  SSA? get captureCell => switch (storage) {
    CaptureCellStorage s => s.cell,
    ExceptionSlotStorage s => s.cell,
    _ => null,
  };

  /// The binding currently occupying this binding's locals slot in [ctx]:
  /// this binding, or the snapshot binding a save/restore cycle installed
  /// in its place.
  LocalBinding liveIn(ScopeContext ctx) {
    if (frameIndex < 0 || frameIndex >= ctx.locals.length) return this;
    return ctx.locals[frameIndex][name] ?? this;
  }

  /// Replaces the binding's current value — assignment, reconciliation at
  /// flow joins, and in-place box/unbox updates. Storage is unchanged:
  /// rebinding never moves the value in or out of a cell or slot.
  void rebind(Variable value) {
    _current = value..binding = this;
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

    // A binding whose cell is preserved in an exception slot still writes
    // through the cell. The trampoline restores the cell itself.
    if (storage case ExceptionSlotStorage(:final cell?)) {
      ctx.pushOp(WriteCaptureCell(cell, stored.ssa, local.representation));
      rebind(local.widened());
      return stored;
    }
    if (storage case ExceptionSlotStorage(:final slot)) {
      ctx.pushOp(StoreExceptionSlot(slot, stored.ssa));
      rebind(local.widened());
      return stored;
    }
    if (captureCell case final cell?) {
      ctx.pushOp(WriteCaptureCell(cell, stored.ssa, local.representation));
      rebind(local.widened());
      return stored;
    }

    ctx.pushOp(Assign(local.ssa, stored.ssa));
    // Keep a promotion only if the new value still conforms to it.
    final localType = declaredType.isSpec(CoreTypes.dynamic)
        ? declaredType
        : stored.type.isAssignableTo(ctx, local.type)
        ? local.type
        : declaredType;
    // Build the bound value from what was stored so callable metadata is
    // replaced too, including when the new value has no known call target.
    rebind(
      stored.copyWith(
        name: local.name,
        type: localType,
        declaredType: declaredType,
        rep: local.rep,
        facts: stored.facts.forBinding(),
      ),
    );
    return stored;
  }

  /// The binding's value as a read: capture-cell / exception-slot loads
  /// are materialized here. The result is a fresh unbound SSA value.
  Variable read(CompilerContext ctx) => switch (storage) {
    ExceptionSlotStorage s when s.cell == null => Variable.ssa(
      ctx,
      LoadExceptionSlot(ctx.svar('protected'), s.slot),
      _current.type,
      declaredType: declaredType,
      rep: repForType(_current.type, _current.representation),
      isFinal: isFinal,
      callable: _current.callable,
    ),
    ExceptionSlotStorage s => _readCell(ctx, s.cell!),
    CaptureCellStorage s => _readCell(ctx, s.cell),
    _ => _current,
  };

  Variable _readCell(CompilerContext ctx, SSA cell) => Variable.ssa(
    ctx,
    ReadCaptureCell(ctx.svar('captured'), cell, _current.representation),
    _current.type,
    declaredType: declaredType,
    rep: repForType(_current.type, _current.representation),
    isFinal: isFinal,
    callable: _current.callable,
  );

  /// Moves the binding's storage behind a capture cell when [declaration]
  /// is captured by a nested closure — allocation proofs are dropped since
  /// any closure invocation can rewrite the cell.
  void captureBinding(CompilerContext ctx, AstNode declaration) {
    if (!capturesFor(declaration).captured.contains(declaration)) return;
    final cell = ctx.svar('cell');
    ctx.pushOp(NewCaptureCell(cell, _current.ssa, _current.representation));
    storage = CaptureCellStorage(cell);
    rebind(_current.widened());
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
      _ => ExceptionSlotStorage(slot),
    };
  }

  /// Replaces the binding's current value's flow type (promotion, `is`
  /// narrowing, `inferType`).
  void promote(TypeRef type) {
    _current = _current.copyWith(type: type);
  }
}
