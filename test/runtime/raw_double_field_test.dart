import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _entrypoint = 'package:raw_double_field/main.dart';

Program _compile(String source) => Compiler().compile({
  'raw_double_field': {'main.dart': source},
});

void _expectResult(Program program, Object expected) {
  for (final runtime in [
    Runtime.ofProgram(program),
    Runtime(program.write().buffer),
  ]) {
    expect(runtime.executeLib(_entrypoint, 'main'), expected);
  }
}

void main() {
  test('boxed constructor field and native write share readable storage', () {
    final program = _compile('''
      class Sample {
        Sample(this.amount);
        double amount;
        double get doubled => amount * 2;
        double read() => amount;
        void add(double value) { amount = amount + value; }
      }
      bool main() {
        final sample = Sample(1.5);
        if (sample.amount != 1.5) return false;
        sample.amount = 3.25;
        sample.add(1.25);
        dynamic unknown = sample;
        Object fromGetter = unknown.amount;
        Function read = sample.read;
        final fromTearoff = read();
        return sample.amount == 4.5 && sample.doubled == 9.0 &&
            fromGetter is double && fromGetter == 4.5 &&
            fromTearoff is double && fromTearoff == 4.5;
      }
    ''');
    expect(
      program.typedProgram.instructions.map((entry) => entry.$2.name),
      contains(anyOf('setPropertyRF', 'setPropertySF', 'setPropertyCF')),
    );
    _expectResult(program, true);
  });

  test('late mutable double reads and late final write guard', () {
    final program = _compile('''
      class Sample {
        late double amount;
        late final double locked;
        void setAmount(double value) { amount = value; }
        void setLocked(double value) { locked = value; }
      }
      bool main() {
        final sample = Sample();
        var uninitialized = false;
        try { sample.amount; } on StateError { uninitialized = true; }
        sample.setAmount(2.5);
        sample.amount = sample.amount + 2.0;
        sample.setLocked(7.25);
        var rejected = false;
        try { sample.setLocked(8.5); } on StateError { rejected = true; }
        dynamic unknown = sample;
        Object amount = unknown.amount;
        return uninitialized && rejected && amount is double &&
            amount == 4.5 && sample.locked == 7.25;
      }
    ''');
    _expectResult(program, true);
  });

  test('inherited and super double reads see native writes', () {
    final program = _compile('''
      class Base {
        Base(this.amount);
        double amount;
        double read() => amount;
      }
      class Child extends Base {
        Child() : super(1.5);
        void raise() { super.amount = super.amount + 2.0; }
        double readSuper() => super.amount;
      }
      bool main() {
        final child = Child();
        child.raise();
        child.amount = child.amount + 1.0;
        Base base = child;
        dynamic unknown = child;
        return child.readSuper() == 4.5 && base.read() == 4.5 &&
            unknown.amount is double && unknown.amount == 4.5;
      }
    ''');
    _expectResult(program, true);
  });
}
