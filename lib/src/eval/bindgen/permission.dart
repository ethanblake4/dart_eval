import 'package:analyzer/dart/element/element.dart';
import 'package:dart_eval/src/eval/bindgen/config.dart';
import 'package:dart_eval/src/eval/bindgen/context.dart';
import 'parameters.dart';

/// Emit `runtime.assertPermission(...)` for YAML `permissions:` entries.
/// [paramNames] is the declaration-order parameter name list used to resolve
/// `paramData` references.
String assertConfigPermissions(
  BindgenContext ctx,
  BindgenMemberConfig? member,
  List<String> paramNames, {
  bool callable = false,
  int paramCount = 0,
}) {
  if (member == null || member.permissions.isEmpty) return '';
  String output = '';
  for (final permission in member.permissions) {
    String data = '';
    if (permission.constData != null) {
      data = ", '${permission.constData}'";
    } else if (permission.paramData != null) {
      final index = paramNames.indexOf(permission.paramData!);
      if (index != -1) {
        final count = paramCount == 0 ? paramNames.length : paramCount;
        final source = callable
            ? callSlotSource(index)
            : registerArgumentSource(index, count);
        data = ', $source?.\$value';
      }
    }
    output += "runtime.assertPermission('${permission.name}'$data);";
  }
  return output;
}

String assertMethodPermissions(
  MethodElement element, {
  bool callable = false,
}) {
  final metadata = element.metadata;

  final permissions = metadata.annotations.where(
    (e) => e.element?.displayName == 'AssertPermission',
  );

  String output = '';
  for (final permission in permissions) {
    final perm = permission.computeConstantValue();
    if (perm == null) {
      print(
        'Warning: skipped permission assertion as the annotation is not a constant value',
      );
      continue;
    }
    final name = perm.getField('name')!.toStringValue();
    final constData = perm.getField('constData')?.toStringValue();
    final paramData = perm.getField('paramData')?.toStringValue();

    String data = '';

    if (constData != null) {
      data = ", '$constData'";
    } else if (paramData != null) {
      final params = element.formalParameters;
      for (var i = 0; i < params.length; i++) {
        final param = params[i];
        if (param.name == paramData) {
          final nullCheck = param.isRequired ? '!' : '?';
          final source = callable
              ? callSlotSource(i)
              : registerArgumentSource(i, params.length);
          final value = '$source$nullCheck.\$value';
          data = param.hasDefaultValue
              ? ', ($source == null ? ${param.defaultValueCode} : $value)'
              : ', $value';
          break;
        }
      }
    }

    output += '''runtime.assertPermission('$name'$data);''';
  }

  return output;
}
