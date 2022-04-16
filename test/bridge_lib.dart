import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/bridge/declaration/class.dart';
import 'package:dart_eval/src/eval/bridge/declaration/function.dart';
import 'package:dart_eval/src/eval/bridge/declaration/type.dart';
import 'package:dart_eval/src/eval/shared/types.dart';

class TestClass {
  TestClass(this.someNumber);

  int someNumber;

  bool runTest(int a, {String b = 'hello'}) {
    return a + someNumber > b.length;
  }
}

class $TestClass extends TestClass with $Bridge {
  $TestClass(int someNumber) : super(someNumber);

  static const $type = BridgeTypeReference.unresolved(
      BridgeUnresolvedTypeReference('package:bridge_lib/bridge_lib.dart', 'TestClass'), []);

  static const $declaration = BridgeClassDeclaration($type, isAbstract: false, constructors: {
    '': BridgeConstructorDeclaration(
        false,
        BridgeFunctionDescriptor(BridgeTypeAnnotation($type, false), {}, [
          BridgeParameter(
              'someNumber', BridgeTypeAnnotation(BridgeTypeReference.type(RuntimeTypes.intType, []), false), false),
        ], {}))
  }, methods: {
    'runTest': BridgeMethodDeclaration(
        false,
        BridgeFunctionDescriptor(BridgeTypeAnnotation(BridgeTypeReference.type(RuntimeTypes.boolType, []), false), {}, [
          BridgeParameter('a', BridgeTypeAnnotation(BridgeTypeReference.type(RuntimeTypes.intType, []), false), false),
        ], {
          'b': BridgeParameter(
              'b', BridgeTypeAnnotation(BridgeTypeReference.type(RuntimeTypes.stringType, []), false), false),
        }))
  }, getters: {}, setters: {}, fields: {
    'someNumber': BridgeFieldDeclaration(false, false, BridgeTypeReference.type(RuntimeTypes.intType, [])),
  });

  @override
  $Value? $bridgeGet(String identifier) {
    switch (identifier) {
      case 'runTest':
        return $Function(__runTest);
      case 'someNumber':
        return $int(someNumber);
    }
    throw UnimplementedError();
  }

  @override
  void $bridgeSet(String identifier, $Value value) {
    switch (identifier) {
      case 'someNumber':
        someNumber = value.$value;
        break;
      default:
        throw UnimplementedError();
    }
  }

  static $Value? __runTest(Runtime rt, $Value? target, List<$Value?> args) {
    final $target = target!.$value as TestClass;
    return $bool($target.runTest(args[0]!.$value, b: args[1]!.$value ?? 'hello'));
  }
}
