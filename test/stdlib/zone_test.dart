import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

void main() {
  test('runZoned restores the parent and preserves generic results', () {
    final program = Compiler().compile({
      'zone_test': {
        'main.dart': '''
import 'dart:async';
int main() {
  final parent = Zone.current;
  final result = runZoned<int>(() {
    if (identical(parent, Zone.current)) return -1;
    return Zone.current['answer'] as int;
  }, zoneValues: {'answer': 42});
  return identical(parent, Zone.current) && Zone.current['answer'] == null
      ? result : -2;
}
''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:zone_test/main.dart', 'main'), 42);
    }
  });

  test(
    'zone error handlers run in the parent and guarded results are nullable',
    () {
      final program = Compiler().compile({
        'zone_test': {
          'main.dart': '''
import 'dart:async';
bool main() {
  final parent = Zone.current;
  var errors = 0;
  var handledInParent = true;
  runZoned<void>(() => throw StateError('legacy'), onError: (error, trace) {
    errors++;
    handledInParent = handledInParent && identical(parent, Zone.current);
  });
  final result = runZonedGuarded<int>(() => throw StateError('guarded'),
      (error, trace) {
    errors++;
    handledInParent = handledInParent && identical(parent, Zone.current);
  });
  return errors == 2 && handledInParent && result == null;
}
''',
        },
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(runtime.executeLib('package:zone_test/main.dart', 'main'), true);
      }
    },
  );

  test(
    'runZonedGuarded reports asynchronous errors in the parent zone',
    () async {
      final program = Compiler().compile({
        'zone_test': {
          'main.dart': '''
import 'dart:async';
Future<bool> main() {
  final parent = Zone.current;
  final done = Completer<bool>();
  runZonedGuarded<void>(() {
    scheduleMicrotask(() => throw StateError('asynchronous'));
  }, (error, trace) {
    done.complete(identical(parent, Zone.current));
  });
  return done.future;
}
''',
        },
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(
          await runtime.executeLib('package:zone_test/main.dart', 'main'),
          $bool(true),
        );
      }
    },
  );
}
