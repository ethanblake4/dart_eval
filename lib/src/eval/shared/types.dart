// ignore_for_file: unused_import, unnecessary_import

import 'package:dart_eval/dart_eval_bridge.dart';

/// Bridge type specs for `dart:core`.
class CoreTypes {
  /// Bridge spec for [ArgumentError].
  static const argumentError = BridgeTypeSpec('dart:core', 'ArgumentError');

  /// Bridge spec for [AssertionError].
  static const assertionError = BridgeTypeSpec('dart:core', 'AssertionError');

  /// Bridge spec for [bool].
  static const bool = BridgeTypeSpec('dart:core', 'bool');

  /// Bridge spec for [Comparable].
  static const comparable = BridgeTypeSpec('dart:core', 'Comparable');

  /// Bridge spec for [DateTime].
  static const dateTime = BridgeTypeSpec('dart:core', 'DateTime');

  /// Bridge spec for [double].
  static const double = BridgeTypeSpec('dart:core', 'double');

  /// Bridge spec for [Duration].
  static const duration = BridgeTypeSpec('dart:core', 'Duration');

  /// Bridge spec for [dynamic].
  static const dynamic = BridgeTypeSpec('dart:core', 'dynamic');

  /// Bridge spec for [Enum].
  static const enumType = BridgeTypeSpec('dart:core', 'Enum');

  /// Bridge spec for [Error].
  static const error = BridgeTypeSpec('dart:core', 'Error');

  /// Bridge spec for [Exception].
  static const exception = BridgeTypeSpec('dart:core', 'Exception');

  /// Bridge spec for [FormatException].
  static const formatException = BridgeTypeSpec('dart:core', 'FormatException');

  /// Bridge spec for [Function].
  static const function = BridgeTypeSpec('dart:core', 'Function');

  /// Bridge spec for [Future].
  static const future = BridgeTypeSpec('dart:core', 'Future');

  /// Bridge spec for [int].
  static const int = BridgeTypeSpec('dart:core', 'int');

  /// Bridge spec for [Invocation].
  static const invocation = BridgeTypeSpec('dart:core', 'Invocation');

  /// Bridge spec for [Iterable].
  static const iterable = BridgeTypeSpec('dart:core', 'Iterable');

  /// Bridge spec for [Iterator].
  static const iterator = BridgeTypeSpec('dart:core', 'Iterator');

  /// Bridge spec for [List].
  static const list = BridgeTypeSpec('dart:core', 'List');

  /// Bridge spec for [Map].
  static const map = BridgeTypeSpec('dart:core', 'Map');

  /// Bridge spec for [MapEntry].
  static const mapEntry = BridgeTypeSpec('dart:core', 'MapEntry');

  /// Bridge spec for [Match].
  static const match = BridgeTypeSpec('dart:core', 'Match');

  /// Bridge spec for [Never].
  static const never = BridgeTypeSpec('dart:core', 'Never');

  /// Bridge spec for [NoSuchMethodError].
  static const noSuchMethodError = BridgeTypeSpec(
    'dart:core',
    'NoSuchMethodError',
  );

  /// Bridge spec for [Null].
  static const nullType = BridgeTypeSpec('dart:core', 'Null');

  /// Bridge spec for [num].
  static const num = BridgeTypeSpec('dart:core', 'num');

  /// Bridge spec for [Object].
  static const object = BridgeTypeSpec('dart:core', 'Object');

  /// Bridge spec for [Pattern].
  static const pattern = BridgeTypeSpec('dart:core', 'Pattern');

  /// Bridge spec for [RangeError].
  static const rangeError = BridgeTypeSpec('dart:core', 'RangeError');

  /// Bridge spec for [Record].
  static const record = BridgeTypeSpec('dart:core', 'Record');

  /// Bridge spec for [RegExp].
  static const regExp = BridgeTypeSpec('dart:core', 'RegExp');

  /// Bridge spec for [RegExpMatch].
  static const regExpMatch = BridgeTypeSpec('dart:core', 'RegExpMatch');

  /// Bridge spec for [Set].
  static const set = BridgeTypeSpec('dart:core', 'Set');

  /// Bridge spec for [Sink].
  static const sink = BridgeTypeSpec('dart:core', 'Sink');

  /// Bridge spec for [StackTrace].
  static const stackTrace = BridgeTypeSpec('dart:core', 'StackTrace');

  /// Bridge spec for [StateError].
  static const stateError = BridgeTypeSpec('dart:core', 'StateError');

  /// Bridge spec for [Stopwatch].
  static const stopwatch = BridgeTypeSpec('dart:core', 'Stopwatch');

  /// Bridge spec for [Stream].
  static const stream = BridgeTypeSpec('dart:core', 'Stream');

  /// Bridge spec for [String].
  static const string = BridgeTypeSpec('dart:core', 'String');

  /// Bridge spec for [StringBuffer].
  static const stringBuffer = BridgeTypeSpec('dart:core', 'StringBuffer');

