# Third improvement loop, September 25, 2026

Starting revisions: dart_eval `e7a8aef` on `xv2`, control_flow_graph
`bd9c394` on `main`. Windows x64, Dart 3.13.4, CPython 3.12.9.

## Step 1: labeled exits across finally

`exception/multiple_breaks_crossing_finally_test.dart` returned `1-b` where
`1-a` was required. The finally body ran, but the compiler dropped the code
after the outer labeled block. An inner return incorrectly made the whole
outer block appear to return on every path, despite a break targeting its exit.

Labeled statements now report normal completion when their exit has incoming
control-flow edges. Otherwise they retain the inner statement's completion
status, including breaks to outer labels. This repairs the existing graph;
it adds no runtime checks, boxing, opcodes or interpreter changes.

The original SDK test passes and its expected-failure entry is removed. Four
focused regressions cover nested break targets through finally, captured locals,
break versus return or throw, and unreachable tails after an outer-only break.
Fresh and serialized execution agree. The 27 existing exception regressions pass.

The survey also identified a runner limitation in
`exception/code_after_try_is_executed_test.dart`: the file includes a tagged
runtime-error multitest variant that deliberately throws at the end. Its failure
is not a missed catch. The status reason now describes that limitation.

## Step 2: service configuration validation

`benchmark/config_validation.dart` and `.py` validate ten service manifests per
batch. Eight are valid and two fail validation. The workload exercises nested
maps and lists, type guards, missing and null defaults, named constructor
arguments, typed result objects, property getters, interpolated error paths,
and custom exceptions caught at a batch boundary. Both ports validate the same
inputs and consume all successful values and error details in their checksums.
Small-count checksums match. AOT compilation uses a shared driver for all 19
benchmarks, preserving a baseline before performance changes in
`.dart_tool/loop3/baseline-sweep.exe`.

Step 1 validation: 1,631 root tests passed, 62 skipped. SDK core reports 418
passes, 38 expected failures and 32 expected compile errors. All 99 sibling graph
tests pass. Analysis of the compiler change and regressions is clean.


The retained changes remove work at common language boundaries:

- Concrete type tests use a ground-type opcode. Tests containing class or
  callable type parameters keep environment resolution, including parameters
  nested inside records, function signatures and collection arguments.
- Core nominal type IDs are cached per runtime instead of repeatedly looking
  them up by library and name during checks.
- String arguments and results use the existing native-string ABI for top-level
  functions and constructor arguments. Dynamic instance members and erased
  generic parameters retain their boxed convention.
- String emptiness and String-prefix checks use generated native operations.
  Pattern prefixes and explicit start offsets retain normal member dispatch.
- Conditions branch through type tests directly. Promotions follow the selected
  short-circuit edge and stop applying after assignments invalidate them.
- Null comparisons use the existing null-test operation and preserve evaluation
  order without invoking user equality overrides.

The machine generator produced the new operations; no generated stdlib was
edited. The bytecode codec is version 126. No graph-library changes were needed.

### Measurements

The first exploratory measurements were noisy. An orphaned test from an earlier
run was still consuming CPU despite a log that had stopped hours earlier; that
process was stopped. The recorded final sweep ran sequentially with CPU affinity
mask 4, 15 samples per driver, and no concurrent test/build jobs. All 19 drivers
completed and all 18 execution checksums matched. The compile driver records code
size separately: 1,222 bytes before, 1,221 after.

| Workload | Before, ms | After, ms | Change |
| --- | ---: | ---: | ---: |
| Configuration validation, 2,000 batches | 106.023 | 85.242 | -19.6% |
| JSON codec, 200 iterations | 483.570 | 371.005 | -23.3% |
| Event bus, 60,000 events | 102.302 | 89.949 | -12.1% |
| Template rendering, 20,000 documents | 116.326 | 114.102 | -1.9% |

CPython configuration validation took 39.557 ms in the follow-up measurement,
with the same checksum, 241657475650. A second comparison measured
135.852 -> 109.257 ms for dart_eval and 39.048 ms for CPython. Absolute Dart
measurements varied with host load, while the improvement remained about 20%.
The Python gap is smaller but remains material: roughly 2.2-2.8x in these runs.

Apparent call/argument regressions in the first sweep did not persist. A final
paired repeat measured polymorphic calls at 14.077 -> 13.946 ms, boxed arguments
at 14.746 -> 14.761 ms and overflow arguments at 21.231 -> 20.626 ms.
External-call repeats at ten times the original iteration count differed by
under 3%. Other sweep medians were within 7%, apart from improvements and very
short async/dispatch measurements affected by host timing noise.

Reproduction uses `dart compile exe benchmark/config_validation.dart` followed
by the resulting executable with `2000 15`, and
`python benchmark/config_validation.py 2000 15`. Compilation and serialization
are outside the timed guest execution; both ports use the same warmups, samples,
inputs and checksum calculation. The final shared AOT executable is
`.dart_tool/loop3/null-sweep.exe`; paired logs and checksum verification are in
`.dart_tool/loop3/sweep/`, with additional call and Python logs in its parent.

Final correctness validation: all 1,650 root tests passed, with 62 skipped.
SDK core remained at 418 passes, 38 expected failures and 32 expected compile
errors. The sibling graph suite passed all 99 tests earlier in this loop.
Analysis reports only the four pre-existing repository issues. The generated
machine check passes with 220 typed instructions, 157 extended.

Focused regressions execute both fresh and serialized programs. They cover
short-circuit type promotions invalidated by assignments, generic structural
type checks, null equality and operand order, nullable/dynamic string dispatch,
and native String calls through constructors, defaults, generic/dynamic
tear-offs and recursive finally blocks.
