`dart_eval` is an extensible interpreter for the Dart language, written in Dart. 
It's powered under the hood by the Dart [analyzer](https://pub.dev/packages/analyzer),
so it achieves 100% correct parsing (although evaluation isn't quite there yet.)


The primary goal of `dart_eval` is to be interoperable with real Dart code.
Classes created in 'real Dart' can be used inside the interpreter with a
wrapper, and classes created in the interpreter can be used outside it by
creating an interface and bridge class.

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

There are three types of interop:
* Value interop
* Function/field interop
* Bridge interop

Value interop


An example featuring interop:

```dart
import 'package:dart_eval/dart_eval.dart';

abstract class Cat {
  void speakName();
}

final catType = EvalType('Cat', 'Cat', 'example.dart', [EvalType.objectType], true);

class EvalCat extends Cat with DartBridge<Cat>, EvalBridgeObjectMixin<Cat>, 
    BridgeRectifier<Cat> {

    static final cls = EvalBridgeAbstractClass([], EvalGenericsList([]), catType, EvalScope.empty, Cat);
  
    @override
    final EvalBridgeData evalBridgeData = EvalBridgeData(cls);
  
    @override
    EvalValue getField(String name) {
      throw ArgumentError();
    }
  
    @override
    EvalValue setField(String name, EvalValue value) {
      throw ArgumentError();
    }
  
    @override
    void speakName() => bridgeCall('speakName');
}

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
## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: http://example.com/issues/replaceme
