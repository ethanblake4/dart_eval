import 'package:analyzer/dart/element/element.dart';
import 'package:dart_eval/src/eval/bindgen/context.dart';

String $enumValues(BindgenContext ctx, EnumElement element) {
  return '''
  static final _\$values = {
    ${element.constants.map((e) => "'${e.name}': \$${element.name}.wrap(${element.name}.${e.name})").join(', ')}
  };
  ''';
}
