import 'dart:io';

import 'package:dart_eval/src/eval/bindgen/bindgen.dart';
import 'package:dart_eval/src/eval/bindgen/config.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test(
    'bindgen preserves analyzed and configured nullable upper bounds',
    () async {
      final directory = Directory(
        'test',
      ).absolute.createTempSync('nullable_bound_');
      addTearDown(() => directory.deleteSync(recursive: true));
      final source = File(p.join(directory.path, 'native.dart'))
        ..writeAsStringSync('''
class Nullable<T extends Object?> {
  Nullable();
  T choose<T extends Object?>(T value) => value;
}
class Strict<T extends Object> { Strict(); }
class Override<T extends Object> { Override(); }
mixin Opaque<T extends Object?> {}
T identity<T extends num?>(T value) => value;
''');
      final config = BindgenConfig.parse('''
version: 1
libraries:
  - uri: ${source.uri}
    classes:
      Nullable:
        include: true
      Strict:
        include: true
      Override:
        include: true
        generics:
          T: Object?
      Opaque:
        include: true
        opaque: true
    functions:
      identity:
        include: true
''')..resolveDefaults();
      final outputs = await Bindgen().parseLibrary(
        source.uri.toString(),
        config,
        config.libraries.single,
      );
      final generated = outputs.values.join('\n');
      expect(RegExp('boundNullable: true').allMatches(generated).length, 5);
      expect(outputs['Opaque.dart'], contains('boundNullable: true'));
      expect(outputs['Strict.dart'], isNot(contains('boundNullable: true')));
      expect(generated, contains("'Strict'"));
      expect(generated, contains("'Opaque'"));
      expect(generated, contains("'identity'"));
    },
  );
}
