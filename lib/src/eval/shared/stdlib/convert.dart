import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/convert/converter.dart';
import 'package:dart_eval/src/eval/shared/stdlib/convert/utf.dart';

const convertSource = '''
final utf8 = Utf8Codec();
''';

/// [EvalPlugin] for the `dart:convert` library
class DartConvertPlugin implements EvalPlugin {
  @override
  String get identifier => 'dart:convert';

  @override
  void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($Converter.$declaration);
    registry.defineBridgeClass($Utf8Decoder.$declaration);
    registry.defineBridgeClass($Utf8Codec.$declaration);
    registry.addSource(DartSource('dart:convert', convertSource));
  }

  @override
  void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFunc('dart:convert', 'Utf8Decoder.', $Utf8Decoder.$new);
    runtime.registerBridgeFunc('dart:convert', 'Utf8Codec.', $Utf8Codec.$new);
  }
}
