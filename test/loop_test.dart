import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

void main() {
  group('Loop tests', () {
    late Compiler compiler;

    setUp(() {
      compiler = Compiler();
    });

    test('For loop', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            num main() {
              var i = 0;
              for (; i < 555; i++) {}
              return i;
            }
          ''',
        }
      });
      expect(
          runtime.executeLib('package:example/main.dart', 'main'), $int(555));
    });

    test('For loop + branching', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
          dynamic doThing() {
            var count = 0;
            for (var i = 0; i < 1000; i++) {
              if (count < 500) {
                count--;
              } else if (count < 750) {
                count++;
              }
              count += i;
            }
            
            return count;
          }
        '''
        }
      });

      expect(runtime.executeLib('package:example/main.dart', 'doThing'),
          $int(499472));
    });

    test('Simple foreach', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            num main() {
              var i = 0;
              for (var x in [1, 2, 3, 4, 5]) {
                i += x;
              }
              return i;
            }
          ''',
        }
      });
      expect(runtime.executeLib('package:example/main.dart', 'main'), $int(15));
    });

    test('Foreach with dynamic iterable, specifying type in loop', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            num main() {
              var i = 0;
              dynamic list = [[1, 2], [3, 4], [5]];
              for (List<int> x in list) {
                i += x[0];
              }
              i++;
              return i;
            }
          ''',
        }
      });
      expect(runtime.executeLib('package:example/main.dart', 'main'), $int(10));
    });

    test('Simple while loop', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            num main() {
              var i = 0;
              while (i < 555) {
                i++;
              }
              return i;
            }
          ''',
        }
      });
      expect(
          runtime.executeLib('package:example/main.dart', 'main'), $int(555));
    });

    test('Simple do-while loop', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            num main() {
              var i = 0;
              do {
                i++;
              } while (i < 555);
              return i;
            }
          ''',
        }
      });
      expect(
          runtime.executeLib('package:example/main.dart', 'main'), $int(555));
    });

    test('For loop with break', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            num main() {
              var i = 0;
              for (; i < 555; i++) {
                print(i);
                if (i == 5) {
                  break;
                }
              }
              return i;
            }
          ''',
        }
      });
      expect(runtime.executeLib('package:example/main.dart', 'main'), $int(5));
    });

    test('Nested for loop with break', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            num main() {
              var i = 0;
              var j = 0;
              for (; i < 555; i++) {
                for (; j < 555; j++) {
                  if (j == 100) {
                    break;
                  }
                }
                if (i == 100) {
                  break;
                }
              }
              return i * 1000 + j;
            }
          ''',
        }
      });
      expect(runtime.executeLib('package:example/main.dart', 'main'),
          $int(100100));
    });

    test('continue statement should skip iteration when condition is met', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            num main() {
              var count = 0;
              for (var i = 0; i < 5; i++) {
                if (i == 2) {
                  continue;
                }
                count++;
              }
              return count;
            }
          ''',
        }
      });
      // skip when i == 2, -> 4
      expect(runtime.executeLib('package:example/main.dart', 'main'), $int(4));
    });

    test('For loop with continue', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            num main() {
              var total = 0;
              for (var i = 0; i < 10; i++) {
                if (i > 2) {
                  continue;
                }
                total += i;
              }
              return total;
            }
          ''',
        }
      });
      // skip 3, 4, 5, 6, 7, 8, 9
      // so 0 + 1 + 2 = 3
      expect(runtime.executeLib('package:example/main.dart', 'main'), $int(3));
    });

    test('continue statement skips iteration and adds i to count', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
        num main() {
          var count = 0;
          for (var i = 0; i < 5; i++) {
            if (i == 2) {
              continue;
            } 
            count += i;
          }
          return count;
        }
      ''',
        }
      });
      expect(runtime.executeLib('package:example/main.dart', 'main'), $int(8));
    });

    test('continue statement skips iteration and adds i to count', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
        num main() {
          var count = 0;
          for (var i = 0; i < 5; i++) {
            if (i is num) {
              continue;
            } 
            count += i;
          }
          return count;
        }
      ''',
        }
      });
      expect(runtime.executeLib('package:example/main.dart', 'main'), $int(0));
    });

    test('if statement inside for loop works when using equality operator', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
        num main() {
          var count = 0;
          for (var i = 0; i < 5; i++) {
            if (i == 2) {
            // nop
            } else {
            count += i;
            }
          }
          return count;
        }
      ''',
        }
      });
      expect(runtime.executeLib('package:example/main.dart', 'main'), $int(8));
    });

    test('continue with string concatenation after increment', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
        String main() {
          var result = "";
          for (var i = 0; i < 5; i++) {
            if (i == 2) {
              continue;
            }
            result += i.toString();
          }
          return result;
        }
      ''',
        }
      });
      expect(runtime.executeLib('package:example/main.dart', 'main'),
          $String("0134"));
    });

    test('continue with compound assignment operators', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
        int main() {
          var sum = 1;
          for (var i = 1; i < 6; i++) {
            if (i == 3) {
              continue;
            }
            sum *= i;
          }
          return sum;
        }
      ''',
        }
      });
      // 1 * 1 * 2 * 4 * 5 = 40 (skipping i=3)
      expect(runtime.executeLib('package:example/main.dart', 'main'), 40);
    });

    test('continue with subtraction and comparison operations', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
        int main() {
          var count = 0;
          for (var i = 10; i > 0; i--) {
            if (i == 5) {
              continue;
            }
            if (i > 7) {
              count -= i;
            } else {
              count += i;
            }
          }
          return count;
        }
      ''',
        }
      });
      // i values: 10, 9, 8, 7, 6, 4, 3, 2, 1 (skipping 5)
      // count = 0 - 10 - 9 - 8 + 7 + 6 + 4 + 3 + 2 + 1 = -4
      expect(runtime.executeLib('package:example/main.dart', 'main'), -4);
    });

    test('continue with mixed variable types and operations', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
        double main() {
          var intSum = 0;
          var doubleSum = 0.0;
          for (var i = 0; i < 5; i++) {
            if (i == 2) {
              continue;
            }
            intSum += i;
            doubleSum += i / 2.0;
          }
          return (intSum + doubleSum).toDouble();
        }
      ''',
        }
      });
      // intSum = 0 + 1 + 3 + 4 = 8
      // doubleSum = 0/2 + 1/2 + 3/2 + 4/2 = 0 + 0.5 + 1.5 + 2.0 = 4.0
      // total = 8 + 4.0 = 12.0
      expect(runtime.executeLib('package:example/main.dart', 'main'), 12.0);
    });

    test('continue with boolean logic operations', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
        int main() {
          var count = 0;
          for (var i = 0; i < 6; i++) {
            if (i == 3) {
              continue;
            }
            if (i > 2 && i < 5) {
              count += 10;
            } else if (i <= 1) {
              count += 1;
            }
          }
          return count;
        }
      ''',
        }
      });
      // i=5: no change -> count = 12
      expect(runtime.executeLib('package:example/main.dart', 'main'), 12);
    });

    test('continue with list operations and indexing', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
        int main() {
          var numbers = [10, 20, 30, 40, 50];
          var sum = 0;
          for (var i = 0; i < numbers.length; i++) {
            if (i == 2) {
              continue;
            }
            sum += numbers[i];
          }
          return sum;
        }
      ''',
        }
      });
      // sum = 10 + 20 + 40 + 50 = 120 (skipping numbers[2] = 30)
      expect(runtime.executeLib('package:example/main.dart', 'main'), 120);
    });

    test('continue with nested arithmetic and multiple variables', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
        int main() {
          var x = 5;
          var y = 2;
          var result = 0;
          for (var i = 0; i < 4; i++) {
            if (i == 1) {
              continue;
            }
            result += (x + i) * (y - i);
            x += 1;
          }
          return result;
        }
      ''',
        }
      });
      // i=0: result += (5+0) * (2-0) = 5 * 2 = 10, x becomes 6
      // i=1: continue (skip)
      // i=2: result += (6+2) * (2-2) = 8 * 0 = 0, x becomes 7
      // i=3: result += (7+3) * (2-3) = 10 * (-1) = -10, x becomes 8
      // result = 10 + 0 + (-10) = 0
      expect(runtime.executeLib('package:example/main.dart', 'main'), 0);
    });

    test('continue with type check expression (is)', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
        int main() {
          var sum = 0;
          for (var i = 0; i < 6; i++) {
            if (i is num && i > 2) {
              continue;
            }
            sum += i * 2;
          }
          return sum;
        }
      ''',
        }
      });
      // i=0: sum += 0*2 = 0 (0 is num but not > 2)
      // i=1: sum += 1*2 = 2 (1 is num but not > 2)
      // i=2: sum += 2*2 = 4 (2 is num but not > 2)
      // i=3: continue (3 is num && 3 > 2)
      // i=4: continue (4 is num && 4 > 2)
      // i=5: continue (5 is num && 5 > 2)
      // sum = 0 + 2 + 4 = 6
      expect(runtime.executeLib('package:example/main.dart', 'main'), 6);
    });

    test('continue with null check expression', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
        int main() {
          var sum = 0;
          int? nullableInt = 10;
          for (var i = 0; i < 5; i++) {
            if (nullableInt != null && i == nullableInt ~/ 5) {
              continue;
            }
            sum += i;
          }
          return sum;
        }
      ''',
        }
      });
      // sum = 0 + 1 + 3 + 4 = 8
      expect(runtime.executeLib('package:example/main.dart', 'main'), 8);
    });

    test('continue with string comparison expression', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
        int main() {
          var count = 0;
          var target = "2";
          for (var i = 0; i < 5; i++) {
            if (i.toString() == target) {
              continue;
            }
            count += i;
          }
          return count;
        }
      ''',
        }
      });
      // count = 0 + 1 + 3 + 4 = 8
      expect(runtime.executeLib('package:example/main.dart', 'main'), 8);
    });

    test('continue with method call in condition', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
        int main() {
          var result = 0;
          var list = [1, 3, 5, 7, 9];
          for (var i = 0; i < 5; i++) {
            if (list.contains(i * 2 + 1)) {
              continue;
            }
            result += i;
          }
          return result;
        }
      ''',
        }
      });
      // result = 0 (all iterations continue)
      expect(runtime.executeLib('package:example/main.dart', 'main'), 0);
    });

    test('continue with logical operators in condition', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
        int main() {
          var sum = 0;
          for (var i = 0; i < 8; i++) {
            if ((i > 1 && i < 4) || i == 6) {
              continue;
            }
            sum += i;
          }
          return sum;
        }
      ''',
        }
      });
      // sum = 0 + 1 + 4 + 5 + 7 = 17
      expect(runtime.executeLib('package:example/main.dart', 'main'), 17);
    });

    test('continue with ternary operator in condition', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
        int main() {
          var total = 0;
          var threshold = 3;
          for (var i = 0; i < 6; i++) {
            if ((i % 2 == 0 ? i > threshold : i < threshold)) {
              continue;
            }
            total += i * 10;
          }
          return total;
        }
      ''',
        }
      });
      // total = 0 + 20 + 30 + 50 = 100
      expect(runtime.executeLib('package:example/main.dart', 'main'), 100);
    });

    test('continue with nested function call in condition', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
        int main() {
          var count = 0;
          for (var i = 0; i < 6; i++) {
            if (i.toString().length > 0 && int.parse(i.toString()) % 3 == 0) {
              continue;
            }
            count += i;
          }
          return count;
        }
      ''',
        }
      });

      // count = 1 + 2 + 4 + 5 = 12
      expect(runtime.executeLib('package:example/main.dart', 'main'), 12);
    });

    test('continue with variable assignment in condition', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
        int main() {
          var result = 0;
          var temp = 0;
          for (var i = 0; i < 5; i++) {
            if ((temp = i * 2) > 4) {
              continue;
            }
            result += temp;
          }
          return result;
        }
      ''',
        }
      });

      // result = 0 + 2 + 4 = 6
      expect(runtime.executeLib('package:example/main.dart', 'main'), 6);
    });
  });
}
