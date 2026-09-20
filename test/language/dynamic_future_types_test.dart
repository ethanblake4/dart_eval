import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _library = 'package:dynamic_future_types/main.dart';

Iterable<(String, Runtime)> _runtimes(String source) sync* {
  final program = Compiler().compile({
    'dynamic_future_types': {'main.dart': source},
  });
  yield ('fresh', Runtime.ofProgram(program));
  yield ('serialized', Runtime(program.write().buffer));
}

void main() {
  test('async results and typed then callbacks retain Future payloads', () {
    const source = '''
      Future<int> makeInt() async {
        await 0;
        return 7;
      }

      String stringify(int value) => value.toString();

      int main() {
        dynamic direct = makeInt();
        dynamic chained = makeInt().then(stringify);
        var result = 0;
        if (direct is Future<int>) result += 1;
        if (direct is Future<String>) result += 2;
        if (chained is Future<String>) result += 4;
        if (chained is Future<int>) result += 8;
        return result;
      }
    ''';

    for (final (mode, runtime) in _runtimes(source)) {
      expect(runtime.executeLib(_library, 'main'), 5, reason: mode);
    }
  });

  test('dynamic async payload errors complete the Future', () async {
    const source = '''
      Future<int> bad() async {
        dynamic value = 'bad';
        return value;
      }
    ''';

    for (final (mode, runtime) in _runtimes(source)) {
      final result = runtime.executeLib(_library, 'bad') as Future;
      await expectLater(result, throwsA(isA<TypeError>()), reason: mode);
    }
  });
}
