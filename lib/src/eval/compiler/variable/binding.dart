import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/exception.dart';

/// How a local binding's value is stored at runtime: directly in its SSA
/// slot, behind a capture cell, or in an exception-handler slot.
sealed class BindingStorage {}

/// The value lives directly in the SSA slot it was last assigned.
final class SsaStorage extends BindingStorage {}

/// The value lives behind a capture cell shared with closures.
final class CaptureCellStorage extends BindingStorage {
  CaptureCellStorage(this.cell);
  final Object cell; // SSA — typed Object to avoid an ir dependency
}

/// The value lives in an exception-handler slot (variables captured by a
/// `try` body's control-flow region).
final class ExceptionSlotStorage extends BindingStorage {
  ExceptionSlotStorage(this.slot, {this.cellSlot});
  final ExceptionSlot slot;
  final ExceptionSlot? cellSlot;
}

/// A source-level local (`x`, `#this`, a pattern variable): name, declared
/// type, finality, storage, and its current flow-typed [Variable].
///
/// The binding is the stable identity of a local across flow merges,
/// promotion, and in-place boxing; the [current] variable is a snapshot
/// with a back-reference to this binding.
final class LocalBinding {
  LocalBinding(this.name, Variable current) : _current = current {
    current.binding = this;
  }

  /// A snapshot binding for a save state: a NEW binding around the same
  /// current value — shares the value but not the binding identity, so
  /// rebinding the live binding cannot rewrite the save.
  factory LocalBinding.snapshot(String name, Variable current) =>
      LocalBinding._raw(name, current);

  LocalBinding._raw(this.name, this._current);

  final String name;
  Variable _current;

  /// The binding's current flow-typed value.
  Variable get current => _current;

  /// The stable source-level type of the binding.
  TypeRef get declaredType => _current.declaredType;

  /// Whether reassignment of this binding is forbidden.
  bool get isFinal => _current.isFinal;

  /// Replaces the binding's current value — assignment, reconciliation at
  /// flow joins, and in-place box/unbox updates.
  void rebind(Variable value) {
    _current = value
      ..binding = this
      ..localName = name;
  }

  /// The binding's value as a read: capture-cell / exception-slot loads
  /// are materialized by [Variable.readBinding].
  Variable read(CompilerContext ctx) => _current.readBinding(ctx);

  /// Replaces the binding's current value's flow type (promotion, `is`
  /// narrowing, `inferType`).
  void promote(TypeRef type) {
    _current = _current.copyWith(type: type);
  }
}
