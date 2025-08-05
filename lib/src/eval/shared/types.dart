import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/async/future.dart';
import 'package:dart_eval/src/eval/shared/stdlib/async/stream.dart';
import 'package:dart_eval/src/eval/shared/stdlib/async/stream_controller.dart';
import 'package:dart_eval/src/eval/shared/stdlib/convert/converter.dart';
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

  /// Bridge type spec for [Record]
  static const record = BridgeTypeSpec('dart:core', 'Record');

  /// Bridge type spec for [Type]
  static const type = BridgeTypeSpec('dart:core', 'Type');

  /// Bridge type spec for [Symbol]
  static const symbol = BridgeTypeSpec('dart:core', 'Symbol');

  /// Bridge type spec for [$Duration]
  static const duration = BridgeTypeSpec('dart:core', 'Duration');

  /// Bridge type spec for [$DateTime]
  static const dateTime = BridgeTypeSpec('dart:core', 'DateTime');

  /// Bridge type spec for [$List]
  static const list = BridgeTypeSpec('dart:core', 'List');

  /// Bridge type spec for [$Map]
  static const map = BridgeTypeSpec('dart:core', 'Map');

  /// Bridge type spec for [$Set]
  static const set = BridgeTypeSpec('dart:core', 'Set');

  /// Bridge type spec for [$MapEntry]
  static const mapEntry = BridgeTypeSpec('dart:core', 'MapEntry');

  /// Bridge type spec for [$Iterator]
  static const iterator = BridgeTypeSpec('dart:core', 'Iterator');

  /// Bridge type spec for [$Iterable]
  static const iterable = BridgeTypeSpec('dart:core', 'Iterable');

  /// Bridge type spec for [$Future]
  static const future = BridgeTypeSpec('dart:core', 'Future');

  /// Bridge type spec for [$Stream]
  static const stream = BridgeTypeSpec('dart:core', 'Stream');

  /// Bridge type spec for [$Uri]
  static const uri = BridgeTypeSpec('dart:core', 'Uri');

  /// Bridge type spec for [$Pattern]
  static const pattern = BridgeTypeSpec('dart:core', 'Pattern');

  /// Bridge type spec for [$Match]
  static const match = BridgeTypeSpec('dart:core', 'Match');

  /// Bridge type spec for [$RegExp]
  static const regExp = BridgeTypeSpec('dart:core', 'RegExp');

  /// Bridge type spec for [$StackTrace]
  static const stackTrace = BridgeTypeSpec('dart:core', 'StackTrace');

  /// Bridge type spec for [Error]
  static const error = BridgeTypeSpec('dart:core', 'Error');

  /// Bridge type spec for [RangeError]
  static const rangeError = BridgeTypeSpec('dart:core', 'RangeError');

  /// Bridge type spec for [Exception]
  static const exception = BridgeTypeSpec('dart:core', 'Exception');

  /// Bridge type spec for [Exception]
  static const formatException = BridgeTypeSpec('dart:core', 'FormatException');

  /// Bridge type spec for [$UnsupportedError]
  static const unsupportedError =
      BridgeTypeSpec('dart:core', 'UnsupportedError');

  /// Bridge type spec for [$UnimplementedError]
  static const unimplementedError =
      BridgeTypeSpec('dart:core', 'UnimplementedError');

  /// Bridge type spec for [AssertionError]
  static const assertionError = BridgeTypeSpec('dart:core', 'AssertionError');

  /// Bridge type spec for [ArgumentError]
  static const argumentError = BridgeTypeSpec('dart:core', 'ArgumentError');

  /// Bridge type spec for [StateError]
  static const stateError = BridgeTypeSpec('dart:core', 'StateError');

  /// Bridge type spec for [Comparable]
  static const comparable = BridgeTypeSpec('dart:core', 'Comparable');

  /// Bridge type spec for [StringBuffer]
  static const stringBuffer = BridgeTypeSpec('dart:core', 'StringBuffer');

  /// Bridge type spec for [Sink]
  static const sink = BridgeTypeSpec('dart:core', 'Sink');
}

/// This class contains dart:async bridge type specs for convenience
class AsyncTypes {
  /// Bridge type spec for [$Completer]
  static const completer = BridgeTypeSpec('dart:async', 'Completer');

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

