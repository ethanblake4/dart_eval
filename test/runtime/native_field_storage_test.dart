import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _entrypoint = 'package:native_field_storage/main.dart';

Program _compile(String source) => Compiler().compile({
  'native_field_storage': {'main.dart': source},
});

void _expectResult(String source, Object expected) {
  _expectProgramResult(_compile(source), expected);
}

void _expectProgramResult(Program program, Object expected) {
  for (final runtime in [
    Runtime.ofProgram(program),
    Runtime(program.write().buffer),
  ]) {
    expect(runtime.executeLib(_entrypoint, 'main'), expected);
  }
}

void main() {
  test(
    'int fields mix constructor boxing, native writes, and object reads',
    () {
      final program = _compile('''
      class Counter {
        Counter(this.value);
        int value;
        void setValue(int next) { value = next; }
        void bump() { value++; }
        int read() => value;
      }
      bool main() {
        final counter = Counter(1000);
        if (counter.value != 1000) return false;
        counter.setValue(-1000);
        counter.bump();
        if (counter.value != -999) return false;
        counter.value = 1000;
        counter.bump();
        dynamic unknown = counter;
        Object boxed = unknown.value;
        Function read = counter.read;
        return boxed is int && boxed == 1001 && read() == 1001;
      }
    ''');
      expect(
        program.typedProgram.instructions.map((entry) => entry.$2.name),
        contains(
          anyOf(
            'setPropertyRA',
            'setPropertySA',
            'setPropertySB',
            'setPropertyCA',
            'setPropertyCB',
          ),
        ),
      );
      _expectProgramResult(program, true);
    },
  );

  test('late, inherited, and super int fields preserve their guards', () {
    _expectResult('''
      class Base {
        Base(this.value);
        int value;
        late int delayed;
        late final int frozen;
        void setFrozen(int next) { frozen = next; }
      }
      class Child extends Base {
        Child() : super(500);
        void raise() { super.value++; }
        int readSuper() => super.value;
      }
      bool main() {
        final child = Child();
        var uninitialized = false;
        try { child.delayed; } on StateError { uninitialized = true; }
        child.raise();
        child.value = child.value + 500;
        child.delayed = -500;
        child.delayed++;
        child.setFrozen(1000);
        var rejected = false;
        try { child.setFrozen(1001); } on StateError { rejected = true; }
        Base base = child;
        dynamic unknown = child;
        return uninitialized && rejected && child.readSuper() == 1001 &&
            base.value == 1001 && unknown.value is int &&
            child.delayed == -499 && child.frozen == 1000;
      }
    ''', true);
  });

  test(
    'String fields preserve boxed writes and callbacks',
    () {
      final program = _compile('''
      class Label {
        Label(this.text);
        String text;
        String? optional;
        void update(String next) { text = next; }
        String read() => text;
      }
      bool main() {
        final label = Label('start');
        if (label.text != 'start' || label.optional != null) return false;
        label.update(label.text + '!');
        label.text = label.text + '?';
        label.optional = 'later';
        dynamic unknown = label;
        Object boxed = unknown.text;
        Function read = label.read;
        final callbackValue = read();
        final optionalValue = label.optional;
        label.optional = null;
        return boxed is String && boxed == 'start!?' &&
            callbackValue is String && callbackValue == 'start!?' &&
            optionalValue == 'later' && label.optional == null;
      }
    ''');
      expect(
        program.typedProgram.callSites.map((site) => site.name),
        isNot(contains('text=')),
      );
      expect(
        program.typedProgram.instructions.map((entry) => entry.$2.name),
        contains(
          anyOf(
            'setPropertyRS',
            'setPropertySS',
            'setPropertySC',
            'setPropertyCS',
            'setPropertyCC',
          ),
        ),
      );
      _expectProgramResult(program, true);
    },
  );

  test('late, inherited, and overriding String fields retain semantics', () {
    _expectResult('''
      class Base {
        Base(this.text);
        String text;
        late String delayed;
        late final String frozen;
        void setFrozen(String next) { frozen = next; }
      }
      class Child extends Base {
        Child() : super('base');
        void addSuffix() { super.text = super.text + '!'; }
        String readSuper() => super.text;
      }
      class Override extends Base {
        Override() : super('base');
        set text(String next) { super.text = next + '!'; }
      }
      bool main() {
        final child = Child();
        var uninitialized = false;
        try { child.delayed; } on StateError { uninitialized = true; }
        child.addSuffix();
        child.delayed = child.text + '?';
        child.setFrozen('locked');
        var rejected = false;
        try { child.setFrozen('again'); } on StateError { rejected = true; }
        Base base = child;
        dynamic unknown = child;
        final overridden = Override();
        overridden.text = 'set';
        return uninitialized && rejected && child.readSuper() == 'base!' &&
            base.text == 'base!' && unknown.text == 'base!' &&
            child.delayed == 'base!?' && child.frozen == 'locked' &&
            overridden.text == 'set!';
      }
    ''', true);
  });

  test('generic field setters reject values from widened views', () {
    _expectResult('''
      class Box<T> {
        Box(this.value);
        T value;
      }
      bool rejects(Box<Object> box, dynamic invalid) {
        try { box.value = invalid; } on TypeError { return true; }
        return false;
      }
      bool main() {
        final words = Box<String>('first');
        words.value = 'second';
        final numbers = Box<int>(1000);
        numbers.value = 2000;
        Box<Object> widenedWords = words;
        Box<Object> widenedNumbers = numbers;
        return rejects(widenedWords, 42) && words.value == 'second' &&
            rejects(widenedNumbers, 'wrong') && numbers.value == 2000;
      }
    ''', true);
  });
}
