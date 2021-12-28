import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';

class X {
  const X(this.q);

  final int q;

  int doThing() {
    return q + q;
  }
}

void main(List<String> args) async {

  await Future.delayed(const Duration(seconds: 1));

  final source = '''
dynamic main() {
  var someNumber = 19;

  var a = A(45);
  for (var i = someNumber; i < 200; i = i + 1) {
    final n = a.calculate(i);
    if (n > someNumber) {
      a = B(555);
    } else {
      if (a.number > B(a.number).calculate(2)) {
        a = C(888 + a.number);
      }
      someNumber = someNumber + 1;
    }

    if (n > a.calculate(a.number - i)) {
      a = D(21 + n);
      someNumber = someNumber - 1;
    }
  }

  return a.number;
}

class A {
  final int number;

  A(this.number);

  int calculate(int other) {
    return number + other;
  }
}

class B extends A {
  B(int number) : super(number);

  @override
  int calculate(int other) {
    var d = 1334;
    for (var i = 0; i < 15 + number; i = i + 1) {
      if (d > 4000) {
        d = d - 14;
      }
      d = d + i;
    }
    return d;
  }
}

class C extends A {
  C(int number) : super(number);

  @override
  int calculate(int other) {
    var d = 1556;
    for (var i = 0; i < 24 - number; i = i + 1) {
      if (d > 4000) {
        d = d - 14;
      } else if (d < 299) {
        d = d + 5 + 5;
      }
      d = d + i;
    }
    return d;
  }
}

class D extends A {
  D(int number) : super(number);

  @override
  int calculate(int other) {
    var d = 1334;
    for (var i = 0; i < 15 + number; i = i + 1) {
      if (d > 4000) {
        d = d - 14;
      }
      d = d + super.number;
    }
    return d;
  }
}
  ''';
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final result = eval(source);
  print('Output: $result');
  print('Execution time: ${DateTime.now().millisecondsSinceEpoch - timestamp} ms');

  await Future.delayed(const Duration(seconds: 300));
}

class $X extends X with BridgeInstance {
  const $X(int q) : super(q);

  static const $type = BridgeTypeDescriptor('package:flutter/src/main.dart', 'X');

  static $X _$construct(List<Object?> args) => $X(args[0] as int);

  static const BridgeClass<$X> $classDef = BridgeClass($type, constructors: {
    '': BridgeConstructor(_$construct, [BridgeParameter(type: EvalTypes.intType)])
  }, methods: {
    'doThing': BridgeFunction([])
  }, fields: {
    'q': BridgeField()
  });

  @override
  EvalValue? $bridgeGet(String identifier) {
    switch (identifier) {
      case 'q':
        return EvalInt(super.q);
      case 'doThing':
        return EvalFunctionImpl((runtime, target, args) => EvalInt(super.doThing()));
    }
    throw UnimplementedError();
  }

  @override
  void $bridgeSet(String identifier, EvalValue value) {
    throw UnimplementedError();
  }

  @override
  int get q => $_get('q');

  @override
  int doThing() => $_invoke('doThing', []);
}
