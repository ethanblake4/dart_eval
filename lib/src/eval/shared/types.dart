import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/async/stream.dart';
import 'package:dart_eval/src/eval/shared/stdlib/async/stream_controller.dart';
import 'package:dart_eval/src/eval/shared/stdlib/convert/converter.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/iterator.dart';
import 'package:dart_eval/stdlib/core.dart';

/// This class contains dart:core bridge type specs for convenience
class CoreTypes {
  /// Bridge type spec for [dynamic]
  static const dynamic = BridgeTypeSpec('dart:core', 'dynamic');

  /// Bridge type spec for [void]
  static const voidType = BridgeTypeSpec('dart:core', 'void');

  /// Bridge type spec for [Never]
  static const never = BridgeTypeSpec('dart:core', 'Never');

  /// Bridge type spec for [Null]
  static const nullType = BridgeTypeSpec('dart:core', 'Null');

  /// Bridge type spec for [num]
  static const num = BridgeTypeSpec('dart:core', 'num');

  /// Bridge type spec for [int]
  static const int = BridgeTypeSpec('dart:core', 'int');

  /// Bridge type spec for [double]
  static const double = BridgeTypeSpec('dart:core', 'double');

  /// Bridge type spec for [bool]
  static const bool = BridgeTypeSpec('dart:core', 'bool');

  /// Bridge type spec for [String]
  static const string = BridgeTypeSpec('dart:core', 'String');

  /// Bridge type spec for [Object]
  static const object = BridgeTypeSpec('dart:core', 'Object');

  /// Bridge type spec for [Function]
  static const function = BridgeTypeSpec('dart:core', 'Function');

  /// Bridge type spec for [Enum]
  static const enumType = BridgeTypeSpec('dart:core', 'Enum');

  /// Bridge type spec for [Type]
  static const type = BridgeTypeSpec('dart:core', 'Type');

  /// Bridge type spec for [$Duration]
  static const duration = BridgeTypeSpec('dart:core', 'Duration');

  /// Bridge type spec for [$DateTime]
  static const dateTime = BridgeTypeSpec('dart:core', 'DateTime');

  /// Bridge type spec for [$List]
  static const list = BridgeTypeSpec('dart:core', 'List');

  /// Bridge type spec for [$Map]
  static const map = BridgeTypeSpec('dart:core', 'Map');

  /// Bridge type spec for [$Iterator]
  static const iterator = BridgeTypeSpec('dart:core', 'Iterator');

  /// Bridge type spec for [$Iterable]
  static const iterable = BridgeTypeSpec('dart:core', 'Iterable');

  /// Bridge type spec for [$Future]
  static const future = BridgeTypeSpec('dart:core', 'Future');

  /// Bridge type spec for [$Uri]
  static const uri = BridgeTypeSpec('dart:core', 'Uri');

  /// Bridge type spec for [$Pattern]
  static const pattern = BridgeTypeSpec('dart:core', 'Pattern');

  /// Bridge type spec for [$Match]
  static const match = BridgeTypeSpec('dart:core', 'Match');

  /// Bridge type spec for [$RegExp]
  static const regExp = BridgeTypeSpec('dart:core', 'RegExp');

  /// Bridge type spec for [Error]
  static const error = BridgeTypeSpec('dart:core', 'Error');

  /// Bridge type spec for [RangeError]
  static const rangeError = BridgeTypeSpec('dart:core', 'RangeError');

  /// Bridge type spec for [Exception]
  static const exception = BridgeTypeSpec('dart:core', 'Exception');

  /// Bridge type spec for [AssertionError]
  static const assertionError = BridgeTypeSpec('dart:core', 'AssertionError');

  /// Bridge type spec for [Comparable]
  static const comparable = BridgeTypeSpec('dart:core', 'Comparable');

  /// Bridge type spec for [StringBuffer]
  static const stringBuffer = BridgeTypeSpec('dart:core', 'StringBuffer');
}

/// This class contains dart:async bridge type specs for convenience
class AsyncTypes {
  /// Bridge type spec for [$Stream]
  static const stream = BridgeTypeSpec('dart:async', 'Stream');

  /// Bridge type spec for [$StreamTransformer]
  static const streamTransformer =
      BridgeTypeSpec('dart:async', 'StreamTransformer');

