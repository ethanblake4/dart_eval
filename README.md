[![Build status](https://img.shields.io/github/actions/workflow/status/ethanblake4/dart_eval/dart.yml?branch=master)](https://github.com/ethanblake4/dart_eval/actions/workflows/dart.yml)
[![Star on Github](https://img.shields.io/github/stars/ethanblake4/dart_eval?logo=github&colorB=orange&label=stars)](https://github.com/ethanblake4/dart_eval)
[![License: BSD-3](https://img.shields.io/badge/license-BSD3-purple.svg)](https://opensource.org/licenses/BSD-3-Clause)
[![Web example](https://img.shields.io/badge/web-example-blue.svg)](https://ethanblake.xyz/evalpad)

`dart_eval` is an extensible bytecode compiler and interpreter for the Dart language, 
written in Dart, enabling dynamic execution and codepush for Flutter and Dart AOT.

| dart_eval    | [![pub package](https://img.shields.io/pub/v/dart_eval.svg?label=dart_eval&color=teal)](https://pub.dev/packages/dart_eval)          |
| ------------ | ------------------------------------------------------------------------------------------------------------------------------------ |
| flutter_eval | [![pub package](https://img.shields.io/pub/v/flutter_eval.svg?label=flutter_eval&color=blue)](https://pub.dev/packages/flutter_eval) |
| eval_annotation | [![pub package](https://img.shields.io/pub/v/eval_annotation.svg?label=eval_annotation&color=orange)](https://pub.dev/packages/eval_annotation) |

The primary aspect of `dart_eval`'s goal is to be interoperable with real 
Dart code. Classes created in 'real Dart' can be used inside the interpreter 
with a [wrapper](#wrapper-interop), and classes created in the interpreter 
can be used outside it by creating an interface and [bridge class](#bridge-interop).

dart_eval's compiler is powered under the hood by the Dart 
[analyzer](https://pub.dev/packages/analyzer), so it achieves 100% correct and 
up-to-date parsing. While compilation and execution aren't quite there yet, dart_eval
has over 200 tests that are run in CI to ensure correctness.

Currently dart_eval implements a majority of the Dart spec, but there 
are still missing features like generators, Sets and extension methods.
In addition, parts of the standard library haven't been implemented. See the
[language feature support table](#language-feature-support-table) for details.

## Usage

> **Note**: See the README for [flutter_eval](https://pub.dev/packages/flutter_eval) for
information on setting up Flutter code push.

A basic usage example of the `eval` method, which is a simple shorthand to
execute Dart code at runtime:

```dart
import 'package:dart_eval/dart_eval.dart';

void main() {
  print(eval('2 + 2')); // -> 4
  
  final program = r'''
      class Cat {
        Cat(this.name);
        final String name;
        String speak() => "I'm $name!";
      }
      String main() {
        final cat = Cat('Fluffy');
        return cat.speak();
      }
  ''';
  
  print(eval(program, function: 'main')); // prints 'I'm Fluffy!'
}
```

## Passing arguments
In most cases, you should wrap arguments you pass to dart_eval in `$Value`
wrappers, such as `$String` or `$Map`. These 'boxed types' have information 
about what they are and how to modify them, and you can access their underlying
value with the `$value` property. However, ints, doubles, bools, 
and Lists are treated as primitives and should be passed without wrapping
when their exact type is specified in the function signature:

```dart
final program = '''
  int main(int count, String str) {
    return count + str.length;
  }
''';

print(eval(program, function: 'main', args: [1, $String('Hi!')])); // -> 4
```

When calling a function or constructor externally, you must specify all arguments - even optional and named ones - in order, using null to indicate the absence of an argument (whereas $null() indicates a null value).

## Passing callbacks
You can pass callbacks as arguments to dart_eval using `$Closure`:
  
```dart
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';

void main() {
  final program = '''
    void main(Function callback) {
      callback('Hello');
    }
  ''';

  eval(program, function: 'main', args: [
    $Closure((runtime, target, args) {
      print(args[0]!.$value + '!');
      return null;
    })
  ]); // -> prints 'Hello!'
}
```

## Advanced usage
For more advanced usage, you can use the Compiler and Runtime classes directly,
which will allow you to use multiple 'files' and customize how the program is run:

```dart
import 'package:dart_eval/dart_eval.dart';

void main() {
  final compiler = Compiler();
  
  final program = compiler.compile({'my_package': {
    'main.dart': '''
      import 'package:my_package/finder.dart';
      void main() {
        final parentheses = findParentheses('Hello (world)');
        if (parentheses.isNotEmpty) print(parentheses); 
      }
    ''',
    'finder.dart': r'''
      List<int> findParentheses(string) {
        final regex = RegExp(r'\((.*?)\)');
        final matches = regex.allMatches(string);
        return matches.map((match) => match.start).toList();
      }
    '''
  }});
  
  final runtime = Runtime.ofProgram(program);
  print(runtime.executeLib(
    'package:my_package/main.dart', 'main')); // prints '[6]'
}
```

## Entrypoints and tree-shaking

dart_eval uses tree-shaking to avoid compiling unused code. By default, 
any file named `main.dart` or that contains [runtime overrides](#runtime-overrides) will be treated as an entrypoint and guaranteed to be compiled in its entirety. To add additional entrypoints, append URIs to the
`Compiler.entrypoints` array:

```dart
final compiler = Compiler();
compiler.entrypoints.add('package:my_package/some_file.dart');
compiler.compile(...);
```

## Compiling to a file

If possible, it's recommended to pre-compile your Dart code to EVC bytecode,
to avoid runtime compilation overhead. (This is still runtime code execution, it's
just executing a more efficient code format.) Multiple files will be compiled to a
single bytecode block.

```dart
import 'dart:io';
import 'package:dart_eval/dart_eval.dart';

void main() {
  final compiler = Compiler();
  
  final program = compiler.compile({'my_package': {
    'main.dart': '''
      int main() {
        var count = 0;
        for (var i = 0; i < 1000; i++) {
          count += i;
        }
        return count;
      }
    '''
  }});
  
  final bytecode = program.write();
  
  final file = File('program.evc');
  file.writeAsBytesSync(bytecode);
}
```

You can then load and execute the program later:

```dart
import 'dart:io';
import 'package:dart_eval/dart_eval.dart';

void main() {
  final file = File('program.evc');
  final bytecode = file
      .readAsBytesSync()
      .buffer
      .asByteData();
  
  final runtime = Runtime(bytecode);
  print(runtime.executeLib(
    'package:my_package/main.dart', 'main')); // prints '499500'
}
```

## Using the CLI
The dart_eval CLI allows you to compile existing Dart projects to EVC bytecode,
as well as run and inspect EVC bytecode files.

To enable the CLI globally, run:

`dart pub global activate dart_eval`

### Compiling a project

The CLI supports compiling standard Dart projects. To compile a project, run:

```bash
cd my_project
dart_eval compile -o program.evc
```

This will generate an EVC file in the current directory called `program.evc`.
dart_eval will attempt to compile Pub packages, but it's recommended to
avoid them as they may use features that dart_eval doesn't support yet.

The compiler also supports compiling with JSON-encoded bridge bindings. To add
these, create a folder in your project root called `.dart_eval`, add a
`bindings` subfolder, and place JSON binding files there. The compiler will
automatically load these bindings and make them available to your project.

### Running a program

To run the generated EVC file, use:

`dart_eval run program.evc -p package:my_package/main.dart -f main`

Note that the run command does *not* support bindings, so any file compiled
with bindings will need to be run in a specialized runner that includes the
necessary runtime bindings.

### Inspecting an EVC file

You can dump the op codes of an EVC file using:

`dart_eval dump program.evc`

## Return values

Like with arguments, dart_eval will return a `$Value` wrapper for most values
except ints, doubles, bools, and Lists. If you don't like this inconsistency,
specifying a function's return value as `dynamic` will force dart_eval to
always box the return value in a `$Value` wrapper.

> Note that this does not apply to the `eval()` method, which automatically
unboxes all return values for convenience.

## Security and permissions

dart_eval is designed to be secure. The dart_eval runtime functions like a virtual
machine, effectively sandboxing the code it executes. By default, the runtime will
not allow running programs to access the file system, network, or other system 
resources, but these permissions can be enabled on a granular basis using 
`runtime.grant`:

```dart
final runtime = Runtime(bytecode);

// Allow full access to the file system
runtime.grant(FilesystemPermission.any);

// Allow access to a specific network domain
runtime.grant(NetworkPermission.url('example.com'));

// Allow access to a specific network resource
runtime.grant(NetworkPermission.url('https://dart.dev/api/users.json'));

// Using the eval() method
eval(source, permissions: [
  NetworkPermission.any,
  FilesystemReadPermission.directory('/home/user/mydata'), 
]);
```

Permissions can also be revoked using `runtime.revoke`.

When writing bindings that access sensitive resources, you can check whether a 
permission is enabled using `runtime.checkPermission`, or assert using
`runtime.assertPermission`. Out of the box, dart_eval includes the FilesystemPermission
and NetworkPermission classes ('filesystem' and 'network' domains, respectively)
as well as read/write only variations of FilesystemPermission, but 
you can also create your own custom permissions by implementing the Permission
interface.

## Interop

Interop is a general term for methods in which we can access, use, and modify data
from dart_eval in Dart. Enabling this access is a high priority for dart_eval.

There are three main levels of interop:
* Value interop
* Wrapper interop
* Bridge interop

### Value interop

Value interop happens automatically whenever dart_eval is working
with an object backed by a real Dart value. (Therefore, an int and a string
are value interop enabled, but a class created inside Eval isn't.)
To access the backing object of a `$Value`, use its `$value` property. If the
value is a collection like a Map or a List, you can use its `$reified` property
to also unwrap the values it contains.

### Wrapper interop

Using a wrapper enables the Eval environment to access the functions and fields on
a class created outside Eval. It's much more powerful than value interop, and
more performant than bridge interop, making it a great choice for certain use 
cases. To use wrapper interop, create a class that implements `$Instance`, and
a compile-time class definition. Then, override `$getProperty`, `$setProperty`
and `$getRuntimeType` to enable the Eval environment to access the class's
properties and methods:

```dart
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/dart_eval_extensions.dart';

/// An example class we want to wrap
class Book {
  Book(this.pages);
  final List<String> pages;
  
  String getPage(int index) => pages[index];
}

/// This is our wrapper class
class $Book implements $Instance {
  /// Create a type specification for the dart_eval compiler
  static final $type = BridgeTypeSpec('package:hello/book.dart', 'Book').ref;

  /// Create a class declaration for the dart_eval compiler
  static final $declaration = BridgeClassDef(BridgeClassType($type),
    constructors: {
      // Define the default constructor with an empty string
      '': BridgeFunctionDef(returns: $type.annotate, params: [
        'pages'.param(CoreTypes.string.ref.annotate)
      ]).asConstructor
    },
    methods: {
      'getPage': BridgeFunctionDef(
        returns: CoreTypes.string.ref.annotate,
        params: ['index'.param(CoreTypes.int.ref.annotate)],
      ).asMethod,
    }, wrap: true);

  /// Override $value and $reified to return the value
  @override
  final Book $value;

  @override
  get $reified => $value;
  
  /// Create a constructor that wraps the Book class
  $Book.wrap(this.$value);
  
  static $Value? $new(
    Runtime runtime, $Value? target, List<$Value?> args) {
    return $Book.wrap(Book(args[0]!.$value));
  }

  /// Create a wrapper for property and method getters
  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    if (identifier == 'getPage') {
      return $Function((_, target, args) {
        return $String($value.getPage(args[0]!.$value));
      });
    }
    return $Object(this).$getProperty(runtime, identifier);
  }

  /// Create a wrapper for property setters
  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return $Object(this).$setProperty(runtime, identifier, value);
  }

  /// Allow runtime type lookup
  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);
}

/// Now we can use it in dart_eval!
void main() {
  final compiler = Compiler();
  compiler.defineBridgeClass($Book.$declaration);
  
  final program = compiler.compile({'hello' : { 
    'main.dart': '''
      import 'book.dart';
      void main() {
        final book = Book(['Hello world!', 'Hello again!']);
        print(book.getPage(1));
      }
    '''
  }});

  final runtime = Runtime.ofProgram(program);
  // Register static methods and constructors with the runtime
  runtime.registerBridgeFunc('package:hello/book.dart', 'Book.', $Book.$new);

  runtime.executeLib('package:hello/main.dart', 'main'); // -> 'Hello again!'
}
```

For more information,
see the [wrapper interop wiki page](https://github.com/ethanblake4/dart_eval/wiki/Wrappers).

#### (Experimental) Binding generation for wrappers
As of v0.7.1 the dart_eval CLI includes an experimental wrapper binding generator. 
It can be invoked in a project using `dart_eval bind`, and will generate bindings
for all classes annotated with the @Bind annotation from the eval_annotation package.
You can also pass the '--all' flag to generate bindings for all classes in the project.
Note that the generated bindings should only be used as a starting point; in 
particular, they only include placeholder runtime bindings for methods which will
need to be filled in manually.

Binding generation cannot currently create JSON bindings directly, but you can
use the generated Dart bindings to create JSON bindings using a `BridgeSerializer`.

### Bridge interop

Bridge interop enables the most functionality: Not only can dart_eval access the fields
of an object, but it can also be extended, allowing you to create subclasses within Eval
and use them outside of dart_eval. For example, this can be used to create custom
Flutter widgets that can be dynamically updated at runtime. Bridge interop is also in 
some ways simpler than creating a wrapper, but it comes at a performance cost, so should
be avoided in performance-sensitive situations. To use bridge interop, extend the original
class and mixin `$Bridge`:

```dart
// ** See previous example for the original class and imports **

/// This is our bridge class
class $Book$bridge extends Book with $Bridge<Book> {
  static final $type = ...; // See previous example
  static final $declaration = ...; // Previous example, but use bridge: true instead of wrap

  /// Recreate the original constructor
  $Book$bridge(super.pages);

  static $Value? $new(
    Runtime runtime, $Value? target, List<$Value?> args) {
    return $Book$bridge(args[0]!.$value);
  }

  @override
  $Value? $bridgeGet(String identifier) {
    if (identifier == 'getPage') {
      return $Function((_, target, args) {
        return $String(getPage(args[0]!.$value));
      });
    } 
    throw UnimplementedError('Unknown property $identifier');
  }

  @override
  $Value? $bridgeSet(String identifier) => 
    throw UnimplementedError('Unknown property $identifier');

  /// Override the original class' properties and methods
  @override
  String getPage(int index) => $_invoke('getPage', [$int(index)]);

  @override
  List<String> get pages => $_get('pages');
}

void main() {
  final compiler = Compiler();
  compiler.defineBridgeClass($Book$bridge.$declaration);
  
  final program = compiler.compile({'hello' : { 
    'main.dart': '''
      import 'book.dart';
      class MyBook extends Book {
        MyBook(List<String> pages) : super(pages);
        String getPage(int index) => 'Hello world!';
      }

      Book main() {
        final book = MyBook(['Hello world!', 'Hello again!']);
        return book;
      }
    '''
  }});

  final runtime = Runtime.ofProgram(program);
  runtime.registerBridgeFunc(
    'package:hello/book.dart', 'Book.', $Book$bridge.$new, bridge: true);

  // Now we can use the new book class outside dart_eval!
  final book = runtime.executeLib('package:hello/main.dart', 'main') 
    as Book;
  print(book.getPage(1)); // -> 'Hello world!'
}
```

An example featuring both bridge and wrapper interop is available in the 
`example` directory. For more information, see the 
[wiki page on bridge classes](https://github.com/ethanblake4/dart_eval/wiki/Bridge-classes).

## Plugins

To configure interop for compilation and runtime, it's recommended to create an
`EvalPlugin` which enables reuse of Compiler instances. Basic example:
  
```dart
class MyAppPlugin implements EvalPlugin {
  @override
  String get identifier => 'package:myapp';

  @override
  void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeTopLevelFunction(BridgeFunctionDeclaration(
      'package:myapp/functions.dart',
      'loadData',
      BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object)), params: [])
    ));
    registry.defineBridgeClass($CoolWidget.$declaration);
  }

  @override
  void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFunc('package:myapp/functions.dart', 'loadData', 
        (runtime, target, args) => $Object(loadData()));
    runtime.registerBridgeFunc('package:myapp/classes.dart', 'CoolWidget.', $CoolWidget.$new);
  }
}
```

You can then use this plugin with `Compiler.addPlugin` and `Runtime.addPlugin`.

## Runtime overrides

dart_eval includes a runtime overrides system that allows you to dynamically 
swap in new implementations of functions and constructors at runtime.
To use it, add a null-coalescing call to the `runtimeOverride()` method
at every spot you want to be able to swap:

```dart
void main() {
  // Give the override a unique ID
  final result = runtimeOverride('#myFunction') ?? myFunction();
  print(result);
}

String myFunction() => 'Original version of string';
```

Note that in some cases you may have to cast the return value of `runtimeOverride`
as dart_eval is unable to specify generic parameters to the Dart type system.

Next, mark a function in the eval code with the @RuntimeOverride annotation:

```dart
@RuntimeOverride('#myFunction')
String myFunction() => 'Updated version of string'
```

Finally, follow the normal instructions to compile and run the program, but
call `loadGlobalOverrides` on the Runtime.
This will set the runtime as the single global runtime for the program, and 
load its overrides to be accessible by hot wrappers.

When the program is run, the runtime will automatically replace the
function call with the new implementation.

Overrides can also be versioned, allowing you to roll out updates to a function
immediately using dart_eval and revert to a new native implementation after
an official update is released. To version an override, simply add a semver
version constraint to the `@RuntimeOverride` annotation:

```dart
@RuntimeOverride('#login_page_get_data', version: '<1.4.0')
```

When running the program, specify its current version by setting the value of
the `runtimeOverrideVersion` global property:

```dart
runtimeOverrideVersion = Version.parse('1.3.0');
```

Now, when the program is run, the runtime will automatically replace the instantiation
only if the app version is less than 1.4.0.

## Contributing

See [Contributing](https://github.com/ethanblake4/dart_eval/blob/master/CONTRIBUTING.md).

## FAQ

### How does it work?

`dart_eval` is a fully Dart-based implementation of a bytecode compiler and runtime. 
First, the Dart analyzer is used to parse the code into an AST (abstract syntax tree). 
Then, the compiler looks at each of the declarations in turn, and recursively compiles
to a linear bytecode format.

For evaluation dart_eval uses Dart's optimized dynamic dispatch. This means each bytecode
is actually a class implementing `EvcOp` and we call its `run()` method to execute it.
Bytecodes can do things like push and pop values on the stack, add numbers, and jump to 
other places in the program, as well as more complex Dart-specific operations like 
create a class.

See the [in-depth overview wiki page](https://github.com/ethanblake4/dart_eval/wiki/In-depth-overview) for more information.

### Does it support Flutter?

Yes! Check out [flutter_eval](https://pub.dev/packages/flutter_eval).

### How fast is it?

Preliminary testing shows that `dart_eval` running in AOT-compiled Dart 
is 10-50x slower than standard AOT Dart and is approximately on par with a 
language like Ruby.
It's important to remember this only applies to code running directly in the 
dart_eval VM, and not any code it interacts with. For example, most Flutter apps spend 
the vast majority of their performance budget in the Flutter framework itself, so the
speed impact of dart_eval is usually negligible.

## Language feature support table

The following table details the language features supported by dart_eval with native Dart code. Feature support
may vary when bridging.

| Feature | Support level | Tests |
| ------- | ------------- | ----- |
| Imports | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/lib_composition_test.dart#L14), [[2]](https://github.com/ethanblake4/dart_eval/blob/master/test/lib_composition_test.dart#L144), [[3]](https://github.com/ethanblake4/dart_eval/blob/master/test/lib_composition_test.dart#L176)  |
| Exports | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/lib_composition_test.dart#L45), [[2]](https://github.com/ethanblake4/dart_eval/blob/master/test/lib_composition_test.dart#L200) |
| `part` / `part of` | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/statement_test.dart#L76) |
| `show` and `hide` | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/statement_test.dart#L14) |
| Conditional imports | ❌ | N/A |
| Deferred imports | ❌ | N/A |
| Functions | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/function_test.dart#L36) |
| Anonymous functions | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/function_test.dart#L104), [[2]](https://github.com/ethanblake4/dart_eval/blob/master/test/function_test.dart#L124), [[3]](https://github.com/ethanblake4/dart_eval/blob/master/test/function_test.dart#L141), [[4]](https://github.com/ethanblake4/dart_eval/blob/master/test/function_test.dart#L159), [[5]](https://github.com/ethanblake4/dart_eval/blob/master/test/function_test.dart#L177), [[6]](https://github.com/ethanblake4/dart_eval/blob/master/test/function_test.dart#L195) |
| Arrow functions | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/function_test.dart#L237), [[2]](https://github.com/ethanblake4/dart_eval/blob/master/test/function_test.dart#L249) |
| Sync generators | ❌ | N/A |
| Async generators | ❌ | N/A |
| Tear-offs | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/tearoff_test.dart#L12), [[2]](https://github.com/ethanblake4/dart_eval/blob/master/test/tearoff_test.dart#L31), [[3]](https://github.com/ethanblake4/dart_eval/blob/master/test/tearoff_test.dart#L53) |
| For loops | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/loop_test.dart#L13), [[2]](https://github.com/ethanblake4/dart_eval/blob/master/test/loop_test.dart#L28) |
| While loops | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/loop_test.dart#L69) |
| Do-while loops | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/loop_test.dart#L86) |
| For-each loops | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/statement_test.dart#L52) |
| Async for-each | ❌ | N/A |
| Switch statements | ❌ | N/A |
| Labels and `break` | ❌ | N/A |
| If statements | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/loop_test.dart#L28) |
| Try-catch | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/exception_test.dart#L13), [[2]](https://github.com/ethanblake4/dart_eval/blob/master/test/exception_test.dart#31), [[3]](https://github.com/ethanblake4/dart_eval/blob/master/test/exception_test.dart#49), [[4]](https://github.com/ethanblake4/dart_eval/blob/master/test/exception_test.dart#71), [[5]](https://github.com/ethanblake4/dart_eval/blob/master/test/exception_test.dart#92) |
| Try-catch-finally | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/exception_test.dart#L132), [[2]](https://github.com/ethanblake4/dart_eval/blob/master/test/exception_test.dart#147), [[3]](https://github.com/ethanblake4/dart_eval/blob/master/test/exception_test.dart#187), [[4]](https://github.com/ethanblake4/dart_eval/blob/master/test/exception_test.dart#209), [[5]](https://github.com/ethanblake4/dart_eval/blob/master/test/exception_test.dart#231) |
| Lists | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/collection_test.dart) |
| Iterable | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/collection_test.dart#L14), [[2]](https://github.com/ethanblake4/dart_eval/blob/master/test/collection_test.dart#L29) |
| Maps | Partial | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/convert_test.dart#L60) |
| Sets | ❌ | N/A |
| Collection `for` | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/collection_test.dart#L14), [[2]](https://github.com/ethanblake4/dart_eval/blob/master/test/collection_test.dart#L76) |
| Collection `if` | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/collection_test.dart#L14), [[2]](https://github.com/ethanblake4/dart_eval/blob/master/test/collection_test.dart#L52) |
| Spreads | ❌ | N/A |
| Classes | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/class_test.dart) |
| Class static methods | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/class_test.dart#L147), [[2]](https://github.com/ethanblake4/dart_eval/blob/master/test/class_test.dart#L167) |
| Getters and setters | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/class_test.dart#L253) |
| Factory constructors | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/class_test.dart#L375) |
| `new` keyword | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/class_test.dart#L195) |
| Class inheritance | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/functional1_test.dart) |
| Abstract and `implements` | Partial | ❌ |
| `this` keyword | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/class_test.dart#L89), [[2]](https://github.com/ethanblake4/dart_eval/blob/master/test/class_test.dart#L116) |
| `super` keyword | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/class_test.dart#L319) |
| Super constructor params | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/class_test.dart#L277) |
| Mixins | ❌ | N/A |
| Futures | Partial | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/async_test.dart#L69), [[2]](https://github.com/ethanblake4/dart_eval/blob/master/test/async_test.dart#L88) |
| Async/await | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/async_test.dart#L13), [[2]](https://github.com/ethanblake4/dart_eval/blob/master/test/async_test.dart#L33), [[3]](https://github.com/ethanblake4/dart_eval/blob/master/test/async_test.dart#L51) |
| Streams | Partial | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/stdlib_test.dart#L172) |
| String interpolation | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/stdlib_test.dart#L95) |
| Enums | Partial | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/enum_test.dart#L12), [[2]](https://github.com/ethanblake4/dart_eval/blob/master/test/enum_test.dart#L29), [[3]](https://github.com/ethanblake4/dart_eval/blob/master/test/enum_test.dart#L48) |
| Generic function types | Partial | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/function_test.dart#L302) |
| Typedefs | ❌ | N/A |
| Generic classes | Partial | ❌ |
| Type tests (`is`) | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/expression_test.dart#L12), [[2]](https://github.com/ethanblake4/dart_eval/blob/master/test/expression_test.dart#L44) |
| Casting (`as`) | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/exception_test.dart#L206), [[2]](https://github.com/ethanblake4/dart_eval/blob/master/test/exception_test.dart#L227), [[3]](https://github.com/ethanblake4/dart_eval/blob/master/test/exception_test.dart#L244) |
| `assert` | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/exception_test.dart#L259) |
| Null safety | Partial | ❌ |
| Late initialization | ❌ | N/A |
| Cascades | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/expression_test.dart#L136), [[2]](https://github.com/ethanblake4/dart_eval/blob/master/test/expression_test.dart#L160) |
| Ternary expressions | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/expression_test.dart#L118) |
| Null coalescing expressions | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/expression_test.dart#L64), [[2]](https://github.com/ethanblake4/dart_eval/blob/master/test/expression_test.dart#L186) |
| Extension methods | ❌ | N/A |
| Const expressions | Partial | N/A |
| Isolates | ❌ | N/A |
| Record types | ❌ | N/A |
| Patterns | ❌ | N/A |

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker]. If you need help,
use the [discussion board][discussion].

[tracker]: https://github.com/ethanblake4/dart_eval/issues
[discussion]: https://github.com/ethanblake4/dart_eval/discussions
