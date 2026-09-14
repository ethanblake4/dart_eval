# Typed migration test baseline

2026-09-14. Production typed backend, after the exported-function API merge.
416 passed, 263 failed, six skipped. All failures are test errors; no assertion failures remain in this run. Analysis reports zero errors.

The existing tests use map arguments and normalized host results. API/adapter regressions were fixed; unrelated language/compiler failures remain intentionally untouched. This replaces the reference baseline as the next migration checklist. Counts are not directly comparable because low-level reference tests were migrated and export tests were added.

Reproduce with `dart test --reporter json`, and `dart analyze`. Local full events are saved in `.dart_tool/export-tests-final.jsonl`.

## Failure groups

| First reported failure | Tests |
| --- | ---: |
| Unsupported lowering: InvokeExternal | 110 |
| Unsupported lowering: CreateClosure | 31 |
| Unsupported lowering: EnterTry | 22 |
| Representation mismatch | 21 |
| Unsupported lowering: LoadGlobal | 20 |
| Unsupported lowering: NewMap | 18 |
| Frontend compilation | 10 |
| Null assertion | 10 |
| Unsupported lowering: NewSet | 8 |
| Other execution or linking errors | 4 |
| Unsupported lowering: AssertType | 3 |
| Unsupported lowering: NewBridgeSuperShim | 1 |
| Unsupported lowering: IndexMap | 1 |
| Unsupported lowering: IsType | 1 |
| Unsupported lowering: BridgeInstantiate | 1 |
| Unsupported lowering: LoadConstantType | 1 |
| Unsupported lowering: SetGlobal | 1 |

## Failed tests

### async_test.dart

- Async tests Auto await future return value. Unsupported operation: Typed backend does not yet lower InvokeExternal: #completer₀ = invokeexternal 99 []
- Async tests Chained async/await. Unsupported operation: Typed backend does not yet lower InvokeExternal: #completer₀ = invokeexternal 99 []
- Async tests Future.delayed(). Unsupported operation: Typed backend does not yet lower InvokeExternal: call_3₀ = invokeexternal 32 [var_12₀, var_12₀, var_12₀, var_12₀, arg_0₁, var_12₀]
- Async tests Simple async/await. Unsupported operation: Typed backend does not yet lower InvokeExternal: #completer₀ = invokeexternal 99 []
- Async tests Using a Future result. Unsupported operation: Typed backend does not yet lower InvokeExternal: #completer₀ = invokeexternal 99 []

### bridge_test.dart

- Bridge tests Awaiting a callback. CompileError: Unknown method num.< at unknown (file dart:math)
- Bridge tests Changing a field in the constructor of a subclassed bridge class. CompileError: dart_eval does not support passing named arguments to dynamic targets. at "(a + 2, b: b)" (file package:example/main.dart)
- Bridge tests Passing a map to a function externally. CompileError: Unknown method num.< at unknown (file dart:math)
- Bridge tests Runtime overrides. CompileError: Unknown method num.< at unknown (file dart:math)
- Bridge tests Should catch bridge future error. CompileError: Unknown method num.< at unknown (file dart:math)
- Bridge tests Using a bridge class. Unsupported operation: Typed backend does not yet lower BridgeInstantiate: call_3₀ = newbridge 205, var_13₀ [var_12₁]
- Bridge tests Using a bridged enum. Unsupported operation: Typed backend does not yet lower NewMap: map₀ = {}
- Bridge tests Using a subclassed bridge class inside the runtime. CompileError: dart_eval does not support passing named arguments to dynamic targets. at "(a + 2 + someNumber,..." (file package:example/main.dart)
- Bridge tests Using a subclassed bridge class outside the runtime. CompileError: dart_eval does not support passing named arguments to dynamic targets. at "(a + 2, b: b)" (file package:example/main.dart)
- Bridge tests Using an external static method. Unsupported operation: Typed backend does not yet lower InvokeExternal: method_result_1₀ = invokeexternal 206 [var_12₁]
- Bridge tests Versioned runtime overrides. CompileError: Unknown method num.< at unknown (file dart:math)
- Bridge tests Void async function in a subclassed bridge class. Unsupported operation: Typed backend does not yet lower NewBridgeSuperShim: shim₀ = #shim

### class_test.dart

