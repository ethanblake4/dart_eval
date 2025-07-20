import 'package:collection/collection.dart';

class RuntimeType {
  const RuntimeType(this.type, this.typeArgs);
  final int type;
  final List<RuntimeType> typeArgs;

  factory RuntimeType.fromJson(List json) {
    return RuntimeType(
        json[0], [for (final ta in json[1]) RuntimeType.fromJson(ta)]);
  }

  List toJson() {
    return [
      type,
      [for (final ta in typeArgs) ta.toJson()]
    ];
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RuntimeType &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          typeArgs == other.typeArgs;

  @override
  int get hashCode => type.hashCode ^ typeArgs.hashCode;
}

/// Represents a type and all of the interfaces it conforms to
class RuntimeTypeSet {
  const RuntimeTypeSet(this.rt, this.types, this.typeArgs);

  static const _equality = DeepCollectionEquality();

  factory RuntimeTypeSet.fromJson(List json) {
    return RuntimeTypeSet(json[0], Set.from(json[1]),
        [for (final a in json[2]) RuntimeTypeSet.fromJson(a)]);
  }

  final int rt;
  final Set<int> types;
  final List<RuntimeTypeSet> typeArgs;

  bool isAssignableTo(RuntimeType type) {
    final ta = typeArgs;
    final tta = type.typeArgs;
    final len = ta.length;
    if (len != tta.length) {
      return false;
    }
    for (var i = 0; i < len; i++) {
      if (!ta[i].isAssignableTo(tta[i])) {
        return false;
      }
    }
    return types.contains(type.type);
  }

  List toJson() => [
        rt,
        types.toList(),
        [for (final a in typeArgs) a.toJson()]
      ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RuntimeTypeSet &&
          runtimeType == other.runtimeType &&
          rt == other.rt &&
          types == other.types &&
          DeepCollectionEquality().equals(typeArgs, other.typeArgs);

  @override
  int get hashCode =>
      rt.hashCode ^ _equality.hash(types) ^ _equality.hash(typeArgs);
}
