@TestOn('vm')

import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  group('dart:convert tests', () {
    late Compiler compiler;

    setUp(() {
      compiler = Compiler();
    });

    test('json.encode()', () async {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            import 'dart:convert';

            String main() {
              return json.encode({'a': 1, 'b': 2});
            }
          '''
        }
      });

      expect(
          runtime
              .executeLib(
                'package:example/main.dart',
                'main',
              )
              .$value,
          '{"a":1,"b":2}');
    });

    test('json.decode()', () async {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            import 'dart:convert';

            Map<String, int> main() {
              return json.decode('{"a":1,"b":2}');
            }
          '''
        }
      });

      expect(
          runtime
              .executeLib(
                'package:example/main.dart',
                'main',
              )
              .$reified,
          {'a': 1, 'b': 2});
    });

    test('Accessing results of json.decode()', () async {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            import 'dart:convert';

            int main() {
              final map = json.decode('{"a":1,"b":2}');
              return map['a'];
            }
          '''
        }
      });

      expect(
          runtime.executeLib(
            'package:example/main.dart',
            'main',
          ),
          1);
    });
  });
}
