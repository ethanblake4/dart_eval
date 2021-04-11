import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/primitives.dart';

const _myClassType = EvalType('MyClass', 'MyClass', 'dart_eval_example.dart', [EvalType.objectType], true);

abstract class MyClass {
  String getData(int input);
}

class EvalMyClass extends MyClass
    with ValueInterop<MyClass>, EvalBridgeObjectMixin<MyClass>, BridgeRectifier<MyClass> {

  static final cls = EvalBridgeClass([], EvalGenericsList([]), _myClassType, EvalScope.empty, MyClass,
          (_1, _2, _3) => EvalMyClass());

  @override
  EvalBridgeData evalBridgeData = EvalBridgeData(cls);

  @override
  String getData(int input) => bridgeCall('getData', [EvalInt(input)]);

  @override
  EvalValue setField(String name, EvalValue value, {bool internalSet = false}) {
    throw ArgumentError();
  }
}


void main() {

  final parser = Parse();
  parser.define('MyClass', EvalMyClass.cls);

  final scope = parser.parse('''
    class MyClassImpl extends MyClass {
      @override 
      String getData(int input) {
        return "Hello" + input.toString();
      }
    }
    String fn() {
      return MyClassImpl();
    }
    ''');

  final result = scope('fn', []) as MyClass;
  print(result.getData(1));
}