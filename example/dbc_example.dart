import 'package:dart_eval/src/dbc/dbc_class.dart';
import 'package:dart_eval/src/dbc/dbc_gen.dart';


void main(List<String> args) {
  final gen = DbcGen();

  final files = {
    'example': {
      'main.dart': '''
        import 'package:example/x.dart';
        num main() {
          var i = x();
          return i + 3;
        }
        num x() {
          return x2();
        }
      ''',
      'x.dart': '''
        int x2() {
           var b = 4;
           var a = r();
           var c = 2;
           c = b;
           b = a;
           b = c;
           return b;
        }
        
        int r() {
          var ra = 99;
          return ra;
        }
      '''
    }
  };

  final dt = DateTime.now().millisecondsSinceEpoch;
  final exec = gen.generate(files);
  print('Generate: ${DateTime.now().millisecondsSinceEpoch - dt} ms');


  final dt2 = DateTime.now().millisecondsSinceEpoch;
  exec.loadProgram();
  print('Load: ${DateTime.now().millisecondsSinceEpoch - dt2} ms\n');

  exec.printOpcodes();

  dynamic rv = exec.executeNamed(0, 'main');
  if (rv is DbcValueInterface) {
    rv = rv.evalValue;
  }
  final dt3 = DateTime.now().millisecondsSinceEpoch;
  print('Output: $rv');
  print('Execute: ${DateTime.now().millisecondsSinceEpoch - dt3} ms');
}
