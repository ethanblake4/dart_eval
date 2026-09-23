import '../ir/string.dart';
import '../ir/closures.dart';
import 'backend/representation.dart'
    show MachineRepresentation, representationForType;
import 'helpers/captures.dart';
import '../ir/exception.dart';
import '../ir/flow.dart' show Call;
import '../ir/collection.dart' show ListLength;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/function.dart';
import 'package:dart_eval/src/eval/compiler/expression/identifier.dart'
    show resolveInstanceDeclaration;
import 'package:dart_eval/src/eval/compiler/model/function_type.dart'
    show declaredFunctionType;
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable/value_facts.dart';
import 'package:dart_eval/src/eval/ir/objects.dart';
import 'package:dart_eval/src/eval/ir/primitives.dart';
import 'package:dart_eval/src/eval/ir/types.dart';

import 'errors.dart';
import 'package:dart_eval/src/eval/compiler/dispatch.dart';
import 'package:dart_eval/src/eval/compiler/helpers/extension.dart';
import 'package:dart_eval/src/eval/compiler/helpers/tearoff.dart';
import 'values/abi.dart';
import 'member/member_name.dart';

/// A compiler value with an SSA identity, language type and calling convention.
class Variable {
  Variable(
    TypeRef type, {
    TypeRef? declaredType,
    MachineRepresentation? representation,
    ValueRep? rep,
    this.methodOffset,
    this.methodReturnType,
    this.isFinal = false,
    List<TypeRef> concreteTypes = const [],
    TypeRef? exactType,
    bool isConstInt = false,
    bool isConst = false,
    ValueFacts? facts,
    CallingConvention? callingConvention,
  }) : type = type,
       declaredType = declaredType ?? type,
       representation =
           representation ?? rep?.bank ?? representationForType(type),
       rep =
           rep ??
           repForType(
             type,
             representation ?? rep?.bank ?? representationForType(type),
           ),
       facts =
           facts ??
           ValueFacts(
             exact: exactType,
             possibleClasses: concreteTypes,
             isConst: isConst,
             isConstInt: isConstInt,
           ),
       callingConvention =
           callingConvention ??
           ((type.isFunctionLike && methodOffset == null)
               ? CallingConvention.dynamic
               : CallingConvention.static) {
    assert(
      facts == null ||
          (concreteTypes.isEmpty &&
              exactType == null &&
              !isConst &&
              !isConstInt),
      'pass facts or the legacy fact fields, not both',
    );
  }

  factory Variable.ssa(
    CompilerContext ctx,
    Operation op,
    TypeRef type, {
    TypeRef? declaredType,
    MachineRepresentation? representation,
    ValueRep? rep,
    DeferredOrOffset? methodOffset,
    ReturnType? methodReturnType,
    bool isFinal = false,
    List<TypeRef> concreteTypes = const [],
    TypeRef? exactType,
    bool isConstInt = false,
    bool isConst = false,
    ValueFacts? facts,
    CallingConvention callingConvention = CallingConvention.static,
  }) {
    ctx.pushOp(op);
    return Variable(
      type,
      declaredType: declaredType,
      representation: representation,
      rep: rep,
      methodOffset: methodOffset,
      methodReturnType: methodReturnType,
      isFinal: isFinal,
      concreteTypes: concreteTypes,
      exactType: exactType,
      isConstInt: isConstInt,
      isConst: isConst,
      facts: facts,
      callingConvention: callingConvention,
    )..name = op.writesTo!.name;
  }

  factory Variable.of(
    CompilerContext ctx,
    SSA ssa,
    TypeRef type, {
    TypeRef? declaredType,
    MachineRepresentation? representation,
    ValueRep? rep,
    DeferredOrOffset? methodOffset,
    ReturnType? methodReturnType,
    bool isFinal = false,
    List<TypeRef> concreteTypes = const [],
    TypeRef? exactType,
    bool isConstInt = false,
    bool isConst = false,
    ValueFacts? facts,
    CallingConvention callingConvention = CallingConvention.static,
  }) {
    return Variable(
      type,
      declaredType: declaredType,
      representation: representation,
      rep: rep,
      methodOffset: methodOffset,
      methodReturnType: methodReturnType,
      isFinal: isFinal,
      concreteTypes: concreteTypes,
      exactType: exactType,
      isConstInt: isConstInt,
      isConst: isConst,
      facts: facts,
      callingConvention: callingConvention,
    )..name = ssa.name;
  }

