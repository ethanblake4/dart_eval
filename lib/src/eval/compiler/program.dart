import 'dart:convert';

import 'dart:typed_data';

import 'package:dart_eval/src/eval/compiler/model/override_spec.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart' show Runtime;
import 'package:dart_eval/src/eval/runtime/type.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_program.dart';

/// A Program is a compiled EVC bytecode program that can be executed using
/// a [Runtime].
class Program {
  /// Read shared runtime metadata and its typed bytecode payload.
  factory Program.read(ByteBuffer buffer) {
    final reader = _ProgramReader(buffer);
    reader.readHeader();
    final declarations = _intMap(reader.readMeta(), _stringIntMap);
    final instances = _intMap(
      reader.readMeta(),
      (value) => _stringMap(value, (value) {
        final fields = _list(value);
        if (fields.length != 4) {
          throw const FormatException('Invalid instance declaration');
        }
        return <Object>[
          _stringIntMap(fields[0]),
          _stringIntMap(fields[1]),
          _stringIntMap(fields[2]),
          _integer(fields[3]),
        ];
      }),
    );
    final types = _list(
      reader.readMeta(),
    ).map((value) => _list(value).map(_integer).toSet()).toList();
    final typeIds = _intMap(reader.readMeta(), _stringIntMap);
    final libraries = _stringIntMap(reader.readMeta());
    final functions = _intMap(reader.readMeta(), _stringIntMap);
    final constants = _list(reader.readMeta()).map((value) {
      if (value == null) {
        throw const FormatException('Constant pool entries cannot be null');
      }
      return value;
    }).toList();
    final runtimeTypes = _list(reader.readMeta()).map(_runtimeType).toList();
    final globals = _list(reader.readMeta()).map(_integer).toList();
    final enums = _intMap(
      reader.readMeta(),
      (value) => _stringMap(value, _stringIntMap),
    );
    final overrides = _stringMap(reader.readMeta(), (value) {
      final fields = _list(value);
      if (fields.length != 2 || (fields[1] != null && fields[1] is! String)) {
        throw const FormatException('Invalid runtime override');
      }
      return OverrideSpec(_integer(fields[0]), fields[1] as String?);
    });
    return Program(
      declarations,
      instances,
      typeIds,
      types,
      reader.readTypedProgram(),
      libraries,
      functions,
      constants,
      runtimeTypes,
      globals,
      enums,
      overrides,
    );
  }

  /// Construct a [Program] with bytecode and metadata.
  Program(
    this.topLevelDeclarations,
    this.instanceDeclarations,
    this.typeIds,
    //this.typeNames,
    this.typeTypes,
    this.typedProgram,
    this.bridgeLibraryMappings,
    this.bridgeFunctionMappings,
    this.constantPool,
    this.runtimeTypes,
    this.globalInitializers,
    this.enumMappings,
    this.overrideMap,
  );

  /// Typed function IDs of the program's top-level declarations.
  Map<int, Map<String, int>> topLevelDeclarations;

  /// Typed function IDs of the program's instance-level declarations.
  ///
  /// Example instance declaration:
  /// 1: { // file
  ///    "SomeClass": [
  ///       { "someProp": 221 }, // getters
  ///       { "someProp": 254 }, // setters
  ///       { "someMethod": 288 }, // methods
  ///    ]
  /// }
  Map<int, Map<String, List>> instanceDeclarations;

  /// The ordered list of type names used in the program, with the index
  /// corresponding to the type ID.
  //List<String> typeNames;

  /// The ordered list of type supertype sets used in the program, with the index
  /// corresponding to the type ID.
  List<Set<int>> typeTypes;

  /// Mappings from type specs to IDs.
  Map<int, Map<String, int>> typeIds;

  /// Mappings from library URIs to internal library IDs.
  Map<String, int> bridgeLibraryMappings;

  /// Mappings from bridge function names to internal InvokeExternal IDs.
  Map<int, Map<String, int>> bridgeFunctionMappings;

  /// The program's constant pool.
  List<Object> constantPool;
  List<RuntimeTypeSet> runtimeTypes;

  /// Typed function IDs of initializers for global variables.
  List<int> globalInitializers;

  /// Mappings from enums to globals.
  Map<int, Map<String, Map<String, int>>> enumMappings;

  /// Runtime override map
  Map<String, OverrideSpec> overrideMap;

  /// The executable typed bytecode, including exported declarations.
  final TypedProgram typedProgram;

