import 'package:dart_eval/src/eval/runtime/class.dart';
import 'package:dart_eval/src/eval/compiler/compiler.dart';

void main(List<String> args) {
  final compiler = Compiler();

  final files = {
    'example': {
      'main.dart': '''
        import 'package:example/x.dart';
        num main() {
          var m2 = Vib(z: 6);
          var n = 0;
          for (var i = 1; i < 100000; i = i + 1) {
            n = n + 1;
          }
          return m2.z;
        }
      ''',
      'x.dart': '''
      class Vib {
        Vib({this.z = 3});
        
        int z;
        
        int h() {
          return 11;
        }
      }
      '''
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