  final TypeRef type;

  /// The stable source-level type of a binding. For temporaries this is the
  /// same as [type]; local reads may carry a narrower flow type.
  final TypeRef declaredType;

  /// Physical representation of this SSA value.
  final MachineRepresentation representation;

  /// Which value representation the SSA slot holds. Owns the boxing
  /// decision that used to live on `TypeRef.boxed`.
  final ValueRep rep;
  /// Compile-time facts known about this value: provable runtime types
  /// ([ValueFacts.exact], [ValueFacts.possibleClasses]) and constness.
  /// Mutable: reassignment replaces (not merges) the allocation proofs.
  ValueFacts facts;

  /// The possible runtime classes of the value; empty means unknown.
  List<TypeRef> get concreteTypes => facts.possibleClasses;

  /// The exact runtime type of the value, when provable — an exact type
  /// can never be a subclass instance, so it justifies devirtualization
  /// even for classes that are subclassed.
  TypeRef? get exactType => facts.exact;
  set exactType(TypeRef? v) => facts = facts.copyWith(exact: v);

  /// For a `Type`-typed value, the type it denotes.
  TypeRef? get denotedType => facts.denotedType;

  /// Whether this value is a compile-time-constant int expression —
  /// enables the `int → double` literal coercion. Dropped as soon as the
  /// value is bound or transformed.
  bool get isConstInt => facts.isConstInt;

  /// Whether this value is a compile-time-constant expression.
  bool get isConst => facts.isConst;
  final DeferredOrOffset? methodOffset;
  final ReturnType? methodReturnType;
  final bool isFinal;
  final CallingConvention callingConvention;

  /// The receiver to prepend as the first argument when this variable is
  /// invoked as a function — set on references to a member of the enclosing
  /// extension inside its own body.
  Variable? implicitReceiver;

  /// Non-null when this value came from explicit extension application
  /// `E(x)`: member lookups on it resolve only within that extension.
  BoundExtension? boundExtension;

  bool get boxed => rep.isBoxed;

  /// Returns this variable with the allocation proofs that do not survive a
  /// value change dropped: [exactType], [concreteTypes], and method tear-off
  /// info are cleared. All SSA identity and binding metadata is preserved.
  Variable widened() {
    return Variable(
        type,
        declaredType: declaredType,
        representation: representation,
        rep: rep,
        isFinal: isFinal,
        facts: facts.cleared(),
        callingConvention: callingConvention,
      )
      ..name = name
      ..frameIndex = frameIndex
      ..localName = localName
      ..captureCell = captureCell
      ..implicitReceiver = implicitReceiver
      ..exceptionSlot = exceptionSlot
      ..captureCellSlot = captureCellSlot;
  }

  /// Widens this variable's allocation proofs for a control-flow join.
  /// [incoming] are the variable's counterparts on other incoming edges.
  /// [exactType] survives only when every edge proves the same one;
  /// [concreteTypes] become the union across edges (empty on any edge means
  /// unknown); method tear-off info is dropped when it differs. Returns
  /// `this` when every edge holds this same variable.
  Variable joinedWith(Iterable<Variable> incoming) {
    var merged = facts;
    var mOffset = methodOffset;
    var mReturn = methodReturnType;
    var changed = false;
    for (final other in incoming) {
      if (identical(other, this)) continue;
      changed = true;
      merged = merged.join(other.facts);
      if (other.methodOffset != mOffset || other.methodReturnType != mReturn) {
        mOffset = null;
        mReturn = null;
      }
    }
    if (!changed) return this;
    return Variable(
        type,
        declaredType: declaredType,
        representation: representation,
        rep: rep,
        methodOffset: mOffset,
        methodReturnType: mReturn,
        isFinal: isFinal,
        facts: merged,
        callingConvention: callingConvention,
      )
      ..name = name
      ..frameIndex = frameIndex
      ..localName = localName
      ..captureCell = captureCell
      ..implicitReceiver = implicitReceiver
      ..exceptionSlot = exceptionSlot
      ..captureCellSlot = captureCellSlot;
  }

