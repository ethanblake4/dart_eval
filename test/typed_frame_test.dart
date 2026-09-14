import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_frame.dart';
import 'package:test/test.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_interop.dart';

TypedProgram compile(String source) => Compiler().compileTyped({
  'frames': {'main.dart': source},
}, entrypoint: 'package:frames/main.dart');

void main() {
  const layout = TypedFunction(
    0,
    argumentKinds: [
      TypedArgumentKind.object,
      TypedArgumentKind.object,
      TypedArgumentKind.object,
      TypedArgumentKind.object,
    ],
    intSpillCount: 1,
    objectSpillCount: 1,
    objectOutgoingCount: 2,
  );

  test('entry overflow has independent storage for each run', () {
    final token = Object();
    final objects = <Object?>[null, null, token, null];
    final a = TypedEntry.prepare(layout, [], [], [], objects, null);
    final b = TypedEntry.prepare(layout, [], [], [], objects, null);
    objects[2] = null;
    (a.c as List<Object?>)[0] = null;
    expect(TypedInterop.exportExternal((b.c as List<Object?>)[0]), same(token));
  });

  test(
    'recursive frames isolate outgoing storage and clear inactive objects',
    () {
      final token = Object();
      final root = TypedFrame(layout);
      root.objectOutgoing[0] = token;
      final child = root.enter(layout, 12);
      child.objectOutgoing[0] = Object();
      child.objectSpills[0] = token;
      final grandchild = child.enter(layout, 24);
      expect(identical(root.objectOutgoing, child.objectOutgoing), isFalse);
      expect(grandchild.leave(), same(child));
      expect(child.leave(), same(root));
      expect(child.objectSpills, everyElement(isNull));
      expect(child.objectOutgoing, everyElement(isNull));
      expect(root.objectOutgoing, everyElement(isNull));
      root.objectOutgoing[0] = 19;
      final sibling = root.enter(layout, 36);
      expect(sibling, same(child));
      expect(root.objectOutgoing[0], 19);
      expect(sibling.returnPc, 36);
    },
  );

  test('host snapshots survive reentry and outgoing storage reuse', () {
    final first = Object(), second = Object();
    final frame = TypedFrame(layout);
    frame.objectOutgoing[0] = TypedInterop.boxExternal(first);
    final retained = frame.takeObjectArguments(1);
    expect(frame.objectOutgoing, everyElement(isNull));
    final identity = compile('Object main(Object value) => value;');
    expect(TypedMachine.run(identity, objectArguments: retained), same(first));
    final next = TypedInterop.boxExternal(second);
    frame.objectOutgoing[0] = next;
    expect(TypedInterop.exportExternal(retained.single), same(first));
    retained[0] = null;
    expect(frame.objectOutgoing[0], same(next));
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
