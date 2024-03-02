import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
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
        var result = 0;
      
        var a = A(45);
        for (var i = someNumber; i < 45; i++) {
          final n = a.calculate(i);
          result += n;
          if ((n % i) > a.number + 18) {
            a = B(58);
          } else {
            if (a.number * i * 2 > B(a.number).calculate(2)) {
              a = C(13 + a.number);
            }
            someNumber = someNumber + 1;
          }
        }
        result += D(21 + a.number).calculate(45);
      
        return result;
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

      final result = runtime.executeLib('package:example/main.dart', 'main');
      expect(result, $int(45646));
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
          await Future.delayed(Duration(microseconds: 9500));
          print("complete");
          return func4();
        }

        void func1() async {
          await Future.delayed(Duration(microseconds: 6500));
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
        expect(await runtime.executeLib('package:example/main.dart', 'main'),
            $int(1));
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

    test('Matches test from Readme', () {
      final runtime = compiler.compileWriteAndLoad({
        'my_package': {
          'main.dart': '''
            import 'package:my_package/finder.dart';
            void main() {
              final finder = Finder('Hello (world)');
              final parentheses = finder.findParentheses();
              if (parentheses.isNotEmpty) print(parentheses);
            }
          ''',
          'finder.dart': r'''
            class Finder {
              final String string;
              Finder(this.string);

              List<int> findParentheses() {
                final regex = RegExp(r'\((.*?)\)');
                final matches = regex.allMatches(string);
                return matches.map((match) => match.start).toList();
              }
            }
        '''
        }
      });
      expect(() {
        runtime.executeLib('package:my_package/main.dart', 'main');
      }, prints('[6]\n'));
    });

    /// https://github.com/ethanblake4/dart_eval/issues/137
    test('Regexp firstMatch bug', () {
      final runtime = compiler.compileWriteAndLoad({
        'extensions_test': {
          'main.dart': '''main() {
            var episode = RegExp(r'\\d+').firstMatch('episode 1');
            return episode;
          }'''
        }
      });
      final value = runtime.executeLib(
        'package:extensions_test/main.dart',
        'main',
      );
      expect((value as RegExpMatch).group(0), '1');
    });

    test('Bridged enum equality ternary assignment', () {
      final compiler2 = Compiler();
      compiler2.defineBridgeEnum(BridgeEnumDef(
          BridgeTypeRef(
              BridgeTypeSpec('package:my_package/show.dart', 'ShowType')),
          values: ['Movie', 'Series']));
      final program = compiler2.compile({
        'my_package': {
          'main.dart': r'''
            import 'show.dart';
            class Media {
              Media(this.type, this.url);
              final ShowType type;
              String? url;
            }
            void main() {
              final media = Media(ShowType.Movie, 'example.com');
              final url = media.type == ShowType.Movie ? 
                media.url = 'movie.com' : null;
              print(url);
            }
          '''
        }
      });
      final runtime = Runtime.ofProgram(program);
      runtime.registerBridgeEnumValues('package:my_package/show.dart',
          'ShowType', {'Movie': $int(0), 'Series': $int(1)});
      runtime.executeLib('package:my_package/main.dart', 'main');
    });

    test('Regex replacement loop', () {
      final source = r'''
      main() {
        print(transform(
          "ZAAiPZZiZAPZZAiAPZZZZZPZZiiAPZZAiZPZZiAAPZZZZAPZZZZZPZZAZPZAAiPZAAZ"
          "PZZAZPZZAAAPZZAZPZZZAAPZZiZZPZZAiZPZZAiAPZZZAAPZZZZZPZZAZPZZiZZPZZAZ"
          "iPZZiiiPZZZiAPZAAiPAAAiPZZZAAPZZAAiPZZZAiPZZAiZPZZZZAPZiiZZPZiZZZPAA"
          "ZZPZZiZZPZZAiiPZiiZZPZZAiiPZZZZAPZZZZZPAiZiPZZiZiPZZiZZPZZiiAPZZZAAP"
          "ZZAAiPZZZAiPZZAiZPZAAiPZiiZZPZiZZZPZZiiAPZZZAAPZZiAAPZZZAiPZZAiZPAii"
          "ZPZZAZPZAZAPZZAiZPZiZZZPZiiZiPZZAiiPAAAAPAZZZPZiiiiPZZiAiPZZZAiPZiZZ"
          "iPZZZiZPZZAZiPAiAAPZiZiAPZiZiAPZiZiAPZAZAPZAAZPZAAZPAZAZPZZAZPZAiiZP"
          "ZAAZPZAAiPZAAZP", 45, "iZAPgKQVv", 11, 3));
      }

      String transform(String c, int d, String f, int a, int g) {
        var e = "";
        for (var h = 0, k = c.length; h < k; h++) {
          String l = "";
          while (c[h] != f[g]) {
            l += c[h];
            h++;
          }
          for (var m = 0; m < f.length; m++) {
            l = l.replaceAll(RegExp(f[m], multiLine: true), m.toString());
          }

          print(g);
          e += l;
        }
        return e;
      }
      ''';

      final runtime = compiler.compileWriteAndLoad({
        'example': {'main.dart': source}
      });

      expect(() {
        runtime.executeLib('package:example/main.dart', 'main');
      },
          prints('3\n3\n3\n3\n3\n3\n3\n3\n3\n3\n3\n3\n3\n3\n3\n3\n3\n3\n3\n3\n'
              '3\n3\n3\n3\n3\n3\n3\n3\n3\n3\n3\n3\n3\n3\n3\n3\n3\n3\n3\n3\n'
              '3\n3\n3\n3\n3\n3\n3\n3\n3\n3\n3\n3\n3\n3\n3\n3\n3\n3\n3\n3\n'
              '3\n3\n3\n3\n3\n3\n3\n3\n3\n3\n3\n3\n3\n3\n3\n3\n3\n3\n3\n3\n'
              '3\n3\n3\n3\n3\n3\n'
              '1220110121120211111110021120111022111121111111211220122111211122'
              '2112111122110111120111202111221111111211101111210110001110212202'
              '2201112211220111201120111112100111011122111101111200100111120011'
              '1121111120101101011011110021112211220111201120112201001110111110'
              '0211122110221112011201200111211212112011011110010112002222211110'
              '0001102011120101101110111210202210102101021010212121221122121211'
              '12112001122112201221\n'));
    });

    test('Default parameter boxing error', () {
      final source = r'''
      void main() async {
        final interceptor = AccessTokenInterceptor();
        print(await interceptor.getAccessToken());
      }

      class AccessTokenInterceptor {
        Future<String> getAccessToken([bool force = false]) async {
          final String? token = null;
          if (!force && token != null) {
            return 'decoded';
          } else {
            return refreshAccessToken();
          }
        }

        Future<String> refreshAccessToken([bool force = true]) async {
          return 'refreshed';
        }
      }
      ''';

      final runtime = compiler.compileWriteAndLoad({
        'example': {'main.dart': source}
      });

      expect(() async {
        await runtime.executeLib('package:example/main.dart', 'main');
      }, prints('refreshed\n'));
    });
  });
}
