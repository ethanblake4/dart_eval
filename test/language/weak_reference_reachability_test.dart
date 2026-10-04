import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:test/test.dart';

const _source = r'''
@pragma('weak-tearoff-reference')
Function? weak(Function? target) => throw 'the helper body must not execute';
int live() => 7;
int fromGetter() => 11;
int fromTearoff() => 13;
int fromDefault() => 17;
int dead() => deadCycle();
int deadCycle() => dead();
class Owner {
  int used() => live();
  int get selected => fromGetter();
  int indirect() => fromTearoff();
  int usedDefault([Function callback = fromDefault]) => callback();
  int unused() => dead();
  int unusedDefault([Function callback = dead]) => callback();
}
bool main() {
  final liveWeak = weak(live);
  final getterWeak = weak(fromGetter);
  final tearoffWeak = weak(fromTearoff);
  final defaultWeak = weak(fromDefault);
  const deadAlias = dead;
  final deadWeak = weak(deadAlias);
  final cycleWeak = weak(deadCycle);
  dynamic owner = Owner();
  if (owner.used() != 7 || owner.selected != 11) return false;
  final method = owner.indirect;
  if (method() != 13 || owner.usedDefault() != 17) return false;
  return liveWeak != null && liveWeak() == 7 &&
      getterWeak != null && getterWeak() == 11 &&
      tearoffWeak != null && tearoffWeak() == 13 &&
      defaultWeak != null && defaultWeak() == 17 &&
      identical(liveWeak, live) && deadWeak == null && cycleWeak == null;
}
''';

void main() {
  test(
    'weak targets follow strong calls, dynamic selectors and const aliases',
    () {
      final compiler = Compiler()..entrypointFunctions['/main.dart'] = {'main'};
      final program = compiler.compile({
        'weak': {'main.dart': _source},
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(runtime.executeLib('package:weak/main.dart', 'main'), true);
      }
    },
  );
  test('default library exports remain strong roots', () {
    const source = r'''
@pragma('weak-tearoff-reference')
Function? weak(Function? target) => target;
int exported() => 3;
bool main() {
  final target = weak(exported);
  return target != null && target() == 3;
}
''';
    for (final selected in [false, true]) {
      final compiler = Compiler();
      if (selected) compiler.entrypointFunctions['/main.dart'] = {'main'};
      final program = compiler.compile({
        'weak': {'main.dart': source},
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(runtime.executeLib('package:weak/main.dart', 'main'), !selected);
        if (!selected) {
          expect(runtime.executeLib('package:weak/main.dart', 'exported'), 3);
        }
      }
    }
  });
  test(
    'guest objects inside opaque bridge arguments retain their methods',
    () async {
      const bridge = 'package:opaque/bridge.dart';
      for (final payload in [
        '[owner]',
        '(owner,)',
        'Box(owner)',
        '{owner}.toList()',
        '{owner: 1}.keys',
        'await owner',
        'Factory()()',
      ]) {
        final compiler = Compiler()
          ..entrypointFunctions['/main.dart'] = {'main'}
          ..defineBridgeTopLevelFunction(
            const BridgeFunctionDeclaration(
              bridge,
              'opaque',
              BridgeFunctionDef(
                returns: BridgeTypeAnnotation(
                  BridgeTypeRef(CoreTypes.voidType),
                ),
                params: [
                  BridgeParameter(
                    'value',
                    BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object)),
                    false,
                  ),
                ],
              ),
            ),
          );
        final program = compiler.compile({
          'weak': {
            'main.dart':
                r'''
import 'package:opaque/bridge.dart';
@pragma('weak-tearoff-reference')
Function? weak(Function? target) => target;
int throughOpaque() => 29;
class Owner {
  int reachableFromHost() => throughOpaque();
}
class Box {
  final Owner child;
  Box(this.child);
}
class Factory {
  Owner call() => Owner();
}
bool main([bool flag = true]) {
  final target = weak(throughOpaque);
  final owner = flag ? Owner() : Owner();
  opaque(__payload__);
  return target != null && target() == 29;
}
'''
                    .replaceAll('__payload__', payload)
                    .replaceAll(
                      'bool main([bool flag = true]) {',
                      payload.startsWith('await ')
                          ? 'Future<bool> main([bool flag = true]) async {'
                          : 'bool main([bool flag = true]) {',
                    ),
          },
        });
        for (final runtime in [
          Runtime.ofProgram(program),
          Runtime(program.write().buffer),
        ]) {
          var calls = 0;
          runtime.registerBridgeFuncRegisters(bridge, 'opaque', (
            runtime,
            r,
            s,
            c,
          ) {
            calls++;
            return null;
          });
          final result = await runtime.executeLib(
            'package:weak/main.dart',
            'main',
          );
          expect(
            result is $Value ? result.$value : result,
            true,
            reason: payload,
          );
          expect(calls, 1);
        }
      }
    },
  );
  test('exported objects and callbacks expose guest members to the host', () {
    const source = r'''
import 'targets.dart';
@pragma('weak-tearoff-reference')
Function? weak(Function? target) => target;
class Guest {
  int get value => live();
}
Guest factory() => Guest();
Function callbackFactory() => () => Guest();
bool main() {
  final target = weak(live);
  return target != null && target() == 31 && weak(dead) == null;
}
''';
    for (final roots in [
      null,
      {'main'},
      {'main', 'callbackFactory'},
    ]) {
      final compiler = Compiler();
      if (roots != null) compiler.entrypointFunctions['/main.dart'] = roots;
      final program = compiler.compile({
        'weak': {
          'main.dart': source,
          'targets.dart': 'int live() => 31; int dead() => 37;',
        },
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        final exposed = roots == null || roots.contains('callbackFactory');
        expect(runtime.executeLib('package:weak/main.dart', 'main'), exposed);
        if (roots == null) {
          final guest =
              runtime.executeLib('package:weak/main.dart', 'factory')
                  as $Instance;
          expect(guest.$getProperty(runtime, 'value')?.$value, 31);
        }
        if (exposed) {
          final callback =
              runtime.executeLib('package:weak/main.dart', 'callbackFactory')
                  as EvalCallable;
          final guest =
              callback.call(runtime, null, null, null, 0) as $Instance;
          expect(guest.$getProperty(runtime, 'value')?.$value, 31);
        }
      }
    }
  });
  test(
    'unknown host closures expose arguments while guest closures stay precise',
    () {
      const source = r'''
import 'targets.dart';
@pragma('weak-tearoff-reference')
Function? weak(Function? target) => target;
class Guest {
  int get value => live();
}
bool host(Function callback) {
  final target = weak(live);
  callback(Guest());
  return target != null && target() == 41;
}
bool guest() {
  final target = weak(live);
  final callback = (Guest value) => 1;
  return callback(Guest()) == 1 && target == null;
}
''';
      for (final entry in ['host', 'guest']) {
        final compiler = Compiler()
          ..entrypointFunctions['/main.dart'] = {entry};
        final program = compiler.compile({
          'weak': {'main.dart': source, 'targets.dart': 'int live() => 41;'},
        });
        for (final runtime in [
          Runtime.ofProgram(program),
          Runtime(program.write().buffer),
        ]) {
          var calls = 0;
          final callback = $Function((runtime, target, r, s, c) {
            calls++;
            expect((r as $Instance).$getProperty(runtime, 'value')?.$value, 41);
            return null;
          });
          expect(
            runtime.executeLib(
              'package:weak/main.dart',
              entry,
              arguments: entry == 'host' ? {'callback': callback} : {},
            ),
            true,
          );
          expect(calls, entry == 'host' ? 1 : 0);
        }
      }
    },
  );
}
