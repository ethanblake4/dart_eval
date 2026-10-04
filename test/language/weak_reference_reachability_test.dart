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
  test('guest objects inside opaque bridge arguments retain their methods', () {
    const bridge = 'package:opaque/bridge.dart';
    final compiler = Compiler()
      ..entrypointFunctions['/main.dart'] = {'main'}
      ..defineBridgeTopLevelFunction(
        const BridgeFunctionDeclaration(
          bridge,
          'opaque',
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
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
        'main.dart': r'''
import 'package:opaque/bridge.dart';
@pragma('weak-tearoff-reference')
Function? weak(Function? target) => target;
int throughOpaque() => 29;
class Owner {
  int reachableFromHost() => throughOpaque();
}
bool main([bool flag = true]) {
  final target = weak(throughOpaque);
  final owner = flag ? Owner() : Owner();
  opaque([owner]);
  return target != null && target() == 29;
}
''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      var calls = 0;
      runtime.registerBridgeFuncRegisters(bridge, 'opaque', (runtime, r, s, c) {
        calls++;
        return null;
      });
      expect(runtime.executeLib('package:weak/main.dart', 'main'), true);
      expect(calls, 1);
    }
  });
}
