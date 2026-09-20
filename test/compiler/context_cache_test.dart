import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

const _library = 'package:context/main.dart';
const _host = 'package:context/host.dart';
Compiler _bridgedCompiler() => Compiler()
  ..defineBridgeTopLevelFunction(
    const BridgeFunctionDeclaration(
      _host,
      'initializeFromHost',
      BridgeFunctionDef(
        returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
      ),
    ),
  );
Program _compile(Compiler compiler, String source) => compiler.compile({
  'context': {'main.dart': source},
});
Object? _execute(Program program) {
  final runtime = Runtime.ofProgram(program)
    ..registerBridgeFuncRegisters(
      _host,
      'initializeFromHost',
      (runtime, r, s, c) => $int(11),
    );
  return runtime.executeLib(_library, 'main');
}

void main() {
  for (final global in [false, true]) {
    test('builtin types follow shifted library IDs, global=$global', () {
      _compile(Compiler(), 'int value=3; int main()=>value + 1;');
      final compiler = _bridgedCompiler();
      final program = _compile(
        compiler,
        "import '$_host'; ${global ? 'int value=initializeFromHost(); int main()=>value;' : 'int main()=>initializeFromHost();'}",
      );
      expect(_execute(program), 11);
      expect(_execute(Program.read(program.write().buffer)), 11);
    });
  }

  test(
    'reusing a compiler after another context retains its own type hierarchy',
    () {
      const source =
          'class Parent { int n=7; } class C extends Parent {} int main()=>C().n;';
      final compiler = Compiler();
      final initial = _compile(compiler, source);
      expect(_execute(initial), 7);
      final other = _compile(
        Compiler(),
        'class C { int n=9; } int main()=>C().n;',
      );
      expect(_execute(other), 9);
      _compile(
        _bridgedCompiler(),
        "import '$_host'; int main()=>initializeFromHost();",
      );
      expect(_execute(_compile(compiler, source)), 7);
      expect(_execute(initial), 7);
    },
  );
}
