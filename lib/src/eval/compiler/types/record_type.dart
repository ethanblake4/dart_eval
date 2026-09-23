import '../type.dart';

/// A record type — `(<T...>, {name: T...})`. Replaces the legacy
/// `TypeRef(-1, '@record<...>', recordFields: ...)` encoding: the canonical
/// name and the `recordFields` list are derived from [positional]/[named]
/// at construction so unported readers keep working.
final class RecordTypeRef extends TypeRef {
  factory RecordTypeRef(
    List<TypeRef> positional,
    Map<String, TypeRef> named, {
    bool nullable = false,
  }) {
    final sorted = _sortedByName(named);
    final fields = <RecordParameterType>[
      for (var i = 0; i < positional.length; i++)
        RecordParameterType('\$${i + 1}', positional[i], false),
      for (final entry in sorted.entries)
        RecordParameterType(entry.key, entry.value, true),
    ];
    return RecordTypeRef._(
      List.unmodifiable(positional),
      Map.unmodifiable(sorted),
      TypeRef.recordTypeName(fields),
      fields,
      nullable: nullable,
    );
  }

  const RecordTypeRef._(
    this.positional,
    this.named,
    String name,
    List<RecordParameterType> fields, {
    super.nullable,
  }) : super(-1, name, recordFields: fields);

  /// Positional fields in declaration order.
  final List<TypeRef> positional;

  /// Named fields in canonical (name-sorted) order.
  final Map<String, TypeRef> named;

  static Map<String, TypeRef> _sortedByName(Map<String, TypeRef> named) {
    final entries = named.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return {for (final entry in entries) entry.key: entry.value};
  }
}
