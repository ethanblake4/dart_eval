import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

void main() {
  group('Async tests', () {
    late Compiler compiler;

    setUp(() {
      compiler = Compiler();
    });

    test('Simple async/await', () async {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
          Future main(int milliseconds) async {
            await Future.delayed(Duration(milliseconds: milliseconds));
            return 3;
          }
          '''
        }
      });

      final startTime = DateTime.now().millisecondsSinceEpoch;
      final future = runtime
          .executeLib('package:example/main.dart', 'main', [150]) as Future;
      await expectLater(future, completion($int(3)));
      final endTime = DateTime.now().millisecondsSinceEpoch;
      expect(endTime - startTime, greaterThan(80));
      expect(endTime - startTime, lessThan(450));
    });

    test('Chained async/await', () async {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
          Future main() async {
            return await fun();
          }
          Future fun() async {
            return 3;
          }
          '''
        }
      });

      final future =
          runtime.executeLib('package:example/main.dart', 'main') as Future;
      await expectLater(future, completion($int(3)));
    });

    test('Auto await future return value', () async {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
          Future main() async {
            return fun();
          }
          Future fun() async {
            return 3;
          }
          '''
        }
      });

      final future =
          runtime.executeLib('package:example/main.dart', 'main') as Future;
      await expectLater(future, completion($int(3)));
    });

    test('Future.delayed()', () async {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
          Future main(int milliseconds) {
            return Future.delayed(Duration(milliseconds: milliseconds));
          }
          '''
        }
      });

      final startTime = DateTime.now().millisecondsSinceEpoch;
      final future = runtime
          .executeLib('package:example/main.dart', 'main', [150]) as Future;
      await expectLater(future, completion(null));
      final endTime = DateTime.now().millisecondsSinceEpoch;
      expect(endTime - startTime, greaterThan(100));
      expect(endTime - startTime, lessThan(200));
    });

    test('Using a Future result', () async {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
          import 'dart:math';
          Future<num> main(int milliseconds) async {
            final result = await getPoint(milliseconds).then((result) => result.x + result.y);
            return result + 1;
          }

          Future<Point> getPoint(int milliseconds) async {
            await Future.delayed(Duration(milliseconds: milliseconds));
            return Point(5, 5);
          }
          '''
        }
      });

      final value = await (runtime
          .executeLib('package:example/main.dart', 'main', [150]) as Future);
      expect(value, $int(11));
    });
  });
}
