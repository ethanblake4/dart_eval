import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/shared/stdlib/async/stream.dart';
import 'package:dart_eval/src/eval/shared/stdlib/async/stream_controller.dart';
import 'package:dart_eval/src/eval/shared/stdlib/convert/converter.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/iterator.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/pattern.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/regexp.dart';
import 'package:dart_eval/stdlib/core.dart';

/// Bridged runtime type IDs for core Dart types.
class RuntimeTypes {
  /// Bridged runtime type for [void]
  static const int voidType = -1;

  /// Bridged runtime type for [dynamic]
  static const int dynamicType = -2;

  /// Bridged runtime type for [null]
  static const int nullType = -3;

  /// Bridged runtime type for [Object]
  static const int objectType = -4;

  /// Bridged runtime type for [bool]
  static const int boolType = -5;

  /// Bridged runtime type for [String]
  static const int stringType = -7;

  /// Bridged runtime type for [Map]
  static const int mapType = -10;

  /// Bridged runtime type for [Function]
  static const int functionType = -12;

  /// Bridged runtime type for [Type]
  static const int typeType = -13;

  /// Bridged runtime type for [Future]
  static const int futureType = -16;

  /// Bridged runtime type for [Duration]
  static const int durationType = -17;

  /// Bridged runtime type for [Enum]
  static const int enumType = -18;
}

/// A map of dart_eval compile-time types to runtime type IDs
final Map<TypeRef, int> runtimeTypeMap = {
  EvalTypes.voidType: RuntimeTypes.voidType,
  EvalTypes.dynamicType: RuntimeTypes.dynamicType,
  EvalTypes.nullType: RuntimeTypes.nullType,
  EvalTypes.objectType: RuntimeTypes.objectType,
  EvalTypes.boolType: RuntimeTypes.boolType,
  EvalTypes.stringType: RuntimeTypes.stringType,
  EvalTypes.mapType: RuntimeTypes.mapType,
  EvalTypes.functionType: RuntimeTypes.functionType,
  EvalTypes.typeType: RuntimeTypes.typeType,
  EvalTypes.enumType: RuntimeTypes.enumType
};

/// A map of runtime type IDs to dart_eval compile-time types
final Map<int, TypeRef> inverseRuntimeTypeMap = {
  RuntimeTypes.voidType: EvalTypes.voidType,
  RuntimeTypes.dynamicType: EvalTypes.dynamicType,
  RuntimeTypes.nullType: EvalTypes.nullType,
  RuntimeTypes.objectType: EvalTypes.objectType,
  RuntimeTypes.boolType: EvalTypes.boolType,
  RuntimeTypes.stringType: EvalTypes.stringType,
  RuntimeTypes.mapType: EvalTypes.mapType,
  RuntimeTypes.functionType: EvalTypes.functionType,
  RuntimeTypes.typeType: EvalTypes.typeType
};

/// This class contains dart:core bridge type specs for convenience
class CoreTypes {
  /// Bridge type spec for [num]
  static const num = BridgeTypeSpec('dart:core', 'num');

  /// Bridge type spec for [int]
  static const int = BridgeTypeSpec('dart:core', 'int');

  /// Bridge type spec for [double]
  static const double = BridgeTypeSpec('dart:core', 'double');

  /// Bridge type spec for [$Duration]
  static const duration = BridgeTypeSpec('dart:core', 'Duration');

  /// Bridge type spec for [$DateTime]
  static const dateTime = BridgeTypeSpec('dart:core', 'DateTime');

  /// Bridge type spec for [$List]
  static const list = BridgeTypeSpec('dart:core', 'List');

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