  String? name;

  /// Source binding name, independent of the SSA temporary name.
  String? localName;
  int? frameIndex;
  SSA? captureCell;
  ExceptionSlot? exceptionSlot;
  ExceptionSlot? captureCellSlot;

  Variable captureBinding(CompilerContext ctx, AstNode declaration) {
    if (!capturesFor(declaration).captured.contains(declaration)) return this;
    final cell = ctx.svar('cell');
    ctx.pushOp(NewCaptureCell(cell, ssa, representation));
    // Captured variables can be reassigned by any closure invocation, so
    // their allocation proofs are dropped.
    return widened()..captureCell = cell;
  }

  Variable readBinding(CompilerContext ctx) => exceptionSlot != null
      ? Variable.ssa(
          ctx,
          LoadExceptionSlot(ctx.svar('protected'), exceptionSlot!),
          type,
          declaredType: declaredType,
          representation: representation,
          isFinal: isFinal,
          callingConvention: callingConvention,
          methodReturnType: methodReturnType,
        )
      : captureCell == null
      ? this
      : Variable.ssa(
          ctx,
          ReadCaptureCell(ctx.svar('captured'), captureCell!, representation),
          type,
          declaredType: declaredType,
          representation: representation,
          isFinal: isFinal,
          callingConvention: callingConvention,
          methodReturnType: methodReturnType,
        );

  void renewCaptureCell(CompilerContext ctx) {
    if (captureCell == null) return;
    final previous = readBinding(ctx);
    ctx.pushOp(NewCaptureCell(captureCell!, previous.ssa, representation));
  }

  SSA get ssa => SSA(name!);

  /// Converts this value to [target] rep.
  ///
  /// Emits the needed op into [into] (a fresh SSA leaving this slot
  /// intact) or into this SSA in place when [into] is null. A same-rep
  /// conversion is a no-op unless [into] is given, which emits an [Assign].
  Variable toRep(
    CompilerContext ctx,
    ValueRep target, {
    SSA? into,
    AstNode? source,
  }) {
    if (rep == target) {
      if (into == null) return this;
      return Variable.ssa(
        ctx,
        Assign(into, ssa),
        type,
        rep: target,
        methodReturnType: methodReturnType,
        facts: facts.copyWith(isConst: false, isConstInt: false),
      );
    }
    final dest = into ?? ssa;
    if (target == ValueRep.boxed) {
      _emitBox(ctx, dest, source);
    } else if (rep == ValueRep.boxed) {
      ctx.pushOp(Unbox(dest, ssa, target.bank));
    } else {
      throw CompileError('Cannot convert $rep to $target', source);
    }
    return Variable.of(
      ctx,
      dest,
      type,
      rep: target,
      declaredType: declaredType,
      methodReturnType: methodReturnType,
      facts: facts.copyWith(isConst: false, isConstInt: false),
    );
  }

  /// Emits the op that wraps this non-boxed value into its `$Value` at
  /// [dest]. `Object`/`dynamic` in the object bank are relabels — the
  /// object bank is the uniform representation and the raw reference is
  /// already a valid boxed value; other unboxable types emit their op;
  /// the rest have no boxing path and throw (same as the old
  /// `Cannot box` CompileError).
  void _emitBox(CompilerContext ctx, SSA dest, AstNode? source) {
    switch (rep) {
      case ValueRep.int:
        ctx.pushOp(BoxInt(dest, ssa));
      case ValueRep.double:
        ctx.pushOp(BoxDouble(dest, ssa));
      case ValueRep.bool:
        ctx.pushOp(BoxBool(dest, ssa));
      case ValueRep.string:
        ctx.pushOp(BoxString(dest, ssa));
      case ValueRep.nativeNull:
        ctx.pushOp(BoxNull(dest));
      case ValueRep.nativeList:
        // Collection elements are always boxed (Abi.collectionElement), so a
        // native list's contents never need re-boxing on the way out.
        ctx.pushOp(
          BoxList(dest, ssa, runtimeTypeId: ctx.runtimeTypes.idOf(type)),
        );
      case ValueRep.nativeMap:
        ctx.pushOp(
          BoxMap(dest, ssa, runtimeTypeId: ctx.runtimeTypes.idOf(type)),
        );
      case ValueRep.nativeSet:
        ctx.pushOp(
          BoxSet(dest, ssa, runtimeTypeId: ctx.runtimeTypes.idOf(type)),
        );
      case ValueRep.nativeObject:
        // The object bank is already the uniform representation, so boxing
        // is a relabel. A distinct [dest] slot still needs a definition.
        if (dest != ssa) ctx.pushOp(Assign(dest, ssa));
      case ValueRep.boxed:
        break;
    }
  }

