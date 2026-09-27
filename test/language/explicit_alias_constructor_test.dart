import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _declarations = r'''
  class C<X extends Iterable<num>> {
    C();
    bool get hasExpandedType => X == List<int>;
    factory C.named() => D<X>();
  }

  class D<X extends Iterable<num>> extends C<X> {
    D() : super();
  }

  typedef T<X extends int> = C<List<X>>;
''';

void check(String constructor) {
  final program = Compiler().compile({
    'explicit_alias': {
      'main.dart':
          '''
        $_declarations
        bool main() {
          T<int> value = T<int>$constructor();
          return value.hasExpandedType;
        }
      ''',
    },
  });
  for (final runtime in [
    Runtime.ofProgram(program),
    Runtime(program.write().buffer),
  ]) {
    expect(
      runtime.executeLib('package:explicit_alias/main.dart', 'main'),
      true,
    );
  }
}

void main() {
  test('explicit alias arguments expand for a generative constructor', () {
    check('');
  });

  test('explicit alias arguments expand for a named factory', () {
    check('.named');
  });
}
