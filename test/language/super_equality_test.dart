import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const source = r'''
int baseCalls = 0;
int childCalls = 0;
class Identity {
  bool operator ==(Object other) { childCalls++; return false; }
  int get hashCode => 0;
  bool same(Object other) => super == other;
  bool different(Object other) => super != other;
}
class Base {
  final int value;
  Base(this.value);
  bool operator ==(Object other) {
    baseCalls++;
    return other is int && other == value;
  }
  int get hashCode => value;
}
class Child extends Base {
  Child(int value) : super(value);
  bool operator ==(Object other) { childCalls++; return false; }
  bool same(Object other) => super == other;
  bool different(Object other) => super != other;
}
class Grandchild extends Child {
  Grandchild(int value) : super(value);
}
int main() {
  final identity = Identity();
  if (!identity.same(identity) || identity.different(identity)) return -1;
  if (identity.same(Identity()) || !identity.different(Identity())) return -2;
  if (childCalls != 0) return -3;
  for (final child in <Child>[Child(42), Grandchild(42)]) {
    if (!child.same(42) || child.same(43)) return -4;
    if (child.different(42) || !child.different(43)) return -5;
  }
  if (baseCalls != 8 || childCalls != 0) return -6;
  if (identity == identity || Child(42) == 42) return -7;
  if (baseCalls != 8 || childCalls != 2) return -8;
  return 0;
}
''';

void main() {
  test('super equality selects the lexical superclass operator', () {
    final program = Compiler().compile({
      'super_equality': {'main.dart': source},
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:super_equality/main.dart', 'main'), 0);
    }
  });
}
