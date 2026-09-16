import 'dart:typed_data';

import 'typed_function.dart';
import 'typed_class.dart';
import 'typed_call_site.dart';
import 'typed_program.dart';
import 'typed_export.dart';
import 'typed_external_call.dart';
import 'typed_closure_descriptor.dart';

/// Versioned little-endian format, separate from the generic register format.
abstract final class TypedCodec {
  static const magic = 0x54564544; // DEVT
  static const version = 109;

  static ByteData write(TypedProgram program) {
    final objects = _writeObjects(program.objects);
    final metadata = _writeMetadata(program);
    final result = ByteData(
      64 +
          program.functions.fold<int>(
            0,
            (size, f) => size + 29 + f.argumentKinds.length,
          ) +
          program.integers.length * 8 +
          program.doubles.length * 8 +
          objects.length +
          metadata.length +
          program.code.length,
    );
    var offset = 0;
    void u32(int value) {
      result.setUint32(offset, value, Endian.little);
      offset += 4;
    }

    u32(magic);
    u32(version);
    u32(program.entryFunction);
    u32(program.functions.length);
    u32(program.integers.length);
    u32(program.doubles.length);
    u32(program.code.length);
    u32(program.objects.length);
    u32(objects.length);
    u32(program.classes.length);
    u32(program.callSites.length);
    u32(metadata.length);
    u32(program.exports.length);
    u32(program.externalCalls.length);
    u32(program.closures.length);
    u32(program.closureCalls.length);
    for (final function in program.functions) {
      for (final value in function.layout) {
        u32(value);
      }
      u32(function.argumentKinds.length);
      result.setUint8(offset++, function.resultKind?.index ?? 255);
      for (final kind in function.argumentKinds) {
        result.setUint8(offset++, kind.index);
      }
    }
    result.buffer.asUint8List(offset, metadata.length).setAll(0, metadata);
    offset += metadata.length;
    for (final value in program.integers) {
      result.setInt64(offset, value, Endian.little);
      offset += 8;
    }
    for (final value in program.doubles) {
      result.setFloat64(offset, value, Endian.little);
      offset += 8;
    }
    result.buffer.asUint8List(offset, objects.length).setAll(0, objects);
    offset += objects.length;
    result.buffer.asUint8List(offset).setAll(0, program.code);
    return result;
  }

