import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:test/test.dart';

class NativeRoutingParent {
  final String message;
  final Object? source;
  final int? offset;
  const NativeRoutingParent([
    this.message = '',
    this.source = 'default source',
    this.offset = 9,
  ]);
}

class NativeRoutingChild extends NativeRoutingParent {
  const NativeRoutingChild(super.message, [super.offset]);
}

void main() {
  test('positional super formals forward by position and inherit defaults', () {
    final program = Compiler().compile({
      'routing': {
        'main.dart': '''
          class Parent {
            final String message;
            final Object? source;
            final int? offset;
            const Parent([this.message = '',
                this.source = 'default source', this.offset = 9]);
          }
          class Child extends Parent {
            const Child(super.message, [Object? super.offset]);
          }
          String main() {
            const supplied = Child('bad input', 4);
            const omitted = Child('bad input');
            return '\${supplied.message}|\${supplied.source}|\${supplied.offset};'
                '\${omitted.message}|\${omitted.source}|\${omitted.offset}';
          }
        ''',
      },
    });
    const supplied = NativeRoutingChild('bad input', 4);
    const omitted = NativeRoutingChild('bad input');
    final expected =
        '${supplied.message}|${supplied.source}|${supplied.offset};'
        '${omitted.message}|${omitted.source}|${omitted.offset}';
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:routing/main.dart', 'main'), expected);
    }
  });

  test('positional forwarding retains strict target type checking', () {
    for (final superclass in ['Parent', 'FormatException']) {
      expect(
        () => Compiler().compile({
          'routing': {
            'main.dart':
                '''
              class Parent {
                const Parent([String message = '', Object? source, int? offset]);
              }
              class Child extends $superclass {
                const Child(String super.message, [Object? super.offset]);
              }
              Child main() => Child(4);
            ''',
          },
        }),
        throwsA(isA<CompileError>()),
        reason: superclass,
      );
    }
  });
}