  /// Bridge type spec for [$StreamController]
  static const streamController =
      BridgeTypeSpec('dart:async', 'StreamController');

  /// Bridge type spec for [$StreamSubscription]
  static const streamSubscription =
      BridgeTypeSpec('dart:async', 'StreamSubscription');

  /// Bridge type spec for [$StreamSink]
  static const streamSink = BridgeTypeSpec('dart:async', 'StreamSink');
}

/// This class contains dart:convert bridge type specs for convenience
class ConvertTypes {
  /// Bridge type spec for [$Converter]
  static const converter = BridgeTypeSpec('dart:convert', 'Converter');

  /// Bridge type spec for [$Codec]
  static const codec = BridgeTypeSpec('dart:convert', 'Codec');

  /// Bridge type spec for [$Encoding]
  static const encoding = BridgeTypeSpec('dart:convert', 'Encoding');

  /// Bridge type spec for [$JsonEncoder]
  static const jsonEncoder = BridgeTypeSpec('dart:convert', 'JsonEncoder');

  /// Bridge type spec for [$JsonDecoder]
  static const jsonDecoder = BridgeTypeSpec('dart:convert', 'JsonDecoder');

  /// Bridge type spec for [$JsonCodec]
  static const jsonCodec = BridgeTypeSpec('dart:convert', 'JsonCodec');

  /// Bridge type spec for [$Utf8Encoder]
  static const utf8Encoder = BridgeTypeSpec('dart:convert', 'Utf8Encoder');

  /// Bridge type spec for [$Utf8Decoder]
  static const utf8Decoder = BridgeTypeSpec('dart:convert', 'Utf8Decoder');

  /// Bridge type spec for [$Utf8Codec]
  static const utf8Codec = BridgeTypeSpec('dart:convert', 'Utf8Codec');
}

/// This class contains dart:io bridge type specs for convenience
class IoTypes {
  /// Bridge type spec for [$File]
  static const file = BridgeTypeSpec('dart:io', 'File');

  /// Bridge type spec for [$Directory]
  static const directory = BridgeTypeSpec('dart:io', 'Directory');

  /// Bridge type spec for [$FileSystemEntity]
  static const fileSystemEntity = BridgeTypeSpec('dart:io', 'FileSystemEntity');

  /// Bridge type spec for [$FileSystemEntityType]
  static const fileSystemEntityType =
      BridgeTypeSpec('dart:io', 'FileSystemEntityType');

  /// Bridge type spec for [$FileStat]
  static const fileStat = BridgeTypeSpec('dart:io', 'FileStat');

  /// Bridge type spec for [$FileSystemException]
  static const fileSystemException =
      BridgeTypeSpec('dart:io', 'FileSystemException');

  /// Bridge type spec for [$FileMode]
  static const fileMode = BridgeTypeSpec('dart:io', 'FileMode');

  /// Bridge type spec for [$IOSink]
  static const ioSink = BridgeTypeSpec('dart:io', 'IOSink');

  /// Bridge type spec for [StringSink]
  static const stringSink = BridgeTypeSpec('dart:io', 'StringSink');

  /// Bridge type spec for [$HttpClient]
  static const httpClient = BridgeTypeSpec('dart:io', 'HttpClient');

  /// Bridge type spec for [$HttpClientRequest]
  static const httpClientRequest =
      BridgeTypeSpec('dart:io', 'HttpClientRequest');

  /// Bridge type spec for [$HttpClientResponse]
  static const httpClientResponse =
      BridgeTypeSpec('dart:io', 'HttpClientResponse');
}

class TypedDataTypes {
  /// Bridge type spec for [$ByteBuffer]
  static const byteBuffer = BridgeTypeSpec('dart:typed_data', 'ByteBuffer');

  /// Bridge type spec for [$TypedData]
  static const typedData = BridgeTypeSpec('dart:typed_data', 'TypedData');

  /// Bridge type spec for [$ByteData]
  static const byteData = BridgeTypeSpec('dart:typed_data', 'ByteData');

  /// Bridge type spec for [$Uint8List]
  static const uint8List = BridgeTypeSpec('dart:typed_data', 'Uint8List');
}
