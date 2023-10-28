## 0.7.0
- (Breaking) Removed RuntimeTypes. All builtin types are referenced 
  with CoreTypes/AsyncTypes etc now.
- (Breaking) Improve extension method syntax and make it the default
  for examples
- (Breaking) Added tree-shaking for dead code elimination. To ensure
  a file is compiled you must add it as an entrypoint to the Compiler.
  `main.dart` is always an entrypoint. See README for details.
- Support for compiling Pub packages in the CLI
- Support tryParse() and parse() for `num` and `int`
- Support Iterable.generate() and List.generate() (thanks @wrbl606)
- Support for ++i and --i prefix operators (thanks @wrbl606)
- Fix increment and decrement operations on list elements (thanks 
  @wrbl606)
- Support for `RegExpMatch` and most RegExp methods (thanks @Noobware1)
- Support for function type arguments and inferring generic return 
  types based on argument types
- Support for Comparable
- Support invoking functions stored as fields in a class
- Add `identical` and `Object.hash` functions
- Basic support for `runtimeType`
- Add Runtime.valueToString helper for converting a $Value to a string
  correctly
- Support for default positional parameters
- Use short-circuit evaluation for null coalescing operator `??`
- Support for null-shorted method calls and property access 
  using `?.`
- Support null assertion operator `!`
- Fix type resolution with self-referential generic types such as
  `class T implements Comparable<T>`
- Support for `rethrow`
- Support for symbol literals
- Add bindings for `Exception`, `RangeError`, and `FormatException`
- Add bindings for `Symbol` and `Zone`
- Add bindings for `ByteBuffer`, `TypedData`, `ByteData`, 
  and `Uint8List` from dart:typed_data
- Add binding for `LinkedHashMap` from dart:collection
- Improved performance by optimizing to static method calls and
  field accesses when the concrete type of a variable is known
- Fix super constructor parameter type resolution
- Fix various errors when using non-reserved language keywords as 
  the name of a variable or function
- Fix incorrect type hint for String.contains()
- Fix top-level getters
- Fix named constructor calls using "new" or "const" 
- Runtime errors now print out the scope stack for easier debugging
- Reformat line length to 80 for standardization with Dart ecosystem
- Documentation improvements

## 0.6.5
- Support for try/finally and try/catch/finally
- Fix numerous bugs related to exception handling

## 0.6.4
- Support for casting (`as`)
- Support for asserts and `AssertionError`
- Add magic constant and version to EVC bytecode to prevent
  errors.
- Fix for error when extending a bridge class

## 0.6.3
- Support for cascades
- Support for null coalescing assignment operator `??=`
- Support for many `List` and `Iterable` methods (thanks @kodjodevf)
- Fix error with do-while loops
- Fix scope leak when using arrow functions
- Fix properties not being properly boxed/unboxed when passed to
  a function
- Fix constructor field initializer boxing
- Improve test coverage
- Add topics to pubspec

## 0.6.2+1
- Hotfix to increase size of globals array in runtime

## 0.6.2
- Initial support for enums
- Fix null coalescing expression
- Support for bitwise int xor operator
- Support for optional positional and unspecified
  named parameters in function expressions and tearoffs

## 0.6.1
- Support for multiple catch clauses and `on`
- $Map is now bimodal
- Fix for error when accessing values on a map returned from
  json.decode()
- Fix loops causing errors by attempting to repeatedly unbox 
  variables declared outside the loop on each iteration
- Support for bitwise int operators `|`, `&`, `<<`, and `>>`
- Support for most DateTime functions, getters, and
  `parse` / `tryParse` constructors (thanks @oneplus1000)
- Support for ! and != operators (thanks @oneplus1000)
- Support for most Duration getters (thanks @oneplus1000)
- Support automatic await of Future return values in async
  functions
- Upgrade to analyzer v6
- Support Dart 3

## 0.6.0
- (Deprecated) `BridgeTypeRef.spec`, use the default constructor instead
- (Breaking) The $runtimeType getter on $Value has been replaced with
  a $getRuntimeType method that accepts a Runtime argument.
- (Breaking) Many bridge types now use CoreTypes/AsyncTypes etc
  instead of RuntimeTypes. This allows specifying generic type
  arguments.
- (Breaking) EvalPlugin now uses the supertype `BridgeDeclarationRegistry`
  instead of Compiler in configureForCompile().
- (Breaking) Removed the typeMapper parameter from $Future. It was mostly
  useless and didn't support async/await. Use bimodal wrappers instead.
- Support for relative imports and exports
- Support for Streams and StreamController
- Support for dart:io filesystem and HTTP classes
- Basic support for try/catch and throw. Only 1 untyped catch clause is 
  supported for now, and finally is unsupported.
- Support for ternary expressions
- Support for `is` type-test expressions
- Basic support for RegExp
- Add a runtime permissions system to control access to dart:io. 
  See the README for details.
- @RuntimeOverride annotations are now parsed at compile-time
  to create dynamic runtime overrides consumed by the runtime.
  See README for details.
- Support for Utf8Codec and JsonCodec
- Add BridgeSerializer, a class that can serialize bridge classes to 
  JSON for use in the dart_eval CLI.
- Add an optional extensions syntax to make writing bridge classes
  easier (thanks @canewsin). See `examples/dart_eval_extensions_syntax.dart`.
- Add $Closure for an easier way to pass external functions as arguments
- Support modulo operator on numbers
- Add dart:math functions and constants
- Support for prefixed imports of top-level functions and constructors
- Very basic support for generic function types that simply resolves
  them to `Function`