- Class tests Assigning to default null field. Unsupported operation: Typed backend does not yet lower InvokeExternal: assertion_error₀ = invokeexternal 74 [var_16₁]
- Class tests Constructor field initializers. Bad state: Void function 17 returns a value
- Class tests Factory constructor. Bad state: Void function 17 returns a value
- Class tests Implicit and "this" field access from closure. Unsupported operation: Typed backend does not yet lower CreateClosure: closure₀ = closure DeferredOrOffset{offset: 19, file: null, name: null} captures [arg_0₀, arg_1₀]
- Class tests Int assigned to double setter. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_3₀ = invokeexternal 0 [value₀]
- Class tests Method call on field with inferred type from closure. Unsupported operation: Typed backend does not yet lower CreateClosure: closure₀ = closure DeferredOrOffset{offset: 18, file: null, name: null} captures [arg_0₀]
- Class tests Modifying static class field. Bad state: Incompatible representations for value₀: object and integer; an explicit conversion is required
- Class tests Nullable static value. Unsupported operation: Typed backend does not yet lower SetGlobal: setglobal 12 = var_13₁
- Class tests runtimeType. Unsupported operation: Typed backend does not yet lower LoadConstantType: var_type₀ = loadconstanttype 86
- Class tests Super parameter multi-level indirection. Unsupported operation: Typed backend does not yet lower InvokeExternal: method_result_1₀ = invokeexternal 52 [var_14₁]
- Class tests Using set value. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_3₀ = invokeexternal 0 [string_result₁]

### collection_test.dart

- Iterable tests Iterable.map(). Unsupported operation: Typed backend does not yet lower CreateClosure: closure₀ = closure DeferredOrOffset{offset: 15, file: null, name: null} captures [list_1₀]
- Map tests Access null value from map. Unsupported operation: Typed backend does not yet lower NewMap: map₀ = {}
- Map tests Add key to empty map. Unsupported operation: Typed backend does not yet lower NewMap: map₀ = {}
- Map tests Empty map literal. Unsupported operation: Typed backend does not yet lower NewMap: map₀ = {}
- Map tests List.sort() default comparator. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_3₀ = invokeexternal 0 [method_result_2₀]
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

- read definitions and SSA conversion: Map<String, int> main(Map<String, int> input) => {...input};. Unsupported operation: Typed backend does not yet lower NewMap: map₀ = {}
- read definitions and SSA conversion: Map<String, int> main(Map<String, int> input) => <String, int>{...input};. Unsupported operation: Typed backend does not yet lower NewMap: map₀ = {}
- read definitions and SSA conversion: Map<String, int> main(Map<String, int>? input) => <String, int>{...?input};. Unsupported operation: Typed backend does not yet lower NewMap: map₀ = {}
- read definitions and SSA conversion: Set<int> main(Set<int> input) => <int>{0, ...input};. Unsupported operation: Typed backend does not yet lower NewSet: set₀ = set {}

### compiler_cfg_test.dart

- closure captures and parameters belong to a separate function graph. Unsupported operation: Typed backend does not yet lower CreateClosure: closure₀ = closure DeferredOrOffset{offset: 15, file: null, name: null} captures [arg_0₀]

### compiler_control_flow_test.dart

- try finally handler is reachable without a self edge. Unsupported operation: Typed backend does not yet lower EnterTry: Instance of 'EnterTry'

### compiler_declarations_cfg_test.dart

- enum A { first, second } int main() => A.second.index;. Unsupported operation: Typed backend does not yet lower LoadGlobal: second₀ = loadglobal 13
- Future<int> f() async => 1; Future<int> main() async { return await f(); }. Unsupported operation: Typed backend does not yet lower InvokeExternal: #completer₀ = invokeexternal 99 []
- int main() { try { return 1; } finally { print(2); } }. Unsupported operation: Typed backend does not yet lower EnterTry: Instance of 'EnterTry'
- int main() { try { throw 1; } catch (e) { return 2; } }. Unsupported operation: Typed backend does not yet lower EnterTry: Instance of 'EnterTry'
- int main() { try { throw 1; } on String catch (e) { return 2; } catch (e, s) { return 3; } }. Unsupported operation: Typed backend does not yet lower EnterTry: Instance of 'EnterTry'

### compiler_ssa_test.dart

- SSA dominance: async await preserves explicit results. Unsupported operation: Typed backend does not yet lower InvokeExternal: #completer₀ = invokeexternal 99 []
- SSA dominance: enum instance and getter. Unsupported operation: Typed backend does not yet lower LoadGlobal: active₀ = loadglobal 13
- SSA dominance: finally executes around early return. Unsupported operation: Typed backend does not yet lower EnterTry: Instance of 'EnterTry'
- SSA dominance: mutable local captured by a closure. Unsupported operation: Typed backend does not yet lower CreateClosure: closure₀ = closure DeferredOrOffset{offset: 15, file: null, name: null} captures [count₀]
- SSA dominance: typed catch with local mutation. Unsupported operation: Typed backend does not yet lower EnterTry: Instance of 'EnterTry'

### convert_test.dart

