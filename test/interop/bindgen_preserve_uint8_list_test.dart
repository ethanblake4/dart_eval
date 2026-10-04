import 'dart:io';

import 'package:dart_eval/src/eval/bindgen/bindgen.dart';
import 'package:dart_eval/src/eval/bindgen/config.dart';
import 'package:dart_eval/src/eval/bindgen/errors.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

BindgenConfig config({bool? preserve}) => BindgenConfig.parse('''
version: 1
libraries:
  - uri: package:bytes_fixture/bytes.dart
    classes:
      Receiver:
        methods:
          add:
            params:
              bytes:
                ${preserve == null ? 'optional: false' : 'preserveUint8List: $preserve'}
''')..resolveDefaults();

Future<String> generate(
  BindgenConfig config, {
  String type = 'List<int>',
}) async {
  final directory = Directory('test').absolute.createTempSync('bindgen_bytes_');
  addTearDown(() => directory.deleteSync(recursive: true));
  final source = File(p.join(directory.path, 'bytes.dart'))
    ..writeAsStringSync('class Receiver { void add($type bytes) {} }');
  return (await Bindgen().parse(
    source,
    'bytes.dart',
    'package:bytes_fixture/bytes.dart',
    false,
    config: config,
    libraryConfig: config.libraries.single,
  ))!;
}

void main() {
  test('configured List<int> preserves Uint8List with a cast fallback', () async {
    final configured = config(preserve: true);
    expect(
      configured
          .libraries
          .single
          .classes['Receiver']!
          .methods['add']!
          .params['bytes']!
          .preserveUint8List,
      isTrue,
    );
    final generated = await generate(configured);
    final compact = generated.replaceAll(RegExp(r'\s+'), ' ');
    expect(generated, contains("import 'dart:typed_data';"));
    expect(compact, contains('final value = TypedInterop.exportExternal('));
    expect(
      compact,
      contains(
        'return value is Uint8List ? value : (value as List).cast<int>();',
      ),
    );
    // The guest signature stays List<int>, so ordinary guest lists remain valid.
    expect(
      compact,
      contains("BridgeTypeRef(BridgeTypeSpec('dart:core', 'List'), ["),
    );
    expect(
      compact,
      contains("BridgeTypeRef(BridgeTypeSpec('dart:core', 'int'), [])"),
    );
  });

  test('absent and disabled flags retain existing list emission', () async {
    for (final preserve in <bool?>[null, false]) {
      final configured = config(preserve: preserve);
      expect(
        configured
            .libraries
            .single
            .classes['Receiver']!
            .methods['add']!
            .params['bytes']!
            .preserveUint8List,
        isFalse,
      );
      final generated = await generate(configured);
      expect(generated, contains('.cast<int>()'));
      expect(generated, isNot(contains('value is Uint8List')));
      expect(generated, isNot(contains("import 'dart:typed_data';")));
    }
  });

  test('preservation rejects incompatible parameter types', () async {
    for (final type in ['List<String>', 'List<int?>', 'List<int>?', 'int']) {
      await expectLater(
        generate(config(preserve: true), type: type),
        throwsA(
          isA<BindingGenerationError>().having(
            (error) => error.message,
            'message',
            contains('preserveUint8List requires a non-nullable List<int>'),
          ),
        ),
      );
    }
  });
}
