import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/convert/ascii.dart';
import 'package:dart_eval/src/eval/shared/stdlib/convert/base64.dart';
import 'package:dart_eval/src/eval/shared/stdlib/convert/byte_conversion.dart';
import 'package:dart_eval/src/eval/shared/stdlib/convert/chunked_conversion.dart';
import 'package:dart_eval/src/eval/shared/stdlib/convert/codec.dart';
import 'package:dart_eval/src/eval/shared/stdlib/convert/converter.dart';
import 'package:dart_eval/src/eval/shared/stdlib/convert/encoding.dart';
import 'package:dart_eval/src/eval/shared/stdlib/convert/functions.dart';
import 'package:dart_eval/src/eval/shared/stdlib/convert/html_escape.dart';
import 'package:dart_eval/src/eval/shared/stdlib/convert/line_splitter.dart';
import 'package:dart_eval/src/eval/shared/stdlib/convert/json.dart';
import 'package:dart_eval/src/eval/shared/stdlib/convert/string_conversion_sink.dart';
import 'package:dart_eval/src/eval/shared/stdlib/convert/utf.dart';
import 'package:dart_eval/src/eval/shared/stdlib/convert/typedefs.dart';

const convertSource = '''
final ascii = AsciiCodec();
final utf8 = Utf8Codec();
final latin1 = Encoding.getByName('latin1')!;
final json = JsonCodec();
final Base64Codec base64Url = Base64Codec.urlSafe();
final base64 = Base64Codec();
''';

final _sdkConvertSource = DartSource(
  'dart:convert',
  '${sdkTypedefsSource.stringSource!}\n$convertSource',
);

/// [EvalPlugin] for the `dart:convert` library
class DartConvertPlugin implements EvalPlugin {
  @override
  String get identifier => 'dart:convert';

  @override
  void configureForCompile(BridgeDeclarationRegistry registry) {
    $AsciiCodec.configureForCompile(registry);
    $AsciiEncoder.configureForCompile(registry);
    $AsciiDecoder.configureForCompile(registry);
    $Converter$bridge.configureForCompile(registry);
    $Codec$bridge.configureForCompile(registry);
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
    $HtmlEscapeMode.configureForCompile(registry);
    $HtmlEscape.configureForCompile(registry);
    $ByteConversionSink$bridge.configureForCompile(registry);
    $StringConversionSink$bridge.configureForCompile(registry);
    $ClosableStringSink.configureForCompile(registry);
    $LineSplitter.configureForCompile(registry);
    registry.addSource(_sdkConvertSource);
    registry.defineBridgeTopLevelFunction($base64EncodeFn.$declaration);
    registry.defineBridgeTopLevelFunction($base64DecodeFn.$declaration);
    registry.defineBridgeTopLevelFunction($jsonEncodeFn.$declaration);
    registry.defineBridgeTopLevelFunction($jsonDecodeFn.$declaration);
  }

  @override
  void configureForRuntime(Runtime runtime) {
    $AsciiCodec.configureForRuntime(runtime);
    $AsciiEncoder.configureForRuntime(runtime);
    $AsciiDecoder.configureForRuntime(runtime);
    $Converter$bridge.configureForRuntime(runtime);
    $Codec$bridge.configureForRuntime(runtime);
    $Encoding.configureForRuntime(runtime);
    $Utf8Decoder.configureForRuntime(runtime);
    $Utf8Codec.configureForRuntime(runtime);
    $Base64Encoder.configureForRuntime(runtime);
    $Base64Decoder.configureForRuntime(runtime);
    $Base64Codec.configureForRuntime(runtime);
    $JsonDecoder.configureForRuntime(runtime);
    $JsonEncoder.configureForRuntime(runtime);
    $JsonCodec.configureForRuntime(runtime);
    $jsonEncodeFn.configureForRuntime(runtime);
    $jsonDecodeFn.configureForRuntime(runtime);
    $base64EncodeFn.configureForRuntime(runtime);
    $base64DecodeFn.configureForRuntime(runtime);
    $ByteConversionSink$bridge.configureForRuntime(runtime);
    $ChunkedConversionSink.configureForRuntime(runtime);
    $HtmlEscapeMode.configureForRuntime(runtime);
    $HtmlEscape.configureForRuntime(runtime);
    $StringConversionSink$bridge.configureForRuntime(runtime);
    $ClosableStringSink.configureForRuntime(runtime);
    $LineSplitter.configureForRuntime(runtime);
  }
}
