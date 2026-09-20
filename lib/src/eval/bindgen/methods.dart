import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:dart_eval/src/eval/bindgen/bridge_declaration.dart';
import 'package:dart_eval/src/eval/bindgen/context.dart';
import 'package:dart_eval/src/eval/bindgen/operator.dart';
import 'package:dart_eval/src/eval/bindgen/parameters.dart';
import 'package:dart_eval/src/eval/bindgen/permission.dart';
import 'package:dart_eval/src/eval/bindgen/type.dart';

String $methods(BindgenContext ctx, InterfaceElement element) {
  final methods = [
    if (ctx.implicitSupers)
      for (var s in element.allSupertypes.reversed) ...s.methods,
    ...element.methods,
  ];

  final emitted = dedupeMethods(methods)
      .where((method) => !method.isPrivate && !method.isStatic)
      .where(
        (m) => ctx.memberIncluded(
          m.name!,
          'method',
          isObjectMember: objectMethodNames.contains(m.name),
        ),
      )
      .map((e) {
        final member = ctx.memberConfig(e.name!, 'method');
        final name = member?.rename ?? e.name!;
        final returnsValue =
            e.returnType is! VoidType && !e.returnType.isDartCoreNull;
        final op = operatorForArity(name, e.formalParameters.length);
        // The Dart call must use the real SDK member name even when the
        // bound name is renamed.
        final callOp = operatorForArity(
          e.displayName,
          e.formalParameters.length,
        );
        final hook = member?.hook;
        final expr = member?.expr;
        final String body;
        if (hook != null) {
          final prefix = ctx.hooksPrefix();
          body =
              'return ${prefix != null ? '$prefix.' : ''}$hook'
              '(runtime, target, r, s, c);';
        } else if (expr != null) {
          body =
              'final self = target! as \$${element.name};\n'
              'return $expr;';
        } else {
          body =
              'final self = target! as \$${element.name};\n'
              '${returnsValue ? 'final result = ' : ''}'
              '${callOp.format('self.\$value', argumentAccessors(ctx, e.formalParameters, callable: true, member: member))};\n'
              'return ${wrapVar(ctx, e.returnType, 'result', unionTypeNames: member?.returns?.union)};';
        }
        return '''
        static const \$Function __${op.name} = \$Function(_${op.name});
        static \$Value? _${op.name}(Runtime runtime, \$Value? target, Object? r, Object? s, Object? c) {
          ${assertMethodPermissions(e, callable: true)}
          ${assertConfigPermissions(ctx, member, e.formalParameters.map((p) => p.name ?? '').toList(), callable: true)}
          $body
        }''';
      })
      .join('\n');

  return emitted + _syntheticMethodBodies(ctx, element);
}

/// Emit `__x`/`_x` function bodies for `synthetic:` methods.
String _syntheticMethodBodies(BindgenContext ctx, InterfaceElement element) {
  final synthetic = ctx.classConfig?.synthetic ?? const [];
  return synthetic
      .where((s) => s.kind == 'method' && !s.isStatic)
      .map((s) {
        final op = operatorForArity(s.name, s.params.length);
        final prefix = ctx.hooksPrefix();
        final String body;
        if (s.hook != null) {
          body =
              'return ${prefix != null ? '$prefix.' : ''}${s.hook}'
              '(runtime, target, r, s, c);';
        } else {
          body =
              'final self = target! as \$${element.name};\n'
              'return ${s.expr ?? 'null'};';
        }
        return '''
        static const \$Function __${op.name} = \$Function(_${op.name});
        static \$Value? _${op.name}(Runtime runtime, \$Value? target, Object? r, Object? s, Object? c) {
          $body
        }''';
      })
      .join('\n');
}
