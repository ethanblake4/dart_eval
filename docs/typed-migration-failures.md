# Typed migration test baseline

Production typed backend, after the async-records checkpoint.
827 passed, 9 failed, 6 skipped. Analysis reports zero errors.

36 previously failing tests recovered since maps; 0 regressions among previously passing tests.

The Future.delayed timing assertion includes compilation/runtime setup in a
200 ms limit around a 150 ms delay and may fail under full-suite contention.

Reproduce with `dart test --reporter json` and `dart analyze`. Local events are
in `.dart_tool/async-records-tests-final.jsonl`; the preceding baseline is
`.dart_tool/maps-tests-final.jsonl`. Names and errors are preserved below.

## Failure groups

| First reported failure | Tests |
| --- | ---: |
| Frontend compilation | 3 |
| Representation mismatch | 2 |
| Other execution or linking errors | 2 |
| Unsupported lowering: BridgeInstantiate | 1 |
| Unsupported lowering: NewBridgeSuperShim | 1 |

## Failed tests

### bridge_test.dart

- Bridge tests Changing a field in the constructor of a subclassed bridge class. CompileError: dart_eval does not support passing named arguments to dynamic targets. at "(a + 2, b: b)" (file package:example/main.dart)

- Bridge tests Using a bridge class. Unsupported operation: Typed backend does not yet lower BridgeInstantiate: call_3₀ = newbridge 205, var_13₀ [var_12₁]

- Bridge tests Using a subclassed bridge class inside the runtime. CompileError: dart_eval does not support passing named arguments to dynamic targets. at "(a + 2 + someNumber,..." (file package:example/main.dart)

- Bridge tests Using a subclassed bridge class outside the runtime. CompileError: dart_eval does not support passing named arguments to dynamic targets. at "(a + 2, b: b)" (file package:example/main.dart)

- Bridge tests Void async function in a subclassed bridge class. Unsupported operation: Typed backend does not yet lower NewBridgeSuperShim: shim₀ = #shim

### functional1_test.dart

- Functional tests Regex replacement loop. Bad state: Assignment or phi has incompatible representations: arg_2₁, arg_2₀, arg_2₆ (object, string)

### packages/hlc_test.dart

- package:hlc. Bad state: Incompatible representations for call_7₀: object and integer; an explicit conversion is required

### regexp_test.dart

- RegExp.groupNames. type 'Null' is not a subtype of type '_Mismatch' in type cast

- Regex Tests RegExp.allMatches(). type 'Null' is not a subtype of type '_Mismatch' in type cast
