import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:test/test.dart';

import '../support/bridge_lib.dart';

const _library = 'package:github_bridge/main.dart';
const _nativeLibrary = 'package:bridge_lib/bridge_lib.dart';

Iterable<Runtime> _runtimes(
  String source, {
  List<BridgeClassDef>? declarations,
}) sync* {
  final compiler = Compiler()
    ..defineBridgeClasses(declarations ?? [$TestClass.$declaration]);
  final program = compiler.compile({
    'github_bridge': {'main.dart': source},
  });
  for (final runtime in [
    Runtime.ofProgram(program),
    Runtime(program.write().buffer),
  ]) {
    runtime.registerBridgeFuncRegisters(
      _nativeLibrary,
      'TestClass.',
      $TestClass.$construct,
      isBridge: true,
    );
    yield runtime;
  }
}

void main() {
  test('#184 callable field on a guest bridge subclass keeps its receiver', () {
    for (final runtime in _runtimes('''
      import '$_nativeLibrary';
      class Guest extends TestClass {
        Guest(int value, this.testSum) : super(value);
        final int Function(int) testSum;
      }
      int main() => Guest(18, (value) => value + 1).testSum(1);
    ''')) {
      expect(runtime.executeLib(_library, 'main'), 2);
    }
  });

  test('#276 nullable guest field above a bridge starts as null', () {
    for (final runtime in _runtimes('''
      import '$_nativeLibrary';
      class Option { final String q; Option(this.q); }
      class Guest extends TestClass {
        Guest() : super(1);
        Option? current;
        List<String> build() => [
          'base',
          if (current != null) current?.q ?? 'missing',
        ];
      }
      String main() {
        final guest = Guest();
        final before = guest.build().join(',');
        guest.current = Option('Q42');
        return before + ';' + guest.build().join(',');
      }
    ''')) {
      expect(runtime.executeLib(_library, 'main'), 'base;base,Q42');
    }
  });

  test('#6 bridge classes retain both declared interface contracts', () {
    final original = $TestClass.$declaration;
    final interfaces = [
      for (final name in ['First', 'Second'])
        BridgeClassDef(
          BridgeClassType(
            BridgeTypeRef(BridgeTypeSpec(_nativeLibrary, name)),
            isAbstract: true,
          ),
          constructors: {},
          methods: {'runTest': original.methods['runTest']!},
          wrap: true,
        ),
    ];
    final declaration = BridgeClassDef(
      BridgeClassType(
        $TestClass.$type,
        $implements: [for (final interface in interfaces) interface.type.type],
      ),
      constructors: original.constructors,
      fields: original.fields,
      methods: original.methods,
      getters: original.getters,
      setters: original.setters,
      bridge: true,
    );
    for (final runtime in _runtimes(
      '''
      import '$_nativeLibrary';
      class Guest extends TestClass { Guest() : super(18); }
      bool first(First value) => value.runTest(1, b: 'one');
      bool second(Second value) => value.runTest(2, b: 'two');
      bool main() {
        final native = TestClass(18);
        final guest = Guest();
        return native is First && native is Second &&
            guest is First && guest is Second &&
            first(native) && second(native) && first(guest) && second(guest);
      }
    ''',
      declarations: [...interfaces, declaration],
    )) {
      expect(runtime.executeLib(_library, 'main'), isTrue);
    }
  });
}
