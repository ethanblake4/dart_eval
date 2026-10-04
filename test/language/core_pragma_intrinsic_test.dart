import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('resolved core pragma bridges retain intrinsic identity', () {
    for (final prefix in ['', 'core.']) {
      final compiler = Compiler()..entrypointFunctions['/main.dart'] = {'main'};
      final program = compiler.compile({
        'core_pragma': {
          'main.dart':
              '''
import 'dart:core';
import 'dart:core' as core;
@${prefix}pragma('external-effect')
external void effect(Object? value);
@${prefix}pragma('weak-tearoff-reference')
Function? weak(Function? target) => throw 'helper body must not execute';
int live() => 7;
int dead() => 11;
bool main() {
  int count = 0;
  effect(++count);
  final liveReference = weak(live);
  return count == 0 && live() == 7 && liveReference != null &&
      liveReference() == 7 && weak(dead) == null &&
      core.pragma('guest:keep').name == 'guest:keep';
}
''',
        },
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(
          runtime.executeLib('package:core_pragma/main.dart', 'main'),
          true,
        );
      }
    }
  });
}
