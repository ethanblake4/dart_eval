import 'dart:convert';
import 'dart:io';

import 'dart:typed_data';

import 'package:dart_eval/src/dbc/dbc_executor.dart' hide ops;

class DbcWriter {

  Uint8List write(DbcProgram program) {
    final b = BytesBuilder(copy: false);

    final declarationsJson = json.encode(program.topLevelDeclarations.map((key, value) => MapEntry(key.toString(), value)));
    final encodedDeclarations = utf8.encode(declarationsJson);
    b.add(Dbc.i32b(encodedDeclarations.length));
    b.add(encodedDeclarations);

    final iDeclarationsJson = json.encode(program.instanceDeclarations.map((key, value) => MapEntry(key.toString(), value)));
    final iEncodedDeclarations = utf8.encode(iDeclarationsJson);
    b.add(Dbc.i32b(iEncodedDeclarations.length));
    b.add(iEncodedDeclarations);

    for (final op in program.ops) {
      b.add(Dbc.opcodeFrom(op));
    }
    return b.takeBytes();
  }
}

class DbcProgram {
  DbcProgram(this.topLevelDeclarations, this.instanceDeclarations, this.ops);

  Map<int, Map<String, int>> topLevelDeclarations;
  Map<int, Map<String, List<Map<String, int>>>> instanceDeclarations;
  List<DbcOp> ops;
}