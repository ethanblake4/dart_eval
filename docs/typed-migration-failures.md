# Typed migration test baseline

The final restored-coverage checkpoint passes 856 tests with zero failures and
zero skips. All six preexisting skips are enabled. `dart analyze` reports zero
errors and 50 warnings/info. Generated runtime files match their generator.

Reproduce with:

- `dart test --reporter json`
- `dart analyze`
- `dart run tool/generate_typed_machine.dart --check`

Local evidence: `.dart_tool/restored-tests-final.jsonl` and
`.dart_tool/restored-analyze.txt`. Tests include fresh and serialized programs,
async suspension and exceptions, bridge inheritance, generic call representations,
record fields, late fields, and mapped host collections.

See [the current checkpoint](current-compiler-checkpoint.md) for saved state and
[restored coverage](typed-restored-tests.md) for the final changes.
