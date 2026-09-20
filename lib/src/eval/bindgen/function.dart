import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:dart_eval/src/eval/bindgen/context.dart';
import 'package:dart_eval/src/eval/bindgen/parameters.dart';
import 'package:dart_eval/src/eval/bindgen/permission.dart';
import 'package:dart_eval/src/eval/bindgen/statics.dart';
import 'package:dart_eval/src/eval/bindgen/type.dart';

String $function(BindgenContext ctx, ExecutableElement element) =>
    _function(ctx, element);

String _function(BindgenContext ctx, ExecutableElement element) {
  final member = ctx.libraryConfig?.functions[element.name];
  final returnsValue =
      element.returnType is! VoidType && !element.returnType.isDartCoreNull;
  final String body;
  if (member?.hook != null) {
    final prefix = ctx.hooksPrefix();
    final argsExpr = registerArgsList(element.formalParameters.length);
    body =
        'return ${prefix != null ? '$prefix.' : ''}${member!.hook}'
        '(runtime, null, $argsExpr);';
  } else if (member?.expr != null) {
    body = 'return ${member!.expr};';
  } else {
    body =
        '''
          ${registerArgumentPreamble(element.formalParameters)}
          ${assertConfigPermissions(ctx, member, element.formalParameters.map((p) => p.name ?? '').toList(), registers: true, paramCount: element.formalParameters.length)}
          ${returnsValue ? 'final result = ' : ''}${element.displayName}(${argumentAccessors(ctx, element.formalParameters, registers: true, member: member).join(', ')});
          return ${wrapVar(ctx, element.returnType, 'result', unionTypeNames: member?.returns?.union)};''';
  }
  return '''
        static \$Value? callRegisters(Runtime runtime, Object? r, Object? s, Object? c) {
          $body
        }''';
}
