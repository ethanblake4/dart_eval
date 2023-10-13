import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/collection/list.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/function.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';

import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'builtins.dart';
import 'errors.dart';
import 'offset_tracker.dart';

class Variable {
  Variable(this.scopeFrameOffset, this.type,
      {this.methodOffset,
      this.methodReturnType,
      this.isFinal = false,
      this.concreteTypes = const [],
      CallingConvention? callingConvention})
      // ignore: unnecessary_this
      : this.callingConvention = callingConvention ??
            ((type == EvalTypes.functionType && methodOffset == null)
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

  Variable boxIfNeeded(ScopeContext ctx) {
    if (boxed) {
      return this;
    }

    if (type == EvalTypes.dynamicType) {
      return copyWith(type: type.copyWith(boxed: true));
    }

    Variable V2 = this;

    if (type == EvalTypes.getIntType(ctx as CompilerContext)) {
      ctx.pushOp(BoxInt.make(scopeFrameOffset), BoxInt.LEN);
    } else if (type == EvalTypes.getNumType(ctx)) {
      ctx.pushOp(BoxNum.make(scopeFrameOffset), BoxNum.LEN);
    } else if (type == EvalTypes.getDoubleType(ctx)) {
      ctx.pushOp(BoxDouble.make(scopeFrameOffset), BoxDouble.LEN);
    } else if (type == EvalTypes.boolType) {
      ctx.pushOp(BoxBool.make(scopeFrameOffset), BoxBool.LEN);
    } else if (type == EvalTypes.getListType(ctx)) {
      if (!type.specifiedTypeArgs[0].boxed) {
        V2 = boxListContents(ctx, this);
      }
      ctx.pushOp(BoxList.make(V2.scopeFrameOffset), BoxList.LEN);
    } else if (type == EvalTypes.mapType) {
      ctx.pushOp(BoxMap.make(scopeFrameOffset), BoxMap.LEN);
    } else if (type == EvalTypes.getStringType(ctx)) {
      ctx.pushOp(BoxString.make(scopeFrameOffset), BoxInt.LEN);
    } else if (type == EvalTypes.nullType) {
      ctx.pushOp(BoxNull.make(scopeFrameOffset), BoxNull.LEN);
    } else {
      throw CompileError('Cannot box $type');
    }

    return copyWithUpdate(ctx, type: type.copyWith(boxed: true));
  }

  Variable unboxIfNeeded(ScopeContext ctx) {
    if (!boxed) {
      return this;
    }
    ctx.pushOp(Unbox.make(scopeFrameOffset), Unbox.LEN);
    return copyWithUpdate(ctx, type: type.copyWith(boxed: false));
  }

  Variable updated(ScopeContext ctx) {
    if (name == null) {
      return this;
    }
    return ctx.lookupLocal(name!) ?? this;
  }

  void pushArg(CompilerContext ctx) =>
      ctx.pushOp(PushArg.make(scopeFrameOffset), PushArg.LEN);

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

    if (uV.name != null && ctx != null) {
      ctx.locals[uV.frameIndex!][uV.name!] = uV;
    }

    return uV;
  }

