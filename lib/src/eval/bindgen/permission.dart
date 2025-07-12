import 'package:analyzer/dart/element/element2.dart';

String assertMethodPermissions(MethodElement2 element) {
  final metadata = element.metadata2;

  final permissions = metadata.annotations
      .where((e) => e.element2?.displayName == 'AssertPermission');

  String output = '';
  for (final permission in permissions) {
    final perm = permission.computeConstantValue();
    if (perm == null) {
      print(
          'Warning: skipped permission assertion as the annotation is not a constant value');
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
        if (param.name3 == paramData) {
          final nullCheck = param.isRequired ? '!' : '?';
          final defaultValue =
              param.hasDefaultValue ? ' ?? ${param.defaultValueCode}' : '';
          data = ', args[$i]$nullCheck.\$value$defaultValue';
          break;
        }
      }
    }

    output += '''runtime.assertPermission('$name'$data);''';
  }

  return output;
}
