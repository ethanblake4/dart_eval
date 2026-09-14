# Exported function API

This checkpoint makes the typed compiler the only production backend. It replaces
the old positional host list and return-wrapper convention. The reference
register emitter, interpreter and opcode table have been removed. The original
private `_run` prototype and `xval_ops.dart` remain as design references.

```dart
final compiler = Compiler();
final program = compiler.compile({
  'example': {
    'main.dart': '''
      String greet(String name, {String greeting = 'Hello', String? suffix}) {
        return greeting + ' ' + name;
      }
    ''',
  },
});
final runtime = Runtime.ofProgram(program);
final result = runtime.executeLib(
  'package:example/main.dart',
  'greet',
  arguments: {'name': 'Ethan', 'suffix': null},
);
assert(result == 'Hello Ethan');
```

`eval(source, arguments: {...})` uses the same convention. Every parameter can be
provided by its declared name, including required and optional positional
parameters. Map insertion order has no effect. Unknown names, missing required
arguments and invalid nulls are rejected before the VM starts executing.

Omission uses the declared default; explicit null never means omission. Scalar,
string and null constants are supported, including scalar const references.
Non-scalar default constants currently fail compilation explicitly. Supporting
them requires immutable constant descriptors and shared canonical values used by
both internal calls and external binding. Rebuilding a collection on each call
would violate const identity and mutability semantics.

## Linking and execution

`Compiler.entrypoints` selects libraries whose callable declarations are export
roots. Their reachable functions and classes share one typed program. Export
metadata records URI, name, function ID, parameter names, required/nullability
information, declared type identity and defaults. Machine representations remain
in `TypedFunction.argumentKinds`; public language types do not select registers
by themselves. `compileTyped` remains a convenience for one explicit root using
the same backend.

Runtime caches exports by URI and name. The adapter binds the map, converts host
values and constructs one `TypedEntry` directly from source-order values. It does
not regroup arguments into separate primitive lists. `TypedMachine.runEntry`
starts the typed switch with the prepared registers. Internal calls bypass map
binding and use the existing register ABI, including one C overflow list.

The Program envelope version is 102 and the typed payload version is 107. Old
bytecode must be recompiled. Both in-memory and serialized loading retain library,
type and bridge metadata. There is no backend selector or reference fallback.

## Values across the boundary

Host callers can supply ordinary scalars, native callbacks and collections.
Existing canonical wrappers remain accepted when appropriate. Opaque evaluated
or bridge arguments are not unboxed merely to validate Object or dynamic inputs.
Declared custom types use library-qualified identity and runtime type metadata.
Export metadata currently checks outer declared types, not recursive generic
collection element constraints.

Scalar results are ordinary Dart values regardless of whether their source
return type was int, num, Object or dynamic. Native callback round trips return
the original function. Bridge objects expose their host backing object; evaluated
instances remain `TypedInstance` handles.

List, Map and Set boundary views convert elements lazily. They preserve aliases,
cycles and mutation without deep copying. Host-origin collections return their
original host object. Conversion caches distinguish Runtime contexts so the same
host collection can use different registered wrappers in different runtimes.
This does not add Map/Set bytecodes or implement their missing source lowering.

## Migration scope

Existing language tests now use the map API and normalized return expectations.
Low-level tests construct typed payloads instead of reference instruction words.
The removed reference-finally bytecode test has no typed encoding yet; source
exception tests retain coverage of the required language behavior.

The full suite is run to establish the typed migration baseline. Unsupported
bridge instructions, globals, closures, exceptions, async, maps/sets and remaining
representation errors are recorded without being repaired in this checkpoint.
Follow the failures in `typed-migration-failures.md` when resuming compiler work.
The earlier 28-failure reference baseline is historical and is not a passing gate
for the new backend.

Final run: 416 passed, 263 failed, six skipped; zero analyzer errors. The failure
report groups every failed test. All export/default/identity and codec tests pass.
The full ARM64 arithmetic path remains 38 instructions, and the opcode table
remains at 196 entries. See `typed-arm64-optimization.md` for the measurement.

Next work should begin with `InvokeExternal` lowering, which is the first blocker
in 110 tests, then closure/global conventions and the remaining representation
mismatches. Non-scalar defaults need a shared immutable constant pool before they
can join the external argument contract. These tasks were not started here.