  /// Bridge spec for [StringSink].
  static const stringSink = BridgeTypeSpec('dart:core', 'StringSink');

  /// Bridge spec for [Symbol].
  static const symbol = BridgeTypeSpec('dart:core', 'Symbol');

  /// Bridge spec for [Type].
  static const type = BridgeTypeSpec('dart:core', 'Type');

  /// Bridge spec for [TypeError].
  static const typeError = BridgeTypeSpec('dart:core', 'TypeError');

  /// Bridge spec for [UnimplementedError].
  static const unimplementedError = BridgeTypeSpec(
    'dart:core',
    'UnimplementedError',
  );

  /// Bridge spec for [UnsupportedError].
  static const unsupportedError = BridgeTypeSpec(
    'dart:core',
    'UnsupportedError',
  );

  /// Bridge spec for [Uri].
  static const uri = BridgeTypeSpec('dart:core', 'Uri');

  /// Bridge spec for [void].
  static const voidType = BridgeTypeSpec('dart:core', 'void');
}

/// Bridge type specs for `dart:async`.
class AsyncTypes {
  /// Bridge spec for [Completer].
  static const completer = BridgeTypeSpec('dart:async', 'Completer');

  /// Bridge spec for [StreamController].
  static const streamController = BridgeTypeSpec(
    'dart:async',
    'StreamController',
  );

  /// Bridge spec for [StreamSink].
  static const streamSink = BridgeTypeSpec('dart:async', 'StreamSink');

  /// Bridge spec for [StreamSubscription].
  static const streamSubscription = BridgeTypeSpec(
    'dart:async',
    'StreamSubscription',
  );

  /// Bridge spec for [StreamTransformer].
  static const streamTransformer = BridgeTypeSpec(
    'dart:async',
    'StreamTransformer',
  );

  /// Bridge spec for [StreamView].
  static const streamView = BridgeTypeSpec('dart:async', 'StreamView');

  /// Bridge spec for [Timer].
  static const timer = BridgeTypeSpec('dart:async', 'Timer');

  /// Bridge spec for [Zone].
  static const zone = BridgeTypeSpec('dart:async', 'Zone');
}

/// Bridge type specs for `dart:collection`.
class CollectionTypes {
  /// Bridge spec for [DoubleLinkedQueue].
  static const doubleLinkedQueue = BridgeTypeSpec(
    'dart:collection',
    'DoubleLinkedQueue',
  );

  /// Bridge spec for [DoubleLinkedQueueEntry].
  static const doubleLinkedQueueEntry = BridgeTypeSpec(
    'dart:collection',
    'DoubleLinkedQueueEntry',
  );

  /// Bridge spec for [HashMap].
  static const hashMap = BridgeTypeSpec('dart:collection', 'HashMap');

  /// Bridge spec for [HashSet].
  static const hashSet = BridgeTypeSpec('dart:collection', 'HashSet');

  /// Bridge spec for [IterableBase].
  static const iterableBase = BridgeTypeSpec('dart:collection', 'IterableBase');

  /// Bridge spec for [LinkedHashMap].
  static const linkedHashMap = BridgeTypeSpec(
    'dart:collection',
    'LinkedHashMap',
  );

  /// Bridge spec for [LinkedHashSet].
  static const linkedHashSet = BridgeTypeSpec(
    'dart:collection',
    'LinkedHashSet',
  );

  /// Bridge spec for [ListBase].
  static const listBase = BridgeTypeSpec('dart:collection', 'ListBase');

  /// Bridge spec for [ListMixin].
  static const listMixin = BridgeTypeSpec('dart:collection', 'ListMixin');

  /// Bridge spec for [ListQueue].
  static const listQueue = BridgeTypeSpec('dart:collection', 'ListQueue');

  /// Bridge spec for [MapBase].
  static const mapBase = BridgeTypeSpec('dart:collection', 'MapBase');

  /// Bridge spec for [Queue].
  static const queue = BridgeTypeSpec('dart:collection', 'Queue');

  /// Bridge spec for [SetBase].
  static const setBase = BridgeTypeSpec('dart:collection', 'SetBase');
}

/// Bridge type specs for `dart:convert`.
class ConvertTypes {
  /// Bridge spec for [Base64Codec].
  static const base64Codec = BridgeTypeSpec('dart:convert', 'Base64Codec');

  /// Bridge spec for [Base64Decoder].
  static const base64Decoder = BridgeTypeSpec('dart:convert', 'Base64Decoder');

  /// Bridge spec for [Base64Encoder].
  static const base64Encoder = BridgeTypeSpec('dart:convert', 'Base64Encoder');

  /// Bridge spec for [ByteConversionSink].
  static const byteConversionSink = BridgeTypeSpec(
    'dart:convert',
    'ByteConversionSink',
  );

  /// Bridge spec for [ChunkedConversionSink].
  static const chunkedConversionSink = BridgeTypeSpec(
    'dart:convert',
    'ChunkedConversionSink',
  );

