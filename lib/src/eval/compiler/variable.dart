import 'package:analyzer/dart/ast/ast.dart';
import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/function.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/ir/objects.dart';
import 'package:dart_eval/src/eval/ir/primitives.dart';
import 'package:dart_eval/src/eval/ir/types.dart';
import 'errors.dart';
import 'offset_tracker.dart';

class Variable {
  Variable(this.scopeFrameOffset, this.type,
      {this.methodOffset,
      this.methodReturnType,
      this.isFinal = false,
      this.concreteTypes = const [],
      CallingConvention? callingConvention})
      : this.callingConvention = callingConvention ??
            ((type == TypeRef(dartCoreFile, 'Function') && methodOffset == null)
                ? CallingConvention.dynamic
                : CallingConvention.static);

  factory Variable.alloc(ScopeContext ctx, TypeRef type,
      {DeferredOrOffset? methodOffset,
      ReturnType? methodReturnType,
      bool isFinal = false,
      List<TypeRef> concreteTypes = const [],
      CallingConvention callingConvention = CallingConvention.static}) {
    ctx.allocNest.last++;
    return Variable(ctx.scopeFrameOffset++, type,
        methodOffset: methodOffset,
        methodReturnType: methodReturnType,
        isFinal: isFinal,
        concreteTypes: concreteTypes,
        callingConvention: callingConvention);
  }

  factory Variable.ssa(CompilerContext ctx, Operation op, TypeRef type,
      {DeferredOrOffset? methodOffset,
      ReturnType? methodReturnType,
      bool isFinal = false,
      List<TypeRef> concreteTypes = const [],
      CallingConvention callingConvention = CallingConvention.static}) {
    ctx.pushOp(op);
    return Variable(-1, type,
        methodOffset: methodOffset,
        methodReturnType: methodReturnType,
        isFinal: isFinal,
        concreteTypes: concreteTypes,
        callingConvention: callingConvention)
      ..name = op.writesTo!.name;
  }

  factory Variable.of(CompilerContext ctx, SSA ssa, TypeRef type,
      {DeferredOrOffset? methodOffset,
      ReturnType? methodReturnType,
      bool isFinal = false,
      List<TypeRef> concreteTypes = const [],
      CallingConvention callingConvention = CallingConvention.static}) {
    return Variable(-1, type,
        methodOffset: methodOffset,
        methodReturnType: methodReturnType,
        isFinal: isFinal,
        concreteTypes: concreteTypes,
        callingConvention: callingConvention)
      ..name = ssa.name;
  }

  final int scopeFrameOffset;
  final TypeRef type;
  final List<TypeRef> concreteTypes;
  final DeferredOrOffset? methodOffset;
  final ReturnType? methodReturnType;
  final bool isFinal;
  final CallingConvention callingConvention;

  bool get boxed => type.boxed;

  String? name;
  int? frameIndex;

  SSA get ssa => SSA(name!);

  Variable boxIfNeeded(ScopeContext ctx, [AstNode? source]) {
    if (boxed) {
      return this;
    }

    ctx as CompilerContext;

    if (type == CoreTypes.dynamic.ref(ctx)) {
      return copyWith(type: type.copyWith(boxed: true));
    }

    Variable v2 = this;

    final result = ctx.svar('boxed_' + (name ?? 'result'));

    if (type == CoreTypes.int.ref(ctx)) {
      ctx.pushOp(BoxInt(result, ssa));
    } else if (type == CoreTypes.num.ref(ctx)) {
      ctx.pushOp(BoxNum(result, ssa));
    } else if (type == CoreTypes.double.ref(ctx)) {
      ctx.pushOp(BoxDouble(result, ssa));
    } else if (type == CoreTypes.bool.ref(ctx)) {
      ctx.pushOp(BoxBool(result, ssa));
    } else if (type == CoreTypes.list.ref(ctx)) {
      /* TODO if (!type.specifiedTypeArgs[0].boxed) {
        v2 = boxListContents(ctx, this);
      }*/
      ctx.pushOp(BoxList(result, v2.ssa));
    } else if (type == CoreTypes.map.ref(ctx)) {
      ctx.pushOp(BoxMap(result, ssa));
    } else if (type == CoreTypes.string.ref(ctx)) {
      ctx.pushOp(BoxString(result, ssa));
    } else if (type == CoreTypes.nullType.ref(ctx)) {
      ctx.pushOp(BoxNull(result));
    } else {
      throw CompileError('Cannot box $type', source);
    }

    return copyWithUpdate(ctx,
        type: type.copyWith(boxed: true), name: result.name);
  }

  Variable unboxIfNeeded(CompilerContext ctx, [bool update = true]) {
    if (!boxed) {
      return this;
    }

    if (update) {
      copyWithUpdate(ctx, type: type.copyWith(boxed: false));
    }
    return Variable.ssa(ctx, Unbox(ctx.svar(name ?? 'unboxed'), ssa),
        type.copyWith(boxed: false));
  }

