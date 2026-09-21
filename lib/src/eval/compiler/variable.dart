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
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/collection/list.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/function.dart';
import 'package:dart_eval/src/eval/compiler/expression/identifier.dart'
    show resolveInstanceDeclaration;
import 'package:dart_eval/src/eval/compiler/model/function_type.dart'
    show declaredFunctionType;
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/ir/objects.dart';
import 'package:dart_eval/src/eval/ir/primitives.dart';
import 'package:dart_eval/src/eval/ir/types.dart';

import 'errors.dart';
import 'package:dart_eval/src/eval/compiler/dispatch.dart';
import 'package:dart_eval/src/eval/compiler/helpers/extension.dart';

/// A compiler value with an SSA identity, language type and calling convention.
class Variable {
  Variable(
    this.type, {
    TypeRef? declaredType,
    MachineRepresentation? representation,
    this.methodOffset,
    this.methodReturnType,
    this.isFinal = false,
    this.concreteTypes = const [],
    this.exactType,
    this.isConstInt = false,
    CallingConvention? callingConvention,
  }) : declaredType = declaredType ?? type,
       representation = representation ?? representationForType(type),
       callingConvention =
           callingConvention ??
           ((type == TypeRef(dartCoreFile, 'Function') && methodOffset == null)
               ? CallingConvention.dynamic
               : CallingConvention.static);

  factory Variable.ssa(
    CompilerContext ctx,
    Operation op,
    TypeRef type, {
    TypeRef? declaredType,
    MachineRepresentation? representation,
    DeferredOrOffset? methodOffset,
    ReturnType? methodReturnType,
    bool isFinal = false,
    List<TypeRef> concreteTypes = const [],
    TypeRef? exactType,
    bool isConstInt = false,
    CallingConvention callingConvention = CallingConvention.static,
  }) {
    ctx.pushOp(op);
    return Variable(
      type,
      declaredType: declaredType,
      representation: representation,
      methodOffset: methodOffset,
      methodReturnType: methodReturnType,
      isFinal: isFinal,
      concreteTypes: concreteTypes,
      exactType: exactType,
      isConstInt: isConstInt,
      callingConvention: callingConvention,
    )..name = op.writesTo!.name;
  }

  factory Variable.of(
    CompilerContext ctx,
    SSA ssa,
    TypeRef type, {
    TypeRef? declaredType,
    MachineRepresentation? representation,
    DeferredOrOffset? methodOffset,
    ReturnType? methodReturnType,
    bool isFinal = false,
    List<TypeRef> concreteTypes = const [],
    TypeRef? exactType,
    bool isConstInt = false,
    CallingConvention callingConvention = CallingConvention.static,
  }) {
    return Variable(
      type,
      declaredType: declaredType,
      representation: representation,
      methodOffset: methodOffset,
      methodReturnType: methodReturnType,
      isFinal: isFinal,
      concreteTypes: concreteTypes,
      exactType: exactType,
      isConstInt: isConstInt,
      callingConvention: callingConvention,
    )..name = ssa.name;
  }

  final TypeRef type;

  /// The stable source-level type of a binding. For temporaries this is the
  /// same as [type]; local reads may carry a narrower flow type.
  final TypeRef declaredType;

  /// Physical representation of this SSA value.
  final MachineRepresentation representation;
  final List<TypeRef> concreteTypes;

  /// The exact runtime type of the value, when it is provably exactly this
  /// type (set at allocation sites: literals, constructor calls). Unlike
  /// [concreteTypes], an exact type can never be a subclass instance, so it
  /// justifies devirtualization even for classes that are subclassed.
  /// Not final: reassignment must replace (not merge) the allocation type.
  TypeRef? exactType;

