import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

void main() {
  late Compiler compiler;

  setUp(() {
    compiler = Compiler();
  });

  test('Passing a bridge class from outside', () {
    const source = '''
        import 'package:wrap_test/wrap_test.dart';
            
        int test(WrapTest inp) {
          return inp.value + 1;
        }
      ''';

    compiler.defineBridgeClasses([$WrapTest.$declaration]);
    final runtime = compiler.compileWriteAndLoad({
      'test': {'main.dart': source},
    });

    final wrap = WrapTest(1);
    expect(wrap.value, 1);
    final result = runtime.executeLib('package:test/main.dart', 'test', [
      $WrapTest.wrap(wrap),
    ]);

    expect(result, equals(2));
  });

  group('Unboxing of external classes in lists', () {
    late Runtime runtime;
    final list = [2, 3, 1, 5].map((v) => WrapTest(v)).toList();

    setUp(() {
      const source = '''
        import 'package:wrap_test/wrap_test.dart';
            
        int test(List<WrapTest> inp) {
          int idx = 0;
          while (idx < inp.length && inp[idx].value != 1) idx++;
          return idx;
        }
      ''';

      compiler.defineBridgeClasses([$WrapTest.$declaration]);
      runtime = compiler.compileWriteAndLoad({
        'test': {'main.dart': source},
      });
    });

    test('\$List.wrap()', () {
      final result = runtime.executeLib('package:test/main.dart', 'test', [
        $List.wrap(list.map((e) => $WrapTest.wrap(e)).toList()),
      ]);
      expect(result, equals(2));
    });

    test('\$List.view()', () {
      // Fails with 'WrapTest' is not a subtype of '$Value' at BoxList.run().
      final result = runtime.executeLib('package:test/main.dart', 'test', [
        $List.view(list, (e) => $WrapTest.wrap(e)),
      ]);
      expect(result, equals(2));
    }, skip: true);
  });
}

class WrapTest {
  final int value;
  WrapTest(this.value);
}

class $WrapTest implements $Instance {
  static const $type = BridgeTypeRef(
    BridgeTypeSpec('package:wrap_test/wrap_test.dart', 'WrapTest'),
  );

  static const $declaration = BridgeClassDef(
    BridgeClassType($type),
    constructors: {},
    fields: {
      'value': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
      ),
    },
    wrap: true,
  );

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    if (identifier == 'value') return $int($value.value);
    throw UnimplementedError('Trying to get $identifier');
  }

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    throw UnimplementedError();
  }

  @override
  final WrapTest $value;

  const $WrapTest.wrap(this.$value);
  @override
  get $reified => $value;
}
