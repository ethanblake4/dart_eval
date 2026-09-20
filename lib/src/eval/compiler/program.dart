import 'dart:convert';

import 'dart:typed_data';

import 'package:dart_eval/src/eval/compiler/model/override_spec.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart' show Runtime;
import 'package:dart_eval/src/eval/runtime/typed/typed_program.dart';
import 'package:dart_eval/src/eval/shared/runtime_type_descriptor.dart';

/// A Program is a compiled EVC bytecode program that can be executed using
/// a [Runtime].
class Program {
  /// Read shared runtime metadata and its typed bytecode payload.
  factory Program.read(ByteBuffer buffer) {
    final reader = _ProgramReader(buffer);
    reader.readHeader();
    final types = _list(
      reader.readMeta(),
    ).map((value) => _list(value).map(_integer).toSet()).toList();
    final typeDescriptors = _list(
      reader.readMeta(),
    ).map((value) => _list(value).map(_integer).toList()).toList();
    final typeIds = _intMap(reader.readMeta(), _stringIntMap);
    final libraries = _stringIntMap(reader.readMeta());
    final functions = _intMap(reader.readMeta(), _stringIntMap);
    final constants = _list(reader.readMeta()).map((value) {
      if (value == null) {
        throw const FormatException('Constant pool entries cannot be null');
      }
      return value;
    }).toList();
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
      typeIds,
      types,
      reader.readTypedProgram(),
      libraries,
      functions,
      constants,
      enums,
      overrides,
      typeDescriptors: typeDescriptors,
    );
  }

  /// Construct a [Program] with bytecode and metadata.
  Program(
    this.typeIds,
    this.typeTypes,
    this.typedProgram,
    this.bridgeLibraryMappings,
    this.bridgeFunctionMappings,
    this.constantPool,
    this.enumMappings,
    this.overrideMap, {
    this.typeDescriptors = const [],
  }) {
    _validateTypes();
  }

  void _validateTypes() {
    final count = typeTypes.length;
    for (final supertypes in typeTypes) {
      if (supertypes.any((id) => id < 0 || id >= count)) {
        throw const FormatException('Invalid runtime supertype reference');
      }
    }
    for (final library in typeIds.values) {
      if (library.values.any((id) => id < 0 || id >= count)) {
        throw const FormatException('Invalid runtime type ID');
      }
    }
    if (typedProgram.runtimeTypeReferences.any((id) => id < 0 || id >= count)) {
      throw const FormatException('Invalid executable runtime type reference');
    }
    for (final index in typedProgram.callTypeArgumentConstants) {
      if (index < 0 || index >= constantPool.length) {
        throw const FormatException('Invalid call type-argument constant');
      }
      final value = constantPool[index];
      if (value is! List ||
          value.any((id) => id is! int || id < 0 || id >= count)) {
        throw const FormatException('Invalid call type-argument descriptors');
      }
    }
    if (typeDescriptors.isEmpty) return;
    if (typeDescriptors.length != count) {
      throw const FormatException('Mismatched runtime type descriptor table');
    }
    Iterable<int> referencedTypes(List<int> descriptor) sync* {
      if (descriptor.length < 3 || descriptor[2] >= 0) {
        yield* descriptor.skip(2);
        return;
      }
      switch (descriptor[2]) {
        case RuntimeTypeDescriptorTag.record:
          if (descriptor.length < 5) {
            throw const FormatException('Invalid record type descriptor');
          }
          final positional = descriptor[3], named = descriptor[4];
          if (positional < 0 ||
              named < 0 ||
              descriptor.length != 5 + positional + named * 2) {
            throw const FormatException('Invalid record type descriptor');
          }
          yield* descriptor.skip(5).take(positional);
          String? previousName;
          for (var i = 5 + positional; i < descriptor.length; i += 2) {
            if (descriptor[i] < 0 || descriptor[i] >= constantPool.length) {
              throw const FormatException('Invalid record field name');
            }
            final name = constantPool[descriptor[i]];
            if (name is! String ||
                (previousName != null && previousName.compareTo(name) >= 0)) {
              throw const FormatException(
                'Record field names must be unique and sorted',
              );
            }
            previousName = name;
            yield descriptor[i + 1];
          }
        case RuntimeTypeDescriptorTag.function:
          if (descriptor.length < 7) {
            throw const FormatException('Invalid function type descriptor');
          }
          final required = descriptor[4], positional = descriptor[5];
          final named = descriptor[6];
          if (required < 0 ||
              required > positional ||
              named < 0 ||
              descriptor.length != 7 + positional + named * 3) {
            throw const FormatException('Invalid function type descriptor');
          }
          yield descriptor[3];
          yield* descriptor.skip(7).take(positional);
          String? previousName;
          for (var i = 7 + positional; i < descriptor.length; i += 3) {
            if (descriptor[i] < 0 ||
                descriptor[i] >= constantPool.length ||
                (descriptor[i + 1] != 0 && descriptor[i + 1] != 1)) {
              throw const FormatException('Invalid named function parameter');
            }
            final name = constantPool[descriptor[i]];
            if (name is! String ||
                (previousName != null && previousName.compareTo(name) >= 0)) {
              throw const FormatException(
                'Function parameter names must be unique and sorted',
              );
            }
            previousName = name;
            yield descriptor[i + 2];
          }
        case RuntimeTypeDescriptorTag.typeParameter:
          if (descriptor.length != 6 ||
              descriptor[4] < 0 ||
              descriptor[3] <
                  RuntimeTypeDescriptorTag.callableTypeParameterOwner) {
            throw const FormatException('Invalid type parameter descriptor');
          }
          if (descriptor[3] >= 0) yield descriptor[3];
          yield descriptor[5];
        default:
          throw const FormatException('Unknown runtime type descriptor tag');
      }
    }

    for (final descriptor in typeDescriptors) {
      if (descriptor.length < 2 ||
          descriptor[0] < 0 ||
          descriptor[0] >= count ||
          (descriptor[1] != 0 && descriptor[1] != 1) ||
          referencedTypes(descriptor).any((id) => id < 0 || id >= count)) {
        throw const FormatException('Invalid runtime type descriptor');
      }
    }
    final state = List<int>.filled(count, 0);
    bool cyclic(int id) {
      if (state[id] == 1) return true;
      if (state[id] == 2) return false;
      state[id] = 1;
      for (final argument in referencedTypes(typeDescriptors[id])) {
        if (cyclic(argument)) return true;
      }
      state[id] = 2;
      return false;
    }

    for (var id = 0; id < count; id++) {
      if (cyclic(id)) {
        throw const FormatException('Cyclic runtime type descriptor');
      }
    }
  }

  /// The ordered list of type supertype sets used in the program, with the index
  /// corresponding to the type ID.
  List<Set<int>> typeTypes;

  /// Runtime type descriptors encoded as nominal ID, nullable flag, then type
  /// argument descriptor IDs.
  List<List<int>> typeDescriptors;

  /// Mappings from type specs to IDs.
  Map<int, Map<String, int>> typeIds;

  /// Mappings from library URIs to internal library IDs.
  Map<String, int> bridgeLibraryMappings;

  /// Mappings from bridge function names to internal InvokeExternal IDs.
  Map<int, Map<String, int>> bridgeFunctionMappings;

  /// The program's constant pool.
  List<Object> constantPool;

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

    _writeMetaBlock(b, [for (final t in typeTypes) t.toList()]);
    _writeMetaBlock(b, typeDescriptors);
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
