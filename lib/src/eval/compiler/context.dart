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
import 'backend/representation.dart' show representationForType;

abstract class AbstractScopeContext {
  List<Map<String, LocalBinding>> get locals;

  /// Whether the current emission sequence ended in a terminator — unlike
  /// [blockEndsControlFlow] it stays set once [pushOp] has split off the
  /// dead tail into a detached block, so branch endpoints (`x ? a : throw`)
  /// still see that the arm ended without fallthrough. Restored by
  /// [restoreState] and cleared by [mergeBranchState].
  bool get flowTerminated;
  set flowTerminated(bool value);
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
    flowTerminated = initial.flowTerminated;
    locals = [
      for (final scope in initial.locals)
        {for (final entry in scope.entries) entry.key: entry.value.restore()},
    ];
  }

  /// Widens local type proofs at a control-flow join. For each local that was
  /// reassigned on any of the [incoming] edges, keeps only the allocation
  /// info every edge agrees on, and widens the flow type to the least upper
  /// bound of the edges' types (`i1` is `int?` after `case null: i1 = null`
  /// merges with a promoted `int` edge). The current
  /// state's SSA bindings are authoritative — the incoming states only
  /// contribute their type proofs. Set [includeCurrent] to false when
  /// [incoming] already contains every edge reaching the join.
  void mergeBranchState(
    Iterable<ContextSaveState> incoming, {
    bool includeCurrent = true,
  }) {
    flowTerminated = false;
    for (var i = 0; i < locals.length; i++) {
      final frame = locals[i];
      for (final key in frame.keys.toList()) {
        final binding = frame[key]!;
        final value = binding.current;
        var facts = value.facts;
        var type = value.type;
        var epoch = value.writeEpoch;
        var changed = false;
        var typeChanged = false;
        var hasIncoming = includeCurrent;
        for (final state in incoming) {
          final other = i < state.locals.length
              ? state.locals[i][key]?.current
              : null;
          if (other == null || identical(other, value)) continue;
          changed = true;
          facts = hasIncoming ? facts.join(other.facts) : other.facts;
          // An edge that reassigned the local carries a higher epoch —
          // the join takes the max so records stamped on earlier values
          // stay invalidated.
          if (other.writeEpoch > epoch) epoch = other.writeEpoch;
          if (!hasIncoming) {
            type = other.type;
            typeChanged = type != value.type;
          } else if (other.type != type) {
            type = TypeRef.commonBaseType(this as CompilerContext, {
              type,
              other.type,
            });
            typeChanged = true;
          }
          hasIncoming = true;
        }
        if (changed || epoch != value.writeEpoch) {
          binding.rebind(
            (typeChanged ? value.withType(type) : value).withFacts(facts)
              ..writeEpoch = epoch,
          );
        }
      }
    }
  }

  /// Drops promotions and allocation proofs on reassigned locals before a
  /// loop header: the back edge can supply a differently-typed value.
  void widenAssignedLocals(Set<String> names) {
    for (final name in names) {
      final binding = lookupBinding(name);
      if (binding == null) continue;
      var value = binding.current;
      if (representationForType(binding.declaredType) ==
          MachineRepresentation.object) {
        value = value.boxIfNeeded(this);
      }
      binding.rebind(value.withType(binding.declaredType));
      binding.clearValueFacts();
    }
  }

  /// Like [resolveBranchStateDiscontinuity] but only restores each local's
  /// representation, without emitting box/unbox operations. Use when the
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

  /// The builder for the block currently receiving code. Reassigning it
  /// starts a fresh emission sequence, so it also clears [flowTerminated].
  BasicBlockBuilder get builder => _builder;
  set builder(BasicBlockBuilder value) {
    _builder = value;
    _flowTerminated = false;
  }

  late BasicBlockBuilder _builder;
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
  final Map<int, List<TypeParameterDef>> functionTypeParameters = {};

  /// Hidden zero-arg thunk function per non-scalar parameter default
  /// expression, so the same default is compiled once for closures, call
  /// sites, and host exports.
  final Map<Expression, int> defaultThunkCache = {};

  /// `<generic function adapter>` function id per instantiated signature:
  /// `f<T>` torn off at separate call sites forwards through the same
  /// adapter, so identical instantiations canonicalize to one closure.
  final Map<String, int> instantiatedAdapterIds = {};

  /// One forwarding body per bridged function, shared by its tear-offs.
  final Map<int, int> bridgeTearOffAdapterIds = {};
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

  // pushOp starts a fresh block before appending past a terminator, so only
  // the tail can end control flow. Scanning the entire block for every emitted
  // operation makes large literals and cascades quadratic to compile.
  bool get blockEndsControlFlow =>
      blockCode.isNotEmpty && isTerminatorOp(blockCode.last);

  @override
  bool get flowTerminated => _flowTerminated || blockEndsControlFlow;
  @override
  set flowTerminated(bool value) => _flowTerminated = value;
  bool _flowTerminated = false;

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
    // Bypass the setter: a flush continues the same sequence, so a
    // terminator flag set by [pushOp] must survive it.
    _builder = _builder.thenUnlessTerminated(block, isTerminatorOp);
    return block;
  }

  int library = 0;

  Map<String, int> tempVarMap = {};
  Map<String, int> labelMap = {};

  Declaration? currentClass;

  /// Defaults rematerialize lexical constants instead of reading outer locals.
  bool compilingDefaultExpression = false;

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
  final noSuchMethodForwarders = <(int, String), Set<String>>{};
  final interfaceNoSuchMethodForwarderRequirements =
      <(int, String), List<(ClassMember, int, MemberKind, String, bool)>>{};

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
  final Map<(int, String), int> enumBaseToStringOffsets = {};
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

  /// Private member names that block field promotion in a library: a
  /// `final _f` is only promotable when no class-like declaration in the
  /// same library has a non-final field, concrete getter, or method with
  /// that basename. Cached per library.
  final Map<int, Set<String>> _promotionBlockers = {};
  Set<String> promotionBlockers(int library) =>
      _promotionBlockers[library] ??= _computePromotionBlockers(library);

  Set<String> _computePromotionBlockers(int library) {
    final blockers = <String>{};
    for (final entry
        in topLevelDeclarationsMap[library]?.values ??
            const <DeclarationOrBridge>[]) {
      final members = switch (entry.declaration) {
        ClassDeclaration d => d.body.members,
        MixinDeclaration d => d.body.members,
        EnumDeclaration d => d.body.members,
        _ => const <ClassMember>[],
      };
      for (final member in members) {
        if (member is FieldDeclaration &&
            !member.isStatic &&
            !member.fields.isFinal) {
          for (final field in member.fields.variables) {
            final name = field.name.lexeme;
            if (name.startsWith('_')) blockers.add(name);
          }
        }
        final name = switch (member) {
          // A concrete getter or method supplies a real getter — it
          // blocks. Setters, abstract members (empty body), and statics
          // don't.
          MethodDeclaration m
              when !m.isStatic &&
                  !m.isSetter &&
                  (m.body is! EmptyFunctionBody || m.externalKeyword != null) =>
            m.name.lexeme,
          _ => null,
        };
        if (name != null && name.startsWith('_')) blockers.add(name);
      }
    }

    // A concrete class inheriting or declaring `noSuchMethod` materializes
    // a forwarding getter for every interface member it doesn't implement — those
    // getters are assumed unstable and block promotion library-wide.
    String refKey(NamedType t) {
      final prefix = t.importPrefix;
      return prefix == null
          ? t.name.lexeme
          : '${prefix.name.lexeme}.${t.name.lexeme}';
    }

    final concrete = <String>{};
    final required = <String>{};
    final seen = <String>{};
    var hasNoSuchMethod = false;
    bool isConcrete(Declaration member) => switch (member) {
      FieldDeclaration m => m.abstractKeyword == null,
      MethodDeclaration m =>
        m.body is! EmptyFunctionBody || m.externalKeyword != null,
      _ => true,
    };
    void collect(int file, String name, bool interface) {
      final declaration = topLevelDeclarationsMap[file]?[name]?.declaration;
      final members = switch (declaration) {
        ClassDeclaration d => d.body.members,
        MixinDeclaration d => d.body.members,
        EnumDeclaration d => d.body.members,
        _ => const <ClassMember>[],
      };
      for (final member in members) {
        if (member is MethodDeclaration &&
            !member.isStatic &&
            !interface &&
            member.name.lexeme == 'noSuchMethod' &&
            isConcrete(member)) {
          hasNoSuchMethod = true;
        }
        if (file != library) continue;
        final names = switch (member) {
          FieldDeclaration m when !m.isStatic => m.fields.variables.map(
            (field) => field.name.lexeme,
          ),
          MethodDeclaration m when !m.isStatic && !m.isSetter => [
            m.name.lexeme,
          ],
          _ => const <String>[],
        };
        for (final name in names) {
          if (name.startsWith('_')) {
            (interface || !isConcrete(member) ? required : concrete).add(name);
          }
        }
      }
    }

    void walk(
      int file,
      NamedType? superT,
      List<NamedType> mixins,
      List<NamedType> impls,
      bool interfaceOnly,
    ) {
      void visit(int fromFile, NamedType? t, bool interface) {
        if (t == null) return;
        final ref = visibleTypes[fromFile]?[refKey(t)];
        if (ref == null || !seen.add('${ref.file}/${ref.name}/$interface')) {
          return;
        }
        collect(ref.file, ref.name, interface);
        final decl = topLevelDeclarationsMap[ref.file]?[ref.name]?.declaration;
        final (sup, mix, impl, _) = classLikeClauses(decl);
        visit(ref.file, sup, interface);
        for (final m in mix) {
          visit(ref.file, m, interface);
        }
        for (final i in impl) {
          visit(ref.file, i, true);
        }
      }

      visit(file, superT, interfaceOnly);
      for (final m in mixins) {
        visit(file, m, interfaceOnly);
      }
      for (final i in impls) {
        visit(file, i, true);
      }
    }

    for (final entry
        in topLevelDeclarationsMap[library]?.values ??
            const <DeclarationOrBridge>[]) {
      final dec = entry.declaration;
      if (switch (dec) {
        ClassDeclaration d =>
          d.abstractKeyword != null || d.sealedKeyword != null,
        ClassTypeAlias d => d.abstractKeyword != null,
        EnumDeclaration() => false,
        _ => true,
      }) {
        continue;
      }
      concrete.clear();
      required.clear();
      seen.clear();
      hasNoSuchMethod = false;
      collect(library, declarationName(dec!), false);
      final (sup, mix, impl, _) = classLikeClauses(dec);
      walk(library, sup, mix, impl, false);
      if (!hasNoSuchMethod) continue;
      for (final name in required) {
        if (!concrete.contains(name)) blockers.add(name);
      }
    }
    return blockers;
  }

  Map<int, Map<String, TypeRef>> topLevelVariableInferredTypes = {};
  late final TypeDeclRegistry types = TypeDeclRegistry(this);
  late final TypeSystem typeSystem = TypeSystem(this);

  /// Whether [node]'s compilation unit runs at language version >=
  /// `major.minor` — files pinned below via a `// @dart=` comment keep the
  /// older semantics.
  bool languageVersionAtLeast(AstNode node, int major, int minor) {
    final token = node
        .thisOrAncestorOfType<CompilationUnit>()
        ?.languageVersionToken;
    return token == null ||
        token.major > major ||
        (token.major == major && token.minor >= minor);
  }

  /// Whether the `inference-update-3` typing rules (the greatest-closure
  /// result rule for `?:`/`??`/`??=`, and `K?` as the `??`-operand context)
  /// apply to [node]: the feature shipped with Dart 3.4.
  bool inferenceUpdate3(AstNode node) => languageVersionAtLeast(node, 3, 4);

  /// Dart 3.9 keeps promotion interests after demotion and excludes
  /// statically impossible branches from flow joins.
  bool soundFlowAnalysis(AstNode? node) =>
      node == null || languageVersionAtLeast(node, 3, 9);
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

  /// Names whose write-capture effects are deferred until the current
  /// invocation completes: a closure passed as an argument can be invoked
  /// by the callee, so its writes take effect after the call — but
  /// promotions elsewhere in the argument list still see the
  /// pre-invocation state. Null outside an argument list.
  Set<String>? deferredWriteCaptures;

  /// Applies a captured write to the local [name]: marks the binding
  /// write-captured immediately, or defers it to the enclosing
  /// invocation's completion while [deferredWriteCaptures] is active.
  void applyWriteCapture(String name) {
    final pending = deferredWriteCaptures;
    if (pending != null) {
      pending.add(name);
      return;
    }
    lookupBinding(name)?.markWriteCaptured();
  }

  /// Runs [body] with write captures deferred, applying the collected
  /// captures once it returns — the argument-list boundary at which a
  /// closure argument's writes become visible.
  T withDeferredWriteCaptures<T>(T Function() body) {
    final outer = deferredWriteCaptures;
    deferredWriteCaptures = {};
    try {
      return body();
    } finally {
      final deferred = deferredWriteCaptures!;
      deferredWriteCaptures = outer;
      for (final name in deferred) {
        lookupBinding(name)?.markWriteCaptured();
      }
    }
  }

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

  /// Nonzero while compiling a `late` local initializer. The initializer
  /// runs after the declaration point, so boolean-condition promotions
  /// recorded earlier (`bool b = x != null; if (b)`) cannot be trusted
  /// inside it — the condition variable may be reassigned before the
  /// first read.
  int lateInitializerDepth = 0;
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
      _builder.float(orphan);
      _builder = BasicBlockBuilder(activeGraph, [orphan], _builder);
    }
    blockCode.add(op);
    if (isTerminatorOp(op)) _flowTerminated = true;
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
  /// boxing state). Member promotions ride along — the saved value's
  /// `promotedMembers` replace the live ones, so [uninferTypes] restores
  /// the pre-inference member state exactly.
  void _restoreSavedTypes(List<Map<String, SavedLocalBinding>> savedLocals) {
    final myLocals = [...locals];
    for (var i = 0; i < math.min(savedLocals.length, myLocals.length); i++) {
      final savedLocalsMap = savedLocals[i];
      final myLocalsMap = myLocals[i];

      savedLocalsMap.forEach((key, value) {
        final binding = myLocalsMap[key];
        if (binding == null) return;
        if (binding.writeCaptured) {
          binding.rebind(
            binding.current
                .withType(binding.declaredType)
                .withFacts(binding.current.facts.cleared()),
          );
          return;
        }
        final saved = value.current;
        var current = binding.current;
        if (current.type != saved.type) {
          binding.rebind(current = current.copyWith(type: saved.type));
        }
        final savedMembers = saved.facts.promotedMembers;
        if (!_sameMemberMap(current.facts.promotedMembers, savedMembers)) {
          binding.rebind(
            current.withFacts(
              current.facts.copyWith(promotedMembers: savedMembers ?? const {}),
            ),
          );
        }
      });
    }
  }
}