  /// Boxes the variable, if it isn't yet. Does nothing with a dynamic
  /// type. Pushes a proper operator to box this value on the frame, and
  /// returns this instance with the type marked as boxed.
  Variable boxIfNeeded(ScopeContext ctx, [AstNode? source]) {
    if (boxed) return this;
    final converted = toRep(
      ctx as CompilerContext,
      ValueRep.boxed,
      source: source,
    );
    return copyWithUpdate(
      ctx,
      type: converted.type,
      representation: converted.representation,
      rep: converted.rep,
    );
  }

  /// Boxes this value into a fresh SSA slot instead of boxing the current
  /// slot in place, leaving this variable's SSA representation intact. Used
  /// when the current slot must keep its unboxed representation (e.g. a local
  /// that is read again later).
  Variable boxIntoFreshSlot(CompilerContext ctx, [AstNode? source]) {
    if (boxed) {
      return Variable.ssa(
        ctx,
        Assign(ctx.svar('box_copy'), ssa),
        type,
        methodReturnType: methodReturnType,
        facts: facts.copyWith(isConst: false, isConstInt: false),
      );
    }
    if (rep == ValueRep.nativeObject &&
        (type.isSpec(CoreTypes.dynamic) || type.isSpec(CoreTypes.object))) {
      return copyWith(rep: ValueRep.boxed);
    }
    return toRep(ctx, ValueRep.boxed, into: ctx.svar('boxed'), source: source);
  }

  /// Unboxes this variable, if it isn't yet. Unlike [boxIfNeeded],
  /// pushes the [Unbox] operator also for dynamic variables.
  ///
  /// By default updates the variable in the context locals.
  /// Set [update] to false if that's not desired.
  Variable unboxIfNeeded(CompilerContext ctx, [bool update = true]) {
    // Collection instructions accept the canonical wrapper's interfaces. Keeping
    // that wrapper avoids treating a representation-preserving move as unboxing
    // and then wrapping it a second time when the value leaves this function.
    if (!boxed ||
        type.isSpec(CoreTypes.list) ||
        type.isSpec(CoreTypes.map) ||
        type.isSpec(CoreTypes.set)) {
      return this;
    }
    final converted = toRep(
      ctx,
      unboxedRepOf(type),
      into: update ? null : ctx.svar('unboxed'),
    );
    return update
        ? copyWithUpdate(
            ctx,
            type: converted.type,
            representation: converted.representation,
            rep: converted.rep,
          )
        : converted;
  }

  /// Emits [Assign] copying this value into a fresh SSA slot, preserving its
  /// type, representation and facts. Used when evaluating a following
  /// operand may change a local's slot or representation. The copy is
  /// detached from this variable's binding — boxing/unboxing it must not
  /// rewrite the binding it was copied from.
  Variable copyIntoFreshSlot(CompilerContext ctx, String svar) {
    return Variable.ssa(
      ctx,
      Assign(ctx.svar(svar), ssa),
      type,
      rep: rep,
      methodReturnType: methodReturnType,
      facts: facts.copyWith(isConst: false, isConstInt: false),
    );
  }

  /// Returns a copy of this variable whose static type is [type], keeping
  /// the same physical representation. Used by promotion and `as` casts —
  /// the representation never changes when only the type view narrows.
  Variable withType(TypeRef type, {ValueRep? rep}) {
    return copyWith(type: type, rep: rep ?? this.rep);
  }