  Variable updated(ScopeContext ctx) {
    if (name == null) {
      return this;
    }
    return ctx.lookupLocal(name!) ?? this;
  }

  Variable copyWith(
      {int? scopeFrameOffset,
      TypeRef? type,
      DeferredOrOffset? methodOffset,
      ReturnType? methodReturnType,
      String? name,
      int? frameIndex,
      List<TypeRef>? concreteTypes}) {
    return Variable(
        scopeFrameOffset ?? this.scopeFrameOffset, type ?? this.type,
        methodOffset: methodOffset ?? this.methodOffset,
        methodReturnType: methodReturnType ?? this.methodReturnType,
        concreteTypes: concreteTypes ?? this.concreteTypes)
      ..name = name ?? this.name
      ..frameIndex = frameIndex ?? this.frameIndex;
  }

  Variable copyWithUpdate(ScopeContext? ctx,
      {int? scopeFrameOffset,
      TypeRef? type,
      DeferredOrOffset? methodOffset,
      ReturnType? methodReturnType,
      String? name,
      int? frameIndex,
      List<TypeRef>? concreteTypes}) {
    var uV = Variable(
        scopeFrameOffset ?? this.scopeFrameOffset, type ?? this.type,
        methodOffset: methodOffset ?? this.methodOffset,
        methodReturnType: methodReturnType ?? this.methodReturnType,
        concreteTypes: concreteTypes ?? this.concreteTypes)
      ..name = name ?? this.name
      ..frameIndex = frameIndex ?? this.frameIndex;

    if (uV.name != null && uV.frameIndex != null && ctx != null) {
      ctx.locals[uV.frameIndex!][uV.name!] = uV;
    }

    return uV;
  }

  void inferType(CompilerContext ctx, TypeRef type) {
    if (name != null && ctx.typeInferenceSaveStates.isNotEmpty) {
      final _locals = ctx.typeInferenceSaveStates.last.locals;
      _locals[frameIndex!][name!] =
          _locals[frameIndex!][name!]!.copyWith(type: type);
    }
  }

  Variable getProperty(CompilerContext ctx, String name, {AstNode? source}) {
    if (name == 'runtimeType') {
      if (concreteTypes.isNotEmpty) {
        final concrete = concreteTypes[0];
        return Variable.ssa(
            ctx,
            LoadConstantType(
                ctx.svar('var_type'), concrete.toRuntimeType(ctx).type),
            CoreTypes.type.ref(ctx));
      }
      return Variable.ssa(ctx, LoadRuntimeType(ctx.svar('runtime_type'), ssa),
          CoreTypes.type.ref(ctx));
    }
    final _type = TypeRef.lookupFieldType(ctx, type, name, source: source)
            ?.resolveTypeChain(ctx) ??
        CoreTypes.dynamic.ref(ctx);
    if (concreteTypes.length == 1) {
      // If the concrete type is known we can access the field directly by
      // its index
      final actualType = concreteTypes[0];
      final declaration =
          ctx.topLevelDeclarationsMap[actualType.file]?[actualType.name];
      final fieldDeclaration =
          ctx.instanceDeclarationsMap[actualType.file]?[actualType.name]?[name];
      final isBridge = declaration?.isBridge ?? true;
      if (!isBridge && fieldDeclaration != null) {
        final offset = DeferredOrOffset(
            file: actualType.file, className: actualType.name, name: name);

        // TODO offset should be a DeferredOrOffset
        return Variable.ssa(
            ctx, LoadPropertyStatic(ctx.svar(name), ssa, offset.offset!), type);
      }
    }

    return Variable.ssa(
        ctx, LoadPropertyDynamic(ctx.svar(name), ssa, name), _type);
  }

  static List<Variable> boxUnboxMultiple(
      CompilerContext ctx, List<Variable> variables, bool boxed) {
    final vlist = [...variables];
    final out = <Variable>[];

    for (var i = 0; i < vlist.length; i++) {
      final v = vlist[i];
      final set = boxed ? v.boxIfNeeded(ctx) : v.unboxIfNeeded(ctx);
      out.add(set);
    }

    return out;
  }

  @override
  String toString() {
    final _name = name == null ? 'unnamed' : '"$name"';
    return 'Variable{$_name at L$scopeFrameOffset, $type, '
        '${methodOffset == null ? '' : 'method: $methodReturnType $methodOffset, '}'
        '${boxed ? 'boxed' : 'unboxed'}, F[$frameIndex]}';
  }
}

class InvokeResult {
  const InvokeResult(this.target, this.result, this.args);

  final Variable? target;
  final Variable result;
  final List<Variable> args;
}

class PossiblyValuedParameter {
  PossiblyValuedParameter(this.parameter, this.name, this.V);

  NormalFormalParameter parameter;
  String name;
  Variable? V;
}
