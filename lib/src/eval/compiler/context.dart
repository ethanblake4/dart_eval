// ignore_for_file: body_might_complete_normally_nullable
import 'dart:math' as math;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/assembler/assembler.dart';
import 'package:dart_eval/src/eval/compiler/constant_pool.dart';
import 'package:dart_eval/src/eval/compiler/model/label.dart';
import 'package:dart_eval/src/eval/compiler/model/override_spec.dart';
import 'package:dart_eval/src/eval/compiler/optimizer/prescan.dart';
import 'package:dart_eval/src/eval/compiler/source.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/util.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/bridge/declaration.dart';
import 'package:dart_eval/src/eval/runtime/type.dart';

import 'offset_tracker.dart';

abstract class AbstractScopeContext {
  int get scopeFrameOffset;

  set scopeFrameOffset(int s);

  List<Map<String, Variable>> get locals;

  List<int> get allocNest;

  set allocNest(List<int> a);
}

mixin ScopeContext on Object implements AbstractScopeContext {
  final ControlFlowGraph cfg = ControlFlowGraph();

  @override
  int scopeFrameOffset = 0;
  @override
  List<Map<String, Variable>> locals = [];
  @override
  List<int> allocNest = [0];

  void beginAllocScope(
      {int existingAllocLen = 0, bool requireNonlinearAccess = false}) {
    allocNest.add(existingAllocLen);
    locals.add({});
  }

  int peekAllocPops({int popAdjust = 0}) {
    return allocNest.last;
  }

  int endAllocScope({bool popValues = true, int popAdjust = 0}) {
    locals.removeLast();
    final nestCount = allocNest.removeLast();
    return nestCount;
  }

  int endAllocScopeQuiet({bool popValues = true, int popAdjust = 0}) {
    final nestCount = allocNest.removeLast();
    return nestCount;
  }

  void resetStack({int position = 0}) {
    allocNest = [position];
    scopeFrameOffset = position;
  }

  Variable setLocal(String name, Variable v, {int? frame}) {
    if (frame != null) {
      return locals[frame][name] = v..frameIndex = frame;
    }

    return locals.last[name] = v..frameIndex = locals.length - 1;
  }

  Variable? lookupLocal(String name) {
    for (var i = locals.length - 1; i >= 0; i--) {
      if (locals[i].containsKey(name)) {
        return locals[i][name]!
          ..name = name
          ..frameIndex = i;
      }
    }
  }

  ContextSaveState saveState() {
    final _state = ContextSaveState.of(this);
    return _state;
  }

  void resolveBranchStateDiscontinuity(ContextSaveState initial) {
    final _otherLocals = initial.locals;
    final _myLocals = [...locals];
    for (var i = 0; i < _otherLocals.length; i++) {
      final _otherLocalsMap = _otherLocals[i];
      final _myLocalsMap = _myLocals[i];

      _otherLocalsMap.forEach((key, value) {
        final myLocal = _myLocalsMap[key]!;
        if (!myLocal.boxed && value.boxed) {
          locals[i][key] = myLocal.boxIfNeeded(this);
        } else if (myLocal.boxed && !value.boxed) {
          final _this = this as CompilerContext;
          locals[i][key] = myLocal.unboxIfNeeded(_this);
        }
      });
    }
  }

  void restoreState(ContextSaveState initial) {
    allocNest = initial.allocNest;
    locals = initial.locals;
  }

  void restoreBoxingState(ContextSaveState initial) {
    final _otherLocals = initial.locals;
    final _myLocals = [...locals];
    for (var i = 0; i < math.min(_otherLocals.length, _myLocals.length); i++) {
      final _otherLocalsMap = _otherLocals[i];
      final _myLocalsMap = _myLocals[i];

      _otherLocalsMap.forEach((key, value) {
        final myLocal = _myLocalsMap[key]!;
        if (!myLocal.boxed && value.boxed) {
          locals[i][key] =
              myLocal.copyWith(type: myLocal.type.copyWith(boxed: true));
        } else if (myLocal.boxed && !value.boxed) {
          locals[i][key] =
              myLocal.copyWith(type: myLocal.type.copyWith(boxed: false));
        }
      });
    }
  }
}

class CompilerContext with ScopeContext {
  CompilerContext(this.sourceFile, {this.version, int optimizationLevel = 2})
      : asm = Assembler(optimizationLevel: optimizationLevel);

