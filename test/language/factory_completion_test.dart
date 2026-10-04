import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:test/test.dart';

void main() {
  void accepts(String name, String body, String main, int expected) {
    test(name, () {
      final program = Compiler().compile({
        'factory': {
          'main.dart':
              '''
            int cleanups = 0;
            class Box {
              final int value;
              Box._(this.value);
              factory Box(bool fail) { $body }
            }
            int main() { $main }
          ''',
        },
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(
          runtime.executeLib('package:factory/main.dart', 'main'),
          expected,
        );
      }
    });
  }

  accepts(
    'factory joins returning try with throwing typed catch',
    '''
    try {
      if (fail) throw FormatException('input');
      return Box._(7);
    } on FormatException {
      throw FormatException('rewritten');
    }
  ''',
    '''
    final value = Box(false).value;
    try { Box(true); } on FormatException catch (error) {
      return error.message == 'rewritten' ? value : -1;
    }
    return -2;
  ''',
    7,
  );

  accepts(
    'factory typed catch returns with unmatched exceptions rethrown',
    '''
    try {
      if (fail) throw FormatException('input');
      throw 'unmatched';
    } on FormatException {
      return Box._(9);
    }
  ''',
    '''
    final value = Box(true).value;
    try { Box(false); } catch (error) {
      return error == 'unmatched' ? value : -1;
    }
    return -2;
  ''',
    9,
  );

  accepts(
    'nested mixed completion survives a normally completing finally',
    '''
    {
      try {
        try {
          if (fail) throw FormatException('input');
          return Box._(4);
        } on FormatException {
          throw 'rewritten';
        }
      } finally {
        cleanups++;
      }
    }
  ''',
    '''
    final value = Box(false).value;
    try { Box(true); } catch (error) {
      return error == 'rewritten' ? value + cleanups : -1;
    }
    return -2;
  ''',
    6,
  );

  accepts(
    'returning finally overrides normal and thrown try completion',
    '''
    try {
      if (fail) throw 'input';
      cleanups++;
    } finally {
      return Box._(8);
    }
  ''',
    'return Box(false).value + Box(true).value + cleanups;',
    17,
  );

  accepts(
    'throwing finally overrides a pending return',
    '''
    try { return Box._(8); } finally { throw 'cleanup'; }
  ''',
    '''
    try { Box(false); } catch (error) {
      return error == 'cleanup' ? 1 : -1;
    }
    return -2;
  ''',
    1,
  );

  accepts(
    'mixed completion survives switch and do while aggregation',
    '''
    do {
      switch (fail) {
        case true:
          try { return Box._(3); } catch (error) { throw 'caught'; }
        default:
          throw 'default';
      }
    } while (false);
  ''',
    '''
    final value = Box(true).value;
    try { Box(false); } catch (error) {
      return error == 'default' ? value : -1;
    }
    return -2;
  ''',
    3,
  );

  for (final fixture in <String, String>{
    'try body can fall through': '''
      try { if (fail) throw 'input'; } catch (error) { throw error; }
    ''',
    'catch can fall through': '''
      try { return Box._(1); } catch (error) { cleanups++; }
    ''',
    'conditional finally return can fall through': '''
      try { cleanups++; } finally { if (fail) return Box._(1); }
    ''',
    'switch break reaches factory end': '''
      switch (fail) { case true: return Box._(1); default: break; }
    ''',
    'finally break overrides pending return': '''
      done: {
        try { return Box._(1); } finally { break done; }
      }
    ''',
    'finally continue overrides pending return': '''
      do {
        try { return Box._(1); } finally { continue; }
      } while (false);
    ''',
    'mixed return and continue is not factory completion': '''
      do {
        if (fail) return Box._(1); else continue;
      } while (false);
    ''',
    'mixed return and labeled break is not factory completion': '''
      done: {
        if (fail) return Box._(1); else break done;
      }
    ''',
    'nested switch continue is not factory completion': '''
      do {
        switch (fail) { case true: return Box._(1); default: continue; }
      } while (false);
    ''',
  }.entries) {
    test('rejects factory when ${fixture.key}', () {
      expect(
        () => Compiler().compile({
          'factory': {
            'main.dart':
                '''
              int cleanups = 0;
              class Box {
                final int value;
                Box._(this.value);
                factory Box(bool fail) { ${fixture.value} }
              }
              void main() {}
            ''',
          },
        }),
        throwsA(
          isA<CompileError>().having(
            (error) => error.toString(),
            'message',
            contains('Factory constructor must always return a value or throw'),
          ),
        ),
      );
    });
  }
}