  /// Bridge type spec for [$StreamView]
  static const streamView = BridgeTypeSpec('dart:async', 'StreamView');

  /// Bridge type spec for [$Timer]
  static const timer = BridgeTypeSpec('dart:async', 'Timer');

  /// Bridge type spec for [$Zone]
  static const zone = BridgeTypeSpec('dart:async', 'Zone');
}

/// This class contains dart:collection bridge type specs for convenience
class CollectionTypes {
  /// Bridge type spec for [$IterableBase]
  static const iterableBase = BridgeTypeSpec('dart:collection', 'IterableBase');

  /// Bridge type spec for [$ListBase]
  static const listBase = BridgeTypeSpec('dart:collection', 'ListBase');

  /// Bridge type spec for [$MapBase]
  static const mapBase = BridgeTypeSpec('dart:collection', 'MapBase');

  /// Bridge type spec for [$Queue]
  static const queue = BridgeTypeSpec('dart:collection', 'Queue');

  /// Bridge type spec for [$SetBase]
  static const setBase = BridgeTypeSpec('dart:collection', 'SetBase');

  /// Bridge type spec for [$LinkedHashMap]
  static const linkedHashMap =
      BridgeTypeSpec('dart:collection', 'LinkedHashMap');

  /// Bridge type spec for [$LinkedHashSet]
  static const linkedHashSet =
      BridgeTypeSpec('dart:collection', 'LinkedHashSet');

  /// Bridge type spec for [$DoubleLinkedQueue]
  static const doubleLinkedQueue =
      BridgeTypeSpec('dart:collection', 'DoubleLinkedQueue');

  /// Bridge type spec for [$DoubleLinkedQueueEntry]
  static const doubleLinkedQueueEntry =
      BridgeTypeSpec('dart:collection', 'DoubleLinkedQueueEntry');

  /// Bridge type spec for [$HashMap]
  static const hashMap = BridgeTypeSpec('dart:collection', 'HashMap');

  /// Bridge type spec for [$HashSet]
  static const hashSet = BridgeTypeSpec('dart:collection', 'HashSet');

  /// Bridge type spec for [$ListMixin]
  static const listMixin = BridgeTypeSpec('dart:collection', 'ListMixin');

  /// Bridge type spec for [$ListQueue]
  static const listQueue = BridgeTypeSpec('dart:collection', 'ListQueue');
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

  /// Bridge type spec for [$Base64Encoder]
  static const base64Encoder = BridgeTypeSpec('dart:convert', 'Base64Encoder');

  /// Bridge type spec for [$Base64Decoder]
  static const base64Decoder = BridgeTypeSpec('dart:convert', 'Base64Decoder');

  /// Bridge type spec for [$Base64Codec]
  static const base64Codec = BridgeTypeSpec('dart:convert', 'Base64Codec');

  /// Bridge type spec for [ByteConversionSink]
  static const byteConversionSink =
      BridgeTypeSpec('dart:convert', 'ByteConversionSink');

  /// Bridge type spec for [ChunkedConversionSink]
  static const chunkedConversionSink =
      BridgeTypeSpec('dart:convert', 'ChunkedConversionSink');
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

  /// Bridge type spec for [$InternetAddressType]
  static const internetAddressType =
      BridgeTypeSpec('dart:io', 'InternetAddressType');

  /// Bridge type spec for [$InternetAddress]
  static const internetAddress = BridgeTypeSpec('dart:io', 'InternetAddress');

  /// Bridge type spec for [$HttpClient]
  static const httpClient = BridgeTypeSpec('dart:io', 'HttpClient');

  /// Bridge type spec for [$HttpClientRequest]
  static const httpClientRequest =
      BridgeTypeSpec('dart:io', 'HttpClientRequest');

  /// Bridge type spec for [$HttpClientResponse]
  static const httpClientResponse =
      BridgeTypeSpec('dart:io', 'HttpClientResponse');

  /// Bridge type spec for [$HttpStatus]
  static const httpStatus =
      BridgeTypeSpec('dart:io/http_status.dart', 'HttpStatus');
}

class MathTypes {
  /// Bridge type spec for [$Point]
  static const point = BridgeTypeSpec('dart:math', 'Point');

  /// Bridge type spec for [$Random]
  static const random = BridgeTypeSpec('dart:math', 'Random');
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
