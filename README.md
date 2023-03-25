[![Build status](https://img.shields.io/github/actions/workflow/status/ethanblake4/dart_eval/dart.yml?branch=master)](https://github.com/ethanblake4/dart_eval/actions/workflows/dart.yml)
[![Star on Github](https://img.shields.io/github/stars/ethanblake4/dart_eval?logo=github&colorB=orange&label=stars)](https://github.com/ethanblake4/dart_eval)
[![License: BSD-3](https://img.shields.io/badge/license-BSD3-purple.svg)](https://opensource.org/licenses/BSD-3-Clause)
[![Web example](https://img.shields.io/badge/web-example-blue.svg)](https://ethanblake.xyz/evalpad)

`dart_eval` is an extensible bytecode compiler and interpreter for the Dart language, 
written in Dart, enabling dynamic codepush for Flutter and Dart AOT.

| dart_eval    | [![pub package](https://img.shields.io/pub/v/dart_eval.svg?label=dart_eval&color=teal)](https://pub.dev/packages/dart_eval)          |
| ------------ | ------------------------------------------------------------------------------------------------------------------------------------ |
| flutter_eval | [![pub package](https://img.shields.io/pub/v/flutter_eval.svg?label=flutter_eval&color=blue)](https://pub.dev/packages/flutter_eval) |
| eval_annotation | [![pub package](https://img.shields.io/pub/v/eval_annotation.svg?label=eval_annotation&color=orange)](https://pub.dev/packages/eval_annotation) |

The primary aspect of `dart_eval`'s goal is to be interoperable with real 
Dart code. Classes created in 'real Dart' can be used inside the interpreter 
with a wrapper, and classes created in the interpreter can be used outside it 
by creating an interface and bridge class.

dart_eval's compiler is powered under the hood by the Dart 
[analyzer](https://pub.dev/packages/analyzer), so it achieves 100% correct and 
up-to-date parsing (although compilation and evaluation aren't quite there yet.)

Currently dart_eval implements a decent amount of the Dart spec, but there 
are still missing features like generators, Sets and extension methods.
In addition, much of the standard library hasn't been implemented.
## Usage

A basic usage example of the `eval` method, which is a simple shorthand to
execute Dart code at runtime:

```dart
import 'package:dart_eval/dart_eval.dart';

void main() {
  print(eval('2 + 2')); // -> 4
  
  final program = '''
      class Cat {
        Cat(this.name);
        final String name;
        String speak() {
          return name;
        }
      }
      String main() {
        final cat = Cat('Fluffy');
        return cat.speak();
      }
  ''';
  
  print(eval(program, function: 'main')); // -> 'Fluffy'
}
```

## Compiling to a file

For most use-cases, it's recommended to pre-compile your Dart code to EVC bytecode,
to avoid runtime compilation overhead. (This is still runtime code execution, it's
just executing a more efficient code format.)

This also allows you to compile multiple files into a single bytecode block.

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
          count = count + i;
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
  runtime.setup();
  print(runtime.executeLib('package:my_package/main.dart', 'main')); // -> 499500
}
```

## Using the CLI
The dart_eval CLI allows you to compile existing Dart projects to EVC bytecode,
as well as run and inspect EVC bytecode files.

To enable the CLI globally, run:

`dart pub global activate dart_eval`

### Compiling a project

The CLI supports compiling standard Dart projects, although installed packages
in `pubspec.yaml` are not currently supported. To compile a project, run:

```bash
cd my_project
dart_eval compile -o program.evc
```

This will generate an EVC file in the current directory called `program.evc`.

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

In most cases, dart_eval will return a subclass of `$Value` such as `$int`
or `$String`. These 'boxed types' have information about what they are and 
how to modify them, and like all `$Value`s you can access their underlying
value with the `$value` property. 

However, when working with primitive value types  (int, string etc.) you may find 
that dart_eval returns the underlying primitive directly. This is due to an 
internal performance optimization. If you don't like the inconsistency, you can
change the return type on the function signature to `dynamic` which will force 
dart_eval to always box the value before it's returned.

## Security and permissions

dart_eval is designed to be secure. The dart_eval runtime functions like a virtual
machine, effectively sandboxing the code it executes. By default, the runtime will
not allow running programs to access the file system, network, or other system 
resources, but these permissions can be enabled on a granular basis using 
`runtime.grant`:

```dart
final runtime = Runtime(bytecode);
runtime.setup();

// Allow full access to the file system
runtime.grant(FilesystemPermission.any);

// Allow access to a specific network domain
runtime.grant(NetworkPermission.url('example.com'));

// Allow access to a specific network resource
runtime.grant(NetworkPermission.url('https://dart.dev/api/users.json'));
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

Value interop is the most basic form, and happens automatically whenever the Eval
environment is working with an object backed by a real Dart value. (Therefore, an
int and a string are value interop enabled, but a class created inside Eval isn't.)
To access the backing object of an `$Value`, use its `$value` property. If the
value is a collection like a Map or a List, you can use its `$reified` property
to resolve the values it contains.

To support value interop, a class need simply to implement `$Value`, or extend
`$Value<T>`.

### Wrapper interop

Using a wrapper enables the Eval environment to access the functions and fields on
a class created outside Eval. It's much more powerful than value interop, and
simpler than bridge interop, making it a great choice for certain use cases. To use
wrapper interop, create a class that implements `$Instance`. Then, override 
`$getProperty` / `$setProperty` to define your fields and methods.

#### Hot wrappers and runtime overrides

dart_eval includes a runtime overrides system that allows you to dynamically replace
the implementation of a constructor. To get started, first create a 
[hot wrapper](https://github.com/ethanblake4/dart_eval/wiki/Wrappers#hot-wrappers)
for the class you want to substitute, and replace instantiations of this class with
the hot wrapper constructor throughout your program, using a unique ID for each.:

```dart
// Create a hot wrapper for the class you want to substitute
class $ListView extends $Instance {
  static const $type = ...;
  static const $declaration = ...;

  @override
  final ListView $value;

  $ListView(String id, ListView Function() value) : 
    $value = runtimeOverride(id) as ListView? ?? value();
  
  /// etc...
}

// Replace instantiations of the class with the hot wrapper constructor
Widget build(BuildContext context) {
  return $ListView('#login_page_list_view', () => ListView(children: [
    Text('Login'),
    TextField(),
  ]));
}
```

Note that in some cases you may have to cast the return value of `runtimeOverride`
as dart_eval is unable to specify generic parameters to the Dart type system:
  
```dart
$Iterable(String id, Iterable<E> Function() value) : 
  $value = (runtimeOverride(id) as Iterable?)?.cast() ?? value();
```

Next, mark a function in the eval code with the @RuntimeOverride annotation:

```dart
@RuntimeOverride('#login_page_list_view')
ListView loginPageListView() {
  return ListView(children: [
    Text('Updated Login Experience'),
    TextField(),
    FlatButton()
  ]);
}
```

Finally, follow the normal instructions to compile and run the program, but
call `loadGlobalOverrides` on the Runtime after calling `setup()`.
This will set the runtime as the single global runtime for the program, and 
load its overrides to be accessible by hot wrappers.

When the program is run, the runtime will automatically replace the instantiation
of the hot wrapper with the return value of the function marked with the
`@RuntimeOverride` annotation.

Overrides can also be versioned, allowing you to roll out updates to a function
immediately using dart_eval and revert to a new native implementation after
an official update is released. To version an override, simply add a semver
version constraint to the `@RuntimeOverride` annotation:

```dart
@RuntimeOverride('#login_page_list_view', version: '<1.4.0')
```

When running the program, specify its current version by setting the value of
the `runtimeOverrideVersion` global property:

```dart
runtimeOverrideVersion = '1.3.0';
```

Now, when the program is run, the runtime will automatically replace the instantiation
only if the app version is less than 1.4.0.

### Bridge interop

Bridge interop enables the most functionality: Not only can Eval access the fields
of an object, but it can also be extended, allowing you to create subclasses within Eval
and use them outside of Eval. For example, bridge interop is used by 
Flightstream to enable the creation of custom Flutter widgets. 

However, it is also somewhat difficult to use, and it can't be used to wrap existing 
objects created in code you don't control. (For utmost flexibility at the expense of 
simplicity, you can use both bridge and wrapper interop.) Since Bridge interop requires
a lot of boilerplate code, in the future I will be creating a solution for 
code-generation of that boilerplate.

Bridge interop also requires that the class definitions be available at both compile-time 
and runtime. (If you're just using the `eval` method, you don't have to worry about
this.)

An example featuring bridge interop is available in the `example` directory.

## Plugins

To configure interop for compilation and runtime, it's recommended to create an
`EvalPlugin` which enables reuse of Compiler instances. Basic example:
  
```dart
class MyAppPlugin implements EvalPlugin {
  @override
  String get identifier => 'package:myapp';

  @override
  void configureForCompile(Compiler compiler) {
    compiler.defineBridgeTopLevelFunction(BridgeFunctionDeclaration(
      'package:myapp/functions.dart',
      'loadData',
      BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.objectType)), params: [])
    ));
    compiler.defineBridgeClass($CoolWidget.$declaration);
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

### Does it support Flutter?

Yes! Check out [flutter_eval](https://pub.dev/packages/flutter_eval).

### How fast is it?

Preliminary testing shows that, for simple code, `dart_eval` running in AOT-compiled Dart 
is around 12x slower than standard AOT Dart and is approximately on par with a language like 
Ruby.
For many use cases this actually doesn't matter too much, e.g. in the case of Flutter 
where the app spends 99% of its performance budget in the Flutter framework itself.

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
| Anonymous functions | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/function_test.dart#L108), [[2]](https://github.com/ethanblake4/dart_eval/blob/master/test/function_test.dart#L128), [[3]](https://github.com/ethanblake4/dart_eval/blob/master/test/function_test.dart#L145), [[4]](https://github.com/ethanblake4/dart_eval/blob/master/test/function_test.dart#L163), [[5]](https://github.com/ethanblake4/dart_eval/blob/master/test/function_test.dart#L181) |
| Arrow functions | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/function_test.dart#L243), [[2]](https://github.com/ethanblake4/dart_eval/blob/master/test/function_test.dart#L255) |
| Sync generators | ❌ | N/A |
| Async generators | ❌ | N/A |
| Tear-offs | Partial | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/function_test.dart#L288), [[2]](https://github.com/ethanblake4/dart_eval/blob/master/test/function_test.dart#L307) |
| For loops | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/statement_test.dart#L13), [[2]](https://github.com/ethanblake4/dart_eval/blob/master/test/statement_test.dart#L28) |
| While loops | ✅ | ❌ |
| Do-while loops | ✅ | ❌ |
| For-each loops | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/statement_test.dart#L52) |
| Async for-each | ❌ | N/A |
| Switch statements | ❌ | N/A |
| Labels and `break` | ❌ | N/A |
| If statements | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/statement_test.dart#L28) |
| Try-catch | Partial | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/statement_test.dart#L69), [[2]](https://github.com/ethanblake4/dart_eval/blob/master/test/statement_test.dart#L87) |
| Try-catch-finally | ❌ | N/A |
| Lists | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/collection_test.dart) |
| Iterable | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/collection_test.dart#L14), [[2]](https://github.com/ethanblake4/dart_eval/blob/master/test/collection_test.dart#L29) |
| Maps | Partial | ❌ |
| Sets | ❌ | N/A |
| Collection `for` | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/collection_test.dart#L14), [[2]](https://github.com/ethanblake4/dart_eval/blob/master/test/collection_test.dart#L76) |
| Collection `if` | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/collection_test.dart#L14), [[2]](https://github.com/ethanblake4/dart_eval/blob/master/test/collection_test.dart#L52) |
| Spreads | ❌ | N/A |
| Classes | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/class_test.dart) |
| Class static methods | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/class_test.dart#L147), [[2]](https://github.com/ethanblake4/dart_eval/blob/master/test/class_test.dart#L167) |
| Getters and setters | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/class_test.dart#L253) |
| Factory constructors | ❌ | N/A |
| `new` keyword | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/class_test.dart#L195) |
| Class inheritance | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/functional1_test.dart) |
| Abstract and `implements` | Partial | ❌ |
| `this` keyword | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/class_test.dart#L89), [[2]](https://github.com/ethanblake4/dart_eval/blob/master/test/class_test.dart#L116) |
| `super` keyword | ✅ | ❌ |
| Super constructor params | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/class_test.dart#L277) |
| Mixins | ❌ | N/A |
| Futures | Partial | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/stdlib_test.dart#L27), [[2]](https://github.com/ethanblake4/dart_eval/blob/master/test/stdlib_test.dart#L46) |
| Async/await | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/function_test.dart#L199), [[2]](https://github.com/ethanblake4/dart_eval/blob/master/test/function_test.dart#L270), [[3]](https://github.com/ethanblake4/dart_eval/blob/master/test/function_test.dart#L367) |
| Streams | Partial | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/stdlib_test.dart#L199) |
| String interpolation | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/stdlib_test.dart#L122) |
| Enums | ❌ | N/A |
| Generic function types | Partial | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/function_test.dart#L363) |
| Typedefs | ❌ | N/A |
| Generic classes | Partial | ❌ |
| Type tests (`is`) | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/expression_test.dart#L12) |
| Casting (`as`) | ❌ | N/A |
| `assert` | ❌ | N/A |
| Null safety | Partial | ❌ |
| Late initialization | ❌ | N/A |
| Cascades | ❌ | ❌ |
| Ternary expressions | ✅ | [[1]](https://github.com/ethanblake4/dart_eval/blob/master/test/function_test.dart#L381) |
| Extension methods | ❌ | N/A |
| Const expressions | Partial | N/A |
| Isolates | ❌ | N/A |

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/ethanblake4/dart_eval/issues
