# Contributing

Thanks for helping improve dart_eval. This guide gives you a starting point for
finding a bug or adding support for a Dart feature. The [README](README.md)
covers using the package and its public APIs.

## Getting started

Clone the repository and use a Dart SDK compatible with `pubspec.yaml`. From the
repository root, run:

```sh
dart pub get
dart analyze
dart test
```

Git and network access are needed on the first test run. The SDK language test
harness fetches a pinned Dart SDK checkout into `.dart_tool/sdk_language/`.
The default suite includes its core subset; the full suite is opt-in.
See [Test layout](test/README.md) and the
[SDK language suite guide](test/sdk_language/README.md) for details.

Run a focused test while working, then run the relevant category and the standard
suite before opening a pull request:

```sh
dart test test/language/expressions_test.dart
dart test test/compiler
dart test
```

Format changed Dart files with `dart format` and run `dart analyze`. CI runs
analysis and the standard test suite; its configuration is in
[.github/workflows/dart.yml](.github/workflows/dart.yml).

## Project structure

Public libraries live directly under `lib/`:

- `dart_eval.dart` exports the compiler, runtime, and `eval()` convenience API.
- `dart_eval_bridge.dart` exports declarations and runtime support for host interop.
- `dart_eval_security.dart` exports permissions for protected host resources.
- `dart_eval_extensions.dart` exposes annotations used by bindings and overrides.
- `stdlib/` contains public exports for supported `dart:*` bindings.

Most implementation code lives under `lib/src/eval/`. Paths below are relative to
that directory.

| Area | Responsibility |
| --- | --- |
| `eval.dart` | Convenience API that prepares source, compiles it, configures plugins and permissions, and executes a function. |
| `compiler/compiler.dart`, `compiler/context.dart` | Compilation pipeline and shared state for the current compilation. |
| `compiler/model/`, `compiler/util/` | Source and library models, source loading, imports and parts, dependency graphs, and tree shaking. |
| `compiler/declaration/` | Classes, constructors, fields, functions, enums, and extension type declarations. |
| `compiler/expression/`, `compiler/statement/`, `compiler/collection/` | Compilation of the corresponding Dart syntax into control-flow graphs. |
| `compiler/denotation.dart`, `compiler/member/`, `compiler/invocation/` | Name meaning, member lookup, call binding, argument and generic inference, and invocation targets. |
| `compiler/type.dart`, `compiler/types/` | Compile-time types, type scopes, substitution, inference, and subtyping. |
| `compiler/variable.dart`, `compiler/variable/`, `compiler/values/` | Local bindings, value facts, representations, and calling conventions. |
| `compiler/helpers/`, `compiler/macros/` | Shared compilation logic for patterns, promotion, captures, async functions, generators, branches, loops, and other cross-cutting features. |
| `compiler/optimizer/`, `compiler/backend/` | SSA conversion, optimization, representation analysis, register allocation, and bytecode emission. |
| `ir/` | Intermediate instructions used in control-flow graphs, grouped by operation. |
| `compiler/program.dart` | Compiled program metadata and the outer EVC serialization format. |
| `runtime/runtime.dart` | Runtime setup, library entrypoints, binding registration, and permissions. |
| `runtime/typed/` | Typed VM execution, frames, dispatch, closures, exceptions, async state, generators, collections, interop, and bytecode codecs. |
| `runtime/security/` | Permission definitions and checks for protected resources. |
| `bridge/`, `plugin.dart` | Compile-time bridge declarations, binding registries, runtime wrappers, and plugin configuration. |
| `bindgen/` | Analysis of host Dart code into bridge declarations and generation of bindings. |
| `shared/` | Type IDs, runtime type descriptors, library environments, and standard library bindings shared by compiler and runtime. |
| `cli/` | Compile, run, and bind command implementations. Argument parsing and the dump command live in `bin/dart_eval.dart`. |

Outside `lib/`, `test/` contains regression and conformance tests, `tool/` contains
generators and diagnostic utilities, `benchmark/` contains performance workloads,
and `.dart_eval/bindgen.yaml` configures standard library binding generation.

## How source becomes a running program

The compiler uses the Dart analyzer to parse source into an abstract syntax tree.
It does not use the analyzer's full resolution pipeline. dart_eval handles name
resolution, type inference, and subtyping itself, so valid Dart can still expose a
gap in those parts of the compiler.

Compilation roughly follows these stages:

1. Load source files and resolve library relationships, including imports,
   exports, and parts. Build declaration lookup tables and type information.
