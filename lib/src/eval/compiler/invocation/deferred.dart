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
        final kind = methodType;
        if (kind != null) {
          id = members[kind]?[name];
        } else {
          for (final group in members.values) {
            id ??= group[name];
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
