/// Which syntactic slot a member occupies — the `key` suffix and the
/// position-table index (`0` getter, `1` setter, `2` method/constructor).
enum MemberKind { method, getter, setter, constructor }

extension MemberKindPosition on MemberKind {
  /// The `instanceDeclarationPositions` list index for this kind.
  int get positionIndex => switch (this) {
    MemberKind.getter => 0,
    MemberKind.setter => 1,
    _ => 2,
  };
}

/// A member's identity for member-table keys: `name`, `name*g`, `name*s`,
/// `lib::_name`, and `unary-` for nullary `-`. Replaces `memberKey`,
/// `memberNameKey`, `instanceMethodKey`, and the scattered key formatting.
final class MemberName {
  const MemberName(this.name, this.kind, {this.privateLibraryUri});

  /// A method name, folding nullary `-` to `unary-` — `operator -` is the
  /// only arity-overloadable operator, so the analyzer's element name
  /// (`unary-`) keys it where binary `-` also exists.
  factory MemberName.method(String name, [int positionalArity = -1]) =>
      MemberName(
        name == '-' && positionalArity == 0 ? 'unary-' : name,
        MemberKind.method,
      );

  factory MemberName.getter(String name) =>
      MemberName(name, MemberKind.getter);
  factory MemberName.setter(String name) =>
      MemberName(name, MemberKind.setter);

  /// The source name: `foo`, `_foo`, or `unary-` for nullary `-`.
  final String name;
  final MemberKind kind;

  /// For a private member folded in from another library: its origin
  /// library's URI, so runtime privacy checks scope the key correctly.
  final String? privateLibraryUri;

  /// The kind-free name key — position tables and declared-member sets,
  /// where the slot/index already says which accessor is meant:
  /// `name`, `unary-`, or `uri::_name`.
  String get nameKey =>
      privateLibraryUri == null ? name : '$privateLibraryUri::$name';

  /// The declaration-map key: `name`, `name*g`, `name*s`, `uri::_name*g`.
  String get key => switch (kind) {
    MemberKind.getter => '$nameKey*g',
    MemberKind.setter => '$nameKey*s',
    _ => nameKey,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemberName &&
          name == other.name &&
          kind == other.kind &&
          privateLibraryUri == other.privateLibraryUri;

  @override
  int get hashCode => Object.hash(name, kind, privateLibraryUri);

  @override
  String toString() => 'MemberName($key)';
}