- dart:convert tests Accessing results of json.decode(). Unsupported operation: Typed backend does not yet lower LoadGlobal: json₀ = loadglobal 1
- dart:convert tests base64.decode(). Unsupported operation: Typed backend does not yet lower LoadGlobal: base64₀ = loadglobal 3
- dart:convert tests base64.encode(). Unsupported operation: Typed backend does not yet lower LoadGlobal: base64₀ = loadglobal 3
- dart:convert tests base64Url.decode(). Unsupported operation: Typed backend does not yet lower LoadGlobal: base64Url₀ = loadglobal 2
- dart:convert tests base64Url.encode(). Unsupported operation: Typed backend does not yet lower LoadGlobal: base64Url₀ = loadglobal 2
- dart:convert tests json.decode(). Unsupported operation: Typed backend does not yet lower LoadGlobal: json₀ = loadglobal 1
- dart:convert tests json.encode(). Unsupported operation: Typed backend does not yet lower LoadGlobal: json₀ = loadglobal 1
- dart:convert tests jsonDecode(). Unsupported operation: Typed backend does not yet lower InvokeExternal: call_3₀ = invokeexternal 229 [var_12₁, var_13₀]
- dart:convert tests jsonEncode(). Unsupported operation: Typed backend does not yet lower NewMap: map₀ = {}
- dart:convert tests utf8.decode(). Unsupported operation: Typed backend does not yet lower LoadGlobal: utf8₀ = loadglobal 0
- dart:convert tests utf8.encode(). Unsupported operation: Typed backend does not yet lower LoadGlobal: utf8₀ = loadglobal 0

### datetime_test.dart

- datetime add subtract. Unsupported operation: Typed backend does not yet lower InvokeExternal: method_result_1₀ = invokeexternal 50 [var_12₁]
- datetime compareTo. Unsupported operation: Typed backend does not yet lower InvokeExternal: method_result_1₀ = invokeexternal 50 [var_12₁]
- DateTime default constructor. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_3₀ = invokeexternal 48 [var_12₁, var_13₁, var_14₁, var_15₁, var_16₁, var_17₀, var_17₀, var_17₀]
- datetime difference. Unsupported operation: Typed backend does not yet lower InvokeExternal: method_result_1₀ = invokeexternal 50 [var_12₁]
- datetime isAfter isBefore. Unsupported operation: Typed backend does not yet lower InvokeExternal: method_result_1₀ = invokeexternal 50 [var_12₁]
- datetime parse. Unsupported operation: Typed backend does not yet lower InvokeExternal: method_result_1₀ = invokeexternal 50 [var_12₁]
- datetime year month day. Unsupported operation: Typed backend does not yet lower InvokeExternal: method_result_1₀ = invokeexternal 50 [var_12₁]

### enum_test.dart

- Enum tests Basic enum. Unsupported operation: Typed backend does not yet lower LoadGlobal: B₀ = loadglobal 13
- Enum tests Enum boxing error. CompileError: Unknown method num.< at unknown (file dart:math)
- Enum tests Enum equality. Unsupported operation: Typed backend does not yet lower LoadGlobal: B₀ = loadglobal 13
- Enum tests Enum value index property from imported file. Unsupported operation: Typed backend does not yet lower LoadGlobal: beta₀ = loadglobal 13
- Enum tests Enum with field. Unsupported operation: Typed backend does not yet lower LoadGlobal: B₀ = loadglobal 13

### exception_representation_test.dart

- return preserves its representation across handler normalization. Unsupported operation: Typed backend does not yet lower EnterTry: Instance of 'EnterTry'
- throw preserves the local value across handler normalization. Unsupported operation: Typed backend does not yet lower EnterTry: Instance of 'EnterTry'
- throwing an unboxed parameter preserves boxed exception ABI. Unsupported operation: Typed backend does not yet lower EnterTry: Instance of 'EnterTry'

### exception_test.dart

- Exception tests Basic try/catch. Unsupported operation: Typed backend does not yet lower EnterTry: Instance of 'EnterTry'
- Exception tests Catching exception after await. Unsupported operation: Typed backend does not yet lower InvokeExternal: #completer₀ = invokeexternal 99 []
- Exception tests Code runs after caught exception. Unsupported operation: Typed backend does not yet lower EnterTry: Instance of 'EnterTry'
- Exception tests DateTime.parse throwing exception. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_4₀ = invokeexternal 0 [a₀]
- Exception tests Error propagates through empty finally. Unsupported operation: Typed backend does not yet lower EnterTry: Instance of 'EnterTry'
- Exception tests Exception bubbles through asynchronous gap. Unsupported operation: Typed backend does not yet lower InvokeExternal: #completer₀ = invokeexternal 99 []
- Exception tests Finally can do work and return value from catch. Bad state: Missing handler finally
- Exception tests Manipulating local variables in catch and finally. Unsupported operation: Typed backend does not yet lower EnterTry: Instance of 'EnterTry'
- Exception tests Nested try/catch. Unsupported operation: Typed backend does not yet lower EnterTry: Instance of 'EnterTry'
- Exception tests Nested try/catch/finally. Unsupported operation: Typed backend does not yet lower EnterTry: Instance of 'EnterTry'
- Exception tests Rethrow. Unsupported operation: Typed backend does not yet lower EnterTry: Instance of 'EnterTry'
- Exception tests Return from catch is preceded by finally return. Bad state: Missing handler finally
- Exception tests Return from finally precedes error. Unsupported operation: Typed backend does not yet lower EnterTry: Instance of 'EnterTry'
- Exception tests Simple assert. Unsupported operation: Typed backend does not yet lower InvokeExternal: assertion_error₀ = invokeexternal 74 [var_13₁]
- Exception tests Try without throw skips catch but executes finally. Unsupported operation: Typed backend does not yet lower EnterTry: Instance of 'EnterTry'
- Exception tests try-catch-finally with Exception constructor. Bad state: Assignment or phi has incompatible representations: log₉, string_result_2₀ (object, string)
- Exception tests Try/catch across function boundaries. Unsupported operation: Typed backend does not yet lower EnterTry: Instance of 'EnterTry'
- Exception tests Try/catch no error. Unsupported operation: Typed backend does not yet lower EnterTry: Instance of 'EnterTry'
- Exception tests Try/catch with on. Unsupported operation: Typed backend does not yet lower EnterTry: Instance of 'EnterTry'

