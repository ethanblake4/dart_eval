import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:dart_eval/src/eval/bindgen/context.dart';
import 'package:dart_eval/src/eval/bindgen/parameters.dart';
import 'package:dart_eval/src/eval/bindgen/permission.dart';
import 'package:dart_eval/src/eval/bindgen/type.dart';

String $methods(BindgenContext ctx, ClassElement element) {
  return element.methods
      .where((method) => !method.isPrivate && !method.isStatic)
      .map((e) {
    final returnsValue =
        e.returnType is! VoidType && !e.returnType.isDartCoreNull;
    return '''
        static const \$Function __${e.displayName} = \$Function(_${e.displayName});
        static \$Value? _${e.displayName}(Runtime runtime, \$Value? target, List<\$Value?> args) {
          ${assertMethodPermissions(e)}
          final self = target as \$${element.name};
          ${returnsValue ? 'final result = ' : ''}self.\$value.${e.displayName}(${argumentAccessors(ctx, e.parameters)});
          return ${wrapVar(ctx, e.returnType, 'result')};
        }''';
  }).join('\n');
}
