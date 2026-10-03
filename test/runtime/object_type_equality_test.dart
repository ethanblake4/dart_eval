import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart'
    show TypedRuntimeInterop;
import 'package:test/test.dart';

const source = '''
class Marker {}
int main() {
  final marker = Marker();
  return marker == marker ? 0 : 1;
}
''';

Runtime createRuntime(String package, {bool serialized = false}) {
  final program = Compiler().compile({
    package: {'main.dart': source},
  });
  final runtime = serialized
      ? Runtime(program.write().buffer)
      : Runtime.ofProgram(program);
  expect(runtime.executeLib('package:$package/main.dart', 'main'), 0);
  return runtime;
}

bool compare(
  Runtime runtime,
  $TypeImpl left,
  $TypeImpl right,
  String operator,
) {
  final callable =
      $Object(left).$getProperty(runtime, operator) as EvalCallable;
  return (callable.call(runtime, null, right, null, 1) as $bool).$value;
}

void main() {
  test('imported nominal descriptors retain declaration-site variance', () {
    final producer = Compiler().compile({
      'variance_origin': {
        'main.dart': '''
          class Consumer<in T> {}
          class Cell<inout T> {}
          Object consumer(bool narrow) => narrow ? Consumer<int>() : Consumer<num>();
          Object cell(bool narrow) => narrow ? Cell<int>() : Cell<num>();
        ''',
      },
    });
    for (final serialized in [false, true]) {
      final origin = serialized
          ? Runtime(producer.write().buffer)
          : Runtime.ofProgram(producer);
      final target = createRuntime('variance_target', serialized: serialized);
      const library = 'package:variance_origin/main.dart';
      for (final (method, accepted) in [('consumer', true), ('cell', false)]) {
        final narrow = origin.executeLib(
          library,
          method,
          arguments: {'narrow': true},
        );
        final expected = (narrow as $Value).$getRuntimeType(target);
        final value = origin.executeLib(
          library,
          method,
          arguments: {'narrow': false},
        );
        expect(target.isTypedValueType(value, expected), accepted);
      }
    }
  });

  test('Object equality preserves defining and imported Type descriptors', () {
    final first = createRuntime('first');
    final equivalent = createRuntime('first', serialized: true);
    final different = createRuntime('second');
    final firstId = first.lookupType(
      const BridgeTypeSpec('package:first/main.dart', 'Marker'),
    );
    final equivalentId = equivalent.lookupType(
      const BridgeTypeSpec('package:first/main.dart', 'Marker'),
    );
    final differentId = different.lookupType(
      const BridgeTypeSpec('package:second/main.dart', 'Marker'),
    );
    final firstType = $TypeImpl(firstId, first);
    final equivalentType = $TypeImpl(equivalentId, equivalent);
    final differentType = $TypeImpl(differentId, different);
    final importedType = $TypeImpl(
      first.importRuntimeType(different, differentId),
      first,
    );
    expect(compare(first, firstType, equivalentType, '=='), isTrue);
    expect(compare(first, firstType, equivalentType, '!='), isFalse);
    expect(compare(first, firstType, differentType, '=='), isFalse);
    expect(compare(first, firstType, differentType, '!='), isTrue);
    expect(compare(first, importedType, differentType, '=='), isTrue);
    expect(compare(first, importedType, differentType, '!='), isFalse);
  });
}
