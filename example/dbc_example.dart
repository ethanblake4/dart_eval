import 'package:dart_eval/src/dbc/dbc_gen.dart';

void main(List<String> args) {
  final gen = DbcGen();

  final exec = gen.generate('''
  int main() {
    var i = 3;
    {
      var k = 2;
      k = i;
      return k;
    }
  }
  
  int somethn() {
    var i = main();
    return i;
    {
      var k = 'wow';
      k = 'crazy';
      return k;
    }
  }
 
  ''');

  exec.printOpcodes();

  print(exec.executeNamed(0, 'somethn'));
}