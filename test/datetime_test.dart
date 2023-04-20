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

  test('datetime add subtract', () async {
    final source = '''
      bool fn(){ 
        final a = DateTime.parse('2011-10-22 00:00:00');
        final dur = Duration(days: 1);
        final b = a.add(dur);
        final c = a.subtract(dur);
        if(b is! DateTime){
          return false;
        }
        if(c is! DateTime){
          return false;
        }
        if(!(b.year == 2011 && b.month == 10 && b.day == 23)){
          return false;
        }
        if(!(c.year == 2011 && c.month == 10 && c.day == 21)){
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

  test('datetime difference', () async {
    final source = '''
      bool fn(){ 
        final a = DateTime.parse('2011-10-22 00:00:00');
        final b = DateTime.parse('2011-10-21 00:00:00');
        final diff = a.difference(b);
        if(diff is! Duration){
          return false;
        } 
        if(diff.inDays != 1){
          return false;
        }
        if(diff.inHours != 24){
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
