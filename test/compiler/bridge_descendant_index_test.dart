import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:test/test.dart';

import '../support/bridge_lib.dart';

const _bridgeLibrary = 'package:bridge_lib/bridge_lib.dart';
const _entrypoint = 'package:leaf/main.dart';

void main() {
  test('bridge implementer keeps source interface getter virtual', () {
    final base = $TestClass.$declaration;
    final bridge = BridgeClassDef(
      BridgeClassType(
        $TestClass.$type,
        $implements: [const BridgeTypeRef(BridgeTypeSpec(_entrypoint, 'Base'))],
      ),
      constructors: base.constructors,
      methods: base.methods,
      getters: base.getters,
      setters: base.setters,
      fields: base.fields,
      bridge: true,
    );
    final compiler = Compiler()..defineBridgeClasses([bridge]);
    final program = compiler.compile({
      'leaf': {
        'main.dart': '''
          import 'package:bridge_lib/bridge_lib.dart';
          class Base { int get someNumber => 1; }
          int read(Base value) => value.someNumber;
          int main() => read(TestClass(5)) + read(Base());
        ''',
      },
    });

    final runtime = Runtime.ofProgram(program);
    runtime.registerBridgeFuncRegisters(
      _bridgeLibrary,
      'TestClass.',
      (runtime, r, s, c) => $TestClass.$construct(runtime, r, s, c),
      isBridge: true,
    );
    expect(runtime.executeLib(_entrypoint, 'main'), 6);
  });
}