  /// Returns a copy of this variable carrying [facts] instead of its own.
  Variable withFacts(ValueFacts facts) => copyWith(facts: facts);

  /// Returns a variable with the same name from the context locals.
  /// Iterates over all frames and returns the first found one.
  /// If not found, returns this instance.
  Variable updated(ScopeContext ctx) {
    if (localName == null) return this;
    return ctx.lookupLocal(localName!) ?? this;
  }

  /// Makes a copy of the variable with some fields updated.
  Variable copyWith({
    TypeRef? type,
    TypeRef? declaredType,
    MachineRepresentation? representation,
    ValueRep? rep,
    DeferredOrOffset? methodOffset,
    ReturnType? methodReturnType,
    bool? isFinal,
    bool? isConst,
    String? name,
    int? frameIndex,
    List<TypeRef>? concreteTypes,
    TypeRef? exactType,
    ValueFacts? facts,
    CallingConvention? callingConvention,
  }) {
    final newFacts = facts ??
        this.facts.copyWith(
          possibleClasses: concreteTypes,
          exact: exactType,
          isConst: isConst,
          // The literal-int marker only applies to the literal expression
          // itself; any copy drops it.
          isConstInt: false,
        );
    return Variable(
        type ?? this.type,
        declaredType: declaredType ?? this.declaredType,
        representation: representation ?? this.representation,
        rep: rep ?? this.rep,
        methodOffset: methodOffset ?? this.methodOffset,
        isFinal: isFinal ?? this.isFinal,
        methodReturnType: methodReturnType ?? this.methodReturnType,
        facts: newFacts,
        callingConvention: callingConvention ?? this.callingConvention,
      )
      ..name = name ?? this.name
      ..frameIndex = frameIndex ?? this.frameIndex
      ..localName = localName
      ..captureCell = captureCell
      ..implicitReceiver = implicitReceiver
      ..boundExtension = boundExtension
      ..exceptionSlot = exceptionSlot
      ..captureCellSlot = captureCellSlot;
  }

  /// Makes a copy of the variable with some fields updated, and also
  /// updates the reference on the context frame.
  Variable copyWithUpdate(
    ScopeContext? ctx, {
    TypeRef? type,
    TypeRef? declaredType,
    MachineRepresentation? representation,
    ValueRep? rep,
    DeferredOrOffset? methodOffset,
    ReturnType? methodReturnType,
    String? name,
    int? frameIndex,
    List<TypeRef>? concreteTypes,
    ValueFacts? facts,
  }) {
    var uV = copyWith(
      type: type,
      declaredType: declaredType,
      representation: representation,
      rep: rep,
      methodOffset: methodOffset,
      methodReturnType: methodReturnType,
      name: name,
      frameIndex: frameIndex,
      concreteTypes: concreteTypes,
      facts: facts,
    );

    if (uV.localName != null && uV.frameIndex != null && ctx != null) {
      ctx.locals[uV.frameIndex!][uV.localName!] = uV;
    }

    return uV;
  }

  void inferType(CompilerContext ctx, TypeRef type) {
    if (localName != null &&
        frameIndex != null &&
        ctx.typeInferenceSaveStates.isNotEmpty) {
      final locals = ctx.typeInferenceSaveStates.last.locals;
      locals[frameIndex!][localName!] = locals[frameIndex!][localName!]!
          .copyWith(type: type);
    }
  }