  /// Bridge spec for [Codec].
  static const codec = BridgeTypeSpec('dart:convert', 'Codec');

  /// Bridge spec for [Converter].
  static const converter = BridgeTypeSpec('dart:convert', 'Converter');

  /// Bridge spec for [Encoding].
  static const encoding = BridgeTypeSpec('dart:convert', 'Encoding');

  /// Bridge spec for [JsonCodec].
  static const jsonCodec = BridgeTypeSpec('dart:convert', 'JsonCodec');

  /// Bridge spec for [JsonDecoder].
  static const jsonDecoder = BridgeTypeSpec('dart:convert', 'JsonDecoder');

  /// Bridge spec for [JsonEncoder].
  static const jsonEncoder = BridgeTypeSpec('dart:convert', 'JsonEncoder');

  /// Bridge spec for [Utf8Codec].
  static const utf8Codec = BridgeTypeSpec('dart:convert', 'Utf8Codec');

  /// Bridge spec for [Utf8Decoder].
  static const utf8Decoder = BridgeTypeSpec('dart:convert', 'Utf8Decoder');

  /// Bridge spec for [Utf8Encoder].
  static const utf8Encoder = BridgeTypeSpec('dart:convert', 'Utf8Encoder');
}

/// Bridge type specs for `dart:io`.
class IoTypes {
  /// Bridge spec for [Directory].
  static const directory = BridgeTypeSpec('dart:io', 'Directory');

  /// Bridge spec for [File].
  static const file = BridgeTypeSpec('dart:io', 'File');

  /// Bridge spec for [FileMode].
  static const fileMode = BridgeTypeSpec('dart:io', 'FileMode');

  /// Bridge spec for [FileStat].
  static const fileStat = BridgeTypeSpec('dart:io', 'FileStat');

  /// Bridge spec for [FileSystemEntity].
  static const fileSystemEntity = BridgeTypeSpec('dart:io', 'FileSystemEntity');

  /// Bridge spec for [FileSystemEntityType].
  static const fileSystemEntityType = BridgeTypeSpec(
    'dart:io',
    'FileSystemEntityType',
  );

  /// Bridge spec for [FileSystemException].
  static const fileSystemException = BridgeTypeSpec(
    'dart:io',
    'FileSystemException',
  );

  /// Bridge spec for [HttpClient].
  static const httpClient = BridgeTypeSpec('dart:io', 'HttpClient');

  /// Bridge spec for [HttpClientRequest].
  static const httpClientRequest = BridgeTypeSpec(
    'dart:io',
    'HttpClientRequest',
  );

  /// Bridge spec for [HttpClientResponse].
  static const httpClientResponse = BridgeTypeSpec(
    'dart:io',
    'HttpClientResponse',
  );

  /// Bridge spec for [HttpStatus].
  static const httpStatus = BridgeTypeSpec('dart:io', 'HttpStatus');

  /// Bridge spec for [InternetAddress].
  static const internetAddress = BridgeTypeSpec('dart:io', 'InternetAddress');

  /// Bridge spec for [InternetAddressType].
  static const internetAddressType = BridgeTypeSpec(
    'dart:io',
    'InternetAddressType',
  );

  /// Bridge spec for [IOSink].
  static const ioSink = BridgeTypeSpec('dart:io', 'IOSink');

  /// Bridge spec for [Process].
  static const process = BridgeTypeSpec('dart:io', 'Process');

  /// Bridge spec for [ProcessInfo].
  static const processInfo = BridgeTypeSpec('dart:io', 'ProcessInfo');

  /// Bridge spec for [ProcessResult].
  static const processResult = BridgeTypeSpec('dart:io', 'ProcessResult');

  /// Bridge spec for [ProcessSignal].
  static const processSignal = BridgeTypeSpec('dart:io', 'ProcessSignal');

  /// Bridge spec for [ProcessStartMode].
  static const processStartMode = BridgeTypeSpec('dart:io', 'ProcessStartMode');
}

/// Bridge type specs for `dart:math`.
class MathTypes {
  /// Bridge spec for [Point].
  static const point = BridgeTypeSpec('dart:math', 'Point');

  /// Bridge spec for [Random].
  static const random = BridgeTypeSpec('dart:math', 'Random');
}

/// Bridge type specs for `dart:typed_data`.
class TypedDataTypes {
  /// Bridge spec for [ByteBuffer].
  static const byteBuffer = BridgeTypeSpec('dart:typed_data', 'ByteBuffer');

  /// Bridge spec for [ByteData].
  static const byteData = BridgeTypeSpec('dart:typed_data', 'ByteData');

  /// Bridge spec for [TypedData].
  static const typedData = BridgeTypeSpec('dart:typed_data', 'TypedData');

  /// Bridge spec for [Uint8List].
  static const uint8List = BridgeTypeSpec('dart:typed_data', 'Uint8List');
}
