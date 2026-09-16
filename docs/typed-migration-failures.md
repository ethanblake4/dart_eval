# Typed migration test baseline

2026-09-15. Production typed backend, after the global storage checkpoint.
665 passed, 128 failed, six skipped. Analysis reports zero errors.

23 tests that failed at the closure checkpoint now pass. No previously passing
test regressed. Global load/store lowering failures are gone. Enum initializer
linking, constructor exports and compiler-context cache isolation are corrected.

There are 127 errors in unfinished compiler/runtime features and one timing
assertion failure. Future.delayed requires a 150 ms timer plus runtime setup to
finish within 200 ms. It passes in isolation and passed one intermediate full
run, but failed the final full run. The test remains unchanged.

Reproduce with `dart test --reporter json` and `dart analyze`. Full local events
are in `.dart_tool/globals-tests-final.jsonl`; the prior baseline is in
`.dart_tool/closure-tests-final.jsonl`. The failed names and first errors below
preserve the checkpoint independently of those ignored logs.

## Failure groups

| First reported failure | Tests |
| --- | ---: |
| Unsupported lowering: EnterTry | 24 |
| Representation mismatch | 21 |
| Unsupported lowering: NewMap | 20 |
| Unsupported lowering: Await | 15 |
| Null assertion | 9 |
| Other execution or linking errors | 8 |
| Unsupported lowering: NewSet | 8 |
| Unsupported lowering: Assert | 5 |
| Unsupported lowering: ReturnAsync | 3 |
| Frontend compilation | 3 |
| Unsupported lowering: IsType | 3 |
| Unsupported lowering: AssertType | 3 |
| Unsupported lowering: IndexMap | 2 |
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

- Bridge tests Passing a map to a function externally. Unsupported operation: Typed backend does not yet lower IndexMap: map₀ = indexmap arg_0₁[var_12₁]

- Bridge tests Should catch bridge future error. Unsupported operation: Typed backend does not yet lower Await: await_result₀ = await closure_result₀, completer: #completer₀

- Bridge tests Using a bridge class. Unsupported operation: Typed backend does not yet lower BridgeInstantiate: call_3₀ = newbridge 205, var_13₀ [var_12₁]

- Bridge tests Using a bridged enum. Unsupported operation: Typed backend does not yet lower NewMap: map₀ = {}

- Bridge tests Using a subclassed bridge class inside the runtime. CompileError: dart_eval does not support passing named arguments to dynamic targets. at "(a + 2 + someNumber,..." (file package:example/main.dart)

- Bridge tests Using a subclassed bridge class outside the runtime. CompileError: dart_eval does not support passing named arguments to dynamic targets. at "(a + 2, b: b)" (file package:example/main.dart)

- Bridge tests Void async function in a subclassed bridge class. Unsupported operation: Typed backend does not yet lower NewBridgeSuperShim: shim₀ = #shim

### class_test.dart

- Class tests Assigning to default null field. Unsupported operation: Typed backend does not yet lower Assert: assert not_equal₀, assertion_error₀

- Class tests Constructor field initializers. Bad state: Void function 17 returns a value

- Class tests Factory constructor. Bad state: Void function 17 returns a value

- Class tests runtimeType. Unsupported operation: Typed backend does not yet lower LoadConstantType: var_type₀ = loadconstanttype 86

### collection_test.dart

- Map tests Access null value from map. Unsupported operation: Typed backend does not yet lower NewMap: map₀ = {}

- Map tests Add key to empty map. Unsupported operation: Typed backend does not yet lower NewMap: map₀ = {}

- Map tests Empty map literal. Unsupported operation: Typed backend does not yet lower NewMap: map₀ = {}

- Map tests Map index access []. Unsupported operation: Typed backend does not yet lower NewMap: map₀ = {}

- Map tests Map null values == null. Unsupported operation: Typed backend does not yet lower NewMap: map₀ = {}

- Map tests Map.addAll(). Unsupported operation: Typed backend does not yet lower NewMap: map₀ = {}

- Map tests Map.cast(). Unsupported operation: Typed backend does not yet lower NewMap: map₀ = {}

- Map tests Map.containsKey(). Unsupported operation: Typed backend does not yet lower NewMap: map₀ = {}

- Map tests Map.entries. Unsupported operation: Typed backend does not yet lower NewMap: map₀ = {}

- Map tests Map.keys. Unsupported operation: Typed backend does not yet lower NewMap: map₀ = {}

- Map tests Map.length. Unsupported operation: Typed backend does not yet lower NewMap: map₀ = {}

