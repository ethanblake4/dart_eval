import '../ir/string.dart';
import '../ir/closures.dart';
import 'backend/representation.dart'
    show MachineRepresentation, representationForType;
import 'helpers/captures.dart';
import '../ir/exception.dart';
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
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/ir/objects.dart';
import 'package:dart_eval/src/eval/ir/primitives.dart';
import 'package:dart_eval/src/eval/ir/types.dart';

import 'errors.dart';
import 'offset_tracker.dart';

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
  final DeferredOrOffset? methodOffset;
  final ReturnType? methodReturnType;
  final bool isFinal;
  final CallingConvention callingConvention;

  bool get boxed => type.boxed;

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
    return copyWith()..captureCell = cell;
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

    if (type == CoreTypes.dynamic.ref(ctx)) {
      return copyWith(
        type: type.copyWith(boxed: true),
        representation: MachineRepresentation.object,
      );
    }

    final result = ssa;

    Variable v2 = this;

    if (type == CoreTypes.int.ref(ctx)) {
      ctx.pushOp(BoxInt(result, ssa));
    } else if (type == CoreTypes.num.ref(ctx)) {
      ctx.pushOp(BoxNum(result, ssa));
    } else if (type == CoreTypes.double.ref(ctx)) {
      ctx.pushOp(BoxDouble(result, ssa));
    } else if (type == CoreTypes.bool.ref(ctx)) {
      ctx.pushOp(BoxBool(result, ssa));
    } else if (type == CoreTypes.list.ref(ctx)) {
      if (!type.specifiedTypeArgs[0].boxed) {
        v2 = boxListContents(ctx, this);
      }
      ctx.pushOp(
        BoxList(result, v2.ssa, runtimeTypeId: type.runtimeTypeId(ctx)),
      );
    } else if (type == CoreTypes.map.ref(ctx)) {
      ctx.pushOp(BoxMap(result, ssa, runtimeTypeId: type.runtimeTypeId(ctx)));
    } else if (type == CoreTypes.set.ref(ctx)) {
      ctx.pushOp(BoxSet(result, ssa, runtimeTypeId: type.runtimeTypeId(ctx)));
    } else if (type == CoreTypes.string.ref(ctx)) {
      ctx.pushOp(BoxString(result, ssa));
    } else if (type == CoreTypes.nullType.ref(ctx)) {
      ctx.pushOp(BoxNull(result));
    } else {
      throw CompileError('Cannot box $type', source);
    }

    return copyWithUpdate(
      ctx,
      type: type.copyWith(boxed: true),
      representation: MachineRepresentation.object,
    );
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
        callingConvention: callingConvention ?? this.callingConvention,
      )
      ..name = name ?? this.name
      ..frameIndex = frameIndex ?? this.frameIndex
      ..localName = localName
      ..captureCell = captureCell
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
        return Variable.ssa(
          ctx,
          LoadConstantType(ctx.svar('var_type'), concrete.runtimeTypeId(ctx)),
          CoreTypes.type.ref(ctx),
        );
      }
      return Variable.ssa(
        ctx,
        LoadRuntimeType(ctx.svar('runtime_type'), ssa),
        CoreTypes.type.ref(ctx),
      );
    }
    final resolvedReceiver = type.resolveTypeChain(ctx);
    final resolvedField = TypeRef.lookupFieldType(
      ctx,
      resolvedReceiver,
      name,
      source: source,
    );
    if (resolvedField == null &&
        resolvedReceiver != CoreTypes.dynamic.ref(ctx) &&
        resolveInstanceDeclaration(
              ctx,
              resolvedReceiver.file,
              resolvedReceiver.name,
              name,
            ) ==
            null) {
      throw CompileError(
        'Member "$name" is not defined for type $resolvedReceiver',
        source,
      );
    }
    final fieldType =
        resolvedField?.resolveTypeChain(ctx) ?? CoreTypes.dynamic.ref(ctx);
    final receiver = boxIfNeeded(ctx);
    return Variable.ssa(
      ctx,
      LoadPropertyDynamic(
        ctx.svar(name),
        receiver.ssa,
        name,
        callerLibrary: ctx.library,
      ),
      fieldType,
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

class PossiblyValuedParameter {
  PossiblyValuedParameter(this.parameter, this.V);

  NormalFormalParameter parameter;
  Variable? V;
}