### expression_test.dart

- Expression tests "is" expression. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_3₀ = invokeexternal 0 [var_13₁]
- Expression tests Bitwise int operators. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_3₀ = invokeexternal 0 [invoke_result_2₀]
- Expression tests Cascade with method call. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_3₀ = invokeexternal 0 [a₀]
- Expression tests Class cast. Unsupported operation: Typed backend does not yet lower AssertType: asserttype x₀ is 86
- Expression tests Failing cast. Unsupported operation: Typed backend does not yet lower AssertType: asserttype x₀ is 87
- Expression tests Is num. Null check operator used on a null value
- Expression tests Not expression. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_3₀ = invokeexternal 0 [not_result₁]
- Expression tests Null assertion. Unsupported operation: Typed backend does not yet lower InvokeExternal: assertion_error₀ = invokeexternal 74 [var_14₁]
- Expression tests Null coalescing assignment. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_3₀ = invokeexternal 0 [var_12₃]
- Expression tests Null coalescing copy method. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_5₀ = invokeexternal 0 [method_result_1₀]
- Expression tests Null coalescing operator. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_3₀ = invokeexternal 0 [var_13₃]
- Expression tests Null-shorted method call. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_3₀ = invokeexternal 0 [var_13₁]
- Expression tests Null-shorted property access. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_3₀ = invokeexternal 0 [var_13₁]
- Expression tests Num cast. Unsupported operation: Typed backend does not yet lower AssertType: asserttype x₀ is 12
- Expression tests Short-circuiting logical operators. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_3₀ = invokeexternal 0 [var_12₁]
- Expression tests Simple cascade. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_3₀ = invokeexternal 0 [a₀]

### field_test.dart

- Regular classes test Final fields test. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_4₀ = invokeexternal 0 [value₀]

### filesystem_permission_test.dart

- FilesystemPermission Tests resolves relative file paths using currentDir with permissions. Unsupported operation: Typed backend does not yet lower InvokeExternal: #completer₀ = invokeexternal 99 []
- FilesystemPermission Tests should allow file operations in subdirectory using relative path when currentDir is set and permission is granted for parent directory. Unsupported operation: Typed backend does not yet lower InvokeExternal: #completer₀ = invokeexternal 99 []
- FilesystemPermission Tests should allow file read/write/delete using IOOverrides for currentDir. Unsupported operation: Typed backend does not yet lower InvokeExternal: #completer₀ = invokeexternal 99 []

### function_test.dart

- Function tests Anonymous function with arg. Unsupported operation: Typed backend does not yet lower CreateClosure: closure₀ = closure DeferredOrOffset{offset: 15, file: null, name: null} captures []
- Function tests Anonymous function with many unordered named args. Unsupported operation: Typed backend does not yet lower CreateClosure: closure₀ = closure DeferredOrOffset{offset: 15, file: null, name: null} captures []
- Function tests Anonymous function with named args, different sorting from call site. Unsupported operation: Typed backend does not yet lower CreateClosure: closure₀ = closure DeferredOrOffset{offset: 15, file: null, name: null} captures []
- Function tests Anonymous function with named args, one unspecified. Unsupported operation: Typed backend does not yet lower CreateClosure: closure₀ = closure DeferredOrOffset{offset: 15, file: null, name: null} captures []
- Function tests Anonymous function with named args, same sorting as call site. Unsupported operation: Typed backend does not yet lower CreateClosure: closure₀ = closure DeferredOrOffset{offset: 15, file: null, name: null} captures []
- Function tests Arrow function expression. Unsupported operation: Typed backend does not yet lower CreateClosure: closure₀ = closure DeferredOrOffset{offset: 15, file: null, name: null} captures []
- Function tests Basic anonymous function. Unsupported operation: Typed backend does not yet lower CreateClosure: closure₀ = closure DeferredOrOffset{offset: 15, file: null, name: null} captures []
- Function tests Basic generic function type. Unsupported operation: Typed backend does not yet lower CreateClosure: closure₀ = closure DeferredOrOffset{offset: 15, file: null, name: null} captures []
- Function tests Basic inline anonymous function. Unsupported operation: Typed backend does not yet lower CreateClosure: closure₀ = closure DeferredOrOffset{offset: 15, file: null, name: null} captures []
- Function tests Closure can modify variable outside its scope. Unsupported operation: Typed backend does not yet lower CreateClosure: closure₀ = closure DeferredOrOffset{offset: 15, file: null, name: null} captures [k₀]
- Function tests Closure with arg. Unsupported operation: Typed backend does not yet lower CreateClosure: closure₀ = closure DeferredOrOffset{offset: 16, file: null, name: null} captures [b₀]
- Function tests Function equality test. Unsupported operation: Typed backend does not yet lower LoadGlobal: instance_1₀ = loadglobal 12
- Function tests Indexing outer list from a closure. Unsupported operation: Typed backend does not yet lower CreateClosure: closure₀ = closure DeferredOrOffset{offset: 15, file: null, name: null} captures [list_1₀]

