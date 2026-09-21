import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

void main() {
  for (final code in [
    'var x = new Future.value(1);',
    'var x = const Future.value(1);',
    'var x = new foo.Foo();',
    'var x = new foo.Foo.bar<int>();',
    'var x = Future.value(1);',
    'var x = foo.Foo.bar();',
    'var x = Future<int>.value(1);',
  ]) {
    final r = parseString(content: code);
    final d = r.unit.declarations.first as TopLevelVariableDeclaration;
    final e = d.variables.variables.first.initializer!;
    print('--- $code -> ${e.runtimeType}');
    if (e is InstanceCreationExpression) {
      final cn = e.constructorName;
      final t = cn.type;
      print('    type.name=${t.name.lexeme} prefix=${t.importPrefix?.name.lexeme} ctorName=${cn.name?.name}');
    } else if (e is MethodInvocation) {
      print('    target=${e.target} (${e.target.runtimeType}) method=${e.methodName.name}');
      if (e.target is PrefixedIdentifier) {
        final p = e.target as PrefixedIdentifier;
        print('    prefixedId: ${p.prefix.name}.${p.identifier.name}');
      }
    }
  }
}
