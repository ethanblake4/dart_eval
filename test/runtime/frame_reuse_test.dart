import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_frame.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

const _library = 'package:frame_reuse/main.dart';

Iterable<(String, Runtime)> _runtimes(String source) sync* {
  final program = Compiler().compile({
    'frame_reuse': {'main.dart': source},
  });
  yield ('fresh', Runtime.ofProgram(program));
  yield ('serialized', Runtime(program.write().buffer));
}

void main() {
  test('inactive leaf storage grows, clears, and survives retargeting', () {
    const small = TypedFunction(
      0,
      intSpillCount: 1,
      objectSpillCount: 1,
      objectOutgoingCount: 1,
    );
    const large = TypedFunction(
      1,
      intSpillCount: 4,
      doubleSpillCount: 3,
      boolSpillCount: 2,
      objectSpillCount: 5,
      objectOutgoingCount: 6,
    );
    final root = TypedFrame(small);
    final child = root.enter(small, 10);
    final retained = Object();
    child.objectSpills[0] = retained;
    child.objectOutgoing[0] = retained;

    expect(child.leave(), same(root));
    expect(child.returnPc, -1);
    expect(child.asyncState, isNull);
    expect(child.exceptions, isNull);
    expect(child.objectSpills, everyElement(isNull));
    expect(child.objectOutgoing, everyElement(isNull));

    final grown = root.enter(large, 20);
    expect(grown, same(child));
    expect(grown.function, same(large));
    expect(grown.intSpills.length, greaterThanOrEqualTo(4));
    expect(grown.doubleSpills.length, greaterThanOrEqualTo(3));
    expect(grown.boolSpills.length, greaterThanOrEqualTo(2));
    expect(grown.objectSpills.length, greaterThanOrEqualTo(5));
    expect(grown.objectOutgoing.length, greaterThanOrEqualTo(6));
    expect(grown.objectSpills, everyElement(isNull));
    expect(grown.objectOutgoing, everyElement(isNull));

    final ints = grown.intSpills;
    final doubles = grown.doubleSpills;
    final booleans = grown.boolSpills;
    final objects = grown.objectSpills;
    final outgoing = grown.objectOutgoing;
    grown.objectSpills.last = retained;
    grown.objectOutgoing.last = retained;
    grown.leave();

    final shrunk = root.enter(small, 30);
    expect(shrunk, same(child));
    expect(shrunk.function, same(small));
    expect(shrunk.intSpills, same(ints));
    expect(shrunk.doubleSpills, same(doubles));
    expect(shrunk.boolSpills, same(booleans));
    expect(shrunk.objectSpills, same(objects));
    expect(shrunk.objectOutgoing, same(outgoing));
    expect(shrunk.objectSpills, everyElement(isNull));
    expect(shrunk.objectOutgoing, everyElement(isNull));
    shrunk.leave();

    final suspended = root.enter(large, 40);
    suspended.detachAsync();
    expect(suspended.parent, isNull);
    expect(suspended.returnPc, -1);
    final replacement = root.enter(small, 50);
    expect(replacement, isNot(same(suspended)));
    expect(replacement.parent, same(root));
  });

  test('alternating callees preserve large spills and outgoing overflow', () {
    const source = r'''
      int small(int value) => value + 1;

      int sum6(int a, int b, int c, int d, int e, int f) =>
          a + b + c + d + e + f;

      String join6(
        String a,
        String b,
        String c,
        String d,
        String e,
        String f,
      ) => a + b + c + d + e + f;

      int large(int seed) {
        var a = seed + 1;
        var b = seed + 2;
        var c = seed + 3;
        var d = seed + 4;
        var e = seed + 5;
        var f = seed + 6;
        var oa = 'a';
        var ob = 'b';
        var oc = 'c';
        var od = 'd';
        var oe = 'e';
        var of = 'f';
        final number = sum6(a, b, c, d, e, f);
        final text = join6(oa, ob, oc, od, oe, of);
        return number + text.length + a + f;
      }

      int main() {
        var checksum = 0;
        for (var i = 0; i < 40; i = i + 1) {
          checksum = checksum + small(i);
          final expanded = large(i);
          checksum = checksum + expanded;
          checksum = checksum + small(expanded);
        }
        return checksum;
      }
    ''';
    for (final (kind, runtime) in _runtimes(source)) {
      expect(runtime.executeLib(_library, 'main'), 16060, reason: kind);
    }
  });

  test('exception unwinds do not leak state into a different callee', () {
    const source = r'''
      int marker = 0;

      int small(int value) => value * 2;
      void fail(int value) { throw 'failure'; }

      int protectedLarge(int seed, bool shouldFail) {
        var a = seed + 1;
        var b = seed + 2;
        var c = seed + 3;
        var d = seed + 4;
        try {
          if (shouldFail) fail(seed);
          return a + b + c + d;
        } finally {
          marker = marker + a;
        }
      }

      int main() {
        var checksum = 0;
        for (var i = 0; i < 12; i = i + 1) {
          try {
            checksum = checksum + protectedLarge(i, true);
          } catch (error) {
            checksum = checksum + small(i);
          }
          checksum = checksum + protectedLarge(i, false);
          checksum = checksum + small(i + 1);
        }
        return checksum * 1000 + marker;
      }
    ''';
    for (final (kind, runtime) in _runtimes(source)) {
      expect(runtime.executeLib(_library, 'main'), 672156, reason: kind);
    }
  });

  test(
    'suspended children detach before the parent enters another callee',
    () async {
      const source = r'''
      int immediate(int value) => value + 5;

      Future<int> suspended(int seed) async {
        var a = seed + 1;
        var b = seed + 2;
        var c = seed + 3;
        var d = seed + 4;
        await 0;
        return a + b + c + d;
      }

      Future<int> main() async {
        final first = suspended(3);
        final between = immediate(4);
        final second = suspended(7);
        final after = immediate(8);
        return between + after + await first + await second;
      }
    ''';
      for (final (kind, runtime) in _runtimes(source)) {
        expect(
          await runtime.executeLib(_library, 'main'),
          $int(82),
          reason: kind,
        );
      }
    },
  );

  test('recursive sibling calls alternate frame shapes at every depth', () {
    const source = r'''
      int sum6(int a, int b, int c, int d, int e, int f) =>
          a + b + c + d + e + f;

      int walk(int depth) {
        if (depth == 0) return 1;
        return left(depth - 1) + right(depth - 1);
      }

      int left(int depth) => walk(depth) + 1;

      int right(int depth) {
        var a = depth;
        var b = depth + 1;
        var c = depth + 2;
        var d = depth + 3;
        var e = depth + 4;
        var f = depth + 5;
        final nested = walk(depth);
        return nested + 2 + sum6(a, b, c, d, e, f);
      }

      int main() => walk(5);
    ''';
    for (final (kind, runtime) in _runtimes(source)) {
      expect(runtime.executeLib(_library, 'main'), 746, reason: kind);
    }
  });
}