### functional1_test.dart

- Functional tests Await chain. Unsupported operation: Typed backend does not yet lower InvokeExternal: #completer₀ = invokeexternal 99 []
- Functional tests Bridged enum equality ternary assignment. CompileError: Unknown method num.< at unknown (file dart:math)
- Functional tests Default parameter boxing error. Unsupported operation: Typed backend does not yet lower InvokeExternal: #completer₀ = invokeexternal 99 []
- Functional tests Matches test from Readme. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_4₀ = invokeexternal 0 [parentheses₀]
- Functional tests Matches test from Readme using ofProgram. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_4₀ = invokeexternal 0 [parentheses₀]
- Functional tests Regex replacement loop. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_4₀ = invokeexternal 0 [call_3₀]
- Functional tests Regexp firstMatch bug. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_3₀ = invokeexternal 73 [var_12₁, var_13₀, var_13₀, var_13₀, var_13₀]
- Functional tests String split loop. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_3₀ = invokeexternal 0 [string_result₁]
- Functional tests Sum to. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_4₀ = invokeexternal 0 [call_3₁]

### hlc_test.dart

- package:hlc. Unsupported operation: Typed backend does not yet lower LoadGlobal: delimiter_2₀ = loadglobal 12

### io_test.dart

- dart:io tests HttpClient get(). Unsupported operation: Typed backend does not yet lower InvokeExternal: #completer₀ = invokeexternal 99 []
- dart:io tests HttpClient get() permission denied. Unsupported operation: Typed backend does not yet lower InvokeExternal: #completer₀ = invokeexternal 99 []
- dart:io tests HttpStatus constants. Bad state: Incompatible representations for ok₀: object and integer; an explicit conversion is required
- dart:io tests Write/read a file. Unsupported operation: Typed backend does not yet lower InvokeExternal: #completer₀ = invokeexternal 99 []

### lib_composition_test.dart

- File and library composition Cyclic imports. Bad state: Incompatible representations for constant₀: object and integer; an explicit conversion is required

### local_fn_test.dart

- local function accessing outer variable. Unsupported operation: Typed backend does not yet lower CreateClosure: closure₀ = closure DeferredOrOffset{offset: 15, file: null, name: null} captures [multiplier₀]
- local function calling another local function. Unsupported operation: Typed backend does not yet lower CreateClosure: closure₀ = closure DeferredOrOffset{offset: 15, file: null, name: null} captures []
- local function with block body. Unsupported operation: Typed backend does not yet lower CreateClosure: closure₀ = closure DeferredOrOffset{offset: 15, file: null, name: null} captures []
- simple local function. Unsupported operation: Typed backend does not yet lower CreateClosure: closure₀ = closure DeferredOrOffset{offset: 15, file: null, name: null} captures []

### loop_test.dart

- Loop tests For loop with break. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_3₀ = invokeexternal 0 [i₃]

### operator_test.dart

- Operator method tests Operator ==. Unsupported operation: Typed backend does not yet lower IsType: istype arg_1₀ is 86

### pattern_test.dart

- Patterns Destructure list with variable declaration pattern. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_3₀ = invokeexternal 0 [first₀]
- Patterns Destructure record across function boundary. Null check operator used on a null value
- Patterns Destructure record with variable assignment pattern. Null check operator used on a null value
- Patterns Destructure record with variable declaration pattern. Null check operator used on a null value
- Switch pattern tests Switch matching record pattern. Null check operator used on a null value
- Switch pattern tests Switch with pattern guard. Null check operator used on a null value
- Switch pattern tests Switch with relational pattern. Bad state: Incompatible representations for data₂: integer and object; an explicit conversion is required

### postfix_test.dart

