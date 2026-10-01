import 'package:analyzer/dart/element/element.dart';
import 'package:dart_eval/src/eval/bindgen/config.dart';
import 'package:dart_eval/src/eval/bindgen/context.dart';
import 'package:dart_eval/src/eval/bindgen/errors.dart';
import 'parameters.dart';

/// Emit `runtime.assertPermission(...)` for YAML `permissions:` entries.
/// [parameters] is the declaration-order parameter list used to resolve
/// `paramData` references.
String assertConfigPermissions(
  BindgenContext ctx,
  BindgenMemberConfig? member,
  List<FormalParameterElement> parameters, {
  bool callable = false,
  int paramCount = 0,
}) {
  if (member == null || member.permissions.isEmpty) return '';
  String output = '';
  for (final permission in member.permissions) {
    if (permission.name.isEmpty) {
      throw const BindingGenerationError('Permission name cannot be empty');
    }
    String data = '';
    if (permission.constData != null) {
      data = ", '${_dartLiteral(permission.constData!)}'";
    } else if (permission.paramData != null) {
      final path = permission.paramData!.split('.');
      if (path.isEmpty ||
          path.any(
            (segment) => !RegExp(r'^[A-Za-z_][A-Za-z_0-9]*$').hasMatch(segment),
          )) {
        throw BindingGenerationError(
          'Invalid permission paramData ${permission.paramData}',
        );
      }
      final index = parameters.indexWhere((p) => p.name == path.first);
      if (index == -1) {
        throw BindingGenerationError(
          'Permission paramData ${permission.paramData} does not name a parameter',
        );
      }
      final count = paramCount == 0 ? parameters.length : paramCount;
      final source = callable
          ? callRawSlotSource(index, optional: parameters[index].isOptional)
          : registerRawArgumentSource(
              index,
              count,
              optional: parameters[index].isOptional,
            );
      var value = 'Runtime.permissionData($source)';
      if (path.length > 1) {
        final type = parameters[index].type;
        final typeName = type.element?.name;
        if (typeName == null) {
          throw BindingGenerationError(
            'Permission paramData ${permission.paramData} needs a named parameter type',
          );
        }
        final library = type.element?.library?.uri.toString();
        if (library != null && library != ctx.uri && library != 'dart:core') {
          ctx.imports.add(library);
        }
        value =
            '($value as $typeName?)${path.skip(1).map((segment) => '?.$segment').join()}';
      }
      data = ', $value';
    }
    output +=
        "runtime.assertPermission('${_dartLiteral(permission.name)}'$data);";
  }
  return output;
}

String _dartLiteral(String value) => value
    .replaceAll(r'\', r'\\')
    .replaceAll("'", r"\'")
    .replaceAll(r'$', r'\$');

String assertMethodPermissions(MethodElement element, {bool callable = false}) {
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
