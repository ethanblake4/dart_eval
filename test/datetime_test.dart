import 'package:dart_eval/dart_eval.dart';
import 'package:test/scaffolding.dart';

void main() {
  test('datetime parse', () async {
    //DateTime x = DateTime.now();
    //x.month
    final source = '''
      bool fn(){ 
        final a = DateTime.parse('2011-10-20 23:12:23'); 
        if(a.day != 20){
          return false;
        }
        if(a.month != 10){
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
    //assert(result);
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

  test('datetime isAfter isBefore', () async {
    final source = '''
      bool fn(){ 
        final a = DateTime.parse('2011-10-22 00:00:00');
        final b = DateTime.parse('2011-10-20 00:00:00');
        if(true != true){ 
          return false;
        }
        if(b.isAfter(a)){
          return false;
        }
        if(a.isBefore(b)){
          return false;
        }
        if(!b.isBefore(a)){
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
