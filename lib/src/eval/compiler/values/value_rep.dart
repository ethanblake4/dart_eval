import 'package:dart_eval/src/eval/compiler/backend/representation.dart'
    show representationForType;
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/ir/representation.dart';
import 'package:dart_eval/src/eval/shared/types.dart';

/// The physical representation of a [Variable]'s SSA slot — what actually
/// sits in the slot, independent of its static type.
///
/// Scalars live in their own register banks; everything else shares the
/// object bank, where `boxed` means a `$Value` wrapper and the `native*`
/// reps are raw Dart objects (`null`, `List`, `Map`, `Set`, and — for
/// records, `num`, nullable scalars, `Object`/`dynamic`, and evaluated
/// class instances — whatever other raw object lands there).
enum ValueRep {
  int(MachineRepresentation.integer),
  double(MachineRepresentation.doublePrecision),
  bool(MachineRepresentation.boolean),
  string(MachineRepresentation.string),
  nativeNull(MachineRepresentation.object),
  nativeList(MachineRepresentation.object),
  nativeMap(MachineRepresentation.object),
  nativeSet(MachineRepresentation.object),
  nativeObject(MachineRepresentation.object),
  boxed(MachineRepresentation.object);

  const ValueRep(this.bank);

  /// The register bank this representation occupies.
  final MachineRepresentation bank;
}

extension ValueRepX on ValueRep {
  bool get isBoxed => this == ValueRep.boxed;

  bool get isNativeCollection =>
      this == ValueRep.nativeList ||
      this == ValueRep.nativeMap ||
      this == ValueRep.nativeSet;
}

/// Derives a [Variable]'s [ValueRep] from its type and register bank.
///
/// The bank selects a scalar rep directly; object-bank storage is `boxed`
/// (a `$Value` wrapper) — raw natives only ever describe unboxed
/// temporaries, reached via [unboxedRepOf] or an explicit `rep:` pin on a
/// native-producing op. `Null` is the one exception: its value is the null
/// literal itself, so it stores as [ValueRep.nativeNull].
ValueRep repForType(TypeRef type, MachineRepresentation representation) {
  return switch (representation) {
    MachineRepresentation.integer => ValueRep.int,
    MachineRepresentation.doublePrecision => ValueRep.double,
    MachineRepresentation.boolean => ValueRep.bool,
    MachineRepresentation.string => ValueRep.string,
    MachineRepresentation.object =>
      type.isSpec(CoreTypes.nullType) ? ValueRep.nativeNull : ValueRep.boxed,
  };
}

/// The rep a value of [type] has in its natural unboxed state — scalars in
/// their own banks, raw natives for object-bank types. Ignores ABI
/// boundary conventions; [Abi] owns those.
ValueRep unboxedRepOf(TypeRef type) {
  final bank = representationForType(type);
  if (bank != MachineRepresentation.object) return repForType(type, bank);
  if (type.isDartCore) {
    switch (type.name) {
      case 'Null':
        return ValueRep.nativeNull;
      case 'List':
        return ValueRep.nativeList;
      case 'Map':
        return ValueRep.nativeMap;
      case 'Set':
        return ValueRep.nativeSet;
    }
  }
  return ValueRep.nativeObject;
}