- Map tests Map.remove(). Unsupported operation: Typed backend does not yet lower NewMap: map₀ = {}

- Map tests Map.values. Unsupported operation: Typed backend does not yet lower NewMap: map₀ = {}

### compiler_cfg_expressions_test.dart

- read definitions and SSA conversion: Map<String, int> main(Map<String, int> input) => <String, int>{...input};. Unsupported operation: Typed backend does not yet lower NewMap: map₀ = {}

- read definitions and SSA conversion: Map<String, int> main(Map<String, int> input) => {...input};. Unsupported operation: Typed backend does not yet lower NewMap: map₀ = {}

- read definitions and SSA conversion: Map<String, int> main(Map<String, int>? input) => <String, int>{...?input};. Unsupported operation: Typed backend does not yet lower NewMap: map₀ = {}

- read definitions and SSA conversion: Set<int> main(Set<int> input) => <int>{0, ...input};. Unsupported operation: Typed backend does not yet lower NewSet: set₀ = set {}

### compiler_control_flow_test.dart

- try finally handler is reachable without a self edge. Unsupported operation: Typed backend does not yet lower EnterTry: Instance of 'EnterTry'

### compiler_declarations_cfg_test.dart

- Future<int> f() async => 1; Future<int> main() async { return await f(); }. Unsupported operation: Typed backend does not yet lower ReturnAsync: returnasync var_12₁, #completer₀

- int main() { try { return 1; } finally { print(2); } }. Unsupported operation: Typed backend does not yet lower EnterTry: Instance of 'EnterTry'

- int main() { try { throw 1; } catch (e) { return 2; } }. Unsupported operation: Typed backend does not yet lower EnterTry: Instance of 'EnterTry'

- int main() { try { throw 1; } on String catch (e) { return 2; } catch (e, s) { return 3; } }. Unsupported operation: Typed backend does not yet lower EnterTry: Instance of 'EnterTry'

### compiler_ssa_test.dart

- SSA dominance: async await preserves explicit results. Unsupported operation: Typed backend does not yet lower ReturnAsync: returnasync var_12₁, #completer₀

- SSA dominance: finally executes around early return. Unsupported operation: Typed backend does not yet lower EnterTry: Instance of 'EnterTry'

- SSA dominance: typed catch with local mutation. Unsupported operation: Typed backend does not yet lower EnterTry: Instance of 'EnterTry'

### convert_test.dart

- dart:convert tests Accessing results of json.decode(). Bad state: Incompatible representations for var_12₀: string and object; an explicit conversion is required

- dart:convert tests base64.decode(). Bad state: Incompatible representations for var_12₀: string and object; an explicit conversion is required

- dart:convert tests base64.encode(). dart_eval runtime exception: type 'List<Object?>' is not a subtype of type '$Value?' in type cast

- dart:convert tests json.decode(). Bad state: Incompatible representations for var_12₀: string and object; an explicit conversion is required

- dart:convert tests json.encode(). Unsupported operation: Typed backend does not yet lower NewMap: map₀ = {}

- dart:convert tests jsonEncode(). Unsupported operation: Typed backend does not yet lower NewMap: map₀ = {}

- dart:convert tests utf8.decode(). dart_eval runtime exception: type 'List<Object?>' is not a subtype of type '$Value?' in type cast

- dart:convert tests utf8.encode(). Bad state: Incompatible representations for var_12₀: string and object; an explicit conversion is required

### exception_representation_test.dart

- return preserves its representation across handler normalization. Unsupported operation: Typed backend does not yet lower EnterTry: Instance of 'EnterTry'

- throw preserves the local value across handler normalization. Unsupported operation: Typed backend does not yet lower EnterTry: Instance of 'EnterTry'

- throwing an unboxed parameter preserves boxed exception ABI. Unsupported operation: Typed backend does not yet lower EnterTry: Instance of 'EnterTry'

### exception_test.dart

- Exception tests Basic try/catch. Unsupported operation: Typed backend does not yet lower EnterTry: Instance of 'EnterTry'

- Exception tests Catching exception after await. Unsupported operation: Typed backend does not yet lower Await: await_result₀ = await method_result_1₀, completer: #completer₀

- Exception tests Code runs after caught exception. Unsupported operation: Typed backend does not yet lower EnterTry: Instance of 'EnterTry'

- Exception tests DateTime.parse throwing exception. Unsupported operation: Typed backend does not yet lower EnterTry: Instance of 'EnterTry'

