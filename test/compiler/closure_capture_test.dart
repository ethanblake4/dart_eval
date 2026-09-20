import 'package:dart_eval/dart_eval_bridge.dart' show EvalCallable;
import 'package:dart_eval/stdlib/core.dart' show $int;
import 'package:dart_eval/src/eval/runtime/typed/typed_interop.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:dart_eval/src/eval/compiler/helpers/captures.dart';
import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

class _Nodes extends RecursiveAstVisitor<void> {
  final variables = <VariableDeclaration>[];
  final functions = <FunctionExpression>[];
  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    variables.add(node);
    super.visitVariableDeclaration(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    functions.add(node);
    super.visitFunctionExpression(node);
  }
}

void main() {
  test(
    'capture analysis resolves shadowed bindings and omits unused locals',
    () {
      final unit = parseString(
        content: '''void main() {
      var value = 1; var unused = 2;
      var outer = () => value;
      { var value = 3; var inner = () => value; }
      var shadowed = (int value) => value;
    }''',
      ).unit;
      final nodes = _Nodes();
      unit.accept(nodes);
      final analysis = capturesFor(unit);
      expect(
        analysis.captured.whereType<VariableDeclaration>().toSet(),
        nodes.variables.where((v) => v.name.lexeme == 'value').toSet(),
      );
      expect(analysis.free[nodes.functions[1]], {'value'});
      expect(analysis.free[nodes.functions[2]], {'value'});
      expect(analysis.free[nodes.functions[3]], isNull);
    },
  );
  test(
    'intermediate closures forward free bindings used only by descendants',
    () {
      final unit = parseString(
        content: '''void main(int value) {
      var outer = () => () => value;
    }''',
      ).unit;
      final nodes = _Nodes();
      unit.accept(nodes);
      final analysis = capturesFor(unit);
      expect(analysis.free[nodes.functions[1]], {'value'});
      expect(analysis.free[nodes.functions[2]], {'value'});
      expect(analysis.captured.single, isA<RegularFormalParameter>());
    },
  );
  test('property names do not capture unrelated locals', () {
    final unit = parseString(
      content: '''void main(dynamic object) {
      var length = 3; var fn = () => object.length;
    }''',
    ).unit;
    final nodes = _Nodes();
    unit.accept(nodes);
    expect(capturesFor(unit).free[nodes.functions.last], {'object'});
  });

  test('a closure calling a global function does not retain its receiver', () {
    final runtime = Runtime.ofProgram(
      Compiler().compile({
        'capture': {
          'main.dart': '''int global() => 7;
        class Parent { int value = 9; }
        class Child extends Parent { dynamic make() => () => global(); }
        dynamic main() => Child().make();
      ''',
        },
      }),
    );
    final closure =
        runtime.executeLib('package:capture/main.dart', 'main') as TypedClosure;
    expect(closure.captures, isEmpty);
  });

  test(
    'exported overridden method tearoffs bind defaults through host callbacks',
    () {
      final program = Compiler().compile({
        'capture': {
          'main.dart': '''class Parent {
          int combine({int z = 1, int a = 2}) => 1000;
        }
        class Child extends Parent {
          int combine({int a = 4, int z = 3}) => z * 10 + a;
        }
        dynamic main() { Parent instance = Child(); return instance.combine; }
      ''',
        },
      });
      for (final candidate in [program, Program.read(program.write().buffer)]) {
        final runtime = Runtime.ofProgram(candidate);
        final callable =
            runtime.executeLib('package:capture/main.dart', 'main')
                as EvalCallable;
        expect((callable.call(runtime, null, null, null, 0) as $int).$value, 34);
        expect((TypedInterop.call(runtime, callable, 0, null, null) as $int).$value, 34);
      }
    },
  );

  final cases = <String, (String, Object?)>{
    'conditional closure creation shares the binding': (
      '''int main() {
      var value = 1; dynamic read;
      if (value == 1) { read = () => value; }
      value = 9; return read();
    }''',
      9,
    ),
    'sibling closures share mutations': (
      '''int main() {
      var value = 1;
      var increment = () { value = value + 1; };
      var read = () => value;
      increment(); increment(); return read();
    }''',
      3,
    ),
    'nested closures forward a shared cell': (
      '''int main() {
      var value = 2; var factory = () => () => value;
      var read = factory(); value = 8; return read();
    }''',
      8,
    ),
    'for iterations retain separate captured bindings': (
      '''int main() {
      dynamic first; dynamic second;
      for (var i = 0; i < 2; i++) {
        if (i == 0) { first = () => i; } else { second = () => i; }
      }
      return first() * 10 + second();
    }''',
      1,
    ),
    'for each iterations retain separate captured bindings': (
      '''int main() {
      dynamic first; dynamic second;
      for (var value in [4, 7]) {
        if (value == 4) { first = () => value; } else { second = () => value; }
      }
      return first() * 10 + second();
    }''',
      47,
    ),
    'implicit receiver fields are captured': (
      '''class Counter {
      int value = 3;
      dynamic make() => () { value = value + 2; return value; };
    }
    int main() { var counter = Counter(); var next = counter.make(); return next(); }
    ''',
      5,
    ),
    'explicit receiver references are captured': (
      '''class Counter {
      int value = 3;
      dynamic make() => () => this.value;
    }
    int main() { var counter = Counter(); var read = counter.make(); return read(); }
    ''',
      3,
    ),
    'closure arguments snapshot before later mutations': (
      '''int main() {
      var value = 1; var combine = (int first, int second) => first * 10 + second;
      return combine(value, value = 2);
    }''',
      12,
    ),
    'double closure defaults preserve their declared representation': (
      '''double main() {
      var add = ([double value = 1]) => value + 0.5;
      return add();
    }''',
      1.5,
    ),
    'callee is read before an argument reassigns the same local': (
      '''int main() {
      var function = (dynamic value) => 10;
      return function(function = (dynamic value) => 20);
    }''',
      10,
    ),
    'callee is read before an argument mutates its captured cell': (
      '''int main() {
      var function = (int value) => 10 + value;
      var change = () { function = (int value) => 20 + value; return 1; };
      return function(change());
    }''',
      11,
    ),
    'constructor initializer closures capture constructor parameters': (
      '''class Holder {
      final dynamic read;
      Holder(int value) : read = (() => value) { value = 9; }
    }
    int main() { var holder = Holder(3); var read = holder.read; return read(); }
    ''',
      9,
    ),
    'inherited fields capture the receiver through nested closures': (
      '''class Parent { int value = 6; }
      class Child extends Parent { dynamic make() => () => () => value; }
      int main() { var factory = Child().make(); var read = factory(); return read(); }
    ''',
      6,
    ),
    'top-level tearoffs preserve source-order named parameter locations': (
      '''int combine({int z = 1, int a = 2}) => z * 10 + a;
      int main() { var fn = combine; return fn(z: 3, a: 4); }
    ''',
      34,
    ),
    'method tearoffs preserve mixed named parameter locations': (
      '''class Counter {
        int combine({int z = 1, bool a = true}) { if (a) return z; return 0; }
      }
      int main() { var counter = Counter(); var fn = counter.combine; return fn(z: 7, a: false); }
    ''',
      0,
    ),
    'super method closures retain their receiver': (
      '''class Parent { int value() => 4; }
      class Child extends Parent { dynamic make() => () => super.value(); }
      int main() { var fn = Child().make(); return fn(); }
    ''',
      4,
    ),
    'bound method tearoffs select runtime overrides and bind their named defaults':
        (
          '''class Parent {
        int combine({int z = 1, int a = 2}) => 1000;
      }
      class Child extends Parent {
        int combine({int a = 4, int z = 3}) => z * 10 + a;
      }
      int main() {
        Parent instance = Child(); var fn = instance.combine;
        return fn() + fn(z: 7) + fn(a: 8) + fn(a: 2, z: 9);
      }
    ''',
          238,
        ),
    'inherited bound method tearoffs bind optional positional defaults': (
      '''class Parent {
        int combine(int first, [int second = 5]) => first * 10 + second;
      }
      class Child extends Parent {}
      int main() { var instance = Child(); var fn = instance.combine; return fn(2) + fn(2, 8); }
    ''',
      53,
    ),
    'local recursive functions capture their own cell': (
      '''int main() {
      int sum(int n) { if (n == 0) return 0; return n + sum(n - 1); }
      return sum(4);
    }''',
      10,
    ),
  };
  for (final entry in cases.entries) {
    test(entry.key, () {
      final runtime = Runtime.ofProgram(
        Compiler().compile({
          'capture': {'main.dart': entry.value.$1},
        }),
      );
      expect(
        runtime.executeLib('package:capture/main.dart', 'main'),
        entry.value.$2,
      );
    });
  }
}
