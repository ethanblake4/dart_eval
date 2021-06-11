import 'dart:io';

import 'dart:typed_data';

import 'package:dart_eval/src/dbc/dbc_executor.dart';

class DbcWriter {

  Uint8List write(List<DbcOp> ops) {
    final b = BytesBuilder(copy: false);
    for (final op in ops) {
      b.add(Dbc.opcodeFrom(op));
    }
    return b.takeBytes();
  }
}