2. Compile declarations and their bodies into control-flow graphs containing IR
   instructions. This stage handles source semantics such as member resolution,
   argument binding, captures, and flow promotion.
3. Prepare reachable functions for SSA, optimize the graphs, choose value
   representations, allocate typed registers and frame slots, and emit packed
   bytecode. IR instructions and VM instructions are separate representations.
4. Assemble a `Program` containing code and metadata. `Program.write()` serializes
   it as EVC bytecode. A runtime can load those bytes or use `Runtime.ofProgram()`
   to run the in-memory program.

`Runtime.executeLib()` selects a function in a library. The typed machine executes
its instructions using function frames. Calls into host Dart use the interop
layer; host callbacks can enter evaluated code again. Return values cross the
same boundary back to host Dart.

### Host interop and standard libraries

Bindings have both a compile-time and a runtime side. Bridge declarations describe
what evaluated code can call. Runtime registrations supply host implementations,
and wrappers and adapters convert values and callbacks across the boundary.
`EvalPlugin.configureForCompile()` and `configureForRuntime()` connect these
pieces. A method can compile successfully and still fail if its runtime binding
is missing or disagrees with the declaration.

Standard libraries use this same mechanism. Start at the library's plugin in
`shared/stdlib/`, then follow its declarations, wrappers, copied source, or hooks.
For bindgen, declaration builders own member selection and type rules. The Dart
renderer prints that metadata; JSON output uses the declaration registry and
serializer.

## Tests and debugging

Choose the test category that describes the behavior being checked:

- `test/language/` for Dart source semantics through compiled programs.
- `test/compiler/` for graphs, inference, optimizations, and bytecode generation.
- `test/runtime/` for VM execution, frames, metadata, and codecs.
- `test/interop/` for bridges, host calls, callbacks, wrappers, and bindgen.
- `test/stdlib/` for supported `dart:*` APIs, and `test/security/` for permissions.
- `test/packages/` for package compatibility, and `test/sdk_language/` for upstream
  Dart language conformance. Shared fixtures live in `test/support/`.

For a language regression, compile a small Dart program and assert its observable
result or error. Follow a nearby test for setup. When serialization is relevant,
exercise both `Runtime.ofProgram(program)` and
`Runtime(program.write().buffer)` so the test covers the saved program too.
Use compiler or runtime tests when the issue concerns an internal invariant that
cannot be checked adequately through source behavior.

The full SDK suite is useful for changes that affect many language features:

```sh
dart test -P sdk-full test/sdk_language/full_test.dart
```

Its pinned revision, expected failures, and unsupported cases are configured in
`test/sdk_language/suite.yaml`. Read the suite guide before changing those lists.

Useful tools when narrowing a failure:

- `dart run tool/eval_src.dart path/to/repro.dart` compiles and runs a standalone
  reproduction and prints errors with a short stack trace.
- `Compiler.functionGraphs` and `ssaFunctionGraphs` expose graphs from the last
  compilation. `functionNames` helps identify the function being inspected.
- `dart run bin/dart_eval.dart dump path/to/program.evc` prints the instructions
  in a saved program.
- `tool/ir_snapshot.dart` records serialized program hashes and compilation
  outcomes for SDK core tests and benchmark sources. It can compare against a
  baseline to identify changed output; a changed hash alone does not establish
  correctness.
- `tool/profile_compiler.dart` reports compiler phase timings. Use a workload in
  `benchmark/` that exercises the affected behavior when investigating performance.

## Generated code

Edit the generator or its configuration when changing generated behavior, then
include the regenerated output in the same change.

- `tool/generate_typed_machine.dart` defines instruction operands, metadata, and
  handler bodies. Run `dart run tool/generate_typed_machine.dart` to regenerate
  `runtime/typed/typed_ops.g.dart` and `typed_machine.g.dart` under
  `lib/src/eval/`. Coordinate instruction changes with IR lowering in the backend
  and with codec validation and versioning when the bytecode format changes.
- `.dart_eval/bindgen.yaml` configures generated standard library bindings. Run
  `dart run tool/generate_stdlib.dart` to regenerate them. The config distinguishes
  generated wrappers, hand-maintained wrappers, and types with declarations only.
  Put custom behavior in the configured hooks or handwritten implementations.

Review the generated diff for unintended changes, especially when using a different
host Dart SDK. Run tests for the affected instructions or bindings after regeneration.

## Making a contribution

Fork the repository, make a focused change, and open a pull request. For a bug fix,
include a regression test that fails before the fix.

### Adding a new feature

If you're adding a new feature, the best place to start is by writing a test. 
The error you get when running a failed test will often point you to the right place to start!