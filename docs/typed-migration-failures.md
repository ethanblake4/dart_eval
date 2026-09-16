# Typed migration test baseline

Production typed backend, after the bridge checkpoint.
845 passed, 0 failed, 6 skipped. Analysis reports zero errors and 50 warnings/info.

All nine failing tests from the async/record checkpoint now pass. There are no
regressions among previously passing tests. The delayed-Future tests now use a
monotonic clock to verify the delay, without an OS scheduling deadline.

Reproduce with `dart test --reporter json`, `dart analyze`, and
`dart run tool/generate_typed_machine.dart --check`. Local test events are in
`.dart_tool/bridge-tests-final.jsonl`.

Six preexisting skips remain for the next checkpoint: nested map mutation, late
fields, custom arithmetic and indexing operators, interpolation calling
`toString`, and `$List.view`. A separate `--run-skipped` run identifies stale
fixture expectations and gaps in late fields, indexing, and mapped List views.
