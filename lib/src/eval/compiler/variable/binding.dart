import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/helpers/captures.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/exception.dart';
import 'package:dart_eval/src/eval/ir/closures.dart';
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
  LocalBinding(this.name, Variable current, {this.frameIndex = -1})
    : storage = SsaStorage(),
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
    );
    snapshot.storage = binding.storage;
    snapshot._current.binding = snapshot;
    return snapshot;
  }

  LocalBinding._raw(this.name, this._current, this.frameIndex)
    : storage = SsaStorage();

  final String name;

  /// Scope frame the binding was declared in — -1 until [setLocal] assigns it.
  final int frameIndex;
  Variable _current;

  /// Where the binding's value is stored at runtime.
  BindingStorage storage;

  /// The binding's current flow-typed value.
  Variable get current => _current;

  /// The stable source-level type of the binding.
  TypeRef get declaredType => _current.declaredType;

  /// Whether reassignment of this binding is forbidden.
  bool get isFinal => _current.isFinal;

  /// The capture cell SSA, when the binding is cell-captured.
  SSA? get captureCell => switch (storage) {
    CaptureCellStorage s => s.cell,
    ExceptionSlotStorage s => s.cell,
    _ => null,
  };

  /// Replaces the binding's current value — assignment, reconciliation at
  /// flow joins, and in-place box/unbox updates. Storage is unchanged:
  /// rebinding never moves the value in or out of a cell or slot.
  void rebind(Variable value) {
    _current = value..binding = this;
  }

  /// The binding's value as a read: capture-cell / exception-slot loads
  /// are materialized here. The result is a fresh unbound SSA value.
  Variable read(CompilerContext ctx) => switch (storage) {
    ExceptionSlotStorage s when s.cell == null => Variable.ssa(
      ctx,
      LoadExceptionSlot(ctx.svar('protected'), s.slot),
      _current.type,
      declaredType: _current.declaredType,
      representation: _current.representation,
      isFinal: _current.isFinal,
      callingConvention: _current.callingConvention,
      methodReturnType: _current.methodReturnType,
    ),
    ExceptionSlotStorage s => _readCell(ctx, s.cell!),
    CaptureCellStorage s => _readCell(ctx, s.cell),
    _ => _current,
  };

  Variable _readCell(CompilerContext ctx, SSA cell) => Variable.ssa(
    ctx,
    ReadCaptureCell(ctx.svar('captured'), cell, _current.representation),
    _current.type,
    declaredType: _current.declaredType,
    representation: _current.representation,
    isFinal: _current.isFinal,
    callingConvention: _current.callingConvention,
    methodReturnType: _current.methodReturnType,
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