  final Assembler asm;
  late BasicBlockBuilder builder;
  var blockCode = <Operation>[];
  int library = 0;
  Map<String, int> tempVarMap = {};
  Map<String, int> labelMap = {};
  NamedCompilationUnitMember? currentClass;

  /// A map of library IDs / indexes to a map of String declaration names to
  /// [DeclarationOrBridge]s. See [Compiler._topLevelDeclarationsMap] from which
  /// this is copied.
  Map<int, Map<String, DeclarationOrBridge>> topLevelDeclarationsMap = {};

  Map<int, Map<String, Map<String, Declaration>>> instanceDeclarationsMap = {};
  Map<int, Map<String, TypeRef>> visibleTypes = {};
  Map<int, Map<String, TypeRef>> temporaryTypes = {};
  Map<int, Map<String, DeclarationOrPrefix>> visibleDeclarations = {};
  Map<int, Map<String, int>> topLevelDeclarationPositions = {};
  Map<int, Map<String, int>> bridgeStaticFunctionIndices = {};
  Map<int, Map<String, List>> instanceDeclarationPositions = {};
  Map<int, Map<String, Map<String, int>>> instanceGetterIndices = {};
  Map<int, Map<String, Map<String, TypeRef>>> inferredFieldTypes = {};
  Map<int, Map<String, int>> topLevelGlobalIndices = {};
  Map<int, Map<String, int>> topLevelGlobalInitializers = {};
  Map<int, Map<String, Map<String, int>>> enumValueIndices = {};
  Map<int, int> runtimeGlobalInitializerMap = {};
  Map<int, Map<String, TypeRef>> topLevelVariableInferredTypes = {};
  Map<TypeRef, int> typeRefIndexMap = {};
  Map<String, int> libraryMap = {};
  List<TypeRef> runtimeTypeList = [];
  List<String> typeNames = [];
  List<Set<int>> typeTypes = [];
  List<bool> scopeDoesClose = [];
  List<ContextSaveState> typeInferenceSaveStates = [];
  List<ContextSaveState> typeUninferenceSaveStates = [];
  List<CompilerLabel> labels = [];
  Map<CompilerLabel, Set<int>> labelReferences = {};
  final List<Variable> caughtExceptions = [];
  PrescanContext? preScan;
  int nearestAsyncFrame = -1;
  int globalIndex = 0;
  String? version;
  String? funcLabel;

  final signaturePool = FunctionSignaturePool();
  final constantPool = ConstantPool<Object>();
  final runtimeTypes = ConstantPool<RuntimeTypeSet>();

  /// A map of String IDs to bytecode offsets used for runtime overrides
  Map<String, OverrideSpec> runtimeOverrideMap = {};

  int sourceFile;

  List<Operation> commit() {
    final code = blockCode;
    blockCode = [];
    return code;
  }

  BasicBlock commitBlock([String? label]) {
    return BasicBlock(commit(), label: label ?? funcLabel);
  }

  void resolveNonlinearity([int depth = 1]) {
    for (var i = 0; i < depth; i++) {
      <String, Variable>{...(locals[locals.length - depth])}
          .forEach((key, value) {
        locals[locals.length - depth][key] = value.unboxIfNeeded(this);
      });
    }
  }

  @override
  void beginAllocScope(
      {int existingAllocLen = 0,
      bool requireNonlinearAccess = false,
      bool closure = false}) {
    super.beginAllocScope(
        existingAllocLen: existingAllocLen,
        requireNonlinearAccess: requireNonlinearAccess);
    if (preScan?.closedFrames.contains(locals.length - 1) ?? false) {
      //final ps = PushScope.make(sourceFile, -1, '#');
      //pushOp(ps, PushScope.len(ps));
      scopeDoesClose.add(true);
    } else {
      scopeDoesClose.add(closure);
    }
  }

  SSA svar([String name = 'var']) {
    final tvi = tempVarMap.putIfAbsent(name, () => 0);
    tempVarMap[name] = tvi + 1;
    return SSA('$name' + (tvi == 0 ? '' : '_$tvi'));
  }

  String label([String name = 'label']) {
    final tvi = labelMap.putIfAbsent(name, () => 0);
    labelMap[name] = tvi + 1;
    return '$name' + (tvi == 0 ? '' : '_$tvi');
  }

