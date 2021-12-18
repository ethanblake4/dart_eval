import 'package:dart_eval/src/eval/runtime/class.dart';
import 'package:dart_eval/src/eval/compiler/compiler.dart';

void main(List<String> args) {
  final compiler = Compiler();

  final files = {
    'example': {
      'main.dart': '''
        class X {
          X(this.q);
          
          final int q;
          
          int doThing() {
            return q + q;
          }
        }
        
        class Y extends X {
          Y(): super(1);
          
          int doThing() {
            return super.doThing() + 2;
          }
        }
        
        int main() {
          final r = Y();
          return r.doThing() + r.doThing();
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
  if (rv is DbcValueInterface) {
    rv = rv.evalValue;
  }
  print('Output: $rv');
  print('Execute: ${DateTime.now().millisecondsSinceEpoch - dt3} ms');
}