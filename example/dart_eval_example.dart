import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';

class X {
  const X(this.q);

  final int q;

  int doThing() {
    return q + q;
  }
}

class $X extends X with DbcBridgeInstance {
  const $X(this.$evalId, int q) : super(q);

  final int $evalId;

  static const $type = DbcBridgeTypeDescriptor('package:flutter/src/main.dart', 'X');

  static $X _$construct(int evalId, List<Object?> args) => $X(evalId, args[0] as int);

  static const DbcBridgeClass<$X> $classDef = DbcBridgeClass($type, constructors: {
    '': DbcBridgeConstructor(_$construct, [DbcBridgeParameter(type: DbcTypes.intType)])
  }, methods: {
    'doThing': DbcBridgeFunction([])
  }, fields: {
    'q': DbcBridgeField()
  });

  @override
  IDbcValue? $bridgeGet(String identifier) {
    switch (identifier) {
      case 'q':
        return DbcInt(super.q);
      case 'doThing':
        return DbcFunctionImpl((runtime, target, args) => DbcInt(super.doThing()));
    }
    throw UnimplementedError();
  }

  @override
  void $bridgeSet(String identifier, IDbcValue value) {
    throw UnimplementedError();
  }

  @override
  int doThing() => $invoke('doThing', []);
}

void main(List<String> args) {
  final compiler = Compiler();

  compiler.defineBridgeClass($X.$classDef);

  final files = {
    'example': {
      'main.dart': '''
        import 'package:flutter/src/main.dart';
        
        class Y extends X {
          Y(): super(1);
          
          int doThing() {
            return super.doThing() + 2;
          }
        }
        
        Y main() {
          final r = Y();
          return r;
        }
      ''',
    }
  };

  final dt = DateTime.now().millisecondsSinceEpoch;
  final exec = compiler.compileWriteAndLoad(files);
  print('Generate: ${DateTime.now().millisecondsSinceEpoch - dt} ms');

  final dt2 = DateTime.now().millisecondsSinceEpoch;
  exec.loadProgram();
  print('Load: ${DateTime.now().millisecondsSinceEpoch - dt2} ms\n');

  exec.printOpcodes();

  final dt3 = DateTime.now().millisecondsSinceEpoch;
  dynamic rv = exec.executeNamed(0, 'main');
  if (rv is IDbcValue) {
    rv = rv.$value;
  }
  print('Output: $rv');
  print((rv as X).doThing());
  print('Execute: ${DateTime.now().millisecondsSinceEpoch - dt3} ms');
}