- Improved code documentation (thanks @maxiee)
- Fix type inference using `await`
- Added type inference for class fields
- Fix method resolution on top-level variables
- Fixed an bug where compilation could fail due to a null function
  offset (thanks @maxiee)
- Fixed a type inference error where bridged functions could resolve
  incorrectly to a unboxed return type
- Fixed empty list literals causing the compiler to stall
- Fixed bugs when accessing list elements from class methods and/or
  closures
- Add a feature support table to the README

## 0.5.6
- (Breaking) Use DartTypes.list instead of RuntimeTypes.listType in bridge
  class definitions.
- Support for Iterable and for-each
- Support for collection `for`
- Fixes to branching logic
- Improved generic type inference
- Fix return value boxing in arrow functions
- Allow arrow function entrypoints in `eval()`
- Remove dcli to eliminate many extraneous dependencies
- Improved documentation

## 0.5.4
- Bindings for most String methods (thanks to @maks)
- Support for super constructor params
- Support for plugins in the `eval()` method
- Deprecated compilerSettings and runtimeSettings in `eval()`
  in favor of plugins
- Support for nullable type annotations in argument lists
- Removed the `nullable` param from KnownMethodArg in favor
  of the new `nullable` param in TypeRef
- Improved many error messages to display filename and a code
  snippet
- Error messages about type assignments now disambuigate between
  types if they have the same name
## 0.5.3
- Support for class getters and setters
- Automatic default constructor when none is specified
- Fix prefixed imports causing other types to be unresolvable

## 0.5.2
- Allow null to be boxed
- Fix Maps without explicit type parameters
- Other bug fixes

## 0.5.1
- Propagate expected types from variable declarations and 
  argument lists to the expressions they contain.
- Allow specifying doubles with int literals when the expected 
  type is known
- Fix static bridge method return types being null

## 0.5.0
Note: EVC bytecode generated with this version may not be compatible
with previous versions.
- Web support for both compiler and runtime
- Incremental parsing for faster recompilation
- New plugin system for bridge libraries to enable reusing a
  Compiler instance
- Support for tear-offs (top-level functions and methods within
  the current class only)
- Improve async/await
- Reduce size of generated bytecode

## 0.4.7
- Add bindings for the dart:math Point class
- Add Duration.zero and some other Duration static getters
- Support unary minus on ints and doubles
- Support for optional positional parameters on bridge classes

## 0.4.6
- Support for bridged static getters
- Support for top-level and class arrow functions

## 0.4.5
- Support for arrow function expressions

## 0.4.4
- CLI: allow invoking without `dart pub global run`

## 0.4.3
- CLI: Improved ease of use and documentation
- CLI: Added support for JSON bindings
- Type arguments are now applied when extending a bridge class
  that declares a generic type parameter
- `BridgeTypeRef.ref` is now supported in limited cases for
  referencing generic class type parameters
- Support for bridged getters
- Support for string interpolation
- The `eval()` method now lets you specify an output file
  path and does not automatically output a file if left
  unspecified
- Fix broken sample in README (thanks @g123k)

## 0.4.2
- Fix analyzer version constraint

## 0.4.1
- Fix a potential crash when resolving common base types.
- Support for calling methods on a bridge class's supertype without having to
  declare the method on the subtype's declaration.
- Documentation improvements

## 0.4.0
- (Breaking) You must now specify the `bridge` or `wrap` parameter in a
  `BridgeClassDef`
- (Breaking) You must now specify `isBridge: true` when registering a bridge
  class constructor with `runtime.registerBridgeFunc()`
- Support for bridged (only) enums
- Support for variable captures inside closures
- Support for implicit class field accesses including `this` and `super` in 
  closures
- Bridge declarations are now merged with a Dart source file of the same URI, if
  one exists
- Basic support for top-level variables and static fields
- Support for bool literals and logical and/or
- Support `String.substring()` (thanks to @maks)
- Now using continuous integration (thanks to @maks)
- Various bug fixes and code cleanups

## 0.3.0
- (Breaking) Modified public API for defining bridge classes. See Pub example.
- (Breaking) Relative import URIs may no longer work (it's unclear whether they
  worked before). Support will be re-added in a future release.
- (Deprecated) `Runtime.executeNamed()` is deprecated. Use `Runtime.executeLib()`
  instead.
- Compiler now uses graphs to compose libraries from imports, exports, and parts,
  and should now mostly follow the Dart spec.
- Partial support for `show` and `hide` on imports and exports
- Support defining `extends`, `implements`, and `with` on bridge classes
- Support for adding files to the compiler before compiling, for use in bridge
  libraries to enable exports.
- Add recursion guard for type resolution

## 0.2.0

- Partial support for anonymous functions and the Dart runtime type system
- New serializable interop descriptor classes to allow for code push in the future
- Runtime overrides
- Implement collection `if` for Lists
- Support for `async`/`await` via continuations, as well as `Future.then()`
- Basic CLI

## 0.1.0

- Rebuilt from the ground up around the new DBC bytecode compiler
- Public API changes: see readme
- Massive performance improvements, up to 350x
- Support for the Dart type system (compile-time checks only)
- Refactor class system to support `super`
- New simpler Bridge interop that also allows const classes

## 0.0.4

- Add support for `if`, basic `for`, number comparison operators, and postfix `++`
- Fix `+`, `-`, `*`, and `/` operators
- Improve performance significantly

## 0.0.3

- Make the Pub analyzer happy
- Add some Dartdoc comments

## 0.0.2

- Fix scoping
- Add support for List and Map types

## 0.0.1

- Create parser and interpreter
- Add interop