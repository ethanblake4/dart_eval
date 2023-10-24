import 'package:dart_eval/dart_eval.dart';
import 'package:test/scaffolding.dart';

void main() {
  test('not equal for int', () async {
    final source = '''
      bool fn(){ 
        int x = 1;
        if(x != 2){
          return true;
        }
        return false;
      }
      ''';
    final compiler = Compiler();
    final program = compiler.compile({
      'my_package': {
        'main.dart': source,
      }
    });
    var runtime = Runtime.ofProgram(program);
    runtime.setup();
    var result = runtime.executeLib(
      "package:my_package/main.dart",
      "fn",
    );
    assert(result);
  });
  test('not equal for string', () async {
    final source = '''
      bool fn(){ 
        String x = "a";
        if(x != "axxx"){
          return true;
        }
        return false;
      }
      ''';
    final compiler = Compiler();
    final program = compiler.compile({
      'my_package': {
        'main.dart': source,
      }
    });
    var runtime = Runtime.ofProgram(program);
    runtime.setup();
    var result = runtime.executeLib(
      "package:my_package/main.dart",
      "fn",
    );
    assert(result);
  });

  test('not equal for bool', () async {
    final source = '''
      bool fn(){ 
        bool x = !false; 
        if(x != true){
          return false;
        }
        if(!x){
          return false;
        }
        if(!x != false){
          return false;
        }
        return true;
      }
      ''';
    final compiler = Compiler();
    final program = compiler.compile({
      'my_package': {
        'main.dart': source,
      }
    });
    var runtime = Runtime.ofProgram(program);
    runtime.setup();
    var result = runtime.executeLib(
      "package:my_package/main.dart",
      "fn",
    );
    assert(result);
  });
}