  static TypedProgram read(ByteBuffer buffer) {
    final input = ByteData.view(buffer);
    if (input.lengthInBytes < 64) {
      throw const FormatException('Truncated typed program header');
    }
    var offset = 0;
    int u32() {
      final value = input.getUint32(offset, Endian.little);
      offset += 4;
      return value;
    }

    if (u32() != magic || u32() != version) {
      throw const FormatException('Unsupported typed bytecode format');
    }
    final entry = u32();
    final functionCount = u32(), integerCount = u32(), doubleCount = u32();
    final codeLength = u32();
    final objectCount = u32(), objectLength = u32();
    final classCount = u32(), callSiteCount = u32(), metadataLength = u32();
    final exportCount = u32(), externalCallCount = u32();
    final closureCount = u32(), closureCallCount = u32();
    final sectionsLength =
        integerCount * 8 +
        doubleCount * 8 +
        objectLength +
        codeLength +
        metadataLength;
    final minimumLength = 64 + functionCount * 29 + sectionsLength;
    if (functionCount == 0 ||
        functionCount > 65536 ||
        classCount > 65536 ||
        callSiteCount > 65536 ||
        externalCallCount > 65536 ||
        closureCount > 65536 ||
        closureCallCount > 65536 ||
        minimumLength > input.lengthInBytes ||
        objectCount > objectLength) {
      throw const FormatException('Invalid typed bytecode section lengths');
    }
    final functions = <TypedFunction>[];
    for (var i = 0; i < functionCount; i++) {
      if (offset + 29 > input.lengthInBytes - sectionsLength) {
        throw const FormatException('Truncated typed function layout');
      }
      final layout = List.generate(6, (_) => u32());
      final kindCount = u32();
      final resultTag = input.getUint8(offset++);
      if (resultTag != 255 && resultTag >= TypedArgumentKind.values.length) {
        throw const FormatException('Invalid result representation');
      }
      if (kindCount > 65544 ||
          kindCount > input.lengthInBytes - sectionsLength - offset) {
        throw const FormatException('Invalid argument representation count');
      }
      final kinds = <TypedArgumentKind>[];
      for (var k = 0; k < kindCount; k++) {
        final kind = input.getUint8(offset++);
        if (kind >= TypedArgumentKind.values.length) {
          throw FormatException('Unknown argument representation $kind');
        }
        kinds.add(TypedArgumentKind.values[kind]);
      }
      functions.add(
        TypedFunction(
          layout[0],
          intSpillCount: layout[1],
          doubleSpillCount: layout[2],
          boolSpillCount: layout[3],
          objectSpillCount: layout[4],
          objectOutgoingCount: layout[5],
          argumentKinds: List.unmodifiable(kinds),
          resultKind: resultTag == 255
              ? null
              : TypedArgumentKind.values[resultTag],
        ),
      );
    }
    if (offset + sectionsLength != input.lengthInBytes) {
      throw const FormatException('Invalid typed bytecode section lengths');
    }
    final (
      classes,
      callSites,
      exports,
      externalCalls,
      closures,
      closureCalls,
    ) = _readMetadata(
      ByteData.view(buffer, offset, metadataLength),
      classCount,
      callSiteCount,
      exportCount,
      externalCallCount,
      closureCount,
      closureCallCount,
    );
    offset += metadataLength;
    final integers = List.generate(integerCount, (_) {
      final value = input.getInt64(offset, Endian.little);
      offset += 8;
      return value;
    });
    final doubles = List.generate(doubleCount, (_) {
      final value = input.getFloat64(offset, Endian.little);
      offset += 8;
      return value;
    });
    final objects = _readObjects(
      ByteData.view(buffer, offset, objectLength),
      objectCount,
    );
    offset += objectLength;
    return TypedProgram(
      buffer.asUint8List(offset, codeLength),
      integers: integers,
      doubles: doubles,
      objects: objects,
      functions: functions,
      classes: classes,
      callSites: callSites,
      exports: exports,
      externalCalls: externalCalls,
      closures: closures,
      closureCalls: closureCalls,
      entryFunction: entry,
    );
  }

  static Uint8List _writeMetadata(TypedProgram program) {
    final bytes = BytesBuilder(copy: false);
    void u32(int value) {
      bytes.add(
        (ByteData(4)..setUint32(0, value, Endian.little)).buffer.asUint8List(),
      );
    }

    void string(String value) {
      u32(value.length);
      final data = ByteData(value.length * 2);
      for (var i = 0; i < value.length; i++) {
        data.setUint16(i * 2, value.codeUnitAt(i), Endian.little);
      }
      bytes.add(data.buffer.asUint8List());
    }

    void members(Map<String, int> values) {
      u32(values.length);
      for (final entry in values.entries) {
        string(entry.key);
        u32(entry.value);
      }
    }

    for (final type in program.classes) {
      string(type.name);
      string(type.library);
      u32(type.valueCount);
      members(type.methods);
      members(type.getters);
      members(type.setters);
    }
    for (final site in program.callSites) {
      string(site.name);
      u32(site.argumentCount);
      u32(site.kind.index);
    }
    for (final declaration in program.exports) {
      string(declaration.library);
      string(declaration.name);
      u32(declaration.functionId);
      u32(declaration.parameters.length);
      for (final parameter in declaration.parameters) {
        string(parameter.name);
        u32((parameter.isRequired ? 1 : 0) | (parameter.nullable ? 2 : 0));
        string(parameter.typeName);
        string(parameter.typeLibrary);
        final value = _writeObjects([parameter.defaultValue]);
        u32(value.length);
        bytes.add(value);
      }
    }
    for (final call in program.externalCalls) {
      u32(call.externalFunctionId);
      u32(call.argumentCount);
    }
    void strings(List<String> values) {
      u32(values.length);
      for (final value in values) {
        string(value);
      }
    }

    void defaults(List<Object?> values) {
      final data = _writeObjects(values);
      u32(data.length);
      bytes.add(data);
    }

    for (final descriptor in program.closures) {
      u32(descriptor.functionId);
      u32(descriptor.captureCount);
      u32(descriptor.positionalCount);
      u32(descriptor.requiredPositional);
      u32(
        (descriptor.hasEnvironment ? 1 : 0) |
            (descriptor.boundReceiver ? 2 : 0),
      );
      strings(descriptor.namedNames);
      strings(descriptor.requiredNamed);
      defaults(descriptor.positionalDefaults);
      defaults(descriptor.namedDefaults);
    }
    for (final call in program.closureCalls) {
      u32(call.positionalCount);
      strings(call.namedNames);
    }
    return bytes.takeBytes();
  }