  Variable getProperty(CompilerContext ctx, String name, {AstNode? source}) {
    // A bare function reference has no SSA value; materialize the tear-off
    // first so members like `hashCode`/`runtimeType` resolve on it.
    if (this.name == null && methodOffset != null) {
      return tearOff(ctx).getProperty(ctx, name, source: source);
    }
    if (name == 'length' && !type.nullable) {
      final isString = type.isAssignableTo(
        ctx,
        CoreTypes.string.ref(ctx),
        forceAllowDynamic: false,
      );
      // A declared List may be an evaluated class with an overridden getter.
      // Only a natively-held core List proves native storage at this point.
      final isList = rep == ValueRep.nativeList && type.isSpec(CoreTypes.list);
      if (isString || isList) {
        final receiver = unboxIfNeeded(ctx, false);
        return Variable.ssa(
          ctx,
          isString
              ? StringOperation(
                  ctx.svar('string_length'),
                  StringOperator.length,
                  receiver.ssa,
                )
              : ListLength(ctx.svar('list_length'), receiver.ssa),
          CoreTypes.int.ref(ctx),
          rep: ValueRep.int,
        );
      }
    }
    final resolvedReceiver = ctx.typeSystem.throughTypeParameters(type);
    if (name == 'runtimeType') {
      // `runtimeType` is overridable like any other getter — only
      // intrinsify it when the receiver's class doesn't declare it and
      // no descendant overrides it (otherwise dispatch normally).
      final declaredLocally =
          ctx
              .instanceDeclarationPositions[resolvedReceiver
                  .file]?[resolvedReceiver.name]?[0]
              ?.containsKey('runtimeType') ??
          false;
      final overridable =
          declaredLocally ||
          memberOwner(ctx, resolvedReceiver, 'runtimeType', kind: 0) != null ||
          ctx.memberOverriddenInSubclass(
            resolvedReceiver.file,
            resolvedReceiver.name,
            'runtimeType',
          );
      if (!overridable) {
        if (concreteTypes.isNotEmpty) {
          final concrete = concreteTypes[0];
          final typeId = ctx.runtimeTypes.idOf(concrete);
          final operation = concrete.requiresTypeEnvironment
              ? LoadTypeParameter(ctx.svar('var_type'), typeId)
              : LoadConstantType(ctx.svar('var_type'), typeId);
          return Variable.ssa(ctx, operation, CoreTypes.type.ref(ctx));
        }
        return Variable.ssa(
          ctx,
          LoadRuntimeType(ctx.svar('runtime_type'), ssa),
          CoreTypes.type.ref(ctx),
        );
      }
    }
    // Explicit application `E(x)` pins member resolution to E's members.
    if (boundExtension case final bound?) {
      final getter = extensionMember(bound.ext, name, getter: true);
      if (getter != null) {
        return invokeExtensionGetter(
          ctx,
          this,
          bound.ext,
          getter,
          bound.onBindings,
        );
      }
      final member = extensionMember(bound.ext, name);
      if (member == null) {
        throw CompileError(
          'Extension ${bound.ext.name} has no member $name',
          source,
        );
      }
      return _extensionMethodTearOff(
        ctx,
        bound.ext,
        member,
        extBindingsMap(bound.ext, bound.onBindings),
      );
    }
    final resolvedField = TypeRef.lookupFieldType(
      ctx,
      resolvedReceiver,
      name,
      source: source,
    );
    final member =
        resolvedField == null && !resolvedReceiver.isSpec(CoreTypes.dynamic)
        ? resolveInstanceDeclaration(
            ctx,
            resolvedReceiver.file,
            resolvedReceiver.name,
            name,
            instantiated: resolvedReceiver,
          )
        : null;
    if (resolvedField == null &&
        !resolvedReceiver.isSpec(CoreTypes.dynamic) &&
        member == null) {
      // An extension getter may apply.
      final found = resolveExtensionMember(
        ctx,
        resolvedReceiver,
        name,
        getter: true,
      );
      if (found != null) {
        return invokeExtensionGetter(ctx, this, found.$1, found.$2, found.$3);
      }
      // An extension method read produces a bound tear-off; the receiver is
      // carried through [implicitReceiver] for direct invocation.
      final foundMethod = resolveExtensionMember(ctx, resolvedReceiver, name);
      if (foundMethod != null) {
        return _extensionMethodTearOff(
          ctx,
          foundMethod.$1,
          foundMethod.$2,
          extBindingsMap(foundMethod.$1, foundMethod.$3),
        );
      }
      throw CompileError(
        'Member "$name" is not defined for type $resolvedReceiver',
        source,
      );
    }
    final method = member?.$2.declaration;
    final bridge = member?.$2.bridge;
    // Generic method signatures can't be resolved outside their own scope.
    final isDeclaredMethod =
        method is MethodDeclaration &&
        !method.isGetter &&
        !method.isSetter &&
        method.typeParameters == null;
    final isBridgeMethod = bridge is BridgeMethodDef;

    // A method member read produces a tear-off; carry its signature so calls
    // through the result stay typed.
    final TypeRef fieldType;
    final ReturnType? methodReturnType;
    if (isDeclaredMethod) {
      // The declaring class's type parameters bind to its instantiated view
      // (`member.$1`) — `b.remove` on `B extends A<int>` sees `T: int`.
      final methodHost = method.parent?.parent;
      final hostParams = methodHost is Declaration
          ? classLikeClauses(methodHost).$4?.typeParameters ?? const []
          : const <TypeParameter>[];
      final hostArgs = member!.$1.typeArguments;
      fieldType = declaredFunctionType(
        ctx,
        resolvedReceiver.file,
        method.parameters,
        method.returnType,
        method.typeParameters,
        memberTypeParameters: {
          for (var i = 0; i < hostParams.length && i < hostArgs.length; i++)
            hostParams[i].name.lexeme: hostArgs[i],
        },
      );
      methodReturnType = AlwaysReturnType.fromInstanceMethod(
        ctx,
        resolvedReceiver,
        name,
        CoreTypes.dynamic.ref(ctx),
      );
    } else if (isBridgeMethod) {
      fieldType = CoreTypes.function.ref(ctx);
      methodReturnType = bridgeFunctionReturnType(
        ctx,
        bridge.functionDescriptor,
        specifiedType: resolvedReceiver,
      );
    } else {
      fieldType = resolvedField ?? CoreTypes.dynamic.ref(ctx);
      methodReturnType = null;
    }
    final receiver = boxIfNeeded(ctx);
    final exact = exactType;
    if (exact != null && !hasBridgeSuperclass(ctx, exact)) {
      // Storage for an inherited field lives on its declaring class's link,
      // reached from the receiver by LoadSuper hops. First locate the owning
      // link, then emit the hops.
      final links = [exact, ...ctx.typeSystem.superclassChain(exact)];
      var depth = -1;
      int? fieldIndex;
      for (var i = 0; i < links.length; i++) {
        final link = links[i];
        final index = ctx.instanceGetterIndices[link.file]?[link.name]?[name];
        if (index != null) {
          fieldIndex = index;
          depth = i;
          break;
        }
        final key = name.startsWith('_')
            ? MemberName(
                name,
                MemberKind.method,
                privateLibraryUri: ctx.libraryUri(link.file),
              ).nameKey
            : name;
        if ((ctx.instanceDeclarationPositions[link.file]?[link.name]?[0]
                        as Map?)
                    ?.containsKey(key) ==
                true &&
            concreteMemberDecl(ctx, link, name, kind: 0) != null) {
          depth = i;
          break;
        }
      }
      if (depth >= 0) {
        final link = links[depth];
        // Field members resolve to their [VariableDeclaration]; real
        // accessors resolve to [MethodDeclaration]. Field storage is
        // link-relative so it always needs the declaring link; a real
        // accessor needs it only when its body uses `super`.
        final decl = resolveInstanceDeclaration(
          ctx,
          link.file,
          link.name,
          name,
          instantiated: link,
        )?.$2.declaration;
        final fieldDecl = decl is VariableDeclaration
            ? decl.parent?.parent
            : null;
        final needsLink =
            fieldIndex != null ||
            memberNeedsOwnerLink(ctx, link, name, kind: 0);
        var linkSsa = receiver.ssa;
        if (needsLink) {
          for (var i = 0; i < depth; i++) {
            final parent = links[i + 1];
            linkSsa = Variable.ssa(
              ctx,
              LoadSuper(ctx.svar('super'), linkSsa),
              parent,
              concreteTypes: [parent],
            ).ssa;
          }
        }
        if (fieldIndex != null) {
          final isLate =
              fieldDecl is FieldDeclaration && fieldDecl.fields.isLate;
          return Variable.ssa(
            ctx,
            LoadPropertyStatic(
              ctx.svar(name),
              linkSsa,
              fieldIndex,
              isLate: isLate,
            ),
            fieldType,
            rep: ValueRep.boxed,
          );
        }
        final key = name.startsWith('_')
            ? MemberName(
                name,
                MemberKind.method,
                privateLibraryUri: ctx.libraryUri(link.file),
              ).nameKey
            : name;
        return Variable.ssa(
          ctx,
          Call(
            DeferredOrOffset(
              file: link.file,
              className: link.name,
              methodType: 0,
              name: key,
            ),
            [linkSsa],
            result: ctx.svar(name),
            typeEnvironmentReceiver: receiver.ssa,
          ),
          fieldType,
          rep: ValueRep.boxed,
        );
      }
    }
    if (exact == null &&
        concreteTypes.length == 1 &&
        !hasBridgeSuperclass(ctx, concreteTypes.first)) {
      // The receiver may hold a subclass: a getter can be called directly on
      // the dispatch root only when it isn't overridden and its body never
      // touches `super` (so any link works as `this`).
      final owner = directMemberOwner(ctx, concreteTypes.first, name, kind: 0);
      if (owner != null && !memberNeedsOwnerLink(ctx, owner, name, kind: 0)) {
        final key = name.startsWith('_')
            ? '${ctx.libraryUri(owner.file)}::$name'
            : name;
        return Variable.ssa(
          ctx,
          Call(
            DeferredOrOffset(
              file: owner.file,
              className: owner.name,
              methodType: 0,
              name: key,
            ),
            [receiver.ssa],
            result: ctx.svar(name),
            typeEnvironmentReceiver: receiver.ssa,
          ),
          fieldType,
          rep: ValueRep.boxed,
        );
      }
    }
    return Variable.ssa(
      ctx,
      LoadPropertyDynamic(
        ctx.svar(name),
        receiver.ssa,
        name,
        callerLibrary: ctx.library,
      ),
      fieldType,
      rep: ValueRep.boxed,
      methodReturnType: methodReturnType,
      callingConvention: isDeclaredMethod || isBridgeMethod
          ? CallingConvention.dynamic
          : CallingConvention.static,
    );
  }

