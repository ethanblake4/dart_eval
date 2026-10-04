import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'Future.sync infers callback values and adopts typed nested results',
    () async {
      final program = Compiler().compile({
        'future_sync': {
          'main.dart': r'''
          import 'dart:async';

          FutureOr<int> union(bool pending) =>
              pending ? Future<int>.value(40) : 40;
          Future<int> inferred() => Future.sync(() => 40).then((x) => x + 2);
          Future<int> inferredBlock() => Future.sync(() { return 40; })
              .then((x) => x + 2);
          Future<int> explicit() => Future<int>.sync(() => 41)
              .then((x) => x + 1);
          Future<int?> nullable() => Future<int?>.sync(() => null);
          Future<int> recovered() => Future<int>.sync(() {
            throw StateError('sync');
          }).catchError((Object error) => 9);
          Future<List<int>> nested() => Future.sync(
              () => Future<List<int>>.value([4, 5])).then((x) => x);
          Future<List<int>> explicitNested() => Future<List<int>>.sync(
              () => Future<List<int>>.value([6, 7])).then((x) => x);
          Future<int> unionResult(bool pending) => Future.sync(() => union(pending))
              .then((x) => x + 2);
          Future<int> unionChain(bool pending) => Future.sync(() => 0)
              .then((_) => union(pending)).then((x) => x + 2);
          Future<bool> main() async =>
              await inferred() == 42 && await inferredBlock() == 42 &&
              await explicit() == 42 && await nullable() == null &&
              await recovered() == 9 && (await nested()).join(',') == '4,5' &&
              (await explicitNested()).join(',') == '6,7' &&
              await unionResult(false) == 42 && await unionResult(true) == 42 &&
              await unionChain(false) == 42 && await unionChain(true) == 42;
        ''',
        },
      });
      for (final (mode, runtime) in [
        ('fresh', Runtime.ofProgram(program)),
        ('encoded', Runtime(program.write().buffer)),
      ]) {
        expect(
          await runtime.executeLib('package:future_sync/main.dart', 'main'),
          $bool(true),
          reason: mode,
        );
      }
    },
  );

  test(
    'Future.sync rejects invalid dynamic scalar and nested list results',
    () async {
      final program = Compiler().compile({
        'future_sync': {
          'main.dart': r'''
          import 'dart:async';
          dynamic invalid() => 'wrong';
          dynamic invalidList() => Future<List<String>>.value(['wrong']);
          Future<int> scalar() => Future<int>.sync(() => invalid());
          Future<List<int>> nested() => Future<List<int>>.sync(() => invalidList());
        ''',
        },
      });
      for (final (mode, runtime) in [
        ('fresh', Runtime.ofProgram(program)),
        ('encoded', Runtime(program.write().buffer)),
      ]) {
        for (final function in ['scalar', 'nested']) {
          await expectLater(
            runtime.executeLib('package:future_sync/main.dart', function),
            throwsA(isA<TypeError>()),
            reason: '$mode $function',
          );
        }
      }
    },
  );
}
