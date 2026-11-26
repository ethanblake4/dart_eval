# Test layout

- `compiler/` checks control-flow graphs, SSA, representation analysis, instruction selection, and compiler intrinsics.
- `runtime/` checks the typed machine, frames, codecs, validation, and raw runtime entry behavior.
- `language/` checks Dart source semantics through compiled programs.
- `interop/` checks bridges, host calls, exports, wrappers, bindgen, and collection boundaries.
- `stdlib/` checks supported `dart:*` library behavior.
- `security/` checks permissions and protected host resources.
- `packages/` contains package-level compatibility suites.
- `sdk_language/` runs language tests from a pinned Dart SDK checkout.
- `support/` contains shared test fixtures and helpers; it has no standalone tests.

Run the standard suite with `dart test`. Run a category with commands such as
`dart test test/compiler` or a focused file such as
`dart test test/language/async_test.dart`.

Run the full SDK language suite with
`dart test -P sdk-full test/sdk_language/full_test.dart`. See
[sdk_language/README.md](sdk_language/README.md) for setup and known failures.
