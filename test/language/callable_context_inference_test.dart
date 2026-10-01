import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _source = r'''
// @dart=3.0
Type observed = Object;
class Identity {
  T call<T>(T value) { observed = T; return value; }
}
X Function(String) infer<X>(X Function(String) callback) => callback;
String report(String label, dynamic Function(String) callback) {
  observed = Object;
  final result = callback('s');
  if (observed != String || result != 's') {
    throw StateError('$label instantiated with $observed instead of String');
  }
  return '$label:$observed:${callback.runtimeType}:$result';
}
String main() {
  final unknown = infer(Identity());
  dynamic Function(String) explicitDynamic = Identity();
  Object Function(String) explicitObject = Identity();
  String Function(String) explicitString = Identity();
  final inferredDynamic = infer<dynamic>(Identity());
  final inferredObject = infer<Object>(Identity());
  return [
    report('unknown', unknown),
    report('dynamic', explicitDynamic),
    report('Object', explicitObject),
    report('String', explicitString),
    report('explicit-dynamic-argument', inferredDynamic),
    report('explicit-Object-argument', inferredObject),
  ].join('\n');
}
''';

void main() {
  test('callable coercion preserves explicit return contexts', () {
    final program = Compiler().compile({
      'contexts': {'main.dart': _source},
    });
    final fresh = Runtime.ofProgram(
      program,
    ).executeLib('package:contexts/main.dart', 'main');
    final restored = Runtime(
      program.write().buffer,
    ).executeLib('package:contexts/main.dart', 'main');
    expect(restored, fresh);
    // Each report enforces the verified native call.T == String oracle.
    expect((fresh as String).split('\n'), hasLength(6));
  });
}
