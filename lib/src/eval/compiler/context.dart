// ignore_for_file: body_might_complete_normally_nullable
import 'dart:math' as math;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/src/eval/compiler/constant_pool.dart';
import 'package:dart_eval/src/eval/compiler/model/label.dart';
import 'package:dart_eval/src/eval/compiler/model/override_spec.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/bridge/declaration.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/ir/representation.dart';
import 'package:dart_eval/src/eval/ir/exception.dart';

abstract class AbstractScopeContext {
  List<Map<String, Variable>> get locals;
}

mixin ScopeContext on Object implements AbstractScopeContext {
  @override
  List<Map<String, Variable>> locals = [];

  void beginScope() => locals.add({});

  void endScope() => locals.removeLast();

  Variable setLocal(String name, Variable v, {int? frame}) {
    if (frame != null) {
      return locals[frame][name] = v
        ..frameIndex = frame
        ..localName = name;
    }

    return locals.last[name] = v
      ..frameIndex = locals.length - 1
      ..localName = name;
  }

  Variable? lookupLocal(String name) {
    for (var i = locals.length - 1; i >= 0; i--) {
      if (locals[i].containsKey(name)) {
        return locals[i][name]!
          ..localName = name
          ..frameIndex = i;
      }
    }
  }

  ContextSaveState saveState() {
    final state = ContextSaveState.of(this);
    return state;
  }

  /// Where the current boxing state disagrees with [initial], emits the
  /// box/unbox operations needed to bring each local back to [initial]'s
  /// boxing state. Used to reconcile state at control-flow joins.
  void resolveBranchStateDiscontinuity(ContextSaveState initial) {
    final otherLocals = initial.locals;
    final myLocals = [...locals];
    for (var i = 0; i < otherLocals.length; i++) {
      final otherLocalsMap = otherLocals[i];
      final myLocalsMap = myLocals[i];

      otherLocalsMap.forEach((key, value) {
        final myLocal = myLocalsMap[key]!;
        if (!myLocal.boxed && value.boxed) {
          locals[i][key] = myLocal.boxIfNeeded(this);
        } else if (myLocal.boxed && !value.boxed) {
          locals[i][key] = myLocal.unboxIfNeeded(this as CompilerContext);
        }
      });
    }
  }

  void restoreState(ContextSaveState initial) {
    locals = [
      for (final scope in initial.locals) {...scope},
    ];
  }

  /// Like [resolveBranchStateDiscontinuity] but only rewrites the `boxed` flag
  /// on each local's type, without emitting box/unbox operations. Use when the
  /// boxing ops have already been emitted elsewhere and only the compile-time
  /// bookkeeping needs to catch up.
  void restoreBoxingState(ContextSaveState initial) {
    final otherLocals = initial.locals;
    final myLocals = [...locals];
    for (var i = 0; i < math.min(otherLocals.length, myLocals.length); i++) {
      final otherLocalsMap = otherLocals[i];
      final myLocalsMap = myLocals[i];

      otherLocalsMap.forEach((key, value) {
        final myLocal = myLocalsMap[key]!;
        if (!myLocal.boxed && value.boxed) {
          locals[i][key] = myLocal.copyWith(
            type: myLocal.type.copyWith(boxed: true),
          );
        } else if (myLocal.boxed && !value.boxed) {
          locals[i][key] = myLocal.copyWith(
            type: myLocal.type.copyWith(boxed: false),
          );
        }
      });
    }
  }
}

class CompilerContext with ScopeContext {
  CompilerContext({this.version});

  late BasicBlockBuilder builder;
  var blockCode = <Operation>[];
  final Map<int, ControlFlowGraph> functionGraphs = {};
  final Map<int, ControlFlowGraph> ssaFunctionGraphs = {};
  final Map<int, String> functionNames = {};
  final Map<int, MachineFunctionSignature> functionSignatures = {};
  final Map<int, MachineRepresentation> globalRepresentations = {};
  final Set<int> globalsLate = {};
  final Set<int> globalsFinal = {};
  final Set<int> globalsWithInitializer = {};
  final Map<int, String> globalNames = {};
  final Map<int, List<FormalParameter>> functionParameters = {};
  final Map<int, List<TypeRef>> functionParameterTypes = {};
  final Map<int, List<TypeRef>> functionTypeParameterBounds = {};
  final Map<int, TypeRef> functionRuntimeTypes = {};
  int? currentFunctionId;
  int _nextFunctionId = 0;
  late ControlFlowGraph activeGraph;

  bool get blockEndsControlFlow =>
      blockCode.isNotEmpty &&
      (blockCode.last is Return ||
          blockCode.last is ReturnAsync ||
          blockCode.last is Throw ||
          blockCode.last is Rethrow ||
          blockCode.last is CompleteJump ||
          blockCode.last is Jump);

  int beginFunction(String name) {
    finishMethod();
    final id = _nextFunctionId++;
    currentFunctionId = id;
    funcLabel = label(name);
    functionNames[id] = funcLabel!;
    activeGraph = ControlFlowGraph();
    final root = BasicBlock<Operation>([], label: funcLabel);
    activeGraph.append(root);
    activeGraph.root = root;
    builder = BasicBlockBuilder(activeGraph, [root], null);
    hasBegunMethod = true;
    return id;
  }