- Postfix i--. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_3₀ = invokeexternal 0 [di₁]
- Postfix i++. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_3₀ = invokeexternal 0 [di₁]

### prefix_test.dart

- Prefix --i. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_3₀ = invokeexternal 0 [di₁]
- Prefix ++i. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_3₀ = invokeexternal 0 [di₁]

### prefixed_import_test.dart

- Prefixed imports Importing constant via prefix. Bad state: Incompatible representations for plus₀: object and integer; an explicit conversion is required

### records_test.dart

- Records Create and access records. Null check operator used on a null value
- Records Record with mixed fields. Null check operator used on a null value
- Records Record with named fields. Null check operator used on a null value
- Records Returning record from function. Null check operator used on a null value

### regexp_test.dart

- Regex Tests RegExp.allMatches(). Unsupported operation: Typed backend does not yet lower InvokeExternal: call_3₀ = invokeexternal 73 [var_12₁, var_13₀, var_13₀, var_13₀, var_13₀]
- Regex Tests RegExp.firstMatch(). Unsupported operation: Typed backend does not yet lower InvokeExternal: call_3₀ = invokeexternal 73 [var_13₁, var_14₀, var_14₀, var_14₀, var_14₀]
- Regex Tests RegExp.groups. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_3₀ = invokeexternal 73 [var_13₁, var_14₀, var_14₀, var_14₀, var_14₀]
- Regex Tests RegExp.stringMatch() if has match. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_3₀ = invokeexternal 73 [var_13₁, var_14₀, var_14₀, var_14₀, var_14₀]
- Regex Tests RegExp.stringMatch() if no match. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_3₀ = invokeexternal 73 [var_13₁, var_14₀, var_14₀, var_14₀, var_14₀]
- RegExp.groupCount. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_3₀ = invokeexternal 73 [var_13₁, var_14₀, var_14₀, var_14₀, var_14₀]
- RegExp.groupNames. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_3₀ = invokeexternal 73 [var_12₁, var_13₀, var_13₀, var_13₀, var_13₀]
- RegExp.input. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_3₀ = invokeexternal 73 [var_13₁, var_14₀, var_14₀, var_14₀, var_14₀]
- RegExp.pattern. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_3₀ = invokeexternal 73 [var_13₁, var_14₀, var_14₀, var_14₀, var_14₀]

### register_backend_test.dart

- anonymous and local functions receive zero-based boxed arguments. Unsupported operation: Typed backend does not yet lower CreateClosure: closure₀ = closure DeferredOrOffset{offset: 15, file: null, name: null} captures []
- top-level tearoffs adapt primitive arguments and named defaults. Unsupported operation: Typed backend does not yet lower CreateClosure: tearoff₀ = closure DeferredOrOffset{offset: null, file: 7, name: add} captures []

### set_test.dart

- Set tests Adding elements to a set. Unsupported operation: Typed backend does not yet lower NewSet: set₀ = set {}
- Set tests Creating a set. Unsupported operation: Typed backend does not yet lower NewSet: set₀ = set {}
- Set tests Nested set. Unsupported operation: Typed backend does not yet lower NewSet: set₀ = set {}
- Set tests Removing elements from a set. Unsupported operation: Typed backend does not yet lower NewSet: set₀ = set {}
- Set tests Set intersection operation. Unsupported operation: Typed backend does not yet lower NewSet: set₀ = set {}
- Set tests Set union operation. Unsupported operation: Typed backend does not yet lower NewSet: set₀ = set {}
- Set tests Set with type parameters. Unsupported operation: Typed backend does not yet lower NewSet: set₀ = set {}

### stdlib_test.dart

