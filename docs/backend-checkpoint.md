# Executable backend checkpoint — 2026-09-12

The user asked to stop after the next commit and save progress. Do not continue
the migration automatically after this checkpoint. On resumption, complete stage
4 and then stage 5 from compiler-migration.md, committing at each milestone.

## Checkouts and saved work

- dart_eval: `D:\Projects\dart_eval`, branch `xv2`, remote `origin/xv2`.
- control_flow_graph: `D:\Projects\control_flow_graph`, branch `main`.
  dart_eval intentionally uses this checkout through a local path dependency.
- Earlier dart_eval milestones: `187b0fc` frontend, `43cfa98` graph validation,
  `d787eca` SSA/effects. All were pushed.
- Companion commits before this checkpoint: `dd3df16` reachability/dominators,
  `e72b86c` SSA/effects. Companion commits have been kept local.
- The package checkpoint includes the existing register-preference, spill, and
  next-use improvements needed by this backend. Its preexisting changes to
  complex_cfg_test.dart, for_loop_test.dart, sample_instruction_set.dart,
  sample_ir.dart, and deletion of control_flow_graph_test.dart remain unstaged.
  Preserve them; do not reset the adjacent checkout.

## Implementation

`compiler/backend/register_backend.dart` lowers typed frontend operations to
MachineOperation, reconstructs SSA, removes dead definitions, spills, eliminates
phis, allocates registers, and assembles signed 32-bit words. DCE after lowering
is necessary: semi-pruned SSA creates dead phis with undefined incoming versions.
The default is 32 general Object? registers per invocation. This establishes the
allocator-backed path; separate numeric register banks and instruction variants
are future optimization work. The old experimental typed `_run` remains unused.

Instruction format is documented in runtime/ops/register_ops.dart:
`[opcode, resultRegister, inputCount, inputs..., dataCount, data...]`.
Targets are absolute word offsets. Each function begins with an entry instruction
specifying register and spill counts. StageArgument instructions handle variadic
calls without requiring all arguments to occupy registers simultaneously.

`runtime/register_machine.dart` owns per-call registers, spills, arguments,
captures, handlers, and pending completions. Public execute/bridgeCall use it.
`compiler/program.dart` reads/writes the version 101 format with metadata bounds
checks and signed instruction words. Both Runtime.ofProgram and serialized
Runtime construction share metadata loading.

The package tracks predecessor-specific phi inputs, splits critical edges,
handles parallel copies, inserts edge moves before terminators, expires dead
registers, preserves live copy sources, and rejects missing instruction creators.
The backend's onSplitEdge callback retargets symbolic block addresses.

Closures use separate captures and zero-based parameters. Tearoff metadata
specifies bound receivers and primitive argument unboxing. Captures still hold
values, not shared cells. Break/switch exits now reconcile boxing state. Field
reads use the dynamic getter path instead of the inherited unresolved static
field-offset optimization.

## Verified results

- Full dart_eval analyzer: **0 errors**, 16 warnings, 17 infos. Most warnings
  concern the retained experimental runtime, stdlib dead code, and path dependency.
- Full dart_eval tests: **485 passed, 30 failed, 6 skipped**.
- New register_backend_test.dart (11), register_machine_test.dart (5), and
  program_codec_test.dart (8): **24 passed**.
- Companion package: **21 targeted tests passed**, full analyzer has zero errors
  or warnings and three import infos. The full package golden suite is not green.
- `backend-checkpoint-failures.txt` records the remaining dart_eval failures with
  initial diagnostics. Full local logs are saved under `.dart_tool/migration/`.

Reproduce from dart_eval:

```powershell
dart analyze --format machine
dart test test/register_backend_test.dart test/register_machine_test.dart test/program_codec_test.dart --reporter expanded
dart test --reporter expanded
```

## Resume order

1. Fix exception edges and layout together. Nested EnterTry can fall through into
   a handler because exceptional successors participate in block ordering. Other
   failures report missing finally targets after reachability pruning. Preserve
   every referenced handler, distinguish normal edges, and ensure ordinary
   fallthrough jumps to the protected body. A quick attempt to append a jump to
   an empty dedicated body block made exception tests worse and was reverted;
   inspect DCE/empty-block handling as well as assembly. Four exception tests fail.
2. Fix record runtime-type registration: records and record patterns fail before
   execution around TypeRef.toRuntimeType's missing type IDs. Nine tests fail.
3. Finish bridge ABI parity: subclass/super object handling, external map input,
   runtime overrides, and callback cases. Eight bridge tests fail. Missing host
   arguments are already normalized from $null to native null at bridge calls.
4. Add shared capture cells and closure equality semantics. Two function tests
   still fail here. Direct and bound tearoffs now pass.
5. Resolve remaining boxing/type and larger program failures: enum boxing,
   `is num`, cross-file boxed ints, four functional examples, and Object.hash.
   Keep integer operations strict; do not conceal representation errors with
   indiscriminate runtime unboxing.
6. Re-run full semantic and codec suites; only declare stage 5 complete after
   remaining failures are understood and resolved. Keep focused regressions for
   actual transformation bugs. Benchmark/tune only after correctness.

The package's old golden fixtures also need review. Existing sample edits changed
loop instructions, sample operations lack new purity annotations, and correct phi
lowering now emits edge copies. Validate semantics before refreshing strings;
do not blindly replace expected output to make the suite green.
