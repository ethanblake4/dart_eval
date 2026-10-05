import 'dart:io' show FileSystemException;

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/io/directory.dart';
import 'package:dart_eval/src/eval/shared/stdlib/io/exceptions.dart';
import 'package:dart_eval/src/eval/shared/stdlib/io/link.dart';
import 'package:dart_eval/src/eval/shared/stdlib/io/http_headers.dart';
import 'package:dart_eval/src/eval/shared/stdlib/io/redirect_info.dart';
import 'package:dart_eval/src/eval/shared/stdlib/io/socket_connection.dart';
import 'package:dart_eval/src/eval/shared/stdlib/io/file.dart';
import 'package:dart_eval/src/eval/shared/stdlib/io/file_system_entity.dart';
import 'package:dart_eval/src/eval/shared/stdlib/io/http.dart';
import 'package:dart_eval/src/eval/shared/stdlib/io/http_status.dart';
import 'package:dart_eval/src/eval/shared/stdlib/io/io_sink.dart';
import 'package:dart_eval/src/eval/shared/stdlib/io/process.dart';
import 'package:dart_eval/src/eval/shared/stdlib/io/platform.dart';
import 'package:dart_eval/src/eval/shared/stdlib/io/socket.dart';
import 'package:dart_eval/src/eval/shared/stdlib/io/zlib.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/string_sink.dart';

/// [EvalPlugin] for the `dart:io` library
class DartIoPlugin implements EvalPlugin {
  @override
  String get identifier => 'dart:io';

  @override
  void configureForCompile(BridgeDeclarationRegistry registry) {
    $Platform.configureForCompile(registry);
    registry.defineBridgeClass($StringSink.$declaration);
    registry.defineBridgeClass($IOSink.$declaration);
    registry.defineBridgeClass($HttpClient.$declaration);
    registry.defineBridgeClass($HttpClientRequest.$declaration);
    registry.defineBridgeClass($HttpClientResponse.$declaration);
    registry.defineBridgeClass($FileSystemEntity.$declaration);
    registry.defineBridgeClass($File.$declaration);
    registry.defineBridgeClass($Directory.$declaration);
    $Link.configureForCompile(registry);
    registry.defineBridgeClass($Process.$declaration);
    registry.defineBridgeClass($ProcessInfo.$declaration);
    registry.defineBridgeClass($ProcessResult.$declaration);
    registry.defineBridgeClass($ProcessSignal.$declaration);
    registry.defineBridgeClass($ProcessStartMode.$declaration);
    $InternetAddress.configureForCompile(registry);
    $InternetAddressType.configureForCompile(registry);
    $SocketException.configureForCompile(registry);
    $HttpException.configureForCompile(registry);
    $OSError.configureForCompile(registry);
    $FileSystemException.configureForCompile(registry);
    $HttpHeaders.configureForCompile(registry);
    $RedirectInfo.configureForCompile(registry);
    $Socket.configureForCompile(registry);
    $ZLibCodec.configureForCompile(registry);
    $GZipCodec.configureForCompile(registry);
    $ZLibEncoder.configureForCompile(registry);
    $ZLibDecoder.configureForCompile(registry);
    registry.addSource($HttpStatusSource());
    registry.addSource(
      DartSource('dart:io', '''
    library dart.io;
    export 'dart:io/http_status.dart';
    '''),
    );
  }

  @override
  void configureForRuntime(Runtime runtime) {
    $Platform.configureForRuntime(runtime);
    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpClient.',
      $HttpClient.$new,
    );
    runtime.registerBridgeFuncRegisters('dart:io', 'File.', $File.$new);
    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'File.fromUri',
      $File.$fromUri,
    );
    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'Directory.',
      $Directory.$new,
    );
    $Link.configureForRuntime(runtime);
    $InternetAddress.configureForRuntime(runtime);
    $InternetAddressType.configureForRuntime(runtime);
    $SocketException.configureForRuntime(runtime);
    $HttpException.configureForRuntime(runtime);
    $OSError.configureForRuntime(runtime);
    $FileSystemException.configureForRuntime(runtime);
    runtime.addTypeAutowrapper(
      (value) => value is FileSystemException
          ? $FileSystemException.wrap(value)
          : null,
    );
    $HttpHeaders.configureForRuntime(runtime);
    $RedirectInfo.configureForRuntime(runtime);
    $Socket.configureForRuntime(runtime);
    $Process.configureForRuntime(runtime);
    $ProcessInfo.configureForRuntime(runtime);
    $ProcessResult.configureForRuntime(runtime);
    $ProcessSignal.configureForRuntime(runtime);
    $ProcessStartMode.configureForRuntime(runtime);
    $ZLibCodec.configureForRuntime(runtime);
    $GZipCodec.configureForRuntime(runtime);
    $ZLibEncoder.configureForRuntime(runtime);
    $ZLibDecoder.configureForRuntime(runtime);
  }
}
