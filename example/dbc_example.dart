import 'package:dart_eval/src/dbc/dbc_gen.dart';


void main(List<String> args) {
  final gen = DbcGen();

  final files = {
    'example': {
      'main.dart': '''
        import 'package:example/x.dart';
        int main() {
           return x();
        }
      ''',
      'x.dart': '''
        int x() {
           var b = 4;
           var c = 2;
           c = b;
           b = c;
           return b;
        }
      '''
    }
  };

  final exec = gen.generate(files);

  exec.printOpcodes();

  print(exec.executeNamed(0, 'main'));
}
