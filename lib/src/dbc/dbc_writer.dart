import 'dart:convert';
import 'dart:io';

import 'dart:typed_data';

import 'package:dart_eval/src/dbc/dbc_executor.dart';

class DbcWriter {

  Uint8List write(Map<int, Map<String, int>> topLevelDeclarations, List<DbcOp> ops) {
    final b = BytesBuilder(copy: false);
    final declarationsJson = json.encode(topLevelDeclarations.map((key, value) => MapEntry(key.toString(), value)));
    final encodedDeclarations = utf8.encode(declarationsJson);
    b.add(Dbc.i32b(encodedDeclarations.length));
    b.add(encodedDeclarations);

    for (final op in ops) {
      b.add(Dbc.opcodeFrom(op));
    }
    return b.takeBytes();
  }
}