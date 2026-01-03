import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:dart_eval/src/eval/bindgen/context.dart';
import 'package:dart_eval/src/eval/bindgen/parameters.dart';
import 'package:dart_eval/src/eval/bindgen/type.dart';

String $function(BindgenContext ctx, ExecutableElement element) {
  final returnsValue =
      element.returnType is! VoidType && !element.returnType.isDartCoreNull;
  return '''
        @override
        \$Value? call(Runtime runtime, \$Value? target, List<\$Value?> args) {
          ${returnsValue ? 'final result = ' : ''}${element.displayName}(${argumentAccessors(ctx, element.formalParameters).join(', ')});
          return ${wrapVar(ctx, element.returnType, 'result')};
        }''';
}
