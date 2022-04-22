import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';

class TestClass {
  TestClass(this.someNumber);

  static bool runStaticTest(String m) {
    return m.length > 5;
  }

  int someNumber;

  bool runTest(int a, {String b = 'hello'}) {
    return a + someNumber > b.length;
  }
}

class $TestClass extends TestClass with $Bridge {
  $TestClass(int someNumber) : super(someNumber);

  static $TestClass $construct(
          Runtime runtime, $Value? target, List<$Value?> args) =>
      $TestClass(args[0]!.$value);

  static $bool $runStaticTest(
          Runtime runtime, $Value? target, List<$Value?> args) =>
      $bool(TestClass.runStaticTest(args[0]!.$value));

  static const $type = BridgeTypeReference.unresolved(
      BridgeUnresolvedTypeReference(
          'package:bridge_lib/bridge_lib.dart', 'TestClass'),
      []);

  static const $declaration =
      BridgeClassDeclaration($type, isAbstract: false, constructors: {
    '': BridgeConstructorDeclaration(
        false,
        BridgeFunctionDescriptor(BridgeTypeAnnotation($type, false), {}, [
          BridgeParameter(
              'someNumber',
              BridgeTypeAnnotation(
                  BridgeTypeReference.type(RuntimeTypes.intType, []), false),
              false),
        ], {}))
  }, methods: {
    'runStaticTest': BridgeMethodDeclaration(
        true,
        BridgeFunctionDescriptor(
            BridgeTypeAnnotation(
                BridgeTypeReference.type(RuntimeTypes.boolType, []), false),
            {},
            [
              BridgeParameter(
                  'm',
                  BridgeTypeAnnotation(
                      BridgeTypeReference.type(RuntimeTypes.stringType, []),
                      false),
                  false),
            ],
            {})),
    'runTest': BridgeMethodDeclaration(
        false,
        BridgeFunctionDescriptor(
            BridgeTypeAnnotation(
                BridgeTypeReference.type(RuntimeTypes.boolType, []), false),
            {},
            [
              BridgeParameter(
                  'a',
                  BridgeTypeAnnotation(
                      BridgeTypeReference.type(RuntimeTypes.intType, []),
                      false),
                  false),
            ],
            {
              'b': BridgeParameter(
                  'b',
                  BridgeTypeAnnotation(
                      BridgeTypeReference.type(RuntimeTypes.stringType, []),
                      false),
                  false),
            }))
  }, getters: {}, setters: {}, fields: {
    'someNumber': BridgeFieldDeclaration(
        false, false, BridgeTypeReference.type(RuntimeTypes.intType, [])),
  });

  @override
  $Value? $bridgeGet(String identifier) {
    switch (identifier) {
      case 'runTest':
        return $Function((Runtime rt, $Value? target, List<$Value?> args) {
          return $bool(
              super.runTest(args[0]!.$value, b: args[1]!.$value ?? 'hello'));
        });
      case 'someNumber':
        return $int(super.someNumber);
    }
    throw UnimplementedError();
  }

  @override
  void $bridgeSet(String identifier, $Value value) {
    switch (identifier) {
      case 'someNumber':
        super.someNumber = value.$value;
        break;
      default:
        throw UnimplementedError();
    }
  }

  @override
  bool runTest(int a, {String b = 'hello'}) {
    return $_invoke('runTest', [$int(a), $String(b)]);
  }

  @override
  int get someNumber => $_get('someNumber');

  @override
  set someNumber(int _someNumber) => $_set('someNumber', $int(_someNumber));
}