- Exception tests Error propagates through empty finally. Unsupported operation: Typed backend does not yet lower EnterTry: Instance of 'EnterTry'

- Exception tests Exception bubbles through asynchronous gap. Unsupported operation: Typed backend does not yet lower Await: await_result₀ = await method_result_1₀, completer: #completer₀

- Exception tests Finally can do work and return value from catch. Bad state: Missing handler finally

- Exception tests Manipulating local variables in catch and finally. Unsupported operation: Typed backend does not yet lower EnterTry: Instance of 'EnterTry'

- Exception tests Nested try/catch. Unsupported operation: Typed backend does not yet lower EnterTry: Instance of 'EnterTry'

- Exception tests Nested try/catch/finally. Unsupported operation: Typed backend does not yet lower EnterTry: Instance of 'EnterTry'

- Exception tests Rethrow. Unsupported operation: Typed backend does not yet lower EnterTry: Instance of 'EnterTry'

- Exception tests Return from catch is preceded by finally return. Bad state: Missing handler finally

- Exception tests Return from finally precedes error. Unsupported operation: Typed backend does not yet lower EnterTry: Instance of 'EnterTry'

- Exception tests Simple assert. Unsupported operation: Typed backend does not yet lower Assert: assert var_12₀, assertion_error₀

- Exception tests Try without throw skips catch but executes finally. Unsupported operation: Typed backend does not yet lower EnterTry: Instance of 'EnterTry'

- Exception tests Try/catch across function boundaries. Unsupported operation: Typed backend does not yet lower EnterTry: Instance of 'EnterTry'

- Exception tests Try/catch no error. Unsupported operation: Typed backend does not yet lower EnterTry: Instance of 'EnterTry'

- Exception tests Try/catch with on. Unsupported operation: Typed backend does not yet lower EnterTry: Instance of 'EnterTry'

- Exception tests try-catch-finally with Exception constructor. Bad state: Assignment or phi has incompatible representations: log₉, string_result_2₀ (object, string)

### expression_test.dart

- Expression tests "is" expression. Unsupported operation: Typed backend does not yet lower IsType: istype var_14₁ is! 14

- Expression tests Class cast. Unsupported operation: Typed backend does not yet lower AssertType: asserttype x₀ is 86

- Expression tests Failing cast. Unsupported operation: Typed backend does not yet lower AssertType: asserttype x₀ is 87

- Expression tests Is num. Unsupported operation: Typed backend does not yet lower IsType: istype arg_1₀ is 11

- Expression tests Null assertion. Unsupported operation: Typed backend does not yet lower Assert: assert not_equal₀, assertion_error₀

- Expression tests Num cast. Unsupported operation: Typed backend does not yet lower AssertType: asserttype x₀ is 12

### filesystem_permission_test.dart

- FilesystemPermission Tests resolves relative file paths using currentDir with permissions. Unsupported operation: Typed backend does not yet lower Await: await_result₀ = await method_result_1₀, completer: #completer₀

- FilesystemPermission Tests should allow file operations in subdirectory using relative path when currentDir is set and permission is granted for parent directory. Unsupported operation: Typed backend does not yet lower Await: await_result₀ = await method_result_1₀, completer: #completer₀

- FilesystemPermission Tests should allow file read/write/delete using IOOverrides for currentDir. Unsupported operation: Typed backend does not yet lower EnterTry: Instance of 'EnterTry'

### function_test.dart

- Function tests Function equality test. Unsupported operation: Typed backend does not yet lower Assert: assert not_equal₀, assertion_error₀

### functional1_test.dart

- Functional tests Await chain. Unsupported operation: Typed backend does not yet lower Await: await_result₀ = await method_result_1₀, completer: #completer₀

- Functional tests Default parameter boxing error. Unsupported operation: Typed backend does not yet lower Await: await_result₀ = await method_result_1₀, completer: #completer₀

- Functional tests Regex replacement loop. Bad state: Assignment or phi has incompatible representations: arg_2₁, arg_2₀, arg_2₆ (object, string)

### io_test.dart

- dart:io tests HttpClient get(). Unsupported operation: Typed backend does not yet lower Await: await_result₀ = await method_result_2₀, completer: #completer₀

- dart:io tests HttpClient get() permission denied. Unsupported operation: Typed backend does not yet lower Await: await_result₀ = await method_result_2₀, completer: #completer₀

- dart:io tests Write/read a file. Unsupported operation: Typed backend does not yet lower Await: await_result₀ = await method_result_1₀, completer: #completer₀

### operator_test.dart

