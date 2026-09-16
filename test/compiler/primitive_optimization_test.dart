import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

List<String> opNames(TypedProgram program) {
  final names = <String>[];
  for (var pc = 0; pc < program.code.length;) {
    final instruction = TypedOp.instructions[program.code[pc]];
    names.add(instruction.name);
    pc += instruction.length;
  }
  return names;
}

Program compile(String source) => Compiler().compile({
  'test': {'main.dart': source},
});

void checkBoth(Program program, Object? expected) {
  for (final runtime in [
    Runtime.ofProgram(program),
    Runtime(program.write().buffer),
  ]) {
    expect(runtime.executeLib('package:test/main.dart', 'main'), expected);
  }
}

void main() {
  test(
    'implicit field prefix and compound assignment return stored representation',
    () {
      checkBoth(
        compile('''
      class Counter {
        int value=0;
        int next()=>++value;
        int add()=>value+=3;
      }
      Function callback(){var value=0; return (){value++;return value;};}
      int global=0;
      int main(){final c=Counter(); final cb=callback();
        return c.next()*1000+c.add()*100+(++global)*10+(cb() as int);}
    '''),
        1411,
      );
    },
  );
  test(
    'known integer bitwise and shift operations stay in integer registers',
    () {
      for (final (operator, expected) in [
        ('&', -17 & 3),
        ('|', -17 | 3),
        ('^', -17 ^ 3),
        ('<<', -17 << 3),
        ('>>', -17 >> 3),
        ('>>>', -17 >>> 3),
      ]) {
        final program = compile(
          'int main() {int a=-17; int b=3; return a $operator b;}',
        );
        checkBoth(program, expected);
        final names = opNames(program.typedProgram);
        expect(names, isNot(contains('callVirtual')), reason: operator);
        expect(names.where((name) => name.startsWith('rBox')), isEmpty);
      }
    },
  );

  test('negative shift still throws when its result is discarded', () {
    final program = compile(
      'int main() { var amount=-1; 2 << amount; return 0; }',
    );
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        () => runtime.executeLib('package:test/main.dart', 'main'),
        throwsA(anything),
      );
    }
  });

  test(
    'increment preserves postfix value and selects existing increment opcode',
    () {
      final program = compile(
        'int main() {var x=7; final before=x++; return before*10+x;}',
      );
      checkBoth(program, 78);
      expect(
        opNames(program.typedProgram).any((name) => name.endsWith('Increment')),
        isTrue,
      );
    },
  );

  test(
    'native list length round trip is removed without caching a mutable length',
    () {
      final program = compile(
        'int main() {final xs=<int>[]; final a=xs.length; xs.add(9); return a*10+xs.length;}',
      );
      checkBoth(program, 1);
      final names = opNames(program.typedProgram);
      expect(names.where((name) => name == 'aListLengthR').length, 2);
      // The element 9 escapes to add and must still be boxed. Lengths do not.
      expect(
        names.where((name) => name == 'rBoxA' || name == 'rBoxB').length,
        1,
      );
      expect(names, isNot(contains('aFromR')));
    },
  );

  test('dynamic user operators and getters retain their effects', () {
    checkBoth(
      compile('''
      class Counter {int calls=0; int get length {calls++; return calls;}
        int operator &(int value) => value+100;}
      int main() {dynamic x=Counter(); final a=x.length; final b=x.length;
        return (x & 3)+a*10+b;}
    '''),
      115,
    );
  });

  test('left operand value survives right operand mutation and conversion', () {
    checkBoth(
      compile('''
      class Rate {int apply(int total)=>total-total~/10;}
      int main(){var x=7; final before=x+(x=2); return before*100+Rate().apply(90);}
    '''),
      981,
    );
  });

  test('shopping basket alternates dynamic policies after serialization', () {
    checkBoth(
      compile('''
      class Line {final int price; final int quantity; Line(this.price,this.quantity);
        int total()=>price*quantity;}
      class Rate {int apply(int total)=>total-total~/10;}
      class Voucher {int apply(int total)=>total>1000?total-100:total;}
      int main(){final lines=<Line>[];for(var j=0;j<16;j++){lines.add(Line(100+j*17,1+j%3));}
        final first=Rate();final second=Voucher();var result=0;
        for(var i=0;i<4;i++){var subtotal=0;for(var j=0;j<lines.length;j++){subtotal+=lines[j].total();}
          dynamic rule=first;if(i%2!=0){rule=second;}result+=rule.apply(subtotal) as int;}
        return result;}
    '''),
      26762,
    );
  });
}
