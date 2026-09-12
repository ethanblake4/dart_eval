import 'package:test/test.dart';
import 'compiler_cfg_test.dart' show compileGraph, expectDefinedReads;

void main() {
  for (final source in [
    'int f(int x, [int y = 2]) => x + y; int main() => f(1);',
    'int f({int x = 1}) => x; int main() => f(x: 2);',
    'class A { int x; A(this.x); int get value => x; } int main() => A(1).value;',
    'enum A { first, second } int main() => A.second.index;',
    'Future<int> f() async => 1; Future<int> main() async { return await f(); }',
    'int main() { try { throw 1; } catch (e) { return 2; } }',
    'int main() { try { return 1; } finally { print(2); } }',
    'int main() { try { throw 1; } on String catch (e) { return 2; } catch (e, s) { return 3; } }',
  ]) {
    test(source, () {
      final compiler = compileGraph(source);
      for (final graph in compiler.functionGraphs.values) {
        expectDefinedReads(graph);
      }
    });
  }
}
