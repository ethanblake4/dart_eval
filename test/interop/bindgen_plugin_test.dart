import 'package:dart_eval/src/eval/bindgen/config.dart';
import 'package:dart_eval/src/eval/cli/bind.dart';
import 'package:test/test.dart';

void main() {
  test('aggregate plugin uses full paths and custom declaration overrides', () {
    final config = BindgenConfig.parse('''
version: 1
plugin:
  out: lib/flutter_eval.dart
  class: FlutterEvalPlugin
  identifier: package:flutter
  instance: flutterEvalPlugin
  excludeDeclarations: [StatefulWidget]
  extraDeclarations: ['\$StatefulWidgetBridge.\$declaration']
  extraSources:
    - expression: '\$StatefulWidgetBridge.configureForRuntime(runtime)'
      target: runtime
libraries:
  - uri: package:flutter/src/widgets/framework.dart
    classes: [StatefulWidget]
''')..resolveDefaults();
    final plugin = config.plugin!;
    expect(plugin.excludeDeclarations, ['StatefulWidget']);

    final source = emitPluginSource(plugin, [
      (
        file: 'lib/src/widgets/framework.dart',
        name: 'StatefulWidget',
        kind: BindgenPluginKind.classBinding,
      ),
      (
        file: 'lib/src/material/card.dart',
        name: 'Card',
        kind: BindgenPluginKind.classBinding,
      ),
    ]);

    expect(source, contains("import 'src/widgets/framework.dart';"));
    expect(source, contains("import 'src/material/card.dart';"));
    expect(source, contains('const flutterEvalPlugin = FlutterEvalPlugin();'));
    expect(
      source,
      isNot(
        contains('registry.defineBridgeClass(\$StatefulWidget.\$declaration)'),
      ),
    );
    expect(
      source,
      contains('registry.defineBridgeClass(\$Card.\$declaration)'),
    );
    expect(
      source,
      contains(
        'registry.defineBridgeClass(\$StatefulWidgetBridge.\$declaration)',
      ),
    );
    expect(source, contains('\$StatefulWidget.configureForRuntime(runtime)'));
    expect(
      source,
      contains('\$StatefulWidgetBridge.configureForRuntime(runtime)'),
    );
  });
}