- Operator method tests Operator ==. Unsupported operation: Typed backend does not yet lower IsType: istype arg_1₀ is 86

### packages/hlc_test.dart

- package:hlc. Bad state: Incompatible representations for call_7₀: object and integer; an explicit conversion is required

### pattern_test.dart

- Patterns Destructure record across function boundary. Null check operator used on a null value

- Patterns Destructure record with variable assignment pattern. Null check operator used on a null value

- Patterns Destructure record with variable declaration pattern. Null check operator used on a null value

- Switch pattern tests Switch matching record pattern. Null check operator used on a null value

- Switch pattern tests Switch with pattern guard. Null check operator used on a null value

- Switch pattern tests Switch with relational pattern. Bad state: Incompatible representations for data₂: integer and object; an explicit conversion is required

### records_test.dart

- Records Create and access records. Null check operator used on a null value

- Records Record with mixed fields. Null check operator used on a null value

- Records Record with named fields. Null check operator used on a null value

- Records Returning record from function. Null check operator used on a null value

### regexp_test.dart

- RegExp.groupNames. type 'Null' is not a subtype of type '_Mismatch' in type cast

- Regex Tests RegExp.allMatches(). type 'Null' is not a subtype of type '_Mismatch' in type cast

- Regex Tests RegExp.firstMatch(). Unsupported operation: Typed backend does not yet lower Assert: assert not_equal₀, assertion_error₀

### set_test.dart

- Set tests Adding elements to a set. Unsupported operation: Typed backend does not yet lower NewSet: set₀ = set {}

- Set tests Creating a set. Unsupported operation: Typed backend does not yet lower NewSet: set₀ = set {}

- Set tests Nested set. Unsupported operation: Typed backend does not yet lower NewSet: set₀ = set {}

- Set tests Removing elements from a set. Unsupported operation: Typed backend does not yet lower NewSet: set₀ = set {}

- Set tests Set intersection operation. Unsupported operation: Typed backend does not yet lower NewSet: set₀ = set {}

- Set tests Set union operation. Unsupported operation: Typed backend does not yet lower NewSet: set₀ = set {}

- Set tests Set with type parameters. Unsupported operation: Typed backend does not yet lower NewSet: set₀ = set {}

### stdlib_test.dart

- Standard library tests Boxed null. Unsupported operation: Typed backend does not yet lower IndexMap: map₀ = indexmap a₁[var_12₁]

- Standard library tests StreamController and Stream.listen(). Unsupported operation: Typed backend does not yet lower Await: await_result₀ = await method_result_5₀, completer: #completer₀

- Standard library tests double.parse() throws FormatException without onError. Unsupported operation: Typed backend does not yet lower EnterTry: Instance of 'EnterTry'

- Standard library tests dynamic.toString. Unsupported operation: Typed backend does not yet lower NewMap: map₀ = {}

### switch_test.dart

- Switch statement tests Basic switch with int cases. Bad state: Incompatible representations for x₂: integer and object; an explicit conversion is required

- Switch statement tests Nested switch statements. Bad state: Incompatible representations for x₂: integer and object; an explicit conversion is required

- Switch statement tests Switch with break statements. Bad state: Incompatible representations for x₂: integer and object; an explicit conversion is required

- Switch statement tests Switch with const expression case. Bad state: Incompatible representations for x₂: integer and object; an explicit conversion is required

- Switch statement tests Switch with default case. Bad state: Incompatible representations for x₂: integer and object; an explicit conversion is required

- Switch statement tests Switch with expression evaluation. Bad state: Incompatible representations for numeric_result₂: integer and object; an explicit conversion is required

- Switch statement tests Switch with function calls in cases. Bad state: Incompatible representations for x₂: integer and object; an explicit conversion is required

- Switch statement tests Switch with multiple empty cases (enum-like). Bad state: Incompatible representations for day₂: integer and object; an explicit conversion is required

- Switch statement tests Switch with multiple statements per case. Bad state: Incompatible representations for x₂: integer and object; an explicit conversion is required

- Switch statement tests Switch with no matching case and no default. Bad state: Incompatible representations for x₂: integer and object; an explicit conversion is required

- Switch statement tests Switch with proper fall-through (empty cases). Bad state: Incompatible representations for x₂: integer and object; an explicit conversion is required

- Switch statement tests Switch with return in default case. Bad state: Incompatible representations for x₂: integer and object; an explicit conversion is required

- Switch statement tests Switch with variable assignment in cases. Bad state: Incompatible representations for x₂: integer and object; an explicit conversion is required
