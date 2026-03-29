/// Tests for module-level (global) List/Map mutation via method calls.
///
/// Bug: In dart_eval 0.8.x, calling `.add()` / `.addAll()` / `[key] = value`
/// on a module-level global collection does not persist the mutation.
/// The `LoadGlobal` opcode returns the stored reference, but the subsequent
/// method dispatch operates on a transient copy — the original global is
/// unchanged after the call.
///
/// Only explicit reassignment (`_list = [..._list, item]`) emits `StoreGlobal`
/// and persists correctly. In-place mutation methods do not.
///
/// Contrast with local variables and instance fields, which mutate correctly
/// because they use `LoadLocal` / `LoadField` + `StoreLocal` / `StoreField`
/// opcodes that handle reference semantics properly.
///
/// See: https://github.com/ethanblake4/dart_eval/issues/XXX
import 'dart:async';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

void main() {
  group('Global List mutation', () {
    late Compiler compiler;

    setUp(() {
      compiler = Compiler();
    });

    // ── Baseline: local variable ──────────────────────────────────────────

    test('local List.add() persists — baseline', () {
      // Local variables work correctly; this confirms the test harness is
      // sound before testing globals.
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': '''
            void main() {
              final list = <String>[];
              list.add('a');
              print(list.length);
            }
          ''',
        },
      });

      expect(
        () => runtime.executeLib('package:eval_test/main.dart', 'main'),
        prints('1\n'),
      );
    });

    // ── Core bug: global List.add() ───────────────────────────────────────

    test('global List.add() persists after call', () {
      // This is the minimal reproduction of the bug.
      // A module-level list is mutated via .add() inside a top-level function.
      // After the function returns, the global should contain the added element.
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': '''
            final _items = <String>[];

            void capture(String s) {
              _items.add(s);
            }

            void main() {
              capture('hello');
              print(_items.length);  // expected: 1
            }
          ''',
        },
      });

      expect(
        () => runtime.executeLib('package:eval_test/main.dart', 'main'),
        prints('1\n'),
      );
    });

    test('global List.add() called multiple times accumulates', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': '''
            final _log = <String>[];

            void log(String msg) {
              _log.add(msg);
            }

            void main() {
              log('a');
              log('b');
              log('c');
              print(_log.length);  // expected: 3
              print(_log.join(','));  // expected: a,b,c
            }
          ''',
        },
      });

      expect(
        () => runtime.executeLib('package:eval_test/main.dart', 'main'),
        prints('3\na,b,c\n'),
      );
    });

    test('global List.add() via instance method persists', () {
      // The mutation goes through an instance method (not a top-level function).
      // Both call paths should exhibit the same behavior.
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': '''
            final _keys = <String>[];

            class Collector {
              void collect(String id) {
                _keys.add(id);
              }
            }

            void main() {
              final c = Collector();
              c.collect('x');
              c.collect('y');
              print(_keys.length);   // expected: 2
              print(_keys.join('|'));  // expected: x|y
            }
          ''',
        },
      });

      expect(
        () => runtime.executeLib('package:eval_test/main.dart', 'main'),
        prints('2\nx|y\n'),
      );
    });

    test('global var List.add() persists (var, not final)', () {
      // Verify the bug is not limited to `final` globals.
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': '''
            var _buf = <int>[];

            void push(int v) {
              _buf.add(v);
            }

            void main() {
              push(1);
              push(2);
              print(_buf.length);  // expected: 2
            }
          ''',
        },
      });

      expect(
        () => runtime.executeLib('package:eval_test/main.dart', 'main'),
        prints('2\n'),
      );
    });

    // ── Contrast: reassignment works (documents current workaround) ───────

    test('global list reassignment persists — workaround baseline', () {
      // Explicit reassignment emits StoreGlobal and works today.
      // This test documents the current working alternative and must keep
      // passing after any fix.
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': '''
            var _items = <String>[];

            void capture(String s) {
              _items = [..._items, s];  // reassignment → StoreGlobal
            }

            void main() {
              capture('a');
              capture('b');
              print(_items.length);   // expected: 2
              print(_items.join('-')); // expected: a-b
            }
          ''',
        },
      });

      expect(
        () => runtime.executeLib('package:eval_test/main.dart', 'main'),
        prints('2\na-b\n'),
      );
    });
  });

  // ── Global Map mutation ───────────────────────────────────────────────────

  group('Global Map mutation', () {
    late Compiler compiler;

    setUp(() {
      compiler = Compiler();
    });

    test('global Map[]= persists after call', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': '''
            final _store = <String, dynamic>{};

            void set(String key, dynamic value) {
              _store[key] = value;
            }

            void main() {
              set('name', 'dart');
              set('version', 42);
              print(_store.length);        // expected: 2
              print(_store['name']);       // expected: dart
              print(_store['version']);    // expected: 42
            }
          ''',
        },
      });

      expect(
        () => runtime.executeLib('package:eval_test/main.dart', 'main'),
        prints('2\ndart\n42\n'),
      );
    });

    test('global Map[]= called from instance method persists', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': '''
            final _mutations = <String, dynamic>{};

            class ScriptContext {
              void setDatasource(String id, dynamic rows) {
                _mutations[id] = rows;
              }
            }

            void main() {
              final ctx = ScriptContext();
              ctx.setDatasource('fighters', ['a', 'b']);
              ctx.setDatasource('stats', [1, 2, 3]);
              print(_mutations.length);      // expected: 2
              print(_mutations.keys.join(',')); // expected: fighters,stats
            }
          ''',
        },
      });

      expect(
        () => runtime.executeLib('package:eval_test/main.dart', 'main'),
        prints('2\nfighters,stats\n'),
      );
    });
  });

  // ── Sulfite use-case: full script context simulation ─────────────────────

  group('Sulfite script context simulation', () {
    late Compiler compiler;

    setUp(() {
      compiler = Compiler();
    });

    test('setDatasource via print channel workaround captures mutations', () {
      // This is the current Sulfite workaround: mutations are serialized as
      // sentinel print lines rather than stored in a global collection.
      // Must continue working after any fix to the direct mutation bug.
      //
      // NOTE: registerBridgeFunc must be called on a Runtime created via
      // Runtime.ofProgram(), not compileWriteAndLoad(), to intercept dart:core.print.
      final logs = <String>[];

      final program = compiler.compile({
        'eval_test': {
          'main.dart': r'''
            String _enc(dynamic v) {
              if (v == null) return 'null';
              if (v is String) return '"' + v + '"';
              if (v is num) return v.toString();
              if (v is bool) return v ? 'true' : 'false';
              if (v is List) {
                var r = '[';
                var sep = '';
                for (final item in v) { r = r + sep + _enc(item); sep = ','; }
                return r + ']';
              }
              if (v is Map) {
                var r = '{';
                var sep = '';
                for (final k in v.keys) {
                  r = r + sep + '"' + k.toString() + '":' + _enc(v[k]);
                  sep = ',';
                }
                return r + '}';
              }
              return '"' + v.toString() + '"';
            }

            class ScriptContext {
              void setDatasource(String id, dynamic rows) {
                print('__MUT__' + id + '__JSON__' + _enc(rows));
              }
            }

            void run(ScriptContext ctx) {
              ctx.setDatasource('fighters', [{'name': 'charizard'}, {'name': 'blastoise'}]);
              ctx.setDatasource('stats', [{'hp': 78}, {'hp': 79}]);
            }

            void main() {
              run(ScriptContext());
            }
          ''',
        },
      });

      final runtime = Runtime.ofProgram(program);
      runtime.registerBridgeFunc('dart:core', 'print', (rt, target, args) {
        logs.add(args[0]?.$value?.toString() ?? '');
        return null;
      });

      // Zone capture as fallback: dart_eval 0.8.x may route print through
      // the zone rather than (or in addition to) the bridge.
      runZoned(
        () => runtime.executeLib('package:eval_test/main.dart', 'main'),
        zoneSpecification: ZoneSpecification(
          print: (_, __, ___, line) => logs.add(line),
        ),
      );

      final mutLines = logs.where((l) => l.startsWith('__MUT__')).toList();
      expect(mutLines.length, 2);
      expect(mutLines[0], contains('fighters'));
      expect(mutLines[0], contains('charizard'));
      expect(mutLines[1], contains('stats'));
      expect(mutLines[1], contains('hp'));
    });

    test('setDatasource via direct global Map captures mutations', () {
      // This is the DESIRED behavior after the fix: mutations stored directly
      // in a global Map without the print-channel workaround.
      //
      // Currently FAILS because global Map[]= does not persist.
      // After the fix, this test should pass.
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': r'''
            final _mutations = <String, dynamic>{};

            class ScriptContext {
              void setDatasource(String id, dynamic rows) {
                _mutations[id] = rows;
              }
            }

            void run(ScriptContext ctx) {
              ctx.setDatasource('fighters', [{'name': 'charizard'}]);
              ctx.setDatasource('stats', [{'hp': 78}]);
            }

            int getMutationCount() => _mutations.length;
            dynamic getMutation(String key) => _mutations[key];

            void main() {
              run(ScriptContext());
            }
          ''',
        },
      });

      runtime.executeLib('package:eval_test/main.dart', 'main');

      final count = runtime.executeLib('package:eval_test/main.dart', 'getMutationCount');
      // dart_eval may return a raw int or a $int wrapper — handle both.
      final countValue = count is $Value ? count.$value : count;
      expect(countValue, 2, reason: 'Two setDatasource calls must persist in global Map');

      final fighters = runtime.executeLib(
        'package:eval_test/main.dart',
        'getMutation',
        [$String('fighters')],
      );
      expect(fighters, isNotNull, reason: '"fighters" key must exist in global Map');
    });

    test('global List used as mutation log captures all ids', () {
      // Similar to the Map test but uses a List as the backing store.
      // Currently FAILS.
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': r'''
            final _ids = <String>[];

            void captureId(String id) {
              _ids.add(id);
            }

            void main() {
              captureId('fighters');
              captureId('stats');
              captureId('verdict');
              print(_ids.length);      // expected: 3
              print(_ids.join(','));   // expected: fighters,stats,verdict
            }
          ''',
        },
      });

      expect(
        () => runtime.executeLib('package:eval_test/main.dart', 'main'),
        prints('3\nfighters,stats,verdict\n'),
      );
    });
  });
}
