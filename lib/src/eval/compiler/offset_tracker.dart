import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/src/eval/runtime/ops/all_ops.dart';

class OffsetTracker {
  OffsetTracker(this.context);

  final Map<int, DeferredOrOffset> _deferredOffsets = {};
  CompilerContext context;

  void setOffset(int location, DeferredOrOffset offset) {
    _deferredOffsets[location] = offset;
  }

  List<EvcOp> apply(List<EvcOp> source) {
    _deferredOffsets.forEach((pos, offset) {
      final op = source[pos];
      if (op is Call) {
        final resolvedOffset = context.topLevelDeclarationPositions[offset.file!]![offset.name!]!;
        final newOp = Call.make(resolvedOffset);
        source[pos] = newOp;
      }
    });
    return source;
  }
}

/// An structure pointing to a function that may or may not have been generated already. If it hasn't, the exact program
/// offset will be resolved later by the [OffsetTracker]
class DeferredOrOffset {
  DeferredOrOffset({this.offset, this.file, this.name, this.className, this.methodType});

  final int? offset;
  final int? file;
  final String? className;
  final int? methodType;
  final String? name;

  factory DeferredOrOffset.lookupStatic(CompilerContext ctx, int library, String parent, String name) {
    if (ctx.topLevelDeclarationPositions[library]?.containsKey('$parent.$name') ?? false) {
      return DeferredOrOffset(
          file: library, offset: ctx.topLevelDeclarationPositions[library]!['$parent.$name'], name: '$parent.$name');
    } else {
      return DeferredOrOffset(file: library, name: '$parent.$name');
    }
  }

  @override
  String toString() {
    return 'DeferredOrOffset{offset: $offset, file: $file, name: $name}';
  }
}
