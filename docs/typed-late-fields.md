# Late instance fields

Instance fields declared late without an initializer receive a private sentinel
in their constructor slot. Nullable fields can therefore distinguish an assigned
null from an uninitialized field. Generated late getters reject the sentinel;
generated late final setters require it and replace it only after the assignment
expression has completed. Ordinary field getters and setters retain their
existing operations and incur no late-state check.

The three dedicated operations are rUninitializedField, rLoadLatePropertyR and
setLateFinalPropertyRS. They bring the table to 243 opcodes and payload version
115. No class metadata, per-frame state, or reserved register is added. Field
IR copying preserves the late/late-final flags through allocation.

Initialization failures currently use StateError, matching typed late globals.
This change restores no-initializer late fields; the existing eager handling of
field initializer expressions is unchanged. It does not add deferred evaluation
of late initializer expressions.

The restored field test and three fresh/serialized regressions cover reads before
initialization, nullable write-once state, failed RHS evaluation, separate
instances, inherited fields, constructor-body initialization and initializer-list
values. They also verify discarded property reads: expression statements now
actually read their reference, preserving getter effects and late-read failures.
The field/class/expression/IR/codec regression group passes all 114 tests.