  /// Whether this value is an integer literal or compile-time constant int
  /// expression. Dart's `int → double` coercion applies only to such
  /// expressions (`double d = 5`), never to int-typed variables. Not carried
  /// by [copyWith]/[widened], so it is dropped as soon as the value is bound
  /// or transformed.
  final bool isConstInt;
  final DeferredOrOffset? methodOffset;
  final ReturnType? methodReturnType;
  final bool isFinal;
  final CallingConvention callingConvention;

  /// The receiver to prepend as the first argument when this variable is
  /// invoked as a function — set on references to a member of the enclosing
  /// extension inside its own body.
  Variable? implicitReceiver;

  bool get boxed => type.boxed;

  /// Returns this variable with the allocation proofs that do not survive a
  /// value change dropped: [exactType], [concreteTypes], and method tear-off
  /// info are cleared. All SSA identity and binding metadata is preserved.
  Variable widened() {
    return Variable(
        type,
        declaredType: declaredType,
        representation: representation,
        isFinal: isFinal,
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
    var exact = exactType;
    var concrete = concreteTypes;
    var mOffset = methodOffset;
    var mReturn = methodReturnType;
    var changed = false;
    for (final other in incoming) {
      if (identical(other, this)) continue;
      changed = true;
      if (other.exactType != exact) exact = null;
      concrete = concrete.isEmpty || other.concreteTypes.isEmpty
          ? const []
          : {...concrete, ...other.concreteTypes}.toList();
      if (other.methodOffset != mOffset ||
          other.methodReturnType != mReturn) {
        mOffset = null;
        mReturn = null;
      }
    }
    if (!changed) return this;
    return Variable(
        type,
        declaredType: declaredType,
        representation: representation,
        methodOffset: mOffset,
        methodReturnType: mReturn,
        isFinal: isFinal,
        concreteTypes: concrete,
        exactType: exact,
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

  /// Boxes the variable, if it isn't yet. Does nothing with a dynamic
  /// type. Pushes a proper operator to box this value on the frame, and
  /// returns this instance with the type marked as boxed.
  Variable boxIfNeeded(ScopeContext ctx, [AstNode? source]) {
    if (boxed) {
      return this;
    }

    ctx as CompilerContext;

    if (type == CoreTypes.dynamic.ref(ctx) ||
        type == CoreTypes.object.ref(ctx)) {
      return copyWith(
        type: type.copyWith(boxed: true),
        representation: MachineRepresentation.object,
      );
    }

    _emitBoxOp(ctx, ssa, this, source);

    return copyWithUpdate(
      ctx,
      type: type.copyWith(boxed: true),
      representation: MachineRepresentation.object,
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
        concreteTypes: concreteTypes,
        exactType: exactType,
      );
    }
    if (type == CoreTypes.dynamic.ref(ctx) ||
        type == CoreTypes.object.ref(ctx)) {
      return copyWith(type: type.copyWith(boxed: true));
    }
    final result = ctx.svar('boxed');
    _emitBoxOp(ctx, result, this, source);
    return Variable.of(
      ctx,
      result,
      type.copyWith(boxed: true),
      methodReturnType: methodReturnType,
      concreteTypes: concreteTypes,
      exactType: exactType,
    );
  }

  void _emitBoxOp(
    CompilerContext ctx,
    SSA result,
    Variable V,
    AstNode? source,
  ) {
    Variable v2 = V;
    final source_ = V.ssa;

    if (type == CoreTypes.int.ref(ctx)) {
      ctx.pushOp(BoxInt(result, source_));
    } else if (type == CoreTypes.num.ref(ctx)) {
      ctx.pushOp(BoxNum(result, source_));
    } else if (type == CoreTypes.double.ref(ctx)) {
      ctx.pushOp(BoxDouble(result, source_));
    } else if (type == CoreTypes.bool.ref(ctx)) {
      ctx.pushOp(BoxBool(result, source_));
    } else if (type == CoreTypes.list.ref(ctx)) {
      if (!type.specifiedTypeArgs[0].boxed) {
        v2 = boxListContents(ctx, V);
      }
      ctx.pushOp(
        BoxList(result, v2.ssa, runtimeTypeId: type.runtimeTypeId(ctx)),
      );
    } else if (type == CoreTypes.map.ref(ctx)) {
      ctx.pushOp(BoxMap(result, source_, runtimeTypeId: type.runtimeTypeId(ctx)));
    } else if (type == CoreTypes.set.ref(ctx)) {
      ctx.pushOp(BoxSet(result, source_, runtimeTypeId: type.runtimeTypeId(ctx)));
    } else if (type == CoreTypes.string.ref(ctx)) {
      ctx.pushOp(BoxString(result, source_));
    } else if (type == CoreTypes.nullType.ref(ctx)) {
      ctx.pushOp(BoxNull(result));
    } else {
      throw CompileError('Cannot box $type', source);
    }
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
        type == CoreTypes.list.ref(ctx) ||
        type == CoreTypes.map.ref(ctx) ||
        type == CoreTypes.set.ref(ctx)) {
      return this;
    }
    final target = update ? ssa : ctx.svar('unboxed');
    final targetRepresentation = representationForType(
      type.copyWith(boxed: false),
    );
    ctx.pushOp(Unbox(target, ssa, targetRepresentation));
    return update
        ? copyWithUpdate(
            ctx,
            type: type.copyWith(boxed: false),
            representation: targetRepresentation,
          )
        : Variable.of(
            ctx,
            target,
            type.copyWith(boxed: false),
            declaredType: declaredType,
            representation: targetRepresentation,
            concreteTypes: concreteTypes,
            exactType: exactType,
          );
  }

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
    DeferredOrOffset? methodOffset,
    ReturnType? methodReturnType,
    bool? isFinal,
    String? name,
    int? frameIndex,
    List<TypeRef>? concreteTypes,
    TypeRef? exactType,
    CallingConvention? callingConvention,
  }) {
    return Variable(
        type ?? this.type,
        declaredType: declaredType ?? this.declaredType,
        representation: representation ?? this.representation,
        methodOffset: methodOffset ?? this.methodOffset,
        isFinal: isFinal ?? this.isFinal,
        methodReturnType: methodReturnType ?? this.methodReturnType,
        concreteTypes: concreteTypes ?? this.concreteTypes,
        exactType: exactType ?? this.exactType,
        callingConvention: callingConvention ?? this.callingConvention,
      )
      ..name = name ?? this.name
      ..frameIndex = frameIndex ?? this.frameIndex
      ..localName = localName
      ..captureCell = captureCell
      ..implicitReceiver = implicitReceiver
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
    DeferredOrOffset? methodOffset,
    ReturnType? methodReturnType,
    String? name,
    int? frameIndex,
    List<TypeRef>? concreteTypes,
  }) {
    var uV = copyWith(
      type: type,
      declaredType: declaredType,
      representation: representation,
      methodOffset: methodOffset,
      methodReturnType: methodReturnType,
      name: name,
      frameIndex: frameIndex,
      concreteTypes: concreteTypes,
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
    if (name == 'length' && !type.nullable) {
      final isString = type.isAssignableTo(
        ctx,
        CoreTypes.string.ref(ctx),
        forceAllowDynamic: false,
      );
      // A declared List may be an evaluated class with an overridden getter.
      // Only an unboxed core List proves native storage at this point.
      final isList = !type.boxed && type == CoreTypes.list.ref(ctx);
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
          CoreTypes.int.ref(ctx).copyWith(boxed: false),
        );
      }
    }
    if (name == 'runtimeType') {
      if (concreteTypes.isNotEmpty) {
        final concrete = concreteTypes[0];
        final typeId = concrete.runtimeTypeId(ctx);
        final operation = concrete.requiresTypeEnvironment
            ? LoadTypeParameter(ctx.svar('var_type'), typeId)
            : LoadConstantType(ctx.svar('var_type'), typeId);
        return Variable.ssa(
          ctx,
          operation,
          CoreTypes.type.ref(ctx),
        );
      }
      return Variable.ssa(
        ctx,
        LoadRuntimeType(ctx.svar('runtime_type'), ssa),
        CoreTypes.type.ref(ctx),
      );
    }
    var resolvedReceiver = type.resolveTypeChain(ctx);
    if (resolvedReceiver.isTypeParameter) {
      resolvedReceiver = resolvedReceiver.typeParameterBound
              ?.resolveTypeChain(ctx) ??
          resolvedReceiver;
    }
    final resolvedField = TypeRef.lookupFieldType(
      ctx,
      resolvedReceiver,
      name,
      source: source,
    );
    final member =
        resolvedField == null && resolvedReceiver != CoreTypes.dynamic.ref(ctx)
        ? resolveInstanceDeclaration(
            ctx,
            resolvedReceiver.file,
            resolvedReceiver.name,
            name,
            instantiated: resolvedReceiver,
          )
        : null;
    if (resolvedField == null &&
        resolvedReceiver != CoreTypes.dynamic.ref(ctx) &&
        member == null) {
      // An extension getter may apply.
      final found = resolveExtensionMember(
        ctx,
        resolvedReceiver,
        name,
        getter: true,
      );
      if (found != null) {
        return invokeExtensionGetter(ctx, this, found.$1, found.$2);
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
      final hostParams =
          methodHost is Declaration
              ? classLikeClauses(methodHost).$4?.typeParameters ?? const []
              : const <TypeParameter>[];
      final hostArgs = member!.$1.specifiedTypeArgs;
      fieldType = declaredFunctionType(
        ctx,
        resolvedReceiver.file,
        method.parameters,
        method.returnType,
        method.typeParameters,
        memberTypeParameters: {
          for (
            var i = 0;
            i < hostParams.length && i < hostArgs.length;
            i++
          )
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
      fieldType =
          resolvedField?.resolveTypeChain(ctx) ?? CoreTypes.dynamic.ref(ctx);
      methodReturnType = null;
    }
    final receiver = boxIfNeeded(ctx);
    final exact = exactType;
    if (exact != null && resolvedField != null) {
      // An own field on a value allocated exactly as this type: the field
      // load itself runs inline — no getter call, no dynamic lookup.
      final index =
          ctx.instanceGetterIndices[exact.file]?[exact.name]?[name];
      if (index != null) {
        final decl = resolveInstanceDeclaration(
          ctx,
          exact.file,
          exact.name,
          name,
          instantiated: exact,
        )?.$2
            .declaration;
        final isLate = decl is FieldDeclaration && decl.fields.isLate;
        return Variable.ssa(
          ctx,
          LoadPropertyStatic(
            ctx.svar(name),
            receiver.ssa,
            index,
            isLate: isLate,
          ),
          fieldType,
        );
      }
    }
    // A getter declared on the exact allocation type runs a fixed-offset
    // call. Inexact receivers can't use it: the getter indexes the
    // receiver's own storage directly, which only the allocation-typed
    // node lays out correctly.
    if (exact != null) {
      final ownerType = exact;
      final key = name.startsWith('_')
          ? '${ctx.libraryUri(ownerType.file)}::$name'
          : name;
      if ((ctx.instanceDeclarationPositions[ownerType.file]?[ownerType
                  .name]?[0]
              as Map?)
              ?.containsKey(key) ==
          true) {
        return Variable.ssa(
          ctx,
          Call(
            DeferredOrOffset(
              file: ownerType.file,
              className: ownerType.name,
              methodType: 0,
              name: key,
            ),
            [receiver.ssa],
            result: ctx.svar(name),
            typeEnvironmentReceiver: receiver.ssa,
          ),
          fieldType,
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
      methodReturnType: methodReturnType,
      callingConvention: isDeclaredMethod || isBridgeMethod
          ? CallingConvention.dynamic
          : CallingConvention.static,
    );
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
