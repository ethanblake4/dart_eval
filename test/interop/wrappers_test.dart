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
    final result = runtime.executeLib(
      'package:test/main.dart',
      'test',
      arguments: {'inp': $WrapTest.wrap(wrap)},
    );

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
      final result = runtime.executeLib(
        'package:test/main.dart',
        'test',
        arguments: {
          'inp': $List.wrap(list.map((e) => $WrapTest.wrap(e)).toList()),
        },
      );
      expect(result, equals(2));
    });

    test('\$List.view()', () {
      final result = runtime.executeLib(
        'package:test/main.dart',
        'test',
        arguments: {'inp': $List.view(list, (e) => $WrapTest.wrap(e))},
      );
      expect(result, equals(2));
    });
  });

  test('\$List.view is lazy and writes through, fresh and serialized', () {
    const source = '''
      import 'package:wrap_test/wrap_test.dart';

      int readAt(List<WrapTest> values, int index) => values[index].value;

      int replace(List<WrapTest> values) {
        values[1] = values[0];
        return values[1].value;
      }

      int append(List<WrapTest> values) {
        values.add(values[0]);
        return values.length;
      }

      bool copyNull(List<WrapTest?> values) {
        values[1] = values[0];
        return values[1] == null;
      }

      List<WrapTest> echo(List<WrapTest> values) => values;
    ''';
    compiler.defineBridgeClasses([$WrapTest.$declaration]);
    final program = compiler.compile({
      'test': {'main.dart': source},
    });
    for (final (kind, candidate) in [
      ('fresh', program),
      ('serialized', Program.read(program.write().buffer)),
    ]) {
      final runtime = Runtime.ofProgram(candidate);
      final backing = [WrapTest(2), WrapTest(3)];
      var mappings = 0;
      final view = $List.view(backing, (value) {
        mappings++;
        return $WrapTest.wrap(value);
      });

      expect(
        runtime.executeLib(
          'package:test/main.dart',
          'readAt',
          arguments: {'values': view, 'index': 1},
        ),
        3,
        reason: kind,
      );
      expect(mappings, 1, reason: '$kind maps only the indexed element');

      expect(
        runtime.executeLib(
          'package:test/main.dart',
          'replace',
          arguments: {'values': view},
        ),
        2,
        reason: kind,
      );
      expect(identical(backing[0], backing[1]), isTrue, reason: kind);

      expect(
        runtime.executeLib(
          'package:test/main.dart',
          'append',
          arguments: {'values': view},
        ),
        3,
        reason: kind,
      );
      expect(identical(backing[0], backing[2]), isTrue, reason: kind);
      expect(
        identical(
          runtime.executeLib(
            'package:test/main.dart',
            'echo',
            arguments: {'values': view},
          ),
          backing,
        ),
        isTrue,
        reason: '$kind preserves the host backing identity',
      );

      final nullableBacking = <WrapTest?>[null, WrapTest(8)];
      var nullableMappings = 0;
      final nullableView = $List.view(nullableBacking, (value) {
        nullableMappings++;
        return $WrapTest.wrap(value!);
      });
      expect(
        runtime.executeLib(
          'package:test/main.dart',
          'copyNull',
          arguments: {'values': nullableView},
        ),
        isTrue,
        reason: kind,
      );
      expect(nullableBacking, [null, null], reason: kind);
      expect(nullableMappings, 0, reason: '$kind null bypasses the mapper');
    }
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
