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
import 'package:dart_eval/src/eval/compiler/variable/binding.dart';
import 'package:dart_eval/src/eval/bridge/declaration.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/ir/representation.dart';
import 'package:dart_eval/src/eval/ir/exception.dart';
import 'member/member_lookup.dart';
import 'member/member_name.dart';

abstract class AbstractScopeContext {
  List<Map<String, LocalBinding>> get locals;
}

/// A concrete mixin member compiled into one application layer. Its offset
/// remains callable after a later layer replaces the dispatch-table entry.
typedef FoldedMemberBody = ({
  MethodDeclaration declaration,
  int library,
  int offset,
  int layer,
});

mixin ScopeContext on Object implements AbstractScopeContext {
  @override
  List<Map<String, LocalBinding>> locals = [];

  void beginScope() => locals.add({});

  void endScope() => locals.removeLast();

  /// The binding for [name] in innermost-first scope order.
  LocalBinding? lookupBinding(String name) {
    for (var i = locals.length - 1; i >= 0; i--) {
      final binding = locals[i][name];
      if (binding != null) return binding;
    }
    return null;
  }

  /// Declares or replaces the binding for [name] in [frame] (default:
  /// innermost) and returns it — [LocalBinding.read] materializes the
  /// value for reads; `setValue` writes through the binding's storage.
  LocalBinding setLocal(
    String name,
    Variable v, {
    TypeRef? declaredType,
    bool isFinal = false,
    int? frame,
    bool initialized = true,
  }) {
    final f = frame ?? locals.length - 1;
    final existing = locals[f][name];
    if (existing != null) {
      existing.rebind(v);
      return existing;
    }
    final nb = LocalBinding(
      name,
      v,
      declaredType: declaredType ?? v.type,
      isFinal: isFinal,
      frameIndex: f,
      initialized: initialized,
    );
    locals[f][name] = nb;
    return nb;
  }

  Variable? lookupLocal(String name) => lookupBinding(name)?.current;

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
        final binding = myLocalsMap[key]!;
        final myLocal = binding.current;
        if (!myLocal.boxed && value.current.boxed) {
          binding.rebind(myLocal.boxIfNeeded(this));
        } else if (myLocal.boxed && !value.current.boxed) {
          binding.rebind(myLocal.unboxIfNeeded(this as CompilerContext));
        }
      });
    }
  }

  void restoreState(ContextSaveState initial) {
    locals = [
      for (final scope in initial.locals)
        {for (final entry in scope.entries) entry.key: entry.value.restore()},
    ];
  }

  /// Widens local type proofs at a control-flow join. For each local that was
  /// reassigned on any of the [incoming] edges, keeps only the allocation
  /// info every edge agrees on. The current
  /// state's SSA bindings are authoritative — the incoming states only
  /// contribute their type proofs.
  void mergeBranchState(Iterable<ContextSaveState> incoming) {
    for (var i = 0; i < locals.length; i++) {
      final frame = locals[i];
      for (final key in frame.keys.toList()) {
        final binding = frame[key]!;
        final value = binding.current;
        var facts = value.facts;
        var changed = false;
        for (final state in incoming) {
          final other = i < state.locals.length
              ? state.locals[i][key]?.current
              : null;
          if (other == null || identical(other, value)) continue;
          changed = true;
          facts = facts.join(other.facts);
        }
        if (changed) {
          binding.rebind(value.withFacts(facts));
        }
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
        final binding = frame[name];
        if (binding == null) continue;
        binding.clearValueFacts();
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
        final binding = myLocalsMap[key]!;
        if (binding.current.rep != value.current.rep) {
          binding.rebind(binding.current.copyWith(rep: value.current.rep));
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
  final Set<int> globalsConst = {};
  final Set<int> globalsWithInitializer = {};
  final Map<int, String> globalNames = {};
  final Map<int, List<FormalParameter>> functionParameters = {};
  final Map<int, List<TypeRef>> functionParameterTypes = {};
  final Map<int, List<TypeRef>> functionTypeParameterBounds = {};

  /// Hidden zero-arg thunk function per non-scalar parameter default
  /// expression, so the same default is compiled once for closures, call
  /// sites, and host exports.
  final Map<Expression, int> defaultThunkCache = {};

  /// `<generic function adapter>` function id per instantiated signature:
  /// `f<T>` torn off at separate call sites forwards through the same
  /// adapter, so identical instantiations canonicalize to one closure.
  final Map<String, int> instantiatedAdapterIds = {};
  final Map<int, TypeRef> functionRuntimeTypes = {};
  int? currentFunctionId;
  int _nextFunctionId = 0;
  late ControlFlowGraph activeGraph;

  /// Whether [op] ends a block's normal control flow — the frontend ops
  /// don't declare [Operation.isTerminator], so they are matched here.
  static bool isTerminatorOp(Operation op) =>
      op is Return ||
      op is ReturnAsync ||
      op is Throw ||
      op is Rethrow ||
      op is CompleteJump ||
      op is Jump;

  bool get blockEndsControlFlow =>
      blockCode.isNotEmpty && isTerminatorOp(blockCode.last);


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
    // A tail already ending in a terminator must not gain a fallthrough
    // edge to the new block; it is parked and the block starts detached.
    builder = builder.thenUnlessTerminated(block, isTerminatorOp);
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

  /// The receiver of the cascade currently being compiled (`a` in
  /// `a..b..c`). Cascaded selectors (`..b`, `..c`) read it regardless of
  /// how deeply nested they are in their section's expression tree.
  Variable? cascadeTarget;

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

  /// Earlier mixin bodies visible to a lexical `super` in the member
  /// currently being compiled. Set by [compileClassMembers] for each body.
  Map<String, FoldedMemberBody> lexicalSuperMembers = const {};

  String libraryUri(int index) =>
      libraryMap.entries.firstWhere((e) => e.value == index).key;

  /// The [MemberName] for [name] as written in the current library. A
  /// private member folded in from a different library keeps its origin
  /// library as part of the key so runtime privacy checks scope it correctly.
  MemberName memberNameOf(String name, MemberKind kind) => MemberName(
    name,
    kind,
    privateLibraryUri:
        name.startsWith('_') &&
            enclosingLibrary != null &&
            enclosingLibrary != library
        ? libraryUri(library)
        : null,
  );

  /// The member-table key for [name] as written in the current library.
  String memberNameKey(String name) =>
      memberNameOf(name, MemberKind.method).nameKey;

  /// `operator -` is the only arity-overloadable operator: the nullary form
  /// is keyed `unary-` (the analyzer's element name) so it can't collide
  /// with binary `-` in member tables and runtime descriptors.
  String instanceMethodKey(String name, int positionalArity) => memberNameOf(
    name == '-' && positionalArity == 0 ? 'unary-' : name,
    MemberKind.method,
  ).nameKey;

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

  /// Type parameters currently in scope, per library — folded mixin
  /// members resolve in their own library, so scopes key by library
  /// index. The mapped scope is the innermost frame; [withTypeParameters]
  /// pushes and pops frames around a body, and ambient seeds write into
  /// the head through [typeParameterScope].
  final Map<int, TypeScope> typeScopes = {};

  /// Interned [TypeParameterDef]s by owner — every owner's parameters are
  /// created in exactly one place, so bounds resolve on shared defs.
  final typeParameterDefs = TypeParameterDefs();

  /// Annotation→[TypeRef] resolution — the home of `fromAnnotation`,
  /// `fromBridgeTypeRef`, alias expansion, and function-type construction.
  late final typeFactory = TypeFactory(this);

  /// The mutable entries of [library]'s innermost type-parameter frame,
  /// creating a base frame on first use. Writes are always scoped: seeds
  /// (mixin application arguments, folded member bindings) are added only
  /// inside a [withTypeParameters] frame and pop with it — the base frame
  /// is never a durable write target.
  Map<String, TypeRef> typeParameterScope(int library) =>
      (typeScopes[library] ??= TypeScope(null)).entries;

  /// Runs [body] with [nodes] visible as [library]'s in-scope type
  /// parameters (owned by [owner]), restoring the previous scope on exit.
  T withTypeParameters<T>(
    int library,
    TypeParameterOwner? owner,
    List<TypeParameter>? nodes,
    T Function() body, {
    bool resolveBounds = true,
  }) {
    final scope = TypeScope(typeScopes[library]);
    typeScopes[library] = scope;
    TypeRef.loadTemporaryTypes(
      this,
      nodes,
      library: library,
      owner: owner,
      resolveBounds: resolveBounds,
    );
    try {
      return body();
    } finally {
      final parent = scope.parent;
      if (parent == null) {
        typeScopes.remove(library);
      } else {
        typeScopes[library] = parent;
      }
    }
  }

  Map<int, Map<String, DeclarationOrPrefix>> visibleDeclarations = {};

  /// Import prefixes declared `deferred` in each library (library index →
  /// prefix names). Such prefixes expose a synthetic `loadLibrary` member.
  Map<int, Set<String>> deferredPrefixes = {};
  Map<int, Map<String, int>> topLevelDeclarationPositions = {};
  Map<int, Map<String, int>> bridgeStaticFunctionIndices = {};
  Map<int, Map<String, Map<MemberKind, Map<String, int>>>>
  instanceDeclarationPositions = {};

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

  /// Whether any class in the program declares `'$file:$cls'` as an
  /// ancestor — a receiver typed `cls` may then hold a subclass instance.
  bool hasSubclasses(int file, String cls) =>
      _descendants().containsKey('$file:$cls');

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
  late final TypeDeclRegistry types = TypeDeclRegistry(this);
  late final TypeSystem typeSystem = TypeSystem(this);
  late final MemberLookup memberLookup = MemberLookup(this);
  late final RuntimeTypes runtimeTypes = RuntimeTypes(this);
  final Map<int, TypeRef> bridgeTypeRefCache = {};
  Map<String, int> libraryMap = {};
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

  /// Nonzero while compiling a function-expression (closure) body. Closures
  /// are dynamically callable, so their results must be boxed at the
  /// boundary even when the return type is unboxable for named functions.
  int closureDepth = 0;
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
  void _restoreSavedTypes(List<Map<String, SavedLocalBinding>> savedLocals) {
    final myLocals = [...locals];
    for (var i = 0; i < math.min(savedLocals.length, myLocals.length); i++) {
      final savedLocalsMap = savedLocals[i];
      final myLocalsMap = myLocals[i];

      savedLocalsMap.forEach((key, value) {
        final binding = myLocalsMap[key];
        if (binding != null && binding.current.type != value.current.type) {
          binding.rebind(binding.current.copyWith(type: value.current.type));
        }
      });
    }
  }
}

/// A frozen flow-state view over stable source-level bindings. Restoring a
/// branch changes each binding's current value and storage, never its identity.
final class SavedLocalBinding {
  SavedLocalBinding(LocalBinding binding)
    : binding = binding,
      current = binding.current.copyWith(),
      storage = binding.storage,
      initialized = binding.initialized;

  final LocalBinding binding;
  Variable current;
  final BindingStorage storage;
  final bool initialized;

  void promote(TypeRef type) {
    current = current.copyWith(type: type);
  }

  LocalBinding restore() {
    binding.storage = storage;
    binding.initialized = initialized;
    binding.rebind(current.copyWith());
    return binding;
  }
}

class ContextSaveState {
  ContextSaveState.of(AbstractScopeContext context) {
    locals = [
      for (final scope in context.locals)
        {
          for (final entry in scope.entries)
            entry.key: SavedLocalBinding(entry.value),
        },
    ];
  }

  late final List<Map<String, SavedLocalBinding>> locals;
}

/// State to restore after compiling a function inside another function.
/// Call [resumeAfterFlush] when the outer function's pending block was flushed
/// before the nested function began.
final class NestedFunctionState {
  NestedFunctionState(this.context)
    : graph = context.activeGraph,
      builder = context.builder,
      blockCode = context.blockCode,
      functionId = context.currentFunctionId,
      functionLabel = context.funcLabel,
      hasBegunMethod = context.hasBegunMethod,
      labels = [...context.labels],
      exceptionTargets = [...context.caughtExceptionTargets],
      exceptionDepth = context.exceptionDepth,
      locals = context.saveState();

  final CompilerContext context;
  final ControlFlowGraph graph;
  BasicBlockBuilder builder;
  List<Operation> blockCode;
  final int? functionId;
  final String? functionLabel;
  final bool hasBegunMethod;
  final List<CompilerLabel> labels;
  final List<String> exceptionTargets;
  final int exceptionDepth;
  final ContextSaveState locals;

  void resumeAfterFlush() {
    builder = context.builder;
    blockCode = context.blockCode;
    context.blockCode = [];
  }

  void restore() {
    context
      ..activeGraph = graph
      ..builder = builder
      ..blockCode = blockCode
      ..currentFunctionId = functionId
      ..funcLabel = functionLabel
      ..hasBegunMethod = hasBegunMethod
      ..exceptionDepth = exceptionDepth;
    context.labels
      ..clear()
      ..addAll(labels);
    context.caughtExceptionTargets
      ..clear()
      ..addAll(exceptionTargets);
    context.restoreState(locals);
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