- Standard library tests Boolean literals. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_3₀ = invokeexternal 0 [a₁]
- Standard library tests Boxed bools, logical && and ||. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_3₀ = invokeexternal 0 [var_14₃]
- Standard library tests Boxed null. Unsupported operation: Typed backend does not yet lower IndexMap: map₀ = indexmap a₁[var_12₁]
- Standard library tests dart:math. Bad state: Incompatible representations for pi₀: object and doublePrecision; an explicit conversion is required
- Standard library tests dart:math Point. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_3₀ = invokeexternal 230 [var_12₁, var_13₁]
- Standard library tests double + dynamic. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_3₀ = invokeexternal 0 [invoke_result_2₀]
- Standard library tests double.infinity. Unsupported operation: Typed backend does not yet lower InvokeExternal: infinity₀ = invokeexternal 11 []
- Standard library tests double.parse(). Unsupported operation: Typed backend does not yet lower InvokeExternal: method_result_1₀ = invokeexternal 8 [var_12₁, var_13₀]
- Standard library tests double.parse() throws FormatException without onError. Unsupported operation: Typed backend does not yet lower EnterTry: Instance of 'EnterTry'
- Standard library tests double.parse() with onError callback. Unsupported operation: Typed backend does not yet lower CreateClosure: closure₀ = closure DeferredOrOffset{offset: 15, file: null, name: null} captures []
- Standard library tests double.tryParse(). Unsupported operation: Typed backend does not yet lower InvokeExternal: method_result_1₀ = invokeexternal 9 [var_12₁]
- Standard library tests double.tryParse() returns null for invalid input. Unsupported operation: Typed backend does not yet lower InvokeExternal: method_result_1₀ = invokeexternal 9 [var_12₁]
- Standard library tests dynamic.toString. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_4₀ = invokeexternal 0 [method_result_1₀]
- Standard library tests int.compareTo. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_3₀ = invokeexternal 0 [invoke_result_2₀]
- Standard library tests int.parse in map chain with accumulation. Unsupported operation: Typed backend does not yet lower CreateClosure: closure₀ = closure DeferredOrOffset{offset: 15, file: null, name: null} captures [raw₀]
- Standard library tests int.parse value from String.split. Unsupported operation: Typed backend does not yet lower InvokeExternal: method_result_2₀ = invokeexternal 6 [list₀, var_15₀]
- Standard library tests Iterable.generate. Unsupported operation: Typed backend does not yet lower CreateClosure: closure₀ = closure DeferredOrOffset{offset: 15, file: null, name: null} captures []
- Standard library tests Iterable.generate without generator. Unsupported operation: Typed backend does not yet lower InvokeExternal: method_result_1₀ = invokeexternal 16 [var_12₁, var_13₀]
- Standard library tests List.from. Unsupported operation: Typed backend does not yet lower InvokeExternal: instance₀ = invokeexternal 23 [list₁, var_15₁]
- Standard library tests List.generate. Unsupported operation: Typed backend does not yet lower CreateClosure: closure₀ = closure DeferredOrOffset{offset: 15, file: null, name: null} captures []
- Standard library tests List.of. Unsupported operation: Typed backend does not yet lower InvokeExternal: method_result_1₀ = invokeexternal 24 [list₁, var_15₁]
- Standard library tests List.where. Unsupported operation: Typed backend does not yet lower CreateClosure: closure₀ = closure DeferredOrOffset{offset: 15, file: null, name: null} captures [a₀]
- Standard library tests num -= dynamic in loop. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_3₀ = invokeexternal 0 [x₁]
- Standard library tests Num add. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_4₀ = invokeexternal 0 [call_3₀]
- Standard library tests num.abs. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_3₀ = invokeexternal 0 [method_result_1₀]
- Standard library tests num.isInfinite. Unsupported operation: Typed backend does not yet lower InvokeExternal: infinity₀ = invokeexternal 11 []
- Standard library tests num.isNaN. Unsupported operation: Typed backend does not yet lower InvokeExternal: nan₀ = invokeexternal 10 []
- Standard library tests num.sign. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_3₀ = invokeexternal 0 [sign₀]
- Standard library tests num.toDouble. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_3₀ = invokeexternal 0 [method_result_1₀]
- Standard library tests Num/int parse and tryParse. Unsupported operation: Typed backend does not yet lower InvokeExternal: method_result_1₀ = invokeexternal 4 [var_12₁, var_13₀]
- Standard library tests Object.hash. Unsupported operation: Typed backend does not yet lower InvokeExternal: method_result_1₀ = invokeexternal 2 [var_12₁, var_13₁, var_14₁, var_15₀, var_15₀, var_15₀, var_15₀, var_15₀, var_15₀, var_15₀, var_15₀, var_15₀, var...
- Standard library tests Pattern allMatches() with RegExp. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_3₀ = invokeexternal 73 [var_12₁, var_13₀, var_13₀, var_13₀, var_13₀]
- Standard library tests print(). Unsupported operation: Typed backend does not yet lower InvokeExternal: call_3₀ = invokeexternal 0 [arg_0₁]
- Standard library tests Printing hashCode. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_3₀ = invokeexternal 0 [string_result₁]
- Standard library tests RegExp hasMatch(). Unsupported operation: Typed backend does not yet lower InvokeExternal: call_3₀ = invokeexternal 73 [var_12₁, var_13₀, var_13₀, var_13₀, var_13₀]
- Standard library tests RegExp hasMatch(). Unsupported operation: Typed backend does not yet lower InvokeExternal: call_3₀ = invokeexternal 73 [var_12₁, var_13₀, var_13₀, var_13₀, var_13₀]
- Standard library tests StreamController and Stream.listen(). Unsupported operation: Typed backend does not yet lower InvokeExternal: #completer₀ = invokeexternal 99 []
- Standard library tests String interpolation. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_3₀ = invokeexternal 0 [string_result_2₁]

### string_test.dart

- String Class method tests String has substring method. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_3₀ = invokeexternal 0 [sub₀]
- String Class method tests String substring method works with only 1 parameter. Unsupported operation: Typed backend does not yet lower InvokeExternal: call_3₀ = invokeexternal 0 [sub₀]

### switch_test.dart

- Switch statement tests Basic switch with int cases. Bad state: Incompatible representations for x₂: integer and object; an explicit conversion is required
- Switch statement tests Nested switch statements. Bad state: Incompatible representations for x₂: integer and object; an explicit conversion is required
- Switch statement tests Switch with break statements. Bad state: Incompatible representations for x₂: integer and object; an explicit conversion is required
- Switch statement tests Switch with const expression case. Bad state: Incompatible representations for VALUE₀: object and integer; an explicit conversion is required
- Switch statement tests Switch with default case. Bad state: Incompatible representations for x₂: integer and object; an explicit conversion is required
- Switch statement tests Switch with enum and proper fall-through. Unsupported operation: Typed backend does not yet lower LoadGlobal: segunda₀ = loadglobal 12
- Switch statement tests Switch with enum and vowel/consonant classification. Unsupported operation: Typed backend does not yet lower LoadGlobal: a₀ = loadglobal 12
- Switch statement tests Switch with enum weekend case. Unsupported operation: Typed backend does not yet lower LoadGlobal: segunda₀ = loadglobal 12
- Switch statement tests Switch with expression evaluation. Bad state: Incompatible representations for numeric_result₂: integer and object; an explicit conversion is required
- Switch statement tests Switch with function calls in cases. Bad state: Incompatible representations for x₂: integer and object; an explicit conversion is required
- Switch statement tests Switch with multiple empty cases (enum-like). Bad state: Incompatible representations for day₂: integer and object; an explicit conversion is required
- Switch statement tests Switch with multiple statements per case. Bad state: Incompatible representations for x₂: integer and object; an explicit conversion is required
- Switch statement tests Switch with no matching case and no default. Bad state: Incompatible representations for x₂: integer and object; an explicit conversion is required
- Switch statement tests Switch with proper fall-through (empty cases). Bad state: Incompatible representations for x₂: integer and object; an explicit conversion is required
- Switch statement tests Switch with return in default case. Bad state: Incompatible representations for x₂: integer and object; an explicit conversion is required
- Switch statement tests Switch with variable assignment in cases. Bad state: Incompatible representations for x₂: integer and object; an explicit conversion is required

### tearoff_test.dart

- Function tests Method tearoffs. Unsupported operation: Typed backend does not yet lower CreateClosure: tearoff₀ = closure DeferredOrOffset{offset: null, file: 7, name: add} captures [arg_0₀]
- Function tests Simple tearoff. Unsupported operation: Typed backend does not yet lower CreateClosure: tearoff₀ = closure DeferredOrOffset{offset: null, file: 7, name: fun} captures []
- Function tests Tearoff as argument. Unsupported operation: Typed backend does not yet lower CreateClosure: tearoff₀ = closure DeferredOrOffset{offset: null, file: 7, name: fun2} captures []

### uri_test.dart

- Uri getters tests Uri boolean tests. Unsupported operation: Typed backend does not yet lower InvokeExternal: method_result_1₀ = invokeexternal 52 [uri₀]
- Uri getters tests Uri().authority. Unsupported operation: Typed backend does not yet lower InvokeExternal: method_result_1₀ = invokeexternal 52 [uri₀]
- Uri getters tests Uri().fragment. Unsupported operation: Typed backend does not yet lower InvokeExternal: method_result_1₀ = invokeexternal 52 [uri₀]
- Uri getters tests Uri().host. Unsupported operation: Typed backend does not yet lower InvokeExternal: method_result_1₀ = invokeexternal 52 [uri₀]
- Uri getters tests Uri().path. Unsupported operation: Typed backend does not yet lower InvokeExternal: method_result_1₀ = invokeexternal 52 [uri₀]
- Uri getters tests Uri().pathSegments. Unsupported operation: Typed backend does not yet lower InvokeExternal: method_result_1₀ = invokeexternal 52 [uri₀]
- Uri getters tests Uri().port. Unsupported operation: Typed backend does not yet lower InvokeExternal: method_result_1₀ = invokeexternal 52 [uri₀]
- Uri getters tests Uri().query. Unsupported operation: Typed backend does not yet lower InvokeExternal: method_result_1₀ = invokeexternal 52 [uri₀]
- Uri getters tests Uri().queryParameters. Unsupported operation: Typed backend does not yet lower InvokeExternal: method_result_1₀ = invokeexternal 52 [uri₀]
- Uri getters tests Uri().queryParametersAll. Unsupported operation: Typed backend does not yet lower InvokeExternal: method_result_1₀ = invokeexternal 52 [uri₀]
- Uri getters tests Uri().userInfo. Unsupported operation: Typed backend does not yet lower InvokeExternal: method_result_1₀ = invokeexternal 52 [uri₀]

### variable_test.dart

- Top-level variable tests Assignment to top-level variable. Bad state: Incompatible representations for x₀: object and integer; an explicit conversion is required