  static (
    List<TypedClass>,
    List<TypedCallSite>,
    List<TypedExport>,
    List<TypedExternalCall>,
    List<TypedClosureDescriptor>,
    List<TypedClosureCall>,
  )
  _readMetadata(
    ByteData input,
    int classCount,
    int callSiteCount,
    int exportCount,
    int externalCallCount,
    int closureCount,
    int closureCallCount,
  ) {
    var offset = 0;
    void require(int count) {
      if (count > input.lengthInBytes - offset) {
        throw const FormatException('Truncated typed class metadata');
      }
    }

    int u32() {
      require(4);
      final value = input.getUint32(offset, Endian.little);
      offset += 4;
      return value;
    }

    String string() {
      final length = u32();
      require(length * 2);
      final value = String.fromCharCodes(
        List.generate(
          length,
          (i) => input.getUint16(offset + i * 2, Endian.little),
        ),
      );
      offset += length * 2;
      return value;
    }

    Map<String, int> members() {
      final count = u32();
      require(count * 8);
      final values = <String, int>{};
      for (var i = 0; i < count; i++) {
        final name = string();
        if (values.containsKey(name)) {
          throw const FormatException('Duplicate typed class member');
        }
        values[name] = u32();
      }
      return values;
    }

    require(
      classCount * 24 +
          callSiteCount * 12 +
          exportCount * 16 +
          externalCallCount * 8 +
          closureCount * 36 +
          closureCallCount * 8,
    );
    final classes = <TypedClass>[];
    for (var i = 0; i < classCount; i++) {
      classes.add(
        TypedClass(
          string(),
          library: string(),
          valueCount: u32(),
          methods: members(),
          getters: members(),
          setters: members(),
        ),
      );
    }
    final callSites = <TypedCallSite>[];
    for (var i = 0; i < callSiteCount; i++) {
      final name = string(), argumentCount = u32();
      final kind = u32();
      if (kind >= TypedMemberKind.values.length) {
        throw const FormatException('Invalid typed member kind');
      }
      callSites.add(
        TypedCallSite(
          name,
          argumentCount: argumentCount,
          kind: TypedMemberKind.values[kind],
        ),
      );
    }
    final exports = <TypedExport>[];
    for (var i = 0; i < exportCount; i++) {
      final library = string(), name = string();
      final functionId = u32(), parameterCount = u32();
      if (parameterCount > 65544) {
        throw const FormatException('Invalid typed export parameter count');
      }
      require(parameterCount * 21);
      final parameters = <TypedExportParameter>[];
      for (var j = 0; j < parameterCount; j++) {
        final parameterName = string(), flags = u32();
        if (flags > 3) {
          throw const FormatException('Invalid typed parameter flags');
        }
        final typeName = string(), typeLibrary = string();
        final valueLength = u32();
        require(valueLength);
        final defaultValue = _readObjects(
          ByteData.view(
            input.buffer,
            input.offsetInBytes + offset,
            valueLength,
          ),
          1,
        ).single;
        offset += valueLength;
        parameters.add(
          TypedExportParameter(
            parameterName,
            isRequired: flags & 1 != 0,
            nullable: flags & 2 != 0,
            typeName: typeName,
            typeLibrary: typeLibrary,
            defaultValue: defaultValue,
          ),
        );
      }
      exports.add(
        TypedExport(library, name, functionId, parameters: parameters),
      );
    }
    final externalCalls = <TypedExternalCall>[];
    for (var i = 0; i < externalCallCount; i++) {
      externalCalls.add(TypedExternalCall(u32(), u32()));
    }
    List<String> strings() {
      final count = u32();
      if (count > 65537) {
        throw const FormatException('Too many closure parameter names');
      }
      require(count * 4);
      return List.generate(count, (_) => string());
    }

    List<Object?> defaults(int count) {
      final length = u32();
      require(length);
      if (count > length) {
        throw const FormatException('Truncated closure defaults');
      }
      final values = _readObjects(
        ByteData.view(input.buffer, input.offsetInBytes + offset, length),
        count,
      );
      offset += length;
      return values;
    }

    final closures = <TypedClosureDescriptor>[];
    for (var i = 0; i < closureCount; i++) {
      final functionId = u32(),
          captureCount = u32(),
          positionalCount = u32(),
          requiredPositional = u32(),
          flags = u32();
      if (flags > 2 || positionalCount > 65537 || captureCount > 65536) {
        throw const FormatException('Invalid typed closure descriptor');
      }
      final namedNames = strings(), requiredNamed = strings();
      closures.add(
        TypedClosureDescriptor(
          functionId,
          captureCount: captureCount,
          positionalCount: positionalCount,
          requiredPositional: requiredPositional,
          hasEnvironment: flags & 1 != 0,
          boundReceiver: flags & 2 != 0,
          namedNames: namedNames,
          requiredNamed: requiredNamed,
          positionalDefaults: defaults(positionalCount),
          namedDefaults: defaults(namedNames.length),
        ),
      );
    }
    final closureCalls = <TypedClosureCall>[];
    for (var i = 0; i < closureCallCount; i++) {
      closureCalls.add(TypedClosureCall(u32(), namedNames: strings()));
    }
    if (offset != input.lengthInBytes) {
      throw const FormatException('Invalid typed class metadata length');
    }
    return (classes, callSites, exports, externalCalls, closures, closureCalls);
  }