  /// A bound tear-off of extension [member]: the receiver travels via
  /// [implicitReceiver] so a direct invocation prepends it as the first
  /// argument.
  Variable _extensionMethodTearOff(
    CompilerContext ctx,
    EvalExtension ext,
    MethodDeclaration member,
    Map<String, TypeRef> typeParameters,
  ) {
    return Variable(
      CoreTypes.function.ref(ctx),
      methodOffset: DeferredOrOffset(
        file: ext.library,
        name: ext.memberKey(member),
      ),
      methodReturnType: AlwaysReturnType.fromAnnotation(
        ctx,
        ext.library,
        member.returnType,
        CoreTypes.dynamic.ref(ctx),
        typeParameters: {
          ...typeParameters,
          for (final param
              in member.typeParameters?.typeParameters ??
                  const <TypeParameter>[])
            param.name.lexeme: TypeRef.unresolved(
              ext.library,
              param.name.lexeme,
            ),
        },
      ),
      callingConvention: CallingConvention.static,
    )..implicitReceiver = this;
  }

  static List<Variable> boxUnboxMultiple(
    CompilerContext ctx,
    List<Variable> variables,
    bool boxed,
  ) {
    final vlist = [...variables];
    final out = <Variable>[];

    for (var i = 0; i < vlist.length; i++) {
      final v = vlist[i];
      final set = boxed ? v.boxIfNeeded(ctx) : v.unboxIfNeeded(ctx);
      out.add(set);
      for (var j = i + 1; j < vlist.length; j++) {
        final v2 = vlist[j];
        // not great for large variable lists, but since most variable lists are small...
        if (v2.name == v.name) {
          vlist[j] = set;
        }
      }
    }

    return out;
  }

  @override
  String toString() {
    final varName = name == null ? 'unnamed' : '"$name"';
    return 'Variable{$varName, $type, '
        '${methodOffset == null ? '' : 'method: $methodReturnType $methodOffset, '}'
        '${boxed ? 'boxed' : 'unboxed'}, F[$frameIndex]}';
  }
}

class InvokeResult {
  const InvokeResult(
    this.target,
    this.result,
    this.args, {
    this.namedArgs = const {},
  });

  final Variable? target;
  final Variable result;
  final List<Variable> args;
  final Map<String, Variable> namedArgs;
}
