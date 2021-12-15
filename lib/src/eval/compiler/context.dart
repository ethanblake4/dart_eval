import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/source.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/runtime/ops/all_ops.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

import 'offset_tracker.dart';

class CompilerContext {
  CompilerContext(this.sourceFile);

  final out = <DbcOp>[];
  int library = 0;
  int position = 0;
  int scopeFrameOffset = 0;
  ClassDeclaration? currentClass = null;
  List<List<AstNode>> scopeNodes = [];
  List<Map<String, Variable>> locals = [];
  Map<int, Map<String, Declaration>> topLevelDeclarationsMap = {};
  Map<int, Map<String, Map<String, Declaration>>> instanceDeclarationsMap = {};
  late OffsetTracker offsetTracker = OffsetTracker(this);
  Map<int, Map<String, TypeRef>> visibleTypes = {};
  Map<int, Map<String, DeclarationOrPrefix>> visibleDeclarations = {};
  Map<int, Map<String, int>> topLevelDeclarationPositions = {};
  Map<int, Map<String, List<Map<String, int>>>> instanceDeclarationPositions = {};
  List<int> allocNest = [0];
  int sourceFile;

  int pushOp(DbcOp op, int length) {
    out.add(op);
    position += length;
    return out.length - 1;
  }

  int rewriteOp(int where, DbcOp newOp, int lengthAdjust) {
    out[where] = newOp;
    position += lengthAdjust;
    return where;
  }

  void resetStack({int position = 0}) {
    allocNest = [position];
    scopeFrameOffset = position;
  }

  void popCurrentStack() {
    final nestCount = allocNest.removeLast();
    for (var i = 0; i < nestCount; i++) {
      pushOp(Pop.make(), Pop.LEN);
      scopeFrameOffset--;
    }
  }

  Variable? lookupLocal(String name) {
    for (var i = locals.length - 1; i >= 0; i--) {
      if (locals[i].containsKey(name)) {
        return locals[i][name]!..frameIndex = i;
      }
    }
  }
}