import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

void main() {
  group('Uri getters tests', () {
    late Compiler compiler;

    setUp(() {
      compiler = Compiler();
    });

    test('Uri().authority', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            String main() {
              final uri ='https://username:password@example.com/';
              final parsedUri = Uri.parse(uri);
              return parsedUri.authority;
            }
           ''',
        },
      });

      expect(
        runtime.executeLib('package:example/main.dart', 'main'),
        $String('username:password@example.com'),
      );
    });

    test('Uri().userInfo', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            String main() {
              final uri = 'https://username:password@example.com/';
              final parsedUri = Uri.parse(uri);
              return parsedUri.userInfo;
            }
           ''',
        },
      });

      expect(
        runtime.executeLib('package:example/main.dart', 'main'),
        $String('username:password'),
      );
    });
    test('Uri().host', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            String main() {
              final uri ='https://username:password@example.com/path/to/resource?query=value#fragment';
              final parsedUri = Uri.parse(uri);
              return parsedUri.host;
            }
           ''',
        },
      });

      expect(
        runtime.executeLib('package:example/main.dart', 'main'),
        $String('example.com'),
      );
    });
    test('Uri().path', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            String main() {
              final uri ='https://username:password@example.com/path/to/resource';
              final parsedUri = Uri.parse(uri);
              return parsedUri.path;
            }
           ''',
        },
      });

      expect(
        runtime.executeLib('package:example/main.dart', 'main'),
        $String('/path/to/resource'),
      );
    });

    test('Uri().query', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            String main() {
              final uri ='https://username:password@example.com/path/to/resource?query=value#fragment';
              final parsedUri = Uri.parse(uri);
              return parsedUri.query;
            }
           ''',
        },
      });

      expect(
        runtime.executeLib('package:example/main.dart', 'main'),
        $String('query=value'),
      );
    });

    test('Uri().fragment', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            String main() {
              final uri = 'https://username:password@example.com/path/to/resource?query=value#fragment';
              final parsedUri = Uri.parse(uri);
              return parsedUri.fragment;
            }
          ''',
        },
      });

      expect(
        runtime.executeLib('package:example/main.dart', 'main'),
        $String('fragment'),
      );
    });

    test('Uri().port', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main() {
              final uri = 'https://username:password@example.com:8080/path/to/resource?query=value#fragment';
              final parsedUri = Uri.parse(uri);
              return parsedUri.port;
            }
          ''',
        },
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), 8080);
    });

    test('Uri().pathSegments', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            List<String> main() {
              final uri = 'https://username:password@example.com:8080/path/to/resource?query=value#fragment';
              final parsedUri = Uri.parse(uri);
              return parsedUri.pathSegments;
            }
          ''',
        },
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), [
        $String("path"),
        $String("to"),
        $String("resource"),
      ]);
    });

    test('Uri().queryParameters', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            Map<String, String> main() {
              final uri = 'https://username:password@example.com:8080/path/to/resource?query=value#fragment';
              final parsedUri = Uri.parse(uri);
              return parsedUri.queryParameters;
            }
          ''',
        },
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), {
        $String("query"): $String("value"),
      });
    });

    test('Uri().queryParametersAll', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            Map<String, List<String>> main() {
              final uri = 'https://username:password@example.com:8080/path/to/resource?query=value#fragment';
              final parsedUri = Uri.parse(uri);
              return parsedUri.queryParametersAll;
            }
          ''',
        },
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), {
        $String("query"): [$String("value")],
      });
    });

    test('Uri boolean tests', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            List<bool> main() {
              final uri = 'https://username:password@example.com:8080/path/to/resource?query=value#fragment';
              final parsedUri = Uri.parse(uri);
              return [
                parsedUri.isAbsolute,
                parsedUri.hasScheme,
                parsedUri.hasAuthority,
                parsedUri.hasPort,
                parsedUri.hasQuery,
                parsedUri.hasFragment,
                parsedUri.hasEmptyPath,
                parsedUri.hasAbsolutePath,
              ];
            }
          ''',
        },
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), [
        $bool(false),
        $bool(true),
        $bool(true),
        $bool(true),
        $bool(true),
        $bool(true),
        $bool(false),
        $bool(true),
      ]);
    });
  });
}
