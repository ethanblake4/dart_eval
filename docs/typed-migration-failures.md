# Typed migration test baseline

Production typed backend, after the maps checkpoint.
781 passed, 45 failed, 6 skipped. Analysis reports zero errors.

50 previously failing tests recovered since exception; 0 regressions among previously passing tests.

The Future.delayed timing assertion includes compilation/runtime setup in a
200 ms limit around a 150 ms delay and may fail under full-suite contention.

Reproduce with `dart test --reporter json` and `dart analyze`. Local events are
in `.dart_tool/maps-tests-final.jsonl`; the preceding baseline is
`.dart_tool/exception-tests-final.jsonl`. Names and errors are preserved below.

## Failure groups

| First reported failure | Tests |
| --- | ---: |
| Unsupported lowering: Await | 16 |
| Null assertion | 9 |
| Other execution or linking errors | 5 |
| Unsupported lowering: ReturnAsync | 3 |
| Frontend compilation | 3 |
| Unsupported lowering: AssertType | 3 |
| Representation mismatch | 2 |
| Future.delayed timing threshold | 1 |
| Unsupported lowering: BridgeInstantiate | 1 |
| Unsupported lowering: NewBridgeSuperShim | 1 |
| Unsupported lowering: LoadConstantType | 1 |

## Failed tests

### async_test.dart

- Async tests Auto await future return value. Unsupported operation: Typed backend does not yet lower ReturnAsync: returnasync call_3₀, #completer₀

- Async tests Chained async/await. Unsupported operation: Typed backend does not yet lower Await: await_result₀ = await call_3₀, completer: #completer₀

- Async tests Future.delayed(). Expected: a value less than <200>

- Async tests Simple async/await. Unsupported operation: Typed backend does not yet lower Await: await_result₀ = await method_result_1₀, completer: #completer₀

- Async tests Using a Future result. Unsupported operation: Typed backend does not yet lower Await: await_result₀ = await method_result_1₀, completer: #completer₀

### bridge_test.dart

- Bridge tests Awaiting a callback. Unsupported operation: Typed backend does not yet lower Await: await_result₀ = await closure_result_1₀, completer: #completer₀

- Bridge tests Changing a field in the constructor of a subclassed bridge class. CompileError: dart_eval does not support passing named arguments to dynamic targets. at "(a + 2, b: b)" (file package:example/main.dart)

- Bridge tests Should catch bridge future error. Unsupported operation: Typed backend does not yet lower Await: await_result₀ = await closure_result₀, completer: #completer₀

- Bridge tests Using a bridge class. Unsupported operation: Typed backend does not yet lower BridgeInstantiate: call_3₀ = newbridge 205, var_13₀ [var_12₁]

- Bridge tests Using a subclassed bridge class inside the runtime. CompileError: dart_eval does not support passing named arguments to dynamic targets. at "(a + 2 + someNumber,..." (file package:example/main.dart)

- Bridge tests Using a subclassed bridge class outside the runtime. CompileError: dart_eval does not support passing named arguments to dynamic targets. at "(a + 2, b: b)" (file package:example/main.dart)

- Bridge tests Void async function in a subclassed bridge class. Unsupported operation: Typed backend does not yet lower NewBridgeSuperShim: shim₀ = #shim

### class_test.dart

- Class tests Constructor field initializers. Bad state: Void function 17 returns a value

- Class tests Factory constructor. Bad state: Void function 17 returns a value

- Class tests runtimeType. Unsupported operation: Typed backend does not yet lower LoadConstantType: var_type₀ = loadconstanttype 86

### compiler_declarations_cfg_test.dart

- Future<int> f() async => 1; Future<int> main() async { return await f(); }. Unsupported operation: Typed backend does not yet lower ReturnAsync: returnasync var_12₁, #completer₀

### compiler_ssa_test.dart

- SSA dominance: async await preserves explicit results. Unsupported operation: Typed backend does not yet lower ReturnAsync: returnasync var_12₁, #completer₀

### exception_test.dart

- Exception tests Catching exception after await. Unsupported operation: Typed backend does not yet lower Await: await_result₀ = await method_result_1₀, completer: #completer₀

- Exception tests Exception bubbles through asynchronous gap. Unsupported operation: Typed backend does not yet lower Await: await_result₀ = await method_result_1₀, completer: #completer₀

### expression_test.dart

- Expression tests Class cast. Unsupported operation: Typed backend does not yet lower AssertType: asserttype x₀ is 86

- Expression tests Failing cast. Unsupported operation: Typed backend does not yet lower AssertType: asserttype x₀ is 87

- Expression tests Num cast. Unsupported operation: Typed backend does not yet lower AssertType: asserttype x₀ is 12

### filesystem_permission_test.dart

- FilesystemPermission Tests resolves relative file paths using currentDir with permissions. Unsupported operation: Typed backend does not yet lower Await: await_result₀ = await method_result_1₀, completer: #completer₀

- FilesystemPermission Tests should allow file operations in subdirectory using relative path when currentDir is set and permission is granted for parent directory. Unsupported operation: Typed backend does not yet lower Await: await_result₀ = await method_result_1₀, completer: #completer₀

- FilesystemPermission Tests should allow file read/write/delete using IOOverrides for currentDir. Unsupported operation: Typed backend does not yet lower Await: await_result₀ = await method_result_1₀, completer: #completer₀

### function_test.dart

- Function tests Function equality test. dart_eval runtime exception: EvalUnknownPropertyException (==)

### functional1_test.dart

- Functional tests Await chain. Unsupported operation: Typed backend does not yet lower Await: await_result₀ = await method_result_1₀, completer: #completer₀

- Functional tests Default parameter boxing error. Unsupported operation: Typed backend does not yet lower Await: await_result₀ = await method_result_1₀, completer: #completer₀

- Functional tests Regex replacement loop. Bad state: Assignment or phi has incompatible representations: arg_2₁, arg_2₀, arg_2₆ (object, string)

### io_test.dart

- dart:io tests HttpClient get(). Unsupported operation: Typed backend does not yet lower Await: await_result₀ = await method_result_2₀, completer: #completer₀

- dart:io tests HttpClient get() permission denied. Unsupported operation: Typed backend does not yet lower Await: await_result₀ = await method_result_2₀, completer: #completer₀

- dart:io tests Write/read a file. Unsupported operation: Typed backend does not yet lower Await: await_result₀ = await method_result_1₀, completer: #completer₀

### packages/hlc_test.dart

- package:hlc. Bad state: Incompatible representations for call_7₀: object and integer; an explicit conversion is required

### pattern_test.dart

- Patterns Destructure record across function boundary. Null check operator used on a null value

- Patterns Destructure record with variable assignment pattern. Null check operator used on a null value

- Patterns Destructure record with variable declaration pattern. Null check operator used on a null value

- Switch pattern tests Switch matching record pattern. Null check operator used on a null value

- Switch pattern tests Switch with pattern guard. Null check operator used on a null value

### records_test.dart

- Records Create and access records. Null check operator used on a null value

- Records Record with mixed fields. Null check operator used on a null value

- Records Record with named fields. Null check operator used on a null value

- Records Returning record from function. Null check operator used on a null value

### regexp_test.dart

- RegExp.groupNames. type 'Null' is not a subtype of type '_Mismatch' in type cast

- Regex Tests RegExp.allMatches(). type 'Null' is not a subtype of type '_Mismatch' in type cast

### stdlib_test.dart

- Standard library tests StreamController and Stream.listen(). Unsupported operation: Typed backend does not yet lower Await: await_result₀ = await method_result_5₀, completer: #completer₀