  void finishMethod() {
    if (!hasBegunMethod) return;
    if (blockCode.isNotEmpty) flushBlock();
    functionGraphs[currentFunctionId!] = activeGraph;
    hasBegunMethod = false;
    currentFunctionId = null;
  }

  BasicBlock flushBlock([String? name]) {
    final block = commitBlock(name);
    builder = builder.then(block);
    return block;
  }

  int library = 0;

  Map<String, int> tempVarMap = {};
  Map<String, int> labelMap = {};

  Declaration? currentClass;

  String? get currentClassName {
    final currentClass = this.currentClass;
    if (currentClass == null) return null;
    return declarationName(currentClass);
  }

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
  Map<int, Map<String, Map<String, int>>> enumValueIndices = {};
  Map<int, int> runtimeGlobalInitializerMap = {};
  Map<int, Map<String, TypeRef>> topLevelVariableInferredTypes = {};
  Map<TypeRef, int> typeRefIndexMap = {};
  Map<String, int> runtimeTypeDescriptorIds = {};
  Map<String, int> libraryMap = {};
  List<TypeRef> runtimeTypeList = [];
  List<String> typeNames = [];
  List<Set<int>> typeTypes = [];
  List<List<int>> runtimeTypeDescriptors = [];
  List<ContextSaveState> typeInferenceSaveStates = [];
  List<ContextSaveState> typeUninferenceSaveStates = [];
  List<CompilerLabel> labels = [];
  final List<String> caughtExceptionTargets = [];
  int exceptionDepth = 0;
  int globalIndex = 0;
  String? version;
  String? funcLabel;
  bool hasBegunMethod = false;

  final constantPool = ConstantPool<Object>();

  /// A map of String IDs to function IDs used for runtime overrides
  Map<String, OverrideSpec> runtimeOverrideMap = {};

  SSA svar([String name = 'var']) {
    final tvi = tempVarMap.putIfAbsent(name, () => 0);
    tempVarMap[name] = tvi + 1;
    return SSA('$name${tvi == 0 ? '' : '_$tvi'}');
  }

  String label([String name = 'label']) {
    final tvi = labelMap.putIfAbsent(name, () => 0);
    labelMap[name] = tvi + 1;
    return '$name${tvi == 0 ? '' : '_$tvi'}';
  }

  void pushOp(Operation op) {
    blockCode.add(op);
  }

  List<Operation> commit() {
    final code = blockCode;
    blockCode = [];
    return code;
  }

  BasicBlock commitBlock([String? label]) {
    return BasicBlock(commit(), label: label);
  }

  void enterTypeInferenceContext() {
    typeInferenceSaveStates.add(saveState());
  }

  /// Promotes the types saved by [enterTypeInferenceContext] into [locals], and
  /// records the pre-inference state so [uninferTypes] can restore it.
  void inferTypes() {
    final inferredLocals = typeInferenceSaveStates.removeLast().locals;
    typeUninferenceSaveStates.add(saveState());
    _restoreSavedTypes(inferredLocals);
  }

  /// Reverts the type promotion performed by [inferTypes].
  void uninferTypes() {
    final uninferredLocals = typeUninferenceSaveStates.removeLast().locals;
    _restoreSavedTypes(uninferredLocals);
  }

  /// For every local in [savedLocals] whose type differs from the current
  /// binding, write back a copy carrying the saved type (keeping the current
  /// boxing state).
  void _restoreSavedTypes(List<Map<String, Variable>> savedLocals) {
    final myLocals = [...locals];
    for (var i = 0; i < math.min(savedLocals.length, myLocals.length); i++) {
      final savedLocalsMap = savedLocals[i];
      final myLocalsMap = myLocals[i];

      savedLocalsMap.forEach((key, value) {
        final myLocal = myLocalsMap[key];
        if (myLocal != null &&
            !myLocal.type.isSameSemanticType(this, value.type)) {
          locals[i][key] = myLocal.copyWith(
            type: value.type.copyWith(boxed: myLocal.boxed),
          );
        }
      });
    }
  }
}

class ContextSaveState with ScopeContext {
  ContextSaveState.of(AbstractScopeContext context) {
    locals = [
      for (final scope in context.locals) {...scope},
    ];
  }
}

/// The bare declared name of a class-like [Declaration] (e.g. `Foo` for
/// `class Foo<T>`).
String declarationName(Declaration d) => switch (d) {
  ClassDeclaration() => d.namePart.typeName.lexeme,
  EnumDeclaration() => d.namePart.typeName.lexeme,
  MixinDeclaration() => d.name.lexeme,
  ExtensionTypeDeclaration() => d.namePart.typeName.lexeme,
  FunctionDeclaration() => d.name.lexeme,
  TypeAlias() => d.name.lexeme,
  _ => throw UnimplementedError('Cannot determine name of ${d.runtimeType}'),
};
