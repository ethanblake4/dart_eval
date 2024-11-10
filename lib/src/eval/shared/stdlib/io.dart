import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/io/directory.dart';
import 'package:dart_eval/src/eval/shared/stdlib/io/file.dart';
import 'package:dart_eval/src/eval/shared/stdlib/io/file_system_entity.dart';
import 'package:dart_eval/src/eval/shared/stdlib/io/http.dart';
import 'package:dart_eval/src/eval/shared/stdlib/io/http_status.dart';
import 'package:dart_eval/src/eval/shared/stdlib/io/io_sink.dart';
import 'package:dart_eval/src/eval/shared/stdlib/io/process.dart';
import 'package:dart_eval/src/eval/shared/stdlib/io/socket.dart';
import 'package:dart_eval/src/eval/shared/stdlib/io/string_sink.dart';

/// [EvalPlugin] for the `dart:io` library
class DartIoPlugin implements EvalPlugin {
  @override
  String get identifier => 'dart:io';

  @override
  void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($StringSink.$declaration);
    registry.defineBridgeClass($IOSink.$declaration);
    registry.defineBridgeClass($HttpClient.$declaration);
    registry.defineBridgeClass($HttpClientRequest.$declaration);
    registry.defineBridgeClass($HttpClientResponse.$declaration);
    registry.defineBridgeClass($FileSystemEntity.$declaration);
    registry.defineBridgeClass($File.$declaration);
    registry.defineBridgeClass($Directory.$declaration);
    registry.defineBridgeClass($Process.$declaration);
    registry.defineBridgeClass($ProcessInfo.$declaration);
    registry.defineBridgeClass($ProcessResult.$declaration);
    registry.defineBridgeClass($ProcessSignal.$declaration);
    registry.defineBridgeClass($ProcessStartMode.$declaration);
    $InternetAddress.configureForCompile(registry);
    $InternetAddressType.configureForCompile(registry);
    registry.addSource($HttpStatusSource());
    registry.addSource(DartSource('dart:io', '''
    library dart.io;
    export 'dart:io/http_status.dart';
    '''));
  }

  @override
  void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFunc('dart:io', 'HttpClient.', $HttpClient.$new);
    runtime.registerBridgeFunc('dart:io', 'File.', $File.$new);
    runtime.registerBridgeFunc('dart:io', 'Directory.', $Directory.$new);
    $InternetAddress.configureForRuntime(runtime);
    $InternetAddressType.configureForRuntime(runtime);
    $Process.configureForRuntime(runtime);
    $ProcessInfo.configureForRuntime(runtime);
    $ProcessResult.configureForRuntime(runtime);
    $ProcessSignal.configureForRuntime(runtime);
    $ProcessStartMode.configureForRuntime(runtime);
  }
}