  /// Write the program to a [Uint8List], to be loaded by a [Runtime].
  Uint8List write() {
    final b = BytesBuilder(copy: false);

    b.add([0x58, 0x56, 0x43]); // XVC
    b.add(
      (ByteData(2)..setUint16(0, Runtime.versionCode)).buffer.asUint8List(),
    );

    _writeMetaBlock(
      b,
      topLevelDeclarations.map((key, value) => MapEntry(key.toString(), value)),
    );
    _writeMetaBlock(
      b,
      instanceDeclarations.map((key, value) => MapEntry(key.toString(), value)),
    );
    //_writeMetaBlock(b, typeNames);
    _writeMetaBlock(b, [for (final t in typeTypes) t.toList()]);
    _writeMetaBlock(
      b,
      typeIds.map((key, value) => MapEntry(key.toString(), value)),
    );
    _writeMetaBlock(b, bridgeLibraryMappings);
    _writeMetaBlock(
      b,
      bridgeFunctionMappings.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
    );
    _writeMetaBlock(b, constantPool);
    _writeMetaBlock(b, [for (final rt in runtimeTypes) rt.toJson()]);
    _writeMetaBlock(b, globalInitializers);
    _writeMetaBlock(
      b,
      enumMappings.map((key, value) => MapEntry(key.toString(), value)),
    );
    _writeMetaBlock(
      b,
      overrideMap.map(
        (key, value) => MapEntry(key, [value.offset, value.versionConstraint]),
      ),
    );

    final payload = typedProgram.write().buffer.asUint8List();
    _writeInt32(b, payload.length);
    b.add(payload);
    final res = b.takeBytes();

    return res;
  }

  void _writeMetaBlock(BytesBuilder builder, Object block) {
    final encodedBlock = utf8.encode(json.encode(block));
    _writeInt32(builder, encodedBlock.length);
    builder.add(encodedBlock);
  }
}

void _writeInt32(BytesBuilder builder, int value) {
  if (value < -0x80000000 || value > 0x7fffffff) {
    throw RangeError.range(value, -0x80000000, 0x7fffffff, 'instruction word');
  }
  builder.add((ByteData(4)..setInt32(0, value)).buffer.asUint8List());
}

List<Object?> _list(Object? value) {
  if (value is! List<Object?>) {
    throw const FormatException('Expected a metadata list');
  }
  return value;
}

int _integer(Object? value) {
  if (value is! int) throw const FormatException('Expected a metadata integer');
  return value;
}

Map<String, T> _stringMap<T>(Object? value, T Function(Object?) decode) {
  if (value is! Map<String, Object?>) {
    throw const FormatException('Expected a metadata object');
  }
  return value.map((key, value) => MapEntry(key, decode(value)));
}

Map<String, int> _stringIntMap(Object? value) => _stringMap(value, _integer);

Map<int, T> _intMap<T>(Object? value, T Function(Object?) decode) {
  return _stringMap(value, decode).map((key, value) {
    final id = int.tryParse(key);
    if (id == null || id.toString() != key) {
      throw FormatException('Invalid metadata ID: $key');
    }
    return MapEntry(id, value);
  });
}

RuntimeTypeSet _runtimeType(Object? value) {
  final fields = _list(value);
  if (fields.length != 3) throw const FormatException('Invalid runtime type');
  return RuntimeTypeSet(
    _integer(fields[0]),
    _list(fields[1]).map(_integer).toSet(),
    _list(fields[2]).map(_runtimeType).toList(),
  );
}

class _ProgramReader {
  _ProgramReader(ByteBuffer buffer) : data = ByteData.view(buffer);

  final ByteData data;
  int offset = 0;

  void require(int length) {
    if (length < 0 || length > data.lengthInBytes - offset) {
      throw FormatException('Truncated or invalid XVC data at byte $offset');
    }
  }

  void readHeader() {
    require(5);
    if (data.getUint8(0) != 0x58 ||
        data.getUint8(1) != 0x56 ||
        data.getUint8(2) != 0x43) {
      throw const FormatException('Not an XVC file');
    }
    final version = data.getUint16(3);
    if (version != Runtime.versionCode) {
      throw FormatException(
        'Unsupported XVC version $version; expected ${Runtime.versionCode}',
      );
    }
    offset = 5;
  }

  int readInt32() {
    require(4);
    final value = data.getInt32(offset);
    offset += 4;
    return value;
  }

  Object? readMeta() {
    final length = readInt32();
    require(length);
    final bytes = data.buffer.asUint8List(offset, length);
    offset += length;
    return jsonDecode(utf8.decode(bytes));
  }

  TypedProgram readTypedProgram() {
    final length = readInt32();
    require(length);
    if (length != data.lengthInBytes - offset) {
      throw const FormatException('Unexpected trailing XVC data');
    }
    final bytes = Uint8List.fromList(data.buffer.asUint8List(offset, length));
    offset += length;
    return TypedProgram.read(bytes.buffer);
  }
}
