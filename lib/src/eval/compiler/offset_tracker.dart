import 'package:dart_eval/src/eval/compiler/context.dart';

/// A function ID or declaration reference resolved when the backend links calls.
class DeferredOrOffset {
  DeferredOrOffset({
    this.offset,
    this.file,
    this.name,
    this.className,
    this.methodType,
    this.targetName,
  }) : assert(offset != null || name != null);

  final int? offset;
  final int? file;
  final String? className;
  final int? methodType;
  final String? name;
  final String? targetName;

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
    } else {
      return DeferredOrOffset(file: library, name: '$parent.$name');
    }
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
      other.name == name;

  @override
  int get hashCode =>
      offset.hashCode ^ className.hashCode ^ file.hashCode ^ name.hashCode;
}
