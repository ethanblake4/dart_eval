import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const source = r'''
typedef Exactly<T> = T Function(T);
extension Check<T> on T {
  T check<R extends Exactly<T>>() => this;
}
T context<T>(T value) => value;
Type inferredType<T>(T value) => T;
class CustomNumber {
  CustomNumber operator +(dynamic value) => this;
}
class DynamicNumber {
  dynamic operator +(dynamic value) => this;
}
T inferred<T>(dynamic value, Type expected) {
  if (T != expected) throw StateError('wrong context');
  return value;
}
late final Never never = throw StateError('unreachable');
void numeric<I extends int, D extends double, N extends num>(I i, D d, N n) {
  context<int>(i + inferred(1, int));
  context<double>(i + inferred(1.0, double));
  context<double>(n + inferred(1.0, double));
  context<double>(d + inferred(1.0, num));
  context<double>(1 + inferred(1.0, double));
  context<double>(1.0 + inferred(1.0, num));
  context<double>(d - inferred(1.0, num));
  context<double>(d * inferred(1.0, num));
  context<double>(d % inferred(1.0, num));
  context<double>(d.remainder(inferred(1.0, num)));
  double compound = 8.0;
  compound += inferred(1, num);
  compound -= inferred(1, num);
  compound *= inferred(1, num);
  compound %= inferred(3, num);
  if (compound != 2.0) throw StateError('wrong compound value');
  (n + d).check<Exactly<double>>();
  (n - d).check<Exactly<double>>();
  (n * d).check<Exactly<double>>();
  (n % d).check<Exactly<double>>();
  (i % d).check<Exactly<double>>();
  if (false) {
    (i + never).check<Exactly<num>>();
    (i * never).check<Exactly<num>>();
    (i % never).check<Exactly<num>>();
    (d + never).check<Exactly<double>>();
    (n + never).check<Exactly<num>>();
    (never + d).check<Exactly<Never>>();
  }
}
int main() {
  numeric<int, double, num>(8, 2.0, 8);
  dynamic one = 1;
  CustomNumber custom = CustomNumber();
  (custom += one).check<Exactly<CustomNumber>>();
  DynamicNumber dynamicCustom = DynamicNumber();
  final original = dynamicCustom;
  if (inferredType(dynamicCustom += one) != dynamic) return -5;
  if (!identical(dynamicCustom, original)) return -6;
  double dynamicDouble = 8.0;
  (dynamicDouble += one).check<Exactly<double>>();
  (dynamicDouble -= one).check<Exactly<double>>();
  (dynamicDouble *= one).check<Exactly<double>>();
  (dynamicDouble %= one).check<Exactly<double>>();
  num dynamicNum = 8;
  (dynamicNum += one).check<Exactly<num>>();
  List<num> checked = <int>[1];
  dynamic fraction = 0.5;
  try {
    checked[0] += fraction;
    return -3;
  } on TypeError {}
  if (checked[0] != 1) return -4;
  int changing = 3;
  changing += (changing = 4);
  if (changing != 7) return -1;
  int left = 3;
  final sum = left + (left = 4);
  if (sum != 7 || left != 4) return -2;
  return 0;
}
''';

void main() {
  test(
    'numeric operators preserve operand context and static result types',
    () {
      final program = Compiler().compile({
        'number_operator_inference': {'main.dart': source},
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(
          runtime.executeLib(
            'package:number_operator_inference/main.dart',
            'main',
          ),
          0,
        );
      }
    },
  );
}
