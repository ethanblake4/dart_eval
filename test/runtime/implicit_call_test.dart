import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const source = r'''
int getterReads = 0;
int functionCalls = 0;
class Method {
  int call(int first, {int second = 2}) => first + second;
}
class GenericMethod {
  T call<T>(T value) => value;
}
class Field {
  final int Function(int) call = (value) { functionCalls++; return value + 1; };
}
class Getter {
  int Function(int) get call {
    getterReads++;
    return (value) { functionCalls++; return value + 1; };
  }
}
class SelfGetter {
  dynamic get call { getterReads++; return this; }
}
class Holder {
  Holder(this.item);
  final dynamic item;
}
class Missing {
  int calls = 0;
  dynamic noSuchMethod(Invocation invocation) {
    calls++;
    if (invocation.memberName != #call || !invocation.isMethod) return -20;
    if (invocation.positionalArguments.length != 1 ||
        invocation.positionalArguments[0] != 4 ||
        invocation.namedArguments[#add] != 3) return -21;
    if (invocation.typeArguments.isEmpty) return 7;
    if (invocation.typeArguments.length != 1 || invocation.typeArguments[0] != int) return -22;
    return 8;
  }
}
bool rejects(dynamic value) {
  try { value(4); return false; } on NoSuchMethodError { return true; }
}
int main() {
  dynamic method = Method();
  if (method(4) != 6 || method(4, second: 3) != 7) return -1;
  dynamic generic = GenericMethod();
  if (generic<int>(4) != 4 || generic<String>('value') != 'value') return -2;
  for (dynamic value in [Field(), Getter(), SelfGetter()]) {
    if (!rejects(value)) return -3;
  }
  if (getterReads != 0 || functionCalls != 0) return -4;
  dynamic field = Field();
  dynamic getter = Getter();
  if (field.call(4) != 5 || (field.call)(5) != 6) return -5;
  if (getter.call(4) != 5 || (getter.call)(5) != 6) return -6;
  if (getterReads != 2 || functionCalls != 4) return -7;
  final missing = Missing();
  dynamic callable = missing;
  if (callable(4, add: 3) != 7 || callable<int>(4, add: 3) != 8) return -8;
  if (missing.calls != 2) return -9;
  dynamic holder = Holder(Getter());
  if (holder.item(4) != 5 || getterReads != 3 || functionCalls != 5) return -10;
  try { (holder.item)(4); return -11; } on NoSuchMethodError {}
  final typedHolder = Holder(Getter());
  try { typedHolder.item(4); return -12; } on NoSuchMethodError {}
  if (getterReads != 3 || functionCalls != 5) return -13;
  dynamic methodHolder = Holder(Method());
  dynamic genericHolder = Holder(GenericMethod());
  if (methodHolder.item(4, second: 3) != 7 || genericHolder.item<int>(4) != 4) return -14;
  return 0;
}
''';

void main() {
  test(
    'implicit calls require methods and preserve noSuchMethod invocation',
    () {
      final program = Compiler().compile({
        'implicit_call': {'main.dart': source},
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(
          runtime.executeLib('package:implicit_call/main.dart', 'main'),
          0,
        );
      }
    },
  );
}
