import 'dart:io';

import 'package:dart_eval/src/eval/bindgen/bindgen.dart';
import 'package:dart_eval/src/eval/bindgen/config.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('both mode shares metadata and implements interface classes', () async {
    final directory = Directory('test').absolute.createTempSync('interface_');
    addTearDown(() => directory.deleteSync(recursive: true));
    final source = File(p.join(directory.path, 'native.dart'))
      ..writeAsStringSync('''
abstract interface class Reader<E> {
  E get current;
  bool moveNext();
}
''');
    final config = BindgenConfig.parse('''
version: 1
libraries:
  - uri: package:interface_probe/native.dart
    classes:
      Reader:
        include: true
        mode: both
''')..resolveDefaults();
    final generated = (await Bindgen().parse(
      source,
      'native.dart',
      'package:interface_probe/native.dart',
      false,
      config: config,
      libraryConfig: config.libraries.single,
    ))!;
    expect(
      generated,
      contains(r'with $Bridge<Reader<E>> implements Reader<E>'),
    );
    expect(
      generated,
      contains(r'static const $declaration = $Reader$bridge.$declaration;'),
    );
    expect(RegExp(r'E get current').allMatches(generated), hasLength(1));
    expect(generated, contains('wrap: false'));
    expect(generated, contains('bridge: true'));
  });
}