  /// Warning! Calling invoke() may modify the state of input variables. They should be refreshed
  /// after use.
  InvokeResult invoke(CompilerContext ctx, String method, List<Variable> args) {
    var $this = this;

    final supportedNumIntrinsicOps = {'+', '-', '<', '>', '<=', '>='};
    final supportedBoolIntrinsicOps = {'!'};
    if (type.isAssignableTo(ctx, EvalTypes.getNumType(ctx),
            forceAllowDynamic: false) &&
        supportedNumIntrinsicOps.contains(method)) {
      $this = unboxIfNeeded(ctx);
      if (args.length != 1) {
        throw CompileError(
            'Cannot invoke method "$method" on variable of type $type with args count: ${args.length} (required: 1)');
      }
      var R = args[0];
      if (R.scopeFrameOffset == scopeFrameOffset) {
        R = $this;
      } else {
        R = R.unboxIfNeeded(ctx);
      }

      Variable result;
      switch (method) {
        case '+':
          // Num intrinsic add
          ctx.pushOp(NumAdd.make($this.scopeFrameOffset, R.scopeFrameOffset),
              NumAdd.LEN);
          result = Variable.alloc(
              ctx,
              TypeRef.commonBaseType(ctx, {$this.type, R.type})
                  .copyWith(boxed: false));
          break;
        case '-':
          // Num intrinsic sub
          ctx.pushOp(NumSub.make($this.scopeFrameOffset, R.scopeFrameOffset),
              NumSub.LEN);
          result = Variable.alloc(
              ctx,
              TypeRef.commonBaseType(ctx, {$this.type, R.type})
                  .copyWith(boxed: false));
          break;
        case '<':
          // Num intrinsic less than
          ctx.pushOp(NumLt.make($this.scopeFrameOffset, R.scopeFrameOffset),
              NumLt.LEN);
          result =
              Variable.alloc(ctx, EvalTypes.boolType.copyWith(boxed: false));
          break;
        case '>':
          // Num intrinsic greater than
          ctx.pushOp(NumLt.make(R.scopeFrameOffset, $this.scopeFrameOffset),
              NumLtEq.LEN);
          result =
              Variable.alloc(ctx, EvalTypes.boolType.copyWith(boxed: false));
          break;
        case '<=':
          // Num intrinsic less than equal to
          ctx.pushOp(NumLtEq.make($this.scopeFrameOffset, R.scopeFrameOffset),
              NumLtEq.LEN);
          result =
              Variable.alloc(ctx, EvalTypes.boolType.copyWith(boxed: false));
          break;
        case '>=':
          // Num intrinsic greater than equal to
          ctx.pushOp(NumLtEq.make(R.scopeFrameOffset, $this.scopeFrameOffset),
              NumLt.LEN);
          result =
              Variable.alloc(ctx, EvalTypes.boolType.copyWith(boxed: false));
          break;
        default:
          throw CompileError('Unknown num intrinsic method "$method"');
      }

      return InvokeResult($this, result, [R]);
    } else if (type.isAssignableTo(ctx, EvalTypes.boolType,
            forceAllowDynamic: false) &&
        supportedBoolIntrinsicOps.contains(method)) {
      $this = unboxIfNeeded(ctx);
      ctx.pushOp(LogicalNot.make($this.scopeFrameOffset), LogicalNot.LEN);
      var result =
          Variable.alloc(ctx, EvalTypes.boolType.copyWith(boxed: false));
      return InvokeResult($this, result, []);
    }

    final _boxed = boxUnboxMultiple(ctx, [$this, ...args], true);
    $this = _boxed[0];
    final _args = _boxed.sublist(1);
    final checkEq = method == '==' && _args.length == 1;
    final checkNotEq = method == '!=' && _args.length == 1;
    if (checkEq) {
      ctx.pushOp(
          CheckEq.make($this.scopeFrameOffset, _args[0].scopeFrameOffset),
          CheckEq.LEN);
    } else if (checkNotEq) {
      ctx.pushOp(
          CheckNotEq.make($this.scopeFrameOffset, _args[0].scopeFrameOffset),
          CheckNotEq.LEN);
    } else {
      for (final _arg in _args) {
        ctx.pushOp(PushArg.make(_arg.scopeFrameOffset), PushArg.LEN);
      }

      final invokeOp = InvokeDynamic.make($this.scopeFrameOffset, method);
      ctx.pushOp(invokeOp, InvokeDynamic.len(invokeOp));
    }

    ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);

    final AlwaysReturnType? returnType;
    if ($this.type == EvalTypes.functionType && method == 'call') {
      returnType = null;
    } else {
      returnType = AlwaysReturnType.fromInstanceMethodOrBuiltin(
          ctx, $this.type, method, [..._args.map((e) => e.type)], {});
    }

    final v = Variable.alloc(
        ctx,
        (returnType?.type ?? EvalTypes.dynamicType)
            .copyWith(boxed: !(checkEq || checkNotEq)));
    return InvokeResult($this, v, _args);
  }

  Variable getProperty(CompilerContext ctx, String name) {
    final op = PushObjectProperty.make(scopeFrameOffset, name);
    ctx.pushOp(op, PushObjectProperty.len(op));

    ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);
    final prop = Variable.alloc(
        ctx,
        TypeRef.lookupFieldType(ctx, type, name)?.resolveTypeChain(ctx) ??
            EvalTypes.dynamicType);

    return prop;
  }

  static List<Variable> boxUnboxMultiple(
      CompilerContext ctx, List<Variable> variables, bool boxed) {
    final vlist = [...variables];
    final out = <Variable>[];

    for (var i = 0; i < vlist.length; i++) {
      final v = vlist[i];
      final set = boxed ? v.boxIfNeeded(ctx) : v.unboxIfNeeded(ctx);
      out.add(set);
      for (var j = i + 1; j < vlist.length; j++) {
        final v2 = vlist[j];
        // not great for large variable lists, but since most variable lists are small...
        if (v2.scopeFrameOffset == v.scopeFrameOffset) {
          vlist[j] = set;
        }
      }
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
  PossiblyValuedParameter(this.parameter, this.V);

  NormalFormalParameter parameter;
  Variable? V;
}
