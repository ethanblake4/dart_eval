import 'package:dart_eval/src/dbc/dbc_gen.dart';
import 'package:test/test.dart';

// Functional tests
void main() {
  group('Function tests', () {
    late DbcGen gen;

    setUp(() {
      gen = DbcGen();
    });

    test('Local variable assignment with ints', () {
      final exec = gen.generate({'dbc_test': {'main.dart': '''
      int main() {
        var i = 3;
        {
          var k = 2;
          k = i;
          return k;
        }
      }
      '''}});

      expect(3, exec.executeNamed(0, 'main'));
    });

    test('Simple function call', () {
      final exec = gen.generate({'dbc_test': {'main.dart': '''
     
      int main() {
        var i = x();
        return i;
      }
      int x() {
        return 7;
      }
     
      '''}});

      expect(7, exec.executeNamed(0, 'main'));
    });
  });
}
