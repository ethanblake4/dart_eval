import 'dart:io';

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/dart_eval_security.dart';

const cliPermissionDomains = [
  'network',
  'filesystem',
  'filesystem:read',
  'filesystem:write',
  'process',
  'process:run',
  'process:kill',
];

void grantCliPermissions(Runtime runtime, Iterable<String> domains) {
  for (final domain in domains) {
    switch (domain) {
      case 'network':
        runtime.grant(NetworkPermission.any);
      case 'filesystem':
        runtime.grant(FilesystemPermission.any);
      case 'filesystem:read':
        runtime.grant(FilesystemReadPermission.any);
      case 'filesystem:write':
        runtime.grant(FilesystemWritePermission.any);
      case 'process':
        runtime.grant(ProcessRunPermission.any);
        runtime.grant(const ProcessKillPermisssion());
      case 'process:run':
        runtime.grant(ProcessRunPermission.any);
      case 'process:kill':
        runtime.grant(const ProcessKillPermisssion());
      default:
        throw ArgumentError.value(
          domain,
          'domain',
          'Unknown permission domain',
        );
    }
  }
}

Future<void> cliRun(
  String path,
  String library,
  String function, {
  Iterable<String> permissions = const [],
}) async {
  final evc = File(path).readAsBytesSync();
  final runtime = Runtime(evc.buffer);
  grantCliPermissions(runtime, permissions);
  var result = await runtime.executeLib(library, function);

  if (result != null) {
    if (result is $Value) {
      result = result.$reified;
    }
    print('\nProgram exited with result: $result');
  }
}
