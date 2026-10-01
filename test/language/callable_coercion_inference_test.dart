import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:test/test.dart';

const _source = r'''
// @dart=3.0
typedef Exactly<T> = T Function(T);
extension StaticType<T> on T {
  T expectStaticType<R extends Exactly<T>>() => this;
}
class C {
  T call<T>(T value) => value;
}
class Fixed {
  String call(String value) => value;
}
class Parent<T> {
  T call(T value) => value;
}
class Child extends Parent<String> {}
class VirtualParent {
  T call<T>(T value) => throw StateError('parent call');
}
class VirtualChild extends VirtualParent {
  T call<T>(T value) => value;
}
VirtualParent virtualReceiver() => VirtualChild();
X Function(String) infer<X>(X Function(String) callback) => callback;
X Function(String) named<X>({required X Function(String) callback}) => callback;
int creations = 0;
String events = '';
C create() { creations++; events += 'c'; return C(); }
String scalar() { events += 's'; return 's'; }
X Function(String) pair<X>(X Function(String) callback, String value) {
  events += 'f';
  callback(value);
  return callback;
}
bool main() {
  final generic = infer(C());
  generic.expectStaticType<Exactly<String Function(String)>>();
  final fixed = infer(Fixed());
  fixed.expectStaticType<Exactly<String Function(String)>>();
  final inherited = infer(Child());
  inherited.expectStaticType<Exactly<String Function(String)>>();
  final byName = named(callback: C());
  byName.expectStaticType<Exactly<String Function(String)>>();
  X Function(String) Function<X>(X Function(String)) stored = infer;
  final closureCall = stored(C());
  closureCall.expectStaticType<Exactly<String Function(String)>>();
  final virtual = infer(virtualReceiver());
  virtual.expectStaticType<Exactly<String Function(String)>>();
  String Function(String) assignment = C();
  String Function(String) explicit = infer<String>(C());
  final ordered = pair(create(), scalar());
  ordered.expectStaticType<Exactly<String Function(String)>>();
  return generic('a') == 'a' && fixed('b') == 'b' &&
      inherited('c') == 'c' && byName('d') == 'd' &&
      closureCall('e') == 'e' && assignment('f') == 'f' &&
      virtual('j') == 'j' &&
      explicit('g') == 'g' && ordered('h') == 'h' &&
      creations == 1 && events == 'csf';
}
''';

void main() {
  test('generic callable coercion requires a function context', () {
    expect(
      () => Compiler().compile({
        'callable_union': {
          'main.dart': '''
import 'dart:async';
class C {
  T call<T>(T value) => value;
}
FutureOr<X Function(String)> union<X>(FutureOr<X Function(String)> callback) => callback;
void main() { union(C()); }
''',
        },
      }),
      throwsA(isA<CompileError>()),
    );
  });
  test('callable coercion contributes argument inference constraints', () {
    final program = Compiler().compile({
      'callable': {'main.dart': _source},
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:callable/main.dart', 'main'), true);
    }
  });
}
