import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/collection/list.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/function.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';

import 'package:dart_eval/src/eval/runtime/runtime.dart';
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
                : CallingConvention
                    .static) /*,
        todo: assert(!type.nullable || type.boxed)*/
  ;

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

    ctx as CompilerContext;

    if (type == CoreTypes.dynamic.ref(ctx)) {
      return copyWith(type: type.copyWith(boxed: true));
    }

    Variable v2 = this;

    if (type == CoreTypes.int.ref(ctx)) {
      ctx.pushOp(BoxInt.make(scopeFrameOffset), BoxInt.LEN);
    } else if (type == CoreTypes.num.ref(ctx)) {
      ctx.pushOp(BoxNum.make(scopeFrameOffset), BoxNum.LEN);
    } else if (type == CoreTypes.double.ref(ctx)) {
      ctx.pushOp(BoxDouble.make(scopeFrameOffset), BoxDouble.LEN);
    } else if (type == CoreTypes.bool.ref(ctx)) {
      ctx.pushOp(BoxBool.make(scopeFrameOffset), BoxBool.LEN);
    } else if (type == CoreTypes.list.ref(ctx)) {
      if (!type.specifiedTypeArgs[0].boxed) {
        v2 = boxListContents(ctx, this);
      }
      ctx.pushOp(BoxList.make(v2.scopeFrameOffset), BoxList.LEN);
    } else if (type == CoreTypes.map.ref(ctx)) {
      ctx.pushOp(BoxMap.make(scopeFrameOffset), BoxMap.LEN);
    } else if (type == CoreTypes.string.ref(ctx)) {
      ctx.pushOp(BoxString.make(scopeFrameOffset), BoxInt.LEN);
    } else if (type == CoreTypes.nullType.ref(ctx)) {
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
    if (type.isAssignableTo(ctx, CoreTypes.num.ref(ctx),
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
          result = Variable.alloc(
              ctx, CoreTypes.bool.ref(ctx).copyWith(boxed: false));
          break;
        case '>':
          // Num intrinsic greater than
          ctx.pushOp(NumLt.make(R.scopeFrameOffset, $this.scopeFrameOffset),
              NumLtEq.LEN);
          result = Variable.alloc(
              ctx, CoreTypes.bool.ref(ctx).copyWith(boxed: false));
          break;
        case '<=':
          // Num intrinsic less than equal to
          ctx.pushOp(NumLtEq.make($this.scopeFrameOffset, R.scopeFrameOffset),
              NumLtEq.LEN);
          result = Variable.alloc(
              ctx, CoreTypes.bool.ref(ctx).copyWith(boxed: false));
          break;
        case '>=':
          // Num intrinsic greater than equal to
          ctx.pushOp(NumLtEq.make(R.scopeFrameOffset, $this.scopeFrameOffset),
              NumLt.LEN);
          result = Variable.alloc(
              ctx, CoreTypes.bool.ref(ctx).copyWith(boxed: false));
          break;
        default:
          throw CompileError('Unknown num intrinsic method "$method"');
      }

      return InvokeResult($this, result, [R]);
    } else if (type.isAssignableTo(ctx, CoreTypes.bool.ref(ctx),
            forceAllowDynamic: false) &&
        supportedBoolIntrinsicOps.contains(method)) {
      $this = unboxIfNeeded(ctx);
      ctx.pushOp(LogicalNot.make($this.scopeFrameOffset), LogicalNot.LEN);
      var result =
          Variable.alloc(ctx, CoreTypes.bool.ref(ctx).copyWith(boxed: false));
      return InvokeResult($this, result, []);
    }

    final _boxed = boxUnboxMultiple(ctx, [$this, ...args], true);
    $this = _boxed[0];
    final _args = _boxed.sublist(1);
    final checkEq = method == '==' && _args.length == 1;
    final checkNotEq = method == '!=' && _args.length == 1;
    if (checkEq || checkNotEq) {
      ctx.pushOp(
          CheckEq.make($this.scopeFrameOffset, _args[0].scopeFrameOffset),
          CheckEq.LEN);
    } else {
      for (final _arg in _args) {
        ctx.pushOp(PushArg.make(_arg.scopeFrameOffset), PushArg.LEN);
      }

      final invokeOp = InvokeDynamic.make(
          $this.scopeFrameOffset, ctx.constantPool.addOrGet(method));
      ctx.pushOp(invokeOp, InvokeDynamic.len(invokeOp));
    }

    ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);

    if (checkNotEq) {
      final res = Variable.alloc(ctx, CoreTypes.bool.ref(ctx));
      ctx.pushOp(LogicalNot.make(res.scopeFrameOffset), LogicalNot.LEN);
    }

    final AlwaysReturnType? returnType;
    if ($this.type == CoreTypes.function.ref(ctx) && method == 'call') {
      returnType = null;
    } else {
      returnType = AlwaysReturnType.fromInstanceMethodOrBuiltin(
          ctx, $this.type, method, [..._args.map((e) => e.type)], {});
    }

    final v = Variable.alloc(
        ctx,
        (returnType?.type ?? CoreTypes.dynamic.ref(ctx))
            .copyWith(boxed: !(checkEq || checkNotEq)));
    return InvokeResult($this, v, _args);
  }

  Variable getProperty(CompilerContext ctx, String name) {
    if (name == 'runtimeType') {
      if (concreteTypes.isNotEmpty) {
        final concrete = concreteTypes[0];
        ctx.pushOp(PushConstantType.make(concrete.toRuntimeType(ctx).type),
            PushConstantType.LEN);
        return Variable.alloc(ctx, CoreTypes.type.ref(ctx));
      }
      ctx.pushOp(PushRuntimeType.make(scopeFrameOffset), PushRuntimeType.LEN);
      return Variable.alloc(ctx, CoreTypes.type.ref(ctx));
    }
    final _type =
        TypeRef.lookupFieldType(ctx, type, name)?.resolveTypeChain(ctx) ??
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
        final op =
            PushObjectPropertyImpl.make(scopeFrameOffset, offset.offset ?? -1);
        final loc = ctx.pushOp(op, PushObjectPropertyImpl.length);
        ctx.offsetTracker.setOffset(loc, offset);
        return Variable.alloc(ctx, _type);
      }
    }
    final op = PushObjectProperty.make(
        scopeFrameOffset, ctx.constantPool.addOrGet(name));
    ctx.pushOp(op, PushObjectProperty.len(op));

    ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);
    return Variable.alloc(ctx, _type);
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
