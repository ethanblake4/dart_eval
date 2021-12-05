import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/source.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

import 'offset_tracker.dart';

class CompilerContext {
  CompilerContext(this.sourceFile);

  int library = 0;
  int position = 0;
  int scopeFrameOffset = 0;
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
}