  // Tags: null, false, true, int64, float64, UTF-16 string. Live objects
  // belong in runtime arguments; serializing them would lose their identity.
  static Uint8List _writeObjects(List<Object?> objects) {
    final bytes = BytesBuilder(copy: false);
    for (final value in objects) {
      switch (value) {
        case null:
          bytes.addByte(0);
        case bool():
          bytes.addByte(value ? 2 : 1);
        case int():
          bytes.addByte(3);
          final data = ByteData(8)..setInt64(0, value, Endian.little);
          bytes.add(data.buffer.asUint8List());
        case double():
          bytes.addByte(4);
          final data = ByteData(8)..setFloat64(0, value, Endian.little);
          bytes.add(data.buffer.asUint8List());
        case String():
          bytes.addByte(5);
          final data = ByteData(4 + value.length * 2)
            ..setUint32(0, value.length, Endian.little);
          for (var i = 0; i < value.length; i++) {
            data.setUint16(4 + i * 2, value.codeUnitAt(i), Endian.little);
          }
          bytes.add(data.buffer.asUint8List());
        default:
          throw UnsupportedError(
            'Typed bytecode cannot serialize ${value.runtimeType} object '
            'constants. Pass live objects through objectArguments instead.',
          );
      }
    }
    return bytes.takeBytes();
  }

  static List<Object?> _readObjects(ByteData input, int count) {
    var offset = 0;
    void require(int size) {
      if (size > input.lengthInBytes - offset) {
        throw const FormatException('Truncated typed object constant');
      }
    }

    final objects = <Object?>[];
    for (var i = 0; i < count; i++) {
      require(1);
      final tag = input.getUint8(offset++);
      switch (tag) {
        case 0:
          objects.add(null);
        case 1:
          objects.add(false);
        case 2:
          objects.add(true);
        case 3:
          require(8);
          objects.add(input.getInt64(offset, Endian.little));
          offset += 8;
        case 4:
          require(8);
          objects.add(input.getFloat64(offset, Endian.little));
          offset += 8;
        case 5:
          require(4);
          final length = input.getUint32(offset, Endian.little);
          offset += 4;
          require(length * 2);
          objects.add(
            String.fromCharCodes(
              List.generate(
                length,
                (i) => input.getUint16(offset + i * 2, Endian.little),
              ),
            ),
          );
          offset += length * 2;
        default:
          throw FormatException('Unknown typed object constant tag $tag');
      }
    }
    if (offset != input.lengthInBytes) {
      throw const FormatException('Invalid typed object section length');
    }
    return objects;
  }
}
