import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

Iterable<Runtime> runtimes(String source) sync* {
  final program = Compiler().compile({
    'typed': {'main.dart': source},
  });
  yield Runtime.ofProgram(program);
  yield Runtime(program.write().buffer);
}

void main() {
  test('List results export native elements after explicit return boxing', () {
    for (final runtime in runtimes('''
      List<int> main() {
        var list = [1, 2, 3];
        return [0, ...list, 4];
      }
    ''')) {
      final result = runtime.executeLib('package:typed/main.dart', 'main');
      expect(result, [0, 1, 2, 3, 4]);
      expect((result as List).every((value) => value is int), isTrue);
    }
  });

  test('List input and output preserve host identity through direct calls', () {
    for (final runtime in runtimes('''
      List identity(List values) => values;
      List main(List values) {
        values[0] = values[0] + 3;
        return identity(values);
      }
    ''')) {
      final input = <int>[4, 8];
      final result = runtime.executeLib(
        'package:typed/main.dart',
        'main',
        arguments: {'values': input},
      );
      expect(identical(result, input), isTrue);
      expect(input, [7, 8]);
    }
  });

  test('parameterized exports retain guest and host boundary policies', () {
    final program = Compiler().compile({
      'typed': {
        'main.dart': '''
          int accept(List<int> values) => 7;
          List<String> strings() => ['bad'];
        ''',
      },
    });
    final core = program.bridgeLibraryMappings['dart:core']!;
    final listNominal = program.typeIds[core]!['List']!;
    final intNominal = program.typeIds[core]!['int']!;
    final stringNominal = program.typeIds[core]!['String']!;
    int listDescriptor(int elementNominal) =>
        program.typeDescriptors.indexWhere(
          (descriptor) =>
              descriptor.length == 3 &&
              descriptor[0] == listNominal &&
              program.typeDescriptors[descriptor[2]][0] == elementNominal,
        );

    final intList = listDescriptor(intNominal);
    final stringList = listDescriptor(stringNominal);
    expect(intList, isNonNegative);
    expect(stringList, isNonNegative);
    final matching = $List.wrap(<$Value?>[$int(1)], runtimeTypeId: intList);
    final mismatched = $List.wrap(<$Value?>[
      $String('bad'),
    ], runtimeTypeId: stringList);
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib(
          'package:typed/main.dart',
          'accept',
          arguments: {'values': matching},
        ),
        7,
      );
      expect(
        () => runtime.executeLib(
          'package:typed/main.dart',
          'accept',
          arguments: {'values': mismatched},
        ),
        throwsArgumentError,
      );
      expect(
        runtime.executeLib(
          'package:typed/main.dart',
          'accept',
          arguments: {
            'values': <int>[1],
          },
        ),
        7,
      );
    }
  });

  test(
    'Function exports preserve plain callables and adapt legacy structural ones',
    () {
      final program = Compiler().compile({
        'typed': {
          'main.dart': '''
            int acceptPlain(Function callback) => 1;
            int acceptStructural(int Function(int) callback) => 2;
          ''',
        },
      });
      final closure = $Closure(
        (runtime, target, arguments) => $String('incompatible'),
      );
      final function = $Function(
        (runtime, target, arguments) => $String('also incompatible'),
      );
      for (final (kind, runtime) in [
        ('fresh', Runtime.ofProgram(program)),
        ('serialized', Runtime(program.write().buffer)),
      ]) {
        expect(
          runtime.executeLib(
            'package:typed/main.dart',
            'acceptPlain',
            arguments: {'callback': closure},
          ),
          1,
          reason: kind,
        );
        expect(
          runtime.executeLib(
            'package:typed/main.dart',
            'acceptPlain',
            arguments: {'callback': function},
          ),
          1,
          reason: kind,
        );
        expect(
          runtime.executeLib(
            'package:typed/main.dart',
            'acceptStructural',
            arguments: {'callback': closure},
          ),
          2,
          reason: kind,
        );
      }
    },
  );

  test(
    'nested List returns normalize native elements at the host boundary',
    () {
      for (final runtime in runtimes('''
      List<List<int>> wrap(List<int> values) => [values, [9]];
      List<List<int>> main() => wrap([1, 2]);
    ''')) {
        expect(runtime.executeLib('package:typed/main.dart', 'main'), [
          [1, 2],
          [9],
        ]);
      }
    },
  );
  test('explicit typed entrypoints can select a non-main source library', () {
    final program = Compiler().compileTyped(
      {
        'typed': {'other.dart': 'int read() => 9; Object ignored() => {1: 2};'},
      },
      entrypoint: 'package:typed/other.dart',
      function: 'read',
    );
    expect(TypedMachine.run(program), 9);
    expect(program.exports.single.name, 'read');
    expect(program.functions, hasLength(1));
  });
  test('all exported functions bind any declared parameter by name', () {
    for (final runtime in runtimes('''
      int add(int left, int right) => left + right;
      int main() => add(3, 4);
      int reverse(int first, int second) => first * 10 + second;
    ''')) {
      expect(runtime.executeLib('package:typed/main.dart', 'main'), 7);
      expect(
        runtime.executeLib(
          'package:typed/main.dart',
          'add',
          arguments: {'right': 8, 'left': 2},
        ),
        10,
      );
      expect(
        runtime.executeLib(
          'package:typed/main.dart',
          'reverse',
          arguments: {'second': 4, 'first': 3},
        ),
        34,
      );
    }
  });

  test(
    'omitted native and named parameters receive their declared defaults',
    () {
      for (final runtime in runtimes('''
      double scale(int count, {double factor = 2, bool enabled = true}) =>
        enabled ? count * factor : 0.0;
      int offset(int n, [int amount = -(2 + 3)]) => n + amount;
      double main() => scale(offset(9));
    ''')) {
        expect(runtime.executeLib('package:typed/main.dart', 'main'), 8.0);
        expect(
          runtime.executeLib(
            'package:typed/main.dart',
            'scale',
            arguments: {'count': 3},
          ),
          6.0,
        );
        expect(
          runtime.executeLib(
            'package:typed/main.dart',
            'scale',
            arguments: {'enabled': false, 'count': 3},
          ),
          0.0,
        );
        expect(
          runtime.executeLib(
            'package:typed/main.dart',
            'offset',
            arguments: {'n': 9},
          ),
          4,
        );
      }
    },
  );

  test('explicit null differs from an omitted nullable default', () {
    for (final runtime in runtimes('''
      int choose({int? value = 7}) => value ?? 99;
      int main() => choose(value: null) + choose();
    ''')) {
      expect(runtime.executeLib('package:typed/main.dart', 'choose'), 7);
      expect(
        runtime.executeLib(
          'package:typed/main.dart',
          'choose',
          arguments: {'value': null},
        ),
        99,
      );
      expect(runtime.executeLib('package:typed/main.dart', 'main'), 106);
    }
  });

  test(
    'required nullable arguments may contain null but cannot be omitted',
    () {
      for (final runtime in runtimes(
        'int main({required int? value}) => value ?? 5;',
      )) {
        expect(
          runtime.executeLib(
            'package:typed/main.dart',
            'main',
            arguments: {'value': null},
          ),
          5,
        );
        expect(
          () => runtime.executeLib('package:typed/main.dart', 'main'),
          throwsArgumentError,
        );
      }
    },
  );

  test('generic export parameters bind using their declared bound', () {
    for (final runtime in runtimes('T main<T>(T value) => value;')) {
      expect(
        runtime.executeLib(
          'package:typed/main.dart',
          'main',
          arguments: {'value': 'kept'},
        ),
        'kept',
      );
    }
  });

  test(
    'constructor exports retain field parameter names and declared types',
    () {
      for (final runtime in runtimes('''
      class Counter {
        int value;
        Counter(this.value);
        factory Counter.twice(int value) => Counter(value * 2);
      }
      int read(Counter counter) => counter.value;
    ''')) {
        final counter = runtime.executeLib(
          'package:typed/main.dart',
          'Counter.',
          arguments: {'value': 12},
        );
        expect(
          runtime.executeLib(
            'package:typed/main.dart',
            'read',
            arguments: {'counter': counter},
          ),
          12,
        );
        final doubled = runtime.executeLib(
          'package:typed/main.dart',
          'Counter.twice',
          arguments: {'value': 12},
        );
        expect(
          runtime.executeLib(
            'package:typed/main.dart',
            'read',
            arguments: {'counter': doubled},
          ),
          24,
        );
      }
    },
  );

  test('scalar const defaults resolve in the declaring library', () {
    final compiler = Compiler();
    final program = compiler.compile({
      'typed': {
        'main.dart': "import 'shared.dart'; int main() => offset(8);",
        'shared.dart':
            'const amount = 3; int offset(int n, [int by = amount]) => n + by;',
      },
    });
    expect(
      Runtime.ofProgram(program).executeLib('package:typed/main.dart', 'main'),
      11,
    );
    expect(
      Runtime(
        program.write().buffer,
      ).executeLib('package:typed/main.dart', 'main'),
      11,
    );
  });

  test(
    'entry binding rejects unknown missing and nonnullable null arguments',
    () {
      for (final runtime in runtimes(
        'int main(int n, {required int other}) => n + other;',
      )) {
        expect(
          () => runtime.executeLib(
            'package:typed/main.dart',
            'main',
            arguments: {'n': 1},
          ),
          throwsArgumentError,
        );
        expect(
          () => runtime.executeLib(
            'package:typed/main.dart',
            'main',
            arguments: {'n': 1, 'other': 2, 'typo': 3},
          ),
          throwsArgumentError,
        );
        expect(
          () => runtime.executeLib(
            'package:typed/main.dart',
            'main',
            arguments: {'n': null, 'other': 2},
          ),
          throwsArgumentError,
        );
      }
    },
  );

  test('configured entrypoint libraries share one linked function table', () {
    final compiler = Compiler()..entrypoints.add('/second.dart');
    final program = compiler.compile({
      'typed': {
        'main.dart': "import 'shared.dart'; int main(int n) => twice(n);",
        'second.dart':
            "import 'shared.dart'; int other(int n) => twice(n) + 1;",
        'shared.dart': 'int twice(int n) => n * 2;',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib(
          'package:typed/main.dart',
          'main',
          arguments: {'n': 4},
        ),
        8,
      );
      expect(
        runtime.executeLib(
          'package:typed/second.dart',
          'other',
          arguments: {'n': 4},
        ),
        9,
      );
    }
    expect(program.typedProgram.functions, hasLength(3));
    expect(program.typedProgram.exports, hasLength(2));
  });
}