  void pushOp(Operation op) {
    blockCode.add(op);
  }

  @override
  Variable? lookupLocal(String name) {
    final frameRef = <Variable>[];
    for (var i = locals.length - 1; i >= 0; i--) {
      if (locals[i].containsKey(name)) {
        final v = locals[i][name]!;
        /*if (frameRef.isNotEmpty) {
          var frOffset = frameRef[0].scopeFrameOffset;
          for (var i = 0; i < frameRef.length - 1; i++) {
            final _index =
                BuiltinValue(intval: frameRef[i + 1].scopeFrameOffset)
                    .push(this);
            blockCode.add(
                IndexList(frOffset, _index.scopeFrameOffset), IndexList.LEN);
            frOffset = scopeFrameOffset++;
            allocNest.last++;
          }

          final _index = BuiltinValue(intval: v.scopeFrameOffset).push(this);
          pushOp(IndexList(frOffset, _index.scopeFrameOffset), IndexList.LEN);
          allocNest.last++;

          return v.copyWith(scopeFrameOffset: scopeFrameOffset++);
        }*/
        return v..frameIndex = i;
      }
      if (scopeDoesClose[i]) {
        frameRef.add(locals[i]['#prev']!);
      }
    }
  }

  @override
  int endAllocScope({bool popValues = true, int popAdjust = 0}) {
    /*TODO if (preScan?.closedFrames.contains(locals.length - 1) ?? false) {
      pushOp(PopScope.make(), PopScope.LEN);
      popValues = false;
    }*/
    scopeDoesClose.removeLast();
    return super.endAllocScope(popValues: popValues, popAdjust: popAdjust);
  }

  int rewriteOp(int where, Operation newOp) {
    blockCode[where] = newOp;
    return where;
  }

  void runPrescan(Declaration d) {
    final preScanner = PrescanVisitor();
    preScanner.dynamicType = CoreTypes.dynamic.ref(this);
    d.visitChildren(preScanner);
    preScan = preScanner.ctx;
  }

  @override
  void restoreState(ContextSaveState initial) {
    super.restoreState(initial);
    scopeDoesClose = initial.scopeDoesClose;
  }

  void enterTypeInferenceContext() {
    typeInferenceSaveStates.add(saveState());
  }

  void inferTypes() {
    final inferredLocals = typeInferenceSaveStates.removeLast().locals;
    typeUninferenceSaveStates.add(saveState());
    final _myLocals = [...locals];
    for (var i = 0;
        i < math.min(inferredLocals.length, _myLocals.length);
        i++) {
      final inferredLocalsMap = inferredLocals[i];
      final _myLocalsMap = _myLocals[i];

      inferredLocalsMap.forEach((key, value) {
        final myLocal = _myLocalsMap[key];
        if (myLocal != null && myLocal.type != value.type) {
          locals[i][key] =
              myLocal.copyWith(type: value.type.copyWith(boxed: myLocal.boxed));
        }
      });
    }
  }

  void uninferTypes() {
    final uninferredLocals = typeUninferenceSaveStates.removeLast().locals;
    final _myLocals = [...locals];
    for (var i = 0;
        i < math.min(uninferredLocals.length, _myLocals.length);
        i++) {
      final uninferredLocalsMap = uninferredLocals[i];
      final _myLocalsMap = _myLocals[i];

      uninferredLocalsMap.forEach((key, value) {
        final myLocal = _myLocalsMap[key];
        if (myLocal != null && myLocal.type != value.type) {
          locals[i][key] =
              myLocal.copyWith(type: value.type.copyWith(boxed: myLocal.boxed));
        }
      });
    }
  }

  void resolveLabel(CompilerLabel label) {
    final references = labelReferences[label];
    if (references != null) {
      for (final ref in references) {
        /* TODO final jump = JumpConstant.make(out.length);
        rewriteOp(ref, jump, 0);*/
      }
    }
  }
}

class ContextSaveState with ScopeContext {
  ContextSaveState.of(AbstractScopeContext context)
      : locals = [
          ...context.locals.map((e) => {...e})
        ],
        scopeDoesClose =
            context is CompilerContext ? [...context.scopeDoesClose] : [],
        allocNest = [...context.allocNest];
  List<Map<String, Variable>> locals;
  List<bool> scopeDoesClose;
  List<int> allocNest;
}
