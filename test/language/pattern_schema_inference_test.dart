import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const source = r'''
typedef Exactly<T> = T Function(T);
extension StaticType<T> on T {
  T expectStaticType<R extends Exactly<T>>() => this;
}
T contextType<T>(Object? result) => result as T;
bool main() {
  var [x] = [1]..expectStaticType<Exactly<List<int>>>();
  var [_] = [2]..expectStaticType<Exactly<List<int>>>();
  var [_ as Object] = [3]..expectStaticType<Exactly<List<int>>>();
  var [] = [4]..expectStaticType<Exactly<List<int>>>()..clear();
  var [...] = [5]..expectStaticType<Exactly<List<int>>>();
  var [...Object rest] = [6]..expectStaticType<Exactly<List<int>>>();
  var <dynamic>[d] = [7]..expectStaticType<Exactly<List<dynamic>>>();
  var [[nested]] = [[8]];
  var (int typed, inferred) = (9, 'ten');
  nested.expectStaticType<Exactly<int>>();
  inferred.expectStaticType<Exactly<String>>();
  var [[overlap], <int>[fixed]] = [[16], [17]]
    ..expectStaticType<Exactly<List<List<int>>>>();
  var [(unknownInt, String knownString), (int knownInt, unknownString)] =
      [(18, 'nineteen'), (20, 'twenty-one')]
        ..expectStaticType<Exactly<List<(int, String)>>>();
  var (first, y: String second) = (11, y: 'twelve')
    ..expectStaticType<Exactly<(int, {String y})>>();
  var {1: value} = {1: 'thirteen'}
    ..expectStaticType<Exactly<Map<int, String>>>();
  var <dynamic, dynamic>{1: explicit} = {1: 'fourteen'}
    ..expectStaticType<Exactly<Map<dynamic, dynamic>>>();
  var [...Iterable<int> ints] = contextType(<int>[15])
    ..expectStaticType<Exactly<List<int>>>();
  return x == 1 && (rest as List).length == 1 && (rest as List).first == 6 &&
      d == 7 && nested == 8 &&
      typed == 9 && inferred == 'ten' && first == 11 && second == 'twelve' &&
      value == 'thirteen' && explicit == 'fourteen' && ints.first == 15 &&
      overlap == 16 && fixed == 17 && unknownInt == 18 &&
      knownString == 'nineteen' && knownInt == 20 && unknownString == 'twenty-one';
}
''';

void main() {
  test(
    'pattern schema holes infer values while explicit dynamic constrains them',
    () {
      final program = Compiler().compile({
        'schema': {'main.dart': source},
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(runtime.executeLib('package:schema/main.dart', 'main'), true);
      }
    },
  );
}
