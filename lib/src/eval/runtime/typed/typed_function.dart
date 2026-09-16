/// Representation of an argument before assigning call registers.
enum TypedArgumentKind { integer, doublePrecision, boolean, string, object }

enum TypedRegisterBank { integer, doublePrecision, boolean, object }

/// A register location, or an element of the overflow list in object register C.
class TypedArgumentLocation {
  const TypedArgumentLocation(this.bank, this.index, {this.overflowIndex});

  final TypedRegisterBank bank;
  final int index;
  final int? overflowIndex;
}

/// The common calling convention used by the compiler and public entry adapter.
class TypedCallLayout {
  factory TypedCallLayout(List<TypedArgumentKind> kinds) {
    final counts = <TypedRegisterBank, int>{};
    final locations = List<TypedArgumentLocation?>.filled(kinds.length, null);
    final objectIndices = <int>[];
    for (var i = 0; i < kinds.length; i++) {
      final bank = switch (kinds[i]) {
        TypedArgumentKind.integer => TypedRegisterBank.integer,
        TypedArgumentKind.doublePrecision => TypedRegisterBank.doublePrecision,
        TypedArgumentKind.boolean => TypedRegisterBank.boolean,
        TypedArgumentKind.string ||
        TypedArgumentKind.object => TypedRegisterBank.object,
      };
      final index = counts[bank] ?? 0;
      if (bank != TypedRegisterBank.object && index < 2) {
        locations[i] = TypedArgumentLocation(bank, index);
        counts[bank] = index + 1;
      } else {
        objectIndices.add(i);
      }
    }
    final hasOverflow = objectIndices.length > 3;
    for (var i = 0; i < objectIndices.length; i++) {
      locations[objectIndices[i]] = TypedArgumentLocation(
        TypedRegisterBank.object,
        hasOverflow && i >= 2 ? 2 : i,
        overflowIndex: hasOverflow && i >= 2 ? i - 2 : null,
      );
    }
    return TypedCallLayout._(
      List.unmodifiable(locations.cast<TypedArgumentLocation>()),
      hasOverflow ? objectIndices.length - 2 : 0,
    );
  }

  const TypedCallLayout._(this.arguments, this.overflowCount);

  final List<TypedArgumentLocation> arguments;
  final int overflowCount;
}

/// Layout of a function's private storage and source-order argument signature.
/// Calls clobber registers; values live across calls belong in caller spills.
class TypedFunction {
  const TypedFunction(
    this.entry, {
    this.intSpillCount = 0,
    this.doubleSpillCount = 0,
    this.boolSpillCount = 0,
    this.objectSpillCount = 0,
    this.argumentKinds = const [],
    this.objectOutgoingCount = 0,
    this.resultKind = TypedArgumentKind.object,
  });

  final int entry;
  final int intSpillCount, doubleSpillCount, boolSpillCount, objectSpillCount;
  final List<TypedArgumentKind> argumentKinds;

  /// Null denotes a void result.
  final TypedArgumentKind? resultKind;

  /// Capacity of the single list used to stage overflow and host arguments.
  final int objectOutgoingCount;

  TypedCallLayout get callLayout => TypedCallLayout(argumentKinds);

  /// Validation needs the overflow size without allocating argument locations.
  int get argumentOverflowCount {
    var integers = 0, doubles = 0, booleans = 0, objects = 0;
    for (final kind in argumentKinds) {
      switch (kind) {
        case TypedArgumentKind.integer:
          if (++integers > 2) objects++;
        case TypedArgumentKind.doublePrecision:
          if (++doubles > 2) objects++;
        case TypedArgumentKind.boolean:
          if (++booleans > 2) objects++;
        case TypedArgumentKind.string || TypedArgumentKind.object:
          objects++;
      }
    }
    return objects > 3 ? objects - 2 : 0;
  }

  List<int> get layout => [
    entry,
    intSpillCount,
    doubleSpillCount,
    boolSpillCount,
    objectSpillCount,
    objectOutgoingCount,
  ];
}
