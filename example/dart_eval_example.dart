import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';

class X {
  const X(this.q);

  final int q;

  int doThing() {
    return q + q;
  }
}

void main(List<String> args) {
  final source = '''
    import 'package:flutter/src/main.dart';
    
    class Y extends X {
      Y(): super(1);
      
      int doThing() {
        var count = 0;
        for (var i = 0; i < 1000; i = i + 1) {
          if (count < 500) {
            count = count - 1;
          } else if (count < 750) {
            count = count + 1;
          }
          count = count + i;
        }
        
        return count;
      }
    }
    
    Y main() {
      final r = Y();
      return r;
    }
  ''';
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final result = eval(source, bridgeClasses: [$X.$classDef]);
  print('Output: $result');
  print((result as X).doThing());
  print('Execution time: ${DateTime.now().millisecondsSinceEpoch - timestamp} ms');
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
