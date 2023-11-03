import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/convert/codec.dart';
import 'package:dart_eval/src/eval/shared/stdlib/convert/converter.dart';
import 'package:dart_eval/src/eval/shared/stdlib/convert/encoding.dart';
import 'package:dart_eval/src/eval/shared/stdlib/convert/json.dart';
import 'package:dart_eval/src/eval/shared/stdlib/convert/utf.dart';

const convertSource =
    '''
final utf8 = Utf8Codec();
final json = JsonCodec();
''';

/// [EvalPlugin] for the `dart:convert` library
class DartConvertPlugin implements EvalPlugin {
  @override
  String get identifier => 'dart:convert';

  @override
  void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($Converter.$declaration);
    registry.defineBridgeClass($Codec.$declaration);
    registry.defineBridgeClass($Encoding.$declaration);
    registry.defineBridgeClass($Utf8Decoder.$declaration);
    registry.defineBridgeClass($Utf8Codec.$declaration);
    registry.defineBridgeClass($JsonDecoder.$declaration);
    registry.defineBridgeClass($JsonEncoder.$declaration);
    registry.defineBridgeClass($JsonCodec.$declaration);
    registry.addSource(DartSource('dart:convert', convertSource));
  }

  @override
  void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFunc(
        'dart:convert', 'Utf8Decoder.', $Utf8Decoder.$new);
    runtime.registerBridgeFunc('dart:convert', 'Utf8Codec.', $Utf8Codec.$new);
    runtime.registerBridgeFunc(
        'dart:convert', 'JsonDecoder.', $JsonDecoder.$new);
    runtime.registerBridgeFunc(
        'dart:convert', 'JsonEncoder.', $JsonEncoder.$new);
    runtime.registerBridgeFunc('dart:convert', 'JsonCodec.', $JsonCodec.$new);
  }
}
