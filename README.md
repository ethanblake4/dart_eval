`dart_eval` is an extensible interpreter for the Dart language, written in Dart. 
It's powered under the hood by the Dart [analyzer](https://pub.dev/packages/analyzer),
so it achieves 100% correct and up-to-date parsing (although evaluation isn't quite there yet.)

The primary goal of `dart_eval` is to be interoperable with real Dart code.
Classes created in 'real Dart' can be used inside the interpreter with a
wrapper, and classes created in the interpreter can be used outside it by
creating an interface and bridge class.

For now, the project's current target is to achieve 100% correct evaluation of *valid*
Dart code. Correct error handling (beyond parse errors) is out of the scope at this
time.

## Usage

A simple usage example:

```dart
import 'package:dart_eval/dart_eval.dart';

main() {
  final parser = Parse();

  final scope = parser.parse('''
      class Cat {
        Cat();
        void speak(String name) {
          print('meow');
          print(name);
        }
      }
      void main() {
        final cat = Cat();
        cat.speak('Fluffy');
      }
  ''');

  scope('main', []);
}
```

## Interop

There are three types of interop:
* Value interop
* Wrapper interop
* Bridge interop

### Value interop

Value interop is the most basic form, and happens automatically whenever the Eval
environment is working with an object backed by a real Dart value. (Therefore, an
int and a string are value interop enabled, but a class created inside Eval isn't.)
To access the backing object of an `EvalValue`, use its `realValue` property. You
can also pass a value-interop only enabled object to Eval using `EvalRealObject`
with its optional parameters not set, but this is not recommended. Instead, you
should use the class pertaining to the value type, such as `EvalInt` or `EvalString`.

### Wrapper interop

Using a wrapper enables the Eval environment to access the functions and fields on
a class created outside Eval. It's much more powerful than value interop, but much
simpler than bridge interop, making it a great choice for certain use cases. To use
wrapper interop, create an `EvalRealObject` using its optional parameters to map out
the fields and methods of the wrapped type.

### Bridge interop

Bridge interop enables the most functionality: Not only can Eval access the fields
of an object, but it can also be extended, allowing you to create subclasses within Eval
and use them outside of Eval. For example, bridge interop is used by 
Flightstream to enable the creation of custom Flutter widgets within Eval. 
The downside of bridge interop is that it's comparatively difficult to use, and
it can't be used to wrap existing objects created in code you don't control. (For utmost
flexibility at the expense of simplicity, you can use both bridge and wrapper interop.)

Since Bridge interop requires a lot of boilerplate code, in the future I will be creating
a solution for code-generation of that boilerplate.

An example featuring bridge interop is available in the `example` directory.

## FAQ

### How does it work?

`dart_eval` is a fully Dart-based implementation of an interpreter. First, we use the Dart
analyzer to parse the code into an AST (abstract syntax tree). Then, we map this to our
own AST which is comprised of classes that 'understand' how to evaluate themselves.

Evaluation has two main steps: first, we 'declare' everything, assigning the
scope of every part of the code (basically, grouping all of the declarations into fancy Maps so
they can be quickly accessed via a lookup, and then giving them references to those Maps so
they too can lookup other classes). Then, we simply take a top-level node and execute it, which
then calls all of the child nodes under it.

### Does it support Flutter?

Yes! Well, kind of. Support for Flutter is not built in but can be added via Bridge interop.
I have done so to a very limited extent and it works. In the future this project will expand
support for Flutter.

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/ethanblake4/dart_eval/issues
