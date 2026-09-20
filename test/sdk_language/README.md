# sdk_language test suite

Runs the real `dart-lang/sdk` [`tests/language`](https://github.com/dart-lang/sdk/tree/main/tests/language)
suite under dart_eval — no mirror repository to maintain.

## Layout

- `suite.yaml` — pin, core set, negative-test mode, and status lists.
- `sdk_language.dart` — checkout management, test classification, source
  collection, and `registerSdkSuite` (shared by both entrypoints).
- `shims.dart` — hand-written `package:expect`, `package:expect/async_helper`,
  `package:expect/config`, and `package:meta` sources (the real SDK packages
  rely on features dart_eval doesn't implement, so purpose-built shims are
  compiled in their place).
- `core_test.dart` — the fast subset (runs under `dart test`).
- `full_test.dart` — everything; tagged `sdk-full` and excluded from default
  runs.

## How the SDK checkout works

`suite.yaml` pins `sdk_commit`. On first run the harness creates a sparse,
blobless, depth-1 git checkout of `dart-lang/sdk` at that commit under
`.dart_tool/sdk_language/<sha>/` (gitignored), limited to `tests/language` and
`pkg/expect/lib`. Re-pinning later just means editing the SHA; the old cache
directory can be deleted.

## Running

```sh
dart test                                            # repo suite incl. core
dart test test/sdk_language/core_test.dart           # core only
dart test -P sdk-full test/sdk_language/full_test.dart   # everything
```

## Status lists

The suite follows the SDK's status-file convention: every runnable test is
expected to pass unless `suite.yaml` says otherwise.

- `exclude:` — tests that can never run under dart_eval (crash/hang the
  runner, depend on missing VM facilities). Skipped unconditionally.
- `expect_fail:` — tests known to fail today. Any non-passing outcome
  satisfies the suite; if one starts passing, the suite fails loudly so the
  stale entry gets removed.
- `negative:` — how to treat files carrying static-error markers
  (`// [cfe]`, `// [analyzer]`, `// ^^^`). `skip` (default) or
  `expect_compile_error` — dart_eval isn't a spec frontend, so it accepts
  most code the SDK rejects.

Test files that need harness flags (`VMOptions=`, `Requirements=`, …),
import `dart:`/`package:` libraries dart_eval doesn't implement, or have no
`main` are classified `unsupported` and skipped automatically — no yaml
entry needed.
