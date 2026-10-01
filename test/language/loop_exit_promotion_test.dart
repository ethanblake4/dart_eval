import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:test/test.dart';

void main() {
  test('loop exit promotions follow condition and break predecessors', () {
    final program = Compiler().compile({
      'loop_exit': {'main.dart': _source},
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:loop_exit/main.dart', 'verify'), true);
    }
  });
  for (final body in [
    'while (x is! String) { break; }',
    'do { if (stop) break; } while (x is! String);',
    'while (stop) { x = "text"; }',
    'do { x = "text"; } while (false);',
    'do { x = "text"; break; } while (false);',
    'do { if (stop) return 7; x = "text"; break; } while (false);',
    'while (x is! String) { x = "text"; try { break; } finally { x = 0; } }',
    'while (x is! String) { x = "text"; try { try { break; } finally { x = "inner"; } } finally { x = 0; } }',
    'while (x is! String) { x = "text"; try { continue; } finally { x = 0; break; } }',
    'while (x is! String) { try { break; } finally { x = "again"; continue; } }',
  ]) {
    test('a bypassed condition does not promote: $body', () {
      expect(
        () => Compiler().compile({
          'loop_exit': {
            'main.dart':
                '''
int invalid(Object x, bool stop) { $body return x.length; }
void main() {}
''',
          },
        }),
        throwsA(isA<CompileError>()),
      );
    });
  }
  test('a captured write prevents loop exit promotion', () {
    expect(
      () => Compiler().compile({
        'loop_exit': {
          'main.dart': r'''
int invalid(Object x) {
  void write() { x = 0; }
  while (x is! String) { x = 'text'; }
  write();
  return x.length;
}
void main() {}
''',
        },
      }),
      throwsA(isA<CompileError>()),
    );
  });
}

const _source = r'''
int sdkWhile(Object x) {
  while (x is! String) {}
  return x.length;
}
int sdkDo(Object x) {
  do {} while (x is! String);
  return x.length;
}
int whileExit(Object x) {
  while (x is! String) { x = 'abc'; }
  return x.length;
}
int doExit(Object x) {
  do { x = 'abcd'; } while (x is! String);
  return x.length;
}
int continued(Object x) {
  do { x = 'ab'; continue; } while (x is! String);
  return x.length;
}
int whileContinued(Object x) {
  while (x is! String) { x = 'abc'; continue; }
  return x.length;
}
int breakPromoted(Object x, bool stop) {
  while (x is! String) {
    x = 'a';
    if (stop) break;
  }
  return x.length;
}
int labeledContinue(Object x) {
  outer: while (x is! String) {
    while (true) { x = 'abc'; continue outer; }
  }
  return x.length;
}
int patternContinue(Object x) {
  while (x is! String) {
    switch (x) { case int value when value >= 0: x = 'a'; continue; default: x = 'b'; }
  }
  return x.length;
}
int finallyContinue(Object x) {
  do { try { continue; } finally { x = 'a'; } } while (x is! String);
  return x.length;
}
int nestedFinally(Object x) {
  while (x is! String) {
    x = 'start';
    try {
      try { break; } finally { x = 0; }
    } finally { x = 'outer'; }
  }
  return x.length;
}
int finallyBreakOverridesContinue(Object x) {
  while (x is! String) {
    x = 'before';
    try { continue; } finally { x = 'after'; break; }
  }
  return x.length;
}
int internalBreak(Object x) {
  try {
    while (x is! String) { x = 'ok'; break; }
    return x.length;
  } finally { x = 0; }
}
int shadowedFinally(Object x) {
  while (x is! String) {
    x = 'outer';
    { final marker = 1;
      try { if (marker == 1) break; }
      finally { Object x = 0; x = 'local'; }
    }
  }
  return x.length;
}
int terminalDemotion(Object x) {
  var round = 0;
  while (x is! String) {
    x = 'before';
    try { break; }
    finally {
      round++;
      x = round == 1 ? 0 : 'done';
      continue;
    }
  }
  return x.length;
}
bool verify() => sdkWhile('a') == 1 && sdkDo('ab') == 2 &&
  whileExit(0) == 3 && whileExit('a') == 1 &&
  doExit(0) == 4 && continued(0) == 2 &&
  whileContinued(0) == 3 && breakPromoted(0, true) == 1 &&
  labeledContinue(0) == 3 && patternContinue(0) == 1 && finallyContinue(0) == 1 &&
  nestedFinally(0) == 5 &&
  finallyBreakOverridesContinue(0) == 5 && internalBreak(0) == 2 &&
  shadowedFinally(0) == 5 && terminalDemotion(0) == 4;
void main() { if (!verify()) throw StateError('loop exit promotion'); }
''';
