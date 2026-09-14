import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_frame.dart';
import 'package:test/test.dart';

TypedProgram compile(String source) => Compiler().compileTyped({
  'frames': {'main.dart': source},
}, entrypoint: 'package:frames/main.dart');

void main() {
  const layout = TypedFunction(
    0,
    intArgumentCount: 1,
    doubleArgumentCount: 1,
    boolArgumentCount: 1,
    objectArgumentCount: 1,
    intSpillCount: 1,
    objectSpillCount: 1,
    intOutgoingCount: 1,
    doubleOutgoingCount: 1,
    boolOutgoingCount: 1,
    objectOutgoingCount: 1,
  );

  test('entry storage is independent of caller lists and other runs', () {
    final token = Object();
    final integers = [7], doubles = [1.5], booleans = [true];
    final objects = <Object?>[token];
    final a = TypedFrame.entry(layout, integers, doubles, booleans, objects);
    final b = TypedFrame.entry(layout, integers, doubles, booleans, objects);
    integers[0] = 9;
    doubles[0] = 3;
    booleans[0] = false;
    objects[0] = null;
    a.intArguments[0] = 11;
    a.objectArguments[0] = null;
    expect(b.intArguments.single, 7);
    expect(b.doubleArguments.single, 1.5);
    expect(b.boolArguments.single, 1);
    expect(b.objectArguments.single, same(token));
  });

  test(
    'recursive frames isolate outgoing storage and clear inactive objects',
    () {
      final token = Object();
      final root = TypedFrame.entry(layout, [0], [0], [false], [token]);
      root.intOutgoing[0] = 5;
      root.objectOutgoing[0] = token;
      final child = root.enter(layout, 12, 0);
      child.intOutgoing[0] = 3;
      child.objectOutgoing[0] = Object();
      child.objectSpills[0] = token;
      final grandchild = child.enter(layout, 24, 3);
      expect(child.intArguments.single, 5);
      expect(grandchild.intArguments.single, 3);
      expect(child.objectArguments.single, same(token));
      expect(grandchild.leave(), same(child));
      expect(child.leave(), same(root));
      expect(child.objectSpills, everyElement(isNull));
      expect(child.objectOutgoing, everyElement(isNull));
      expect(root.objectOutgoing.single, isNull);
      root.intOutgoing[0] = 19;
      final sibling = root.enter(layout, 36, 1);
      expect(sibling, same(child));
      expect(sibling.intArguments.single, 19);
      expect(sibling.returnPc, 36);
      expect(sibling.returnBank, 1);
    },
  );

  test('host snapshots survive reentry and outgoing storage reuse', () {
    final first = Object(), second = Object();
    final frame = TypedFrame.entry(layout, [0], [0], [false], [first]);
    frame.objectOutgoing[0] = first;
    final retained = frame.takeObjectArguments(1);
    expect(frame.objectOutgoing.single, isNull);
    final identity = compile('Object main(Object value) => value;');
    expect(TypedMachine.run(identity, objectArguments: retained), same(first));
    frame.objectOutgoing[0] = second;
    expect(retained.single, same(first));
    retained[0] = null;
    expect(frame.objectOutgoing.single, same(second));
  });

  test('recursive mixed calls preserve objects across repeated siblings', () {
    final program = compile('''
      Object choose(int depth, Object first, Object second) {
        if (depth == 0) return first;
        var saved = choose(depth - 1, second, first);
        return choose(0, saved, first);
      }
      Object main(int depth, Object first, Object second) {
        var ignored = choose(depth + 1, first, second);
        return choose(depth, first, second);
      }
    ''');
    final first = Object(), second = Object();
    for (final depth in [6, 3, 0, 9, 2]) {
      expect(
        TypedMachine.run(
          program,
          intArguments: [depth],
          objectArguments: [first, second],
        ),
        same(depth.isEven ? first : second),
      );
    }
  });
}
