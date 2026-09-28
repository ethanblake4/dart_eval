import 'dart:async';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

const _library = 'package:imports/main.dart';

Iterable<Runtime> _runtimes(Program program) sync* {
  yield Runtime.ofProgram(program);
  yield Runtime(program.write().buffer);
}

void main() {
  test('deferred prefixes gate arguments until their load completes', () async {
    final program = Compiler().compile({
      'imports': {
        'main.dart': '''
          import 'values.dart' as eager;
          import 'values.dart' deferred as first;
          import 'values.dart' deferred as second;
          int calls = 0;
          int argument() { calls++; return 5; }
          bool blocked() {
            try { first.echo(argument()); } catch (e) { return calls == 0; }
            return false;
          }
          bool secondBlocked() {
            try { second.echo(0); } catch (e) { return true; }
            return false;
          }
          Future<int> load() async {
            var tearoff = first.loadLibrary;
            var pending = tearoff();
            if (!blocked()) return -1;
            await pending;
            await first.loadLibrary();
            return first.echo(argument()) + eager.echo(2);
          }
        ''',
        'values.dart': 'int echo(int value) => value;',
      },
    });
    for (final runtime in _runtimes(program)) {
      expect(runtime.executeLib(_library, 'blocked'), true);
      expect(await (runtime.executeLib(_library, 'load') as Future), $int(7));
      expect(runtime.executeLib(_library, 'secondBlocked'), true);
    }
  });

  test('conditional imports and exports choose the first matching URI', () {
    final program = Compiler().compile({
      'imports': {
        'main.dart':
            '''
          import 'missing.dart'
            if (dart.library.io == 'true') 'first.dart'
            if (dart.library.io) 'second.dart';
          import 'exports.dart' as exported;
          String main() => value + exported.value +
            const String.fromEnvironment('dart.library.io') +
            '${const bool.fromEnvironment('dart.library.io')}' +
            '${const bool.hasEnvironment('dart.library.io')}';
        ''',
        'exports.dart': '''
          export 'missing.dart'
            if (dart.library.io) 'first.dart'
            if (dart.library.io == 'true') 'second.dart';
        ''',
        'first.dart': "const value = 'first';",
        'second.dart': "const value = 'second';",
      },
    });
    for (final runtime in _runtimes(program)) {
      expect(runtime.executeLib(_library, 'main'), 'firstfirsttruetruetrue');
    }
  });

  test('an unset conditional name only matches its empty string value', () {
    final program = Compiler().compile({
      'imports': {
        'main.dart': '''
          import 'missing.dart'
            if (dart.library.absent == 'false') 'missing.dart'
            if (dart.library.absent == '') 'values.dart';
          int main() => value;
        ''',
        'values.dart': 'const value = 8;',
      },
    });
    for (final runtime in _runtimes(program)) {
      expect(runtime.executeLib(_library, 'main'), 8);
    }
  });

  test('a missing super setter invokes noSuchMethod on the real receiver', () {
    final program = Compiler().compile({
      'imports': {
        'main.dart': '''
          class Base {}
          class Child extends Base {
            int received = 0;
            dynamic noSuchMethod(Invocation invocation) {
              if (invocation.isSetter &&
                  invocation.memberName == const Symbol('missing=')) {
                received = invocation.positionalArguments[0];
              }
            }
            int assign() { return super.missing = 7; }
          }
          int main() {
            var child = Child();
            return child.assign() + child.received;
          }
        ''',
      },
    });
    for (final runtime in _runtimes(program)) {
      expect(runtime.executeLib(_library, 'main'), 14);
    }
  });
}
