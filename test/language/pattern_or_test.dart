import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _source = r'''
typedef Exactly<T> = T Function(T);
extension StaticType<T> on T {
  T check<R extends Exactly<T>>() => this;
}
class Choice {
  Choice(this.leftValue, this.rightValue, [this.fallbackValue = 13]);
  final Object leftValue, rightValue, fallbackValue;
  int leftReads = 0, rightReads = 0, fallbackReads = 0;
  Object get left { leftReads++; return leftValue; }
  Object get right { rightReads++; return rightValue; }
  Object get fallback { fallbackReads++; return fallbackValue; }
}
class SideEffects extends Choice {
  SideEffects(this.change) : super('wrong', 5);
  final void Function() change;
  Object get left { change(); return leftValue; }
  Object get right { change(); return rightValue; }
}
int choose(Choice value) => switch (value) {
  Choice(left: int picked) || Choice(right: int picked) => picked,
  _ => -1,
};
int captures(Choice value) {
  int Function()? saved;
  if (value case Choice(left: int picked) || Choice(right: int picked)
      when (saved = () => picked)() > 0) {
    picked += 10;
    return saved!();
  }
  return -1;
}
int nested(Choice value) {
  int Function()? saved;
  if (value case var original &&
      (Choice(left: int picked) || Choice(right: int picked) ||
          Choice(fallback: int picked))
      when (saved = () => (original == value ? 0 : 100) + picked)() > 0) {
    original = Choice(0, 0);
    picked += 10;
    return saved!();
  }
  return -1;
}
int effects() {
  var writes = 0;
  int observe() => writes;
  final value = SideEffects(() { writes++; });
  if (value case SideEffects(left: int picked) || SideEffects(right: int picked)
      when observe() == 2) {
    return picked + observe();
  }
  return -1;
}
num scalar(Object value) {
  if (value case (num() && int()) || num()) {
    value.check<Exactly<num>>();
    return value;
  }
  return -1;
}
int chained(Object value) {
  if (value case (num() || (num() && int())) && var number) {
    number.check<Exactly<num>>();
    return number.toInt();
  }
  return -1;
}
int field((Object,) value) {
  if (value case (int _ || num _,)) {
    value.check<Exactly<(Object,)>>();
  }
  if (value case (num _ || num _,)) {
    value.check<Exactly<(num,)>>();
    return value.$1.toInt();
  }
  return -1;
}
int nullable(int? value) {
  if (value case int? picked? || int? picked?) {
    picked.check<Exactly<int>>();
    return picked;
  }
  return -1;
}
int mixed(int? value) {
  if (value case int? picked? || int? picked) {
    picked.check<Exactly<int?>>();
    return picked ?? -1;
  }
  return -2;
}
bool main() {
  final left = Choice(7, 9);
  if (choose(left) != 7 || left.leftReads != 1 || left.rightReads != 0) {
    throw StateError('right getter was evaluated after left matched');
  }
  final right = Choice('wrong', 9);
  if (choose(right) != 9 || right.leftReads != 1 || right.rightReads != 1) {
    throw StateError('right alternative did not supply its binding');
  }
  if (choose(Choice('wrong', 'wrong')) != -1) throw StateError('failed OR');
  if (captures(Choice(7, 9)) != 17 || captures(Choice('wrong', 9)) != 19) {
    throw StateError('selected variable did not share the guard capture');
  }
  final third = Choice('wrong', 'wrong');
  if (nested(third) != 123 || third.leftReads != 1 || third.rightReads != 1 ||
      third.fallbackReads != 1 || effects() != 7) {
    throw StateError('nested alternatives lost bindings or outer writes');
  }
  if (scalar(3) != 3 || scalar(2.5) != 2.5 || chained(3) != 3 ||
      field((4,)) != 4 || nullable(3) != 3 || nullable(null) != -1 ||
      mixed(3) != 3 || mixed(null) != -1) {
    throw StateError('lost common promotion or nullable binding');
  }
  return true;
}
''';

void main() {
  test('OR patterns short-circuit, join bindings and retain common proofs', () {
    final program = Compiler().compile({
      'pattern_or': {'main.dart': _source},
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:pattern_or/main.dart', 'main'), true);
    }
  });
}
