import 'dart:convert';

import 'dart:typed_data';

import 'package:dart_eval/src/eval/runtime/runtime.dart' show Runtime;
import 'package:dart_eval/src/eval/runtime/ops/all_ops.dart';
import 'package:dart_eval/src/eval/runtime/type.dart';

class Program {
  Program(
      this.topLevelDeclarations,
      this.instanceDeclarations,
      this.typeNames,
      this.typeTypes,
      this.ops,
      this.bridgeLibraryMappings,
      this.bridgeFunctionMappings,
      this.constantPool,
      this.runtimeTypes,
      this.globalInitializers,
      this.enumMappings);

  Map<int, Map<String, int>> topLevelDeclarations;

  /// Example instance declaration:
  /// 1: { // file
  ///    "SomeClass": [
  ///       { "someProp": 221 }, // getters
  ///       { "someProp": 254 }, // setters
  ///       { "someMethod": 288 }, // methods
  ///    ]
  /// }
  Map<int, Map<String, List>> instanceDeclarations;
  List<String> typeNames;
  List<Set<int>> typeTypes;
  Map<String, int> bridgeLibraryMappings;
  Map<int, Map<String, int>> bridgeFunctionMappings;
  List<Object> constantPool;
  List<RuntimeTypeSet> runtimeTypes;
  List<int> globalInitializers;
  Map<int, Map<String, Map<String, int>>> enumMappings;

  List<EvcOp> ops;

  Uint8List write() {
    final b = BytesBuilder(copy: false);

    _writeMetaBlock(b, topLevelDeclarations.map((key, value) => MapEntry(key.toString(), value)));
    _writeMetaBlock(b, instanceDeclarations.map((key, value) => MapEntry(key.toString(), value)));
    _writeMetaBlock(b, typeNames);
    _writeMetaBlock(b, [for (final t in typeTypes) t.toList()]);
    _writeMetaBlock(b, bridgeLibraryMappings);
    _writeMetaBlock(b, bridgeFunctionMappings.map((key, value) => MapEntry(key.toString(), value)));
    _writeMetaBlock(b, constantPool);
    _writeMetaBlock(b, [for (final rt in runtimeTypes) rt.toJson()]);
    _writeMetaBlock(b, globalInitializers);
    _writeMetaBlock(b, enumMappings.map((key, value) => MapEntry(key.toString(), value)));

    for (final op in ops) {
      b.add(Runtime.opcodeFrom(op));
    }
    final res = b.takeBytes();

    return res;
  }

  void _writeMetaBlock(BytesBuilder builder, Object block) {
    final encodedBlock = utf8.encode(json.encode(block));
    builder.add(Evc.i32b(encodedBlock.length));
    builder.add(encodedBlock);
  }
}
