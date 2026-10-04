import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/member/member_name.dart';

/// A function ID or declaration reference resolved when the backend links
/// calls.
class DeferredOrOffset {
  DeferredOrOffset({
    this.offset,
    this.file,
    this.name,
    this.className,
    this.methodType,
  }) : assert(offset != null || name != null);

  final int? offset;
  final int? file;
  final String? className;
  final MemberKind? methodType;
  final String? name;

  /// Resolves a direct source call after declarations have been compiled.
  int? resolveFunctionId(CompilerContext ctx) {
    var id = offset;
    if (id == null && className != null) {
      final members = ctx.instanceDeclarationPositions[file]?[className];
      if (members != null) {
        final qualifiedName = name;
        final separator = qualifiedName?.lastIndexOf('::') ?? -1;
        final bareName =
            separator >= 0 &&
                qualifiedName!.substring(0, separator) ==
                    ctx.libraryUri(file!) &&
                qualifiedName.substring(separator + 2).startsWith('_')
            ? qualifiedName.substring(separator + 2)
            : null;
        final kind = methodType;
        final groups = kind == null
            ? members.values
            : [if (members[kind] != null) members[kind]!];
        for (final group in groups) {
          id ??= group[name];
        }
        // Own-library private declarations use bare keys; folded private
        // declarations retain their origin URI. Never erase a foreign URI.
        if (id == null && bareName != null) {
          for (final group in groups) {
            id ??= group[bareName];
          }
        }
      }
    }
    return id ?? ctx.topLevelDeclarationPositions[file]?[name];
  }

  factory DeferredOrOffset.lookupStatic(
    CompilerContext ctx,
    int library,
    String parent,
    String name,
  ) {
    if (ctx.topLevelDeclarationPositions[library]?.containsKey(
          '$parent.$name',
        ) ??
        false) {
      return DeferredOrOffset(
        file: library,
        offset: ctx.topLevelDeclarationPositions[library]!['$parent.$name'],
        name: '$parent.$name',
      );
    }
    return DeferredOrOffset(file: library, name: '$parent.$name');
  }

  @override
  String toString() {
    return 'DeferredOrOffset{offset: $offset, file: $file, name: $name}';
  }

  @override
  bool operator ==(Object other) =>
      other is DeferredOrOffset &&
      other.offset == offset &&
      other.file == file &&
      other.className == className &&
      other.methodType == methodType &&
      other.name == name;

  @override
  int get hashCode =>
      offset.hashCode ^
      className.hashCode ^
      methodType.hashCode ^
      file.hashCode ^
      name.hashCode;
}
