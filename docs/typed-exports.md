# Exported function API

Exported functions accept host values by parameter name and normalize return
values at the boundary. The compiler and runtime use the same register backend
for exported and internal calls.

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

The Program envelope version is 103 and the typed payload version is 115. Old
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
Map and Set source lowering is described in [collection intrinsics](typed-maps-sets.md).

## Validation

Export tests cover defaults, named arguments, explicit nulls, host identity,
serialized programs, and rejected arguments. Internal register calls bypass
export adapters. See [the current checkpoint](current-compiler-checkpoint.md)
for full-suite results and remaining limitations.
