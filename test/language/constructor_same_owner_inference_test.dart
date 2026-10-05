import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:test/test.dart';

void main() {
  test('constructor return retains its enclosing class parameter', () {
    final program = Compiler().compile({
      'same_owner': {
        'main.dart': r'''
int factoryCalls = 0;
class Items<T extends num> {
  factory Items([Iterable<T>? values]) {
    factoryCalls++;
    return Items<T>.stored((values ?? <T>[]).toList());
  }
  Items.stored(this.values);
  Items.empty() : values = <T>[];
  final List<T> values;
  Items<T> reverse() {
    final List<T> result = values;
    return Items(result.reversed);
  }
  Items<T> upward() {
    final result = Items(values.reversed);
    return result;
  }
  Items<T> explicit() => Items<T>(values.reversed);
  Items<T> empty() => Items.empty();
  Items<T> shorthand() => .empty();
  Items<T> checked(dynamic value) => Items(value);
  Items<T> checkedExplicit(dynamic value) => Items<T>(value);
}
bool main() {
  final source = Items<int>([1, 2]);
  final result = source.reverse();
  if (result is! Items<int> || result.values.first != 2 ||
      source.upward() is! Items<int> || source.explicit() is! Items<int> ||
      source.empty() is! Items<int> || source.shorthand() is! Items<int> ||
      Items([1]) is! Items<int> ||
      Items() is! Items<num>) return false;
  final before = factoryCalls;
  try {
    source.checked(<String>['wrong']);
    return false;
  } on TypeError {}
  try {
    source.checkedExplicit(<String>['wrong']);
    return false;
  } on TypeError {}
  return factoryCalls == before;
}
''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:same_owner/main.dart', 'main'), true);
    }
  });
  test('same-owner inference still rejects incompatible returns', () {
    expect(
      () => Compiler().compile({
        'same_owner_negative': {
          'main.dart': r'''
class Items<T extends num> {
  Items(Iterable<T> values);
  Items<T> wrong() => Items<double>(<double>[1.5]);
}
void main() {}
''',
        },
      }),
      throwsA(isA<CompileError>()),
    );
  });
}
