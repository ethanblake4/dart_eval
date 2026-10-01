import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('declaration initializers run before replacement values and super', () {
    final program = Compiler().compile({
      'field_initializers': {'main.dart': _source},
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:field_initializers/main.dart', 'verify'),
        true,
      );
    }
  });
}

const _source = r'''
String log = '';

String mark(String value) {
  log += '$value.';
  return value;
}

class Explicit {
  String value = mark('declaration');
  Explicit() : value = mark('initializer') {
    mark('body');
  }
  Explicit.redirect() : this();
  factory Explicit.make() => Explicit();
}

class Formal {
  String value = mark('declaration');
  Formal(this.value) {
    mark('body');
  }
}

class Ordered {
  String second = mark('second');
  String first = mark('first');
  Ordered() : first = mark('first-init'), second = mark('second-init');
}

class Parent {
  String parent = mark('parent');
  Parent() : parent = mark('parent-init') {
    mark('parent-body');
  }
}

class Child extends Parent {
  String child = mark('child');
  Child() : child = mark('child-init'), super() {
    mark('child-body');
  }
}

class Implicit {
  String value = mark('implicit');
}

mixin Fields {
  String mixed = mark('mixed');
}

class Mixed = Implicit with Fields;

String fail() {
  mark('throw');
  throw StateError('initializer');
}

class Throwing {
  String value = fail();
  Throwing() : value = mark('replacement') {
    mark('body');
  }
}

dynamic wrongValue() {
  mark('wrong-type');
  return 'not an int';
}

class Checked {
  int value = wrongValue();
  Checked() : value = 1 {
    mark('body');
  }
}

bool verify() {
  for (var construction in [
    () => Explicit(),
    () => Explicit.redirect(),
    () => Explicit.make(),
  ]) {
    log = '';
    final value = construction();
    if (log != 'declaration.initializer.body.' || value.value != 'initializer') {
      throw StateError('explicit: $log');
    }
  }
  log = '';
  final formal = Formal(mark('argument'));
  if (log != 'argument.declaration.body.' || formal.value != 'argument') {
    throw StateError('formal: $log');
  }
  log = '';
  final ordered = Ordered();
  if (log != 'second.first.first-init.second-init.' ||
      ordered.first != 'first-init' || ordered.second != 'second-init') {
    throw StateError('ordered: $log');
  }
  log = '';
  final child = Child();
  if (log != 'child.child-init.parent.parent-init.parent-body.child-body.' ||
      child.child != 'child-init' || child.parent != 'parent-init') {
    throw StateError('child: $log');
  }
  log = '';
  if (Implicit().value != 'implicit' || log != 'implicit.') {
    throw StateError('implicit: $log');
  }
  log = '';
  final mixed = Mixed();
  if (mixed.mixed != 'mixed' || mixed.value != 'implicit' ||
      log != 'mixed.implicit.') {
    throw StateError('mixin: $log');
  }
  log = '';
  try {
    Throwing();
    throw StateError('missing declaration failure');
  } on StateError catch (error) {
    if (error.message != 'initializer' || log != 'throw.') {
      throw StateError('throwing: $log');
    }
  }
  log = '';
  try {
    Checked();
    throw StateError('missing declaration type check');
  } on TypeError {
    if (log != 'wrong-type.') throw StateError('checked: $log');
  }
  return true;
}

void main() {
  if (!verify()) throw StateError('verification failed');
}
''';
