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
  $TestClass(super.someNumber);

  static $TestClass $construct(
          Runtime runtime, $Value? target, List<$Value?> args) =>
      $TestClass(args[0]!.$value);

  static $bool $runStaticTest(
          Runtime runtime, $Value? target, List<$Value?> args) =>
      $bool(TestClass.runStaticTest(args[0]!.$value));

  static const $type = BridgeTypeRef(
      BridgeTypeSpec('package:bridge_lib/bridge_lib.dart', 'TestClass'));

  static const $declaration = BridgeClassDef(BridgeClassType($type),
      constructors: {
        '': BridgeConstructorDef(
            BridgeFunctionDef(returns: BridgeTypeAnnotation($type), params: [
          BridgeParameter('someNumber',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)), false),
        ], namedParams: []))
      },
      methods: {
        'runStaticTest': BridgeMethodDef(
            BridgeFunctionDef(
                returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
                params: [
                  BridgeParameter(
                      'm',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
                      false),
                ],
                namedParams: []),
            isStatic: true),
        'runTest': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
            params: [
              BridgeParameter('a',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)), false),
            ],
            namedParams: [
              BridgeParameter('b',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)), false),
            ]))
      },
      getters: {},
      setters: {},
      fields: {
        'someNumber':
            BridgeFieldDef(BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int))),
      },
      bridge: true);

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
  set someNumber(int someNumber) => $_set('someNumber', $int(someNumber));
}

enum TestEnum {
  one,
  two,
  three,
}

class $TestEnum implements $Instance {
  static $TestEnum $wrap(Runtime runtime, $Value? target, List<$Value?> args) =>
      $TestEnum.wrap(args[0]!.$value);
  static const $type = BridgeTypeRef(
      BridgeTypeSpec('package:bridge_lib/bridge_lib.dart', 'TestEnum'));
  static const $declaration = BridgeEnumDef($type,
      values: ['one', 'two', 'three'],
      methods: {},
      getters: {},
      setters: {},
      fields: {});
  static final $values = TestEnum.values.asNameMap().map(
        (key, value) => MapEntry(key, $TestEnum.wrap(value)),
      );
  const $TestEnum.wrap(this.$value);

  @override
  final TestEnum $value;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'index':
        return $int($value.index);
      case 'name':
        return $String($value.name);
      case 'hashCode':
        return $int($value.hashCode);
    }
    throw UnimplementedError();
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    throw UnimplementedError('Cannot set property on an enum');
  }

  @override
  get $reified => $value;

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);
}
