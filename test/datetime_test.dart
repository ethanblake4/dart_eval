import 'package:dart_eval/dart_eval.dart';
import 'package:test/scaffolding.dart';

void main() {
  test('datetime parse', () async {
    //DateTime x = DateTime.now();
    //x.month
    final source = '''
      bool fn(){ 
        var a = DateTime.parse('2011-10-20');
        var b = DateTime.parse('2011-10-20');
        var c = DateTime.parse('2011-10-21');
        if(a != b){
          return false;
        }
        if(a == c){
          return false;
        }
        return true;
      }
      ''';
    final compiler = Compiler();
    final program = compiler.compile({
      'my_package': {
        'code.dart': source,
      }
    });
    var runtime = Runtime.ofProgram(program);
    runtime.setup();
    var result = runtime.executeLib(
      "package:my_package/code.dart",
      "fn",
    );
    assert(result);
  });

  test('datetime year month day', () async {
    final source = '''
      bool fn(){ 
        var a = DateTime.parse('2011-10-20');
        if(a.day != 20){
          return false;
        }
        if(a.month != 10 ){
          return false;
        }
        if(a.year != 2011){
          return false;
        }
        return true;
      }
      ''';
    final compiler = Compiler();
    final program = compiler.compile({
      'my_package': {
        'code.dart': source,
      }
    });
    var runtime = Runtime.ofProgram(program);
    runtime.setup();
    var result = runtime.executeLib(
      "package:my_package/code.dart",
      "fn",
    );
    assert(result);
  });
}
