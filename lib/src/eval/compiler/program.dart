import 'dart:convert';

import 'dart:typed_data';

import 'package:dart_eval/src/eval/runtime/runtime.dart' show Runtime;
import 'package:dart_eval/src/eval/runtime/ops/all_ops.dart';


class Program {
  Program(this.topLevelDeclarations, this.instanceDeclarations, this.ops);

  Map<int, Map<String, int>> topLevelDeclarations;

  /// Example instance declaration:
  /// 1: { // file
  ///    "SomeClass": [
  ///       { "someProp": 221 }, // getters
  ///       { "someProp": 254 }, // setters
  ///       { "someMethod": 288 }, // methods
  ///    ]
  /// }
  Map<int, Map<String, List<Map<String, int>>>> instanceDeclarations;
  List<DbcOp> ops;

  Uint8List write() {
    final b = BytesBuilder(copy: false);

    final declarationsJson = json.encode(topLevelDeclarations.map((key, value) => MapEntry(key.toString(), value)));
    final encodedDeclarations = utf8.encode(declarationsJson);
    b.add(Dbc.i32b(encodedDeclarations.length));
    b.add(encodedDeclarations);

    final iDeclarationsJson = json.encode(instanceDeclarations.map((key, value) => MapEntry(key.toString(), value)));
    final iEncodedDeclarations = utf8.encode(iDeclarationsJson);
    b.add(Dbc.i32b(iEncodedDeclarations.length));
    b.add(iEncodedDeclarations);

    for (final op in ops) {
      b.add(Runtime.opcodeFrom(op));
    }
    final res = b.takeBytes();

    return res;
  }
}