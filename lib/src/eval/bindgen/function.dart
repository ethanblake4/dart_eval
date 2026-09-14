import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:dart_eval/src/eval/bindgen/context.dart';
import 'package:dart_eval/src/eval/bindgen/parameters.dart';
import 'package:dart_eval/src/eval/bindgen/type.dart';

String $function(BindgenContext ctx, ExecutableElement element) =>
    '${_function(ctx, element)}\n${_function(ctx, element, registers: true)}';

String _function(
  BindgenContext ctx,
  ExecutableElement element, {
  bool registers = false,
}) {
  final returnsValue =
      element.returnType is! VoidType && !element.returnType.isDartCoreNull;
  return '''
        ${registers ? '' : '@override'}
        ${registers ? 'static ' : ''}\$Value? ${registers ? 'callRegisters(Runtime runtime, Object? r, Object? s, Object? c)' : 'call(Runtime runtime, \$Value? target, List<\$Value?> args)'} {
          ${registers ? registerArgumentPreamble(element.formalParameters.length) : ''}
          ${returnsValue ? 'final result = ' : ''}${element.displayName}(${argumentAccessors(ctx, element.formalParameters, registers: registers).join(', ')});
          return ${wrapVar(ctx, element.returnType, 'result')};
        }''';
}
