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

