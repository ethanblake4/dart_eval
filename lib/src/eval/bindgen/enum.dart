import 'package:analyzer/dart/element/element2.dart';
import 'package:dart_eval/src/eval/bindgen/context.dart';

String $enumValues(BindgenContext ctx, EnumElement2 element) {
  return '''
  static final _\$values = {
    ${element.constants2.map((e) => "'${e.name3}': \$${element.name3}.wrap(${element.name3}.${e.name3})").join(', ')}
  };
  ''';
}
