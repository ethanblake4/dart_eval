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

  List<DbcOp> apply(List<DbcOp> source) {
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

class DeferredOrOffset {
  DeferredOrOffset({this.offset, this.file, this.name});

  final int? offset;
  final int? file;
  final String? name;

  @override
  String toString() {
    return 'DeferredOrOffset{offset: $offset, file: $file, name: $name}';
  }
}