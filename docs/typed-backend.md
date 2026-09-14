# Typed backend implementation

The user approved implementation on 2026-09-13. This supersedes the pause and
generic-runtime-first order in backend-checkpoint.md. Commit and push each
verified stage in both repositories. Preserve the adjacent package's unrelated
working-tree fixture edits.

## Requirements

The production dispatch loop uses a dense integer switch over bytecode and named,
non-nullable typed scalar registers. Arithmetic handlers must not decode register
arrays, recover operand types, allocate instruction objects, or call generic
arithmetic helpers. Fixed operand and destination combinations are encoded in
the opcode. The existing general-object register machine is a semantic reference
while the typed backend reaches parity.

The initial register bank has two integer, two double, and two boolean registers.
Object/string banks, restricted loop registers, and instruction fusion follow
measured requirements. Spills use typed backing storage. Language types, wrapper
objects, and machine representations must remain distinct. Representation changes
are explicit at SSA definitions, phi edges, calls, and suspension boundaries.

## Stages

1. Generate a scalar runtime, opcode metadata, and encodings from one instruction
   description. Verify arithmetic, comparisons, branches, and typed spills with
   execution tests. Establish native Dart and object-register baselines, compile
   AOT, inspect native output, and record reproducible commands and limitations.
2. Make constrained allocation preserve ordered duplicate operands, respect
   register groups and clobbers, and spill live values instead of dropping them
   when destructive instructions need an occupied register. Verify with execution
   tests under two-register pressure and across control-flow edges.
3. Connect frontend SSA representations to the compact backend. Start with explicit
   primitive signatures, arithmetic, branches, loops, and direct calls. Reject
   unsupported operations explicitly. Test source-to-execution and serialization,
   including recursion, spills, and reverse operand order.
4. Add remaining representations and runtime operations with explicit call,
   exception, closure, bridge, and suspension conventions. Resolve the existing
   semantic failures against the typed backend before declaring parity.
5. Tune instruction selection, register counts, spill placement, compact branch
   encodings, and fused instructions using measured workloads. Preserve generated
   assembly and benchmark evidence when changing the hot loop.

## Validation principles

Run AOT performance tests separately from JIT. On Dart 3.10.7 the switch selection
code explicitly limits optimized jump-table selection to AOT. Small synthetic
switches do not reproduce the deployment dispatch function. Record SDK, target,
iterations, timing spread, code size, and benchmark checksums. A zero-allocation
claim must distinguish arithmetic dispatch from run entry, spilling, calls, and
return boxing. An unavailable platform is an unmeasured platform.

New package allocation tests must check executed results and live-value survival.
Do not refresh the preexisting package golden strings merely to silence failures.
