import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

const _declarations = '''
class FakeInvocation extends Invocation {
  final bool isGetter = true;
  bool get isMethod => false;
  bool get isSetter => false;
  Symbol get memberName => Symbol('fake');
  Map<Symbol, dynamic> get namedArguments => {Symbol('named'): 2};
  List get positionalArguments => [1];
}
class Handler {
  Invocation noSuchMethod(Invocation invocation) => invocation;
}
''';

void main() {
  test(
    'Invocation subclasses preserve default getters and noSuchMethod calls',
    () {
      for (final (mode, result) in runDynamicFixture('''
$_declarations
int main() {
  final fake = FakeInvocation();
  final handler = Handler();
  dynamic dynamicHandler = handler;
  Invocation missing = dynamicHandler.missing;
  Invocation manual = handler.noSuchMethod(fake);
  return (manual == fake ? 1 : 0) +
      (manual.isAccessor ? 2 : 0) +
      (manual.typeArguments.isEmpty ? 4 : 0) +
      (missing.isGetter ? 8 : 0) +
      (Invocation.method(Symbol('method'), []).isMethod ? 16 : 0);
}
''')) {
        expect(result, const DynamicFixtureResult.value(31), reason: mode);
      }
    },
  );

  test('Invocation subclasses expose guest getters to host Dart', () {
    final program = Compiler().compile({
      'dynamic_fixtures': {
        'main.dart': '$_declarations Invocation main() => FakeInvocation();',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      final invocation =
          runtime.executeLib(dynamicFixtureLibrary, 'main') as Invocation;
      expect(invocation.memberName, const Symbol('fake'));
      expect(invocation.positionalArguments, [1]);
      expect(invocation.namedArguments, {const Symbol('named'): 2});
      expect(invocation.typeArguments, isEmpty);
      expect(invocation.isAccessor, isTrue);
      expect(invocation.isGetter, isTrue);
      expect(invocation.isMethod, isFalse);
      expect(invocation.isSetter, isFalse);
    }
  });
}
