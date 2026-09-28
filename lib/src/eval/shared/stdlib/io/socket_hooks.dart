import 'dart:io';

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';

import 'socket_connection.dart';

$Value? socketConnect(Runtime runtime, $Value? _, List<$Value?> args) {
  final host = args[0]!.$reified;
  final port = (args[1] as $int).$value;
  _assertNetworkPermission(runtime, host, port);

  final connection = Socket.connect(
    host,
    port,
    sourceAddress: _arg(args, 2)?.$reified,
    sourcePort: _arg(args, 3) == null ? 0 : (_arg(args, 3) as $int).$value,
    timeout: _arg(args, 4)?.$value,
  );
  return $Future.wrap(connection.then((socket) => $Socket.wrap(socket)));
}

$Value? socketStartConnect(Runtime runtime, $Value? _, List<$Value?> args) {
  final host = args[0]!.$reified;
  final port = (args[1] as $int).$value;
  _assertNetworkPermission(runtime, host, port);

  final connection = Socket.startConnect(
    host,
    port,
    sourceAddress: _arg(args, 2)?.$reified,
    sourcePort: _arg(args, 3) == null ? 0 : (_arg(args, 3) as $int).$value,
  );
  return $Future.wrap(connection.then((task) => $Object(task)));
}

$Value? _arg(List<$Value?> args, int index) =>
    index < args.length ? args[index] : null;

void _assertNetworkPermission(Runtime runtime, Object host, int port) {
  final address = host is InternetAddress ? host.address : host as String;
  runtime.assertPermission(
    'network',
    Uri(host: address, port: port).toString(),
  );
}
