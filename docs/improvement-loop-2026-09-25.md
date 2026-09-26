# Improvement loop, September 25, 2026

Environment: Windows x64, Dart 3.13.4, CPython 3.12.9. Starting revisions:
dart_eval `2fbafdd` on `xv2`, control_flow_graph `f0acd09` on `main`.
The local path dependency is intentional.

## Step 1: collection loop captures

The fresh SDK core baseline has 409 actual passes, 49 runtime failures and
30 compile errors. All failures are expected by the status file. The old
untracked SDK log predates the Windows path normalization and is not a baseline.
A focused collection survey has 22 passes and 13 failures across 35 runnable tests.

`control_flow_collections/for_variable_test.dart` fails because classic collection
loops reuse one captured variable cell across iterations. Statement loops already
renew the cell before the updater. Both now use `compileForLoop`, which also
shares the assigned-local scan that discards invalid allocation proofs on back
edges. Collection for-in loops now supply that scan as well.

No runtime or generated standard-library changes. Uncaptured loop variables do
not allocate cells. Regressions exercise list/map/set captures and captures in
conditions and updaters with fresh and serialized programs. The original SDK
test passes and its expected-failure entry is removed. Focused loop, collection,
closure and statement-graph tests pass; analysis of changed files is clean.

Full default suite: 1,585 passed, 62 skipped; targeted SDK case: one passed.
