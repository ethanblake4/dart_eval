@TestOn('vm')
library convert_test;

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
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

    test('jsonEncode()', () async {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            import 'dart:convert';

            String main() {
              return jsonEncode({'a': 1, 'b': 2});
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

    test('jsonDecode()', () async {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            import 'dart:convert';

            Map<String, int> main() {
              return jsonDecode('{"a":1,"b":2}');
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
    test('utf8.encode()', () async {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            import 'dart:convert';

            List<int> main() {
              return utf8.encode("Hello world");
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
              .map((e) => (e is $Value ? e.$reified : e) as int)
              .toList(),
          [72, 101, 108, 108, 111, 32, 119, 111, 114, 108, 100]);
    });

    test('utf8.decode()', () async {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            import 'dart:convert';

            String main() {
              return utf8.decode([72, 101, 108, 108, 111, 32, 119, 111, 114, 108, 100]);
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
          "Hello world");
    });
    test('base64.encode()', () async {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            import 'dart:convert';

            String main() {
              return base64.encode([52, 149, 126]);
            }
          '''
        }
      });

      expect(
          (runtime.executeLib(
            'package:example/main.dart',
            'main',
          ) as $Value)
              .$reified,
          'NJV+');
    });

    test('base64.decode()', () async {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            import 'dart:convert';

            List<int> main() {
              return base64.decode("SGVsbG8gd29ybGQ=");
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
              .map((e) => (e is $Value ? e.$reified : e) as int)
              .toList(),
          [72, 101, 108, 108, 111, 32, 119, 111, 114, 108, 100]);
    });
    test('base64Url.encode()', () async {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            import 'dart:convert';

            String main() {
              return base64Url.encode([52, 149, 126]);
            }
          '''
        }
      });

      expect(
          (runtime.executeLib(
            'package:example/main.dart',
            'main',
          ) as $Value)
              .$reified,
          'NJV-');
    });

    test('base64Url.decode()', () async {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            import 'dart:convert';

            List<int> main() {
              return base64Url.decode("SGVsbG8gd29ybGQ=");
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
              .map((e) => (e is $Value ? e.$reified : e) as int)
              .toList(),
          [72, 101, 108, 108, 111, 32, 119, 111, 114, 108, 100]);
    });
  });
}
