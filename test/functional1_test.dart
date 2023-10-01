import 'dart:math';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

void main() {
  group('Functional tests', () {
    late Compiler compiler;

    setUp(() {
      compiler = Compiler();
    });

    test('Functional test 1', () {
      final source = '''
      dynamic main() {
        var someNumber = 19;
      
        var a = A(45);
        for (var i = someNumber; i < 20; i = i + 1) {
          final n = a.calculate(i);
          if (n > someNumber) {
            a = B(555);
          } else {
            if (a.number > B(a.number).calculate(2)) {
              a = C(888 + a.number);
            }
            someNumber = someNumber + 1;
          }
      
          if (n > a.calculate(a.number - i)) {
            a = D(21 + n);
            someNumber = someNumber - 1;
          }
        }
      
        return a.number;
      }
      
      class A {
        final int number;
      
        A(this.number);
      
        int calculate(int other) {
          return number + other;
        }
      }
      
      class B extends A {
        B(int number) : super(number);
      
        @override
        int calculate(int other) {
          var d = 1334;
          for (var i = 0; i < 15 + number; i = i + 1) {
            if (d > 4000) {
              d = d - 14;
            }
            d += i;
          }
          return d;
        }
      }
      
      class C extends A {
        C(int number) : super(number);
      
        @override
        int calculate(int other) {
          var d = 1556;
          for (var i = 0; i < 24 - number; i = i + 1) {
            if (d > 4000) {
              d = d - 14;
            } else if (d < 299) {
              d = d + 5 + 5;
            }
            d += i;
          }
          return d;
        }
      }
      
      class D extends A {
        D(int number) : super(number);
      
        @override
        int calculate(int other) {
          var d = 1334;
          for (var i = 0; i < 15 + number; i = i + 1) {
            if (d > 4000) {
              d = d - 14;
            }
            d += super.number;
          }
          return d;
        }
      }''';

      final runtime = compiler.compileWriteAndLoad({
        'example': {'main.dart': source}
      });

      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final result = runtime.executeLib('package:example/main.dart', 'main');
      expect(result, $int(555));
      expect(DateTime.now().millisecondsSinceEpoch - timestamp, lessThan(100));
    });

    test('Sum to', () {
      final source = '''
      void main() {
        print(calc(50));
      }

      int calc(int sumTo) {
        if (sumTo == 13) {
          print("unlucky number!");
        }
        int accum = 0;
        for (int i = 0; i < sumTo; i++) {
          final b = i < sumTo;
          accum = accum + i;
        }
        return accum;
      }''';

      final runtime = compiler.compileWriteAndLoad({
        'example': {'main.dart': source}
      });

      expect(() {
        runtime.executeLib('package:example/main.dart', 'main');
      }, prints('1225\n'));
    });

    test('Await chain', () async {
      final source = '''
        import 'dart:async';

        Future<int> main() async {
          func1();
          func2();
          func3();
          await Future.delayed(Duration(microseconds: 5000));
          print("complete");
          return func4();
        }

        void func1() async {
          await Future.delayed(Duration(microseconds: 3500));
          print("func1");
        }

        void func2() async {
          await Future.delayed(Duration(microseconds: 200));
          print("func2");
        }

        void func3() async {
          print("func3");
        }

        Future<int> func4() async {
          print("func4 start");
          await Future.delayed(Duration(milliseconds: 20));
          print("func4 end");
          return 1;
        }
      ''';

      final runtime = compiler.compileWriteAndLoad({
        'example': {'main.dart': source}
      });

      expect(() async {
        expect(await runtime.executeLib('package:example/main.dart', 'main'), $int(1));
      }, prints('func3\nfunc2\nfunc1\ncomplete\nfunc4 start\nfunc4 end\n'));
    });

    test('String split loop', () {
      final source = r'''
      List<String> test() {
        const cat = "Fluffy";
        var list = cat.split("ff");
        ///  ------  add Code Start ---------
        int length = list.length;
        print('length -> $length');
        for(var i = 0 ; i < length; i ++){
            print('i => $i');
        }
        ///  ------  add Code End ---------
        return list;
      }
      ''';

      final runtime = compiler.compileWriteAndLoad({
        'example': {'main.dart': source}
      });

      expect(() {
        runtime.executeLib('package:example/main.dart', 'test');
      }, prints('length -> 2\ni => 0\ni => 1\n'));
    });
  });
}