bool _sameMemberMap(Map<String, TypeRef>? a, Map<String, TypeRef>? b) {
  if (a == null || a.isEmpty) return b == null || b.isEmpty;
  if (b == null || a.length != b.length) return false;
  return a.entries.every((e) => b[e.key] == e.value);
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

  /// Records a member promotion (`c._f is int`) on the saved value — the
  /// facts live on the receiver's variable so they restore with it.
  void promoteMember(String member, TypeRef type) {
    current = current.withFacts(current.facts.withPromotedMember(member, type));
  }

  LocalBinding restore() {
    binding.storage = storage;
    binding.initialized = initialized;
    final restored = current.copyWith();
    if (binding.writeCaptured) {
      final epoch = math.max(restored.writeEpoch, binding.current.writeEpoch);
      binding.rebind(
        restored
            .withType(binding.declaredType)
            .withFacts(restored.facts.cleared())
          ..writeEpoch = epoch,
      );
    } else {
      binding.rebind(restored);
    }
    return binding;
  }
}

class ContextSaveState {
  ContextSaveState.of(AbstractScopeContext context)
    : flowTerminated = context.flowTerminated {
    locals = [
      for (final scope in context.locals)
        {
          for (final entry in scope.entries)
            entry.key: SavedLocalBinding(entry.value),
        },
    ];
  }

  late final List<Map<String, SavedLocalBinding>> locals;

  /// Carries finally writes into a saved jump's proofs, retaining its SSA and
  /// storage. The finalizer accesses those bindings through exception slots.
  void applyFinallyWrites(ContextSaveState entry, ContextSaveState exit) {
    for (var frame = 0; frame < locals.length; frame++) {
      for (final slot in locals[frame].entries) {
        final before = frame < entry.locals.length
            ? entry.locals[frame][slot.key]
            : null;
        final after = frame < exit.locals.length
            ? exit.locals[frame][slot.key]
            : null;
        if (before == null ||
            after == null ||
            !identical(slot.value.binding, before.binding) ||
            !identical(after.binding, before.binding) ||
            after.current.writeEpoch <= before.current.writeEpoch) {
          continue;
        }
        final current = slot.value.current;
        slot.value.current =
            current.copyWith(
                type: after.current.type,
                facts: current.facts.cleared(),
              )
              ..writeEpoch = math.max(
                current.writeEpoch + 1,
                after.current.writeEpoch,
              );
      }
    }
  }

  /// Whether the code sequence had terminated when the state was saved.
  final bool flowTerminated;
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
