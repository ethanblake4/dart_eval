// ignore_for_file: body_might_complete_normally_nullable
import 'dart:math' as math;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/src/eval/compiler/constant_pool.dart';
import 'package:dart_eval/src/eval/compiler/helpers/extension.dart';
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

  /// Widens local type proofs at a control-flow join. For each local that was
  /// reassigned on any of the [incoming] edges, keeps only the allocation
  /// info every edge agrees on (see [Variable.joinedWith]). The current
  /// state's SSA bindings are authoritative — the incoming states only
  /// contribute their type proofs.
  void mergeBranchState(Iterable<ContextSaveState> incoming) {
    for (var i = 0; i < locals.length; i++) {
      final frame = locals[i];
      for (final key in frame.keys.toList()) {
        final current = frame[key]!;
        frame[key] = current.joinedWith([
          for (final state in incoming)
            if (i < state.locals.length && state.locals[i][key] != null)
              state.locals[i][key]!,
        ]);
      }
    }
  }

  /// Drops allocation proofs on the named locals, as they would be after a
  /// reassignment merge. Used before compiling a loop whose body reassigns
  /// them — the back edge can make them hold a differently-typed value.
  void widenAssignedLocals(Set<String> names) {
    for (var i = 0; i < locals.length; i++) {
      final frame = locals[i];
      for (final name in names) {
        final v = frame[name];
        if (v == null) continue;
        frame[name] = v.widened();
      }
    }
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

  /// Hidden zero-arg thunk function per non-scalar parameter default
  /// expression, so the same default is compiled once for closures, call
  /// sites, and host exports.
  final Map<Expression, int> defaultThunkCache = {};
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

  /// The extension whose member is being compiled, if any. Extension
  /// members are instance-like (they have a receiver) but [currentClass]
  /// stays null since the `on` type isn't a declared class member scope.
  Declaration? currentExtension;

  /// While compiling an anonymous-method body (`target.=> expr`), the
  /// receiver the body's `this` resolves to. Like an extension receiver,
  /// this is a plain local — `this` must not emit `LoadThis` (which only
  /// accepts class instances).
  Variable? anonymousThisReceiver;

  /// Active anonymous-method invocations whose block bodies may contain
  /// `return`: each maps the invocation node to its exit block and result
  /// local (see `compileReturn` in statement/return.dart).
  final List<AnonymousMethodReturn> anonymousMethodReturns = [];

  /// The library of the enclosing class being compiled. During folded mixin
  /// member compilation, [library] is the member's own library (so bare
  /// identifiers resolve there) while this stays the applying class's, which
  /// is where instance-declaration positions must be registered.
  int? enclosingLibrary;

  /// The declaration a folded member was written in (e.g. the mixin for a
  /// member folded into a `with` application). Bare identifiers in that
  /// member resolve statically against this declaration's scope, not the
  /// applying class's; null for members declared directly by [currentClass].
  Declaration? memberDeclaringClass;

  String libraryUri(int index) =>
      libraryMap.entries.firstWhere((e) => e.value == index).key;

  /// The member-table key for [name] as written in the current library. A
  /// private member folded in from a different library keeps its origin
  /// library as part of the key so runtime privacy checks scope it correctly.
  String memberNameKey(String name) {
    final enclosing = enclosingLibrary;
    if (!name.startsWith('_') || enclosing == null || enclosing == library) {
      return name;
    }
    return '${libraryUri(library)}::$name';
  }

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

  /// `typedef` declarations visible per library. Aliases never become runtime
  /// types; [TypeRef.fromAnnotation] resolves them lazily to their target.
  Map<int, Map<String, TypeAlias>> typeAliases = {};

  /// The library index each [TypeAlias] was declared in — an imported alias's
  /// body resolves against its own file (it may name private types).
  final typeAliasFiles = Expando<int>();

  /// Aliases currently being resolved by [resolveTypeAlias], to detect
  /// recursive typedefs (`typedef F = List<G>; typedef G = List<F>;`).
  final resolvingTypeAliases = <TypeAlias>{};

  /// Return value types seen while compiling each `async` function literal —
  /// the closure's signature reifies `Future<S>` where `S` is the inferred
  /// return type, matching the VM (`() async { return null; }` reifies
  /// `() => Future<Null>`).
  final asyncClosureReturnTypes = <List<TypeRef>>[];
  Map<int, Map<String, TypeRef>> temporaryTypes = {};
  Map<int, Map<String, DeclarationOrPrefix>> visibleDeclarations = {};
  Map<int, Map<String, int>> topLevelDeclarationPositions = {};
  Map<int, Map<String, int>> bridgeStaticFunctionIndices = {};
  Map<int, Map<String, List>> instanceDeclarationPositions = {};

  /// `'$file:$name'` keys of every class or mixin named as a superinterface
  /// (extends/implements/with/on) somewhere in the compiled program. Members
  /// declared on these types must be invoked dynamically since a subclass may
  /// override them.
  Set<String> subclassedTypes = {};

  /// Direct superinterface edges: descendant 'file:class' → ancestor keys.
  Map<String, List<String>> subclassEdges = {};

  /// Declared instance member names per 'file:class' (privates carry their
  /// library prefix, matching member-table keys).
  Map<String, Set<String>> declaredInstanceMembers = {};
  Map<String, Set<String>>? _descendantMemo;

  /// Whether some descendant of the class `'$file:$cls'` redeclares
  /// `member`. When false, a call on a receiver that is (or may be) that
  /// class can devirtualize even though the class is subclassed.
  bool memberOverriddenInSubclass(int file, String cls, String member) {
    final descendants = _descendants();
    final ds = descendants['$file:$cls'];
    if (ds == null) return false;
    final privateKey = member.startsWith('_')
        ? '${libraryUri(file)}::$member'
        : null;
    for (final d in ds) {
      final names = declaredInstanceMembers[d];
      if (names == null) continue;
      if (names.contains(member) ||
          (privateKey != null && names.contains(privateKey))) {
        return true;
      }
    }
    return false;
  }

  /// Transitive descendant sets keyed by ancestor 'file:class'.
  Map<String, Set<String>> _descendants() {
    final memo = _descendantMemo;
    if (memo != null) return memo;
    final out = <String, Set<String>>{};
    for (final d in subclassEdges.keys) {
      final seen = <String>{};
      final stack = [...?subclassEdges[d]];
      while (stack.isNotEmpty) {
        final a = stack.removeLast();
        if (seen.add(a)) stack.addAll(subclassEdges[a] ?? const []);
      }
      for (final a in seen) {
        (out[a] ??= {}).add(d);
      }
    }
    return _descendantMemo = out;
  }

  Map<int, Map<String, Map<String, int>>> instanceGetterIndices = {};
  Map<int, Map<String, Map<String, TypeRef>>> inferredFieldTypes = {};
  Map<int, Map<String, int>> topLevelGlobalIndices = {};
  Map<int, Map<String, Map<String, int>>> enumValueIndices = {};
  Map<int, int> runtimeGlobalInitializerMap = {};

  /// Every `extension` declaration in the program, with its defining
  /// library and the name its members are registered under. Populated
  /// during the declaration pass; members compile eagerly like class
  /// methods.
  List<EvalExtension> extensions = [];

  /// Extension member keys in [topLevelDeclarationPositions], per library.
  /// They're callable via [Call]/[DeferredOrOffset] but not as exports,
  /// since they take a receiver argument absent from the declared signature.
  Map<int, Set<String>> extensionMemberFunctions = {};

  /// Extensions visible at call sites in each library (the library's own
  /// plus those of its transitive imports).
  Map<int, List<EvalExtension>> visibleExtensions = {};
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

  /// Label names a `LabeledStatement` is about to attach to the next
  /// loop/switch label pushed (see `compileLabeledStatement`). Consumed via
  /// [takePendingLabelNames].
  final Set<String> pendingLabelNames = {};

  /// Drains [pendingLabelNames] into a fresh set, for a loop/switch attaching
  /// its enclosing `label:` names to the [CompilerLabel] it pushes.
  Set<String> takePendingLabelNames() {
    final taken = Set.of(pendingLabelNames);
    pendingLabelNames.clear();
    return taken;
  }

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
    if (blockEndsControlFlow) {
      // A terminator ends the block, but expressions like `f(throw x)` can
      // emit more ops afterwards. Commit the terminated block and redirect
      // into a fresh detached block so dead code neither lands after the
      // terminator nor adds a successor edge out of it.
      flushBlock();
      final orphan = BasicBlock<Operation>([], label: label('dead'));
      builder.float(orphan);
      builder = BasicBlockBuilder(activeGraph, [orphan], builder);
    }
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
  ClassTypeAlias() => d.name.lexeme,
  ExtensionDeclaration() => d.name?.lexeme ?? '',
  ExtensionTypeDeclaration() => d.namePart.typeName.lexeme,
  FunctionDeclaration() => d.name.lexeme,
  TypeAlias() => d.name.lexeme,
  _ => throw UnimplementedError('Cannot determine name of ${d.runtimeType}'),
};
