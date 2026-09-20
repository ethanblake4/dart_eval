import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/convert/base64.dart';
import 'package:dart_eval/src/eval/shared/stdlib/convert/byte_conversion.dart';
import 'package:dart_eval/src/eval/shared/stdlib/convert/chunked_conversion.dart';
import 'package:dart_eval/src/eval/shared/stdlib/convert/codec.dart';
import 'package:dart_eval/src/eval/shared/stdlib/convert/converter.dart';
import 'package:dart_eval/src/eval/shared/stdlib/convert/encoding.dart';
import 'package:dart_eval/src/eval/shared/stdlib/convert/json.dart';
import 'package:dart_eval/src/eval/shared/stdlib/convert/json_functions.dart';
import 'package:dart_eval/src/eval/shared/stdlib/convert/utf.dart';

const convertSource = '''
final utf8 = Utf8Codec();
final json = JsonCodec();
final Base64Codec base64Url = Base64Codec.urlSafe();
final base64 = Base64Codec();
''';

/// [EvalPlugin] for the `dart:convert` library
class DartConvertPlugin implements EvalPlugin {
  @override
  String get identifier => 'dart:convert';

  @override
  void configureForCompile(BridgeDeclarationRegistry registry) {
    $Converter.configureForCompile(registry);
    $Codec.configureForCompile(registry);
    $Encoding.configureForCompile(registry);
    $Utf8Decoder.configureForCompile(registry);
    $Utf8Codec.configureForCompile(registry);
    $Base64Encoder.configureForCompile(registry);
    $Base64Decoder.configureForCompile(registry);
    $Base64Codec.configureForCompile(registry);
    $JsonDecoder.configureForCompile(registry);
    $JsonEncoder.configureForCompile(registry);
    $JsonCodec.configureForCompile(registry);
    $ChunkedConversionSink.configureForCompile(registry);
    $ByteConversionSink.configureForCompile(registry);
    registry.addSource(DartSource('dart:convert', convertSource));
    $JsonEncodeAndDecode.configureForCompile(registry);
  }

  @override
  void configureForRuntime(Runtime runtime) {
    $Converter.configureForRuntime(runtime);
    $Codec.configureForRuntime(runtime);
    $Encoding.configureForRuntime(runtime);
    $Utf8Decoder.configureForRuntime(runtime);
    $Utf8Codec.configureForRuntime(runtime);
    $Base64Encoder.configureForRuntime(runtime);
    $Base64Decoder.configureForRuntime(runtime);
    $Base64Codec.configureForRuntime(runtime);
    $JsonDecoder.configureForRuntime(runtime);
    $JsonEncoder.configureForRuntime(runtime);
    $JsonCodec.configureForRuntime(runtime);
    $JsonEncodeAndDecode.configureForRuntime(runtime);
    $ByteConversionSink.configureForRuntime(runtime);
    $ChunkedConversionSink.configureForRuntime(runtime);
  }
}
