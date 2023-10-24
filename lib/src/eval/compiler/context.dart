// ignore_for_file: body_might_complete_normally_nullable

import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/constant_pool.dart';
import 'package:dart_eval/src/eval/compiler/model/override_spec.dart';
import 'package:dart_eval/src/eval/compiler/optimizer/prescan.dart';
import 'package:dart_eval/src/eval/compiler/source.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/util.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/bridge/declaration.dart';
import 'package:dart_eval/src/eval/runtime/ops/all_ops.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/src/eval/runtime/type.dart';

import 'offset_tracker.dart';

abstract class AbstractScopeContext {
  int get scopeFrameOffset;

  set scopeFrameOffset(int s);

  List<Map<String, Variable>> get locals;

  List<int> get allocNest;

  set allocNest(List<int> a);

  List<bool> get inNonlinearAccessContext;

  int pushOp(EvcOp op, int length) {
    return 0;
  }
}

mixin ScopeContext on Object implements AbstractScopeContext {
  @override
  int scopeFrameOffset = 0;
  @override
  List<Map<String, Variable>> locals = [];
  @override
  List<int> allocNest = [0];
  @override
  List<bool> inNonlinearAccessContext = [false];

  void beginAllocScope(
      {int existingAllocLen = 0, bool requireNonlinearAccess = false}) {
    allocNest.add(existingAllocLen);
    locals.add({});
    inNonlinearAccessContext.add(requireNonlinearAccess);
  }

  int peekAllocPops({int popAdjust = 0}) {
    return allocNest.last;
  }

  int endAllocScope({bool popValues = true, int popAdjust = 0}) {
    inNonlinearAccessContext.removeLast();
    locals.removeLast();
    final nestCount = allocNest.removeLast();
    if (popValues) {
      popN(nestCount + popAdjust);
    }
    scopeFrameOffset -= nestCount;
    return nestCount;
  }

  void popN(int pops) {
    if (pops == 0) {
      return;
    }
    pushOp(Pop.make(pops), Pop.LEN);
  }

  void resetStack({int position = 0}) {
    allocNest = [position];
    scopeFrameOffset = position;
    inNonlinearAccessContext = [false];
  }

  Variable setLocal(String name, Variable v, {int? frame}) {
    if (frame != null) {
      return locals[frame][name] = v
        ..name = name
        ..frameIndex = frame;
    }

    return locals.last[name] = v
      ..name = name
      ..frameIndex = locals.length - 1;
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

  void resolveNonlinearity([int depth = 1]) {
    for (var i = 0; i < depth; i++) {
      <String, Variable>{...(locals[locals.length - depth])}
          .forEach((key, value) {
        locals[locals.length - depth][key] = value.unboxIfNeeded(this);
      });
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
          locals[i][key] = myLocal.unboxIfNeeded(this);
        }
      });
    }
  }

  void restoreState(ContextSaveState initial) {
    allocNest = initial.allocNest;
    locals = initial.locals;
    inNonlinearAccessContext = initial.inNonlinearAccessContext;
  }
}

class CompilerContext with ScopeContext {
  CompilerContext(this.sourceFile, {this.version});

  final out = <EvcOp>[];
  int library = 0;
  int position = 0;
  NamedCompilationUnitMember? currentClass;

  /// A map of library IDs / indexes to a map of String declaration names to
  /// [DeclarationOrBridge]s. See [Compiler._topLevelDeclarationsMap] from which
  /// this is copied.
  Map<int, Map<String, DeclarationOrBridge>> topLevelDeclarationsMap = {};

  Map<int, Map<String, Map<String, Declaration>>> instanceDeclarationsMap = {};
  late OffsetTracker offsetTracker = OffsetTracker(this);
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
  final List<Variable> caughtExceptions = [];
  PrescanContext? preScan;
  int nearestAsyncFrame = -1;
  int globalIndex = 0;
  String? version;

  final signaturePool = FunctionSignaturePool();
  final constantPool = ConstantPool<Object>();
  final runtimeTypes = ConstantPool<RuntimeTypeSet>();

  /// A map of String IDs to bytecode offsets used for runtime overrides
  Map<String, OverrideSpec> runtimeOverrideMap = {};

  bool get requireNonlinearAccess => inNonlinearAccessContext.last;

  int sourceFile;

  @override
  int pushOp(EvcOp op, int length) {
    //print('#: ${op.toString()}');
    out.add(op);
    position += length;
    return out.length - 1;
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
      final ps = PushScope.make(sourceFile, -1, '#');
      pushOp(ps, PushScope.len(ps));
      scopeDoesClose.add(true);
    } else {
      scopeDoesClose.add(closure);
    }
  }

  @override
  Variable? lookupLocal(String name) {
    final frameRef = <Variable>[];
    for (var i = locals.length - 1; i >= 0; i--) {
      if (locals[i].containsKey(name)) {
        final v = locals[i][name]!;
        if (frameRef.isNotEmpty) {
          var frOffset = frameRef[0].scopeFrameOffset;
          for (var i = 0; i < frameRef.length - 1; i++) {
            final _index =
                BuiltinValue(intval: frameRef[i + 1].scopeFrameOffset)
                    .push(this);
            pushOp(IndexList.make(frOffset, _index.scopeFrameOffset),
                IndexList.LEN);
            frOffset = scopeFrameOffset++;
            allocNest.last++;
          }

          final _index = BuiltinValue(intval: v.scopeFrameOffset).push(this);
          pushOp(
              IndexList.make(frOffset, _index.scopeFrameOffset), IndexList.LEN);
          allocNest.last++;

          return v.copyWith(scopeFrameOffset: scopeFrameOffset++);
        }
        return v
          ..name = name
          ..frameIndex = i;
      }
      if (scopeDoesClose[i]) {
        frameRef.add(locals[i]['#prev']!);
      }
    }
  }

  @override
  int endAllocScope({bool popValues = true, int popAdjust = 0}) {
    if (preScan?.closedFrames.contains(locals.length - 1) ?? false) {
      pushOp(PopScope.make(), PopScope.LEN);
      popValues = false;
    }
    scopeDoesClose.removeLast();
    return super.endAllocScope(popValues: popValues, popAdjust: popAdjust);
  }

  int rewriteOp(int where, EvcOp newOp, int lengthAdjust) {
    out[where] = newOp;
    position += lengthAdjust;
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
}

class ContextSaveState {
  ContextSaveState.of(AbstractScopeContext context)
      : locals = [
          ...context.locals.map((e) => {...e})
        ],
        scopeDoesClose =
            context is CompilerContext ? [...context.scopeDoesClose] : [],
        allocNest = [...context.allocNest],
        inNonlinearAccessContext = [...context.inNonlinearAccessContext];
  List<Map<String, Variable>> locals;
  List<bool> scopeDoesClose;
  List<int> allocNest;
  List<bool> inNonlinearAccessContext;
}
