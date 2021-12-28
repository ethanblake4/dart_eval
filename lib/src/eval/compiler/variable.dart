import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/util.dart';

import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'builtins.dart';
import 'errors.dart';
import 'offset_tracker.dart';

class Variable {
  Variable(this.scopeFrameOffset, this.type, {this.methodOffset, this.methodReturnType, this.boxed = true});

  factory Variable.alloc(CompilerContext ctx, TypeRef type,
      {DeferredOrOffset? methodOffset, ReturnType? methodReturnType, bool boxed = true}) {
    ctx.allocNest.last++;
    return Variable(ctx.scopeFrameOffset++, type,
        methodOffset: methodOffset, methodReturnType: methodReturnType, boxed: boxed);
  }

  final int scopeFrameOffset;
  final TypeRef type;
  final DeferredOrOffset? methodOffset;
  final ReturnType? methodReturnType;
  final bool boxed;

  String? name;
  int? frameIndex;

  Variable boxIfNeeded(CompilerContext ctx) {
    if (boxed) {
      return this;
    }
    if (type != EvalTypes.intType) {
      throw CompileError('Can only box ints for now');
    }
    ctx.pushOp(BoxInt.make(scopeFrameOffset), BoxInt.LEN);

    var V2 =
        Variable(scopeFrameOffset, type, methodOffset: methodOffset, methodReturnType: methodReturnType, boxed: true)
          ..name = name
          ..frameIndex = frameIndex;

    if (name != null) {
      ctx.locals[frameIndex!][name!] = V2;
    }
    return V2;
  }

  Variable unboxIfNeeded(CompilerContext ctx) {
    if (!boxed) {
      return this;
    }
    ctx.pushOp(Unbox.make(scopeFrameOffset), Unbox.LEN);

    var uV =
        Variable(scopeFrameOffset, type, methodOffset: methodOffset, methodReturnType: methodReturnType, boxed: false)
          ..name = name
          ..frameIndex = frameIndex;

    if (name != null) {
      ctx.locals[frameIndex!][name!] = uV;
    }
    return uV;
  }

  Pair<Variable, Variable> invoke(CompilerContext ctx, String method, List<Variable> args) {
    var $this = this;

    final supportedNumIntrinsicOps = {'+', '-', '<', '>'};
    if (type.isAssignableTo(EvalTypes.numType) && supportedNumIntrinsicOps.contains(method)) {
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
          ctx.pushOp(NumAdd.make($this.scopeFrameOffset, R.scopeFrameOffset), NumAdd.LEN);
          result = Variable.alloc(ctx, EvalTypes.intType, boxed: false);
          break;
        case '-':
          // Num intrinsic sub
          ctx.pushOp(NumSub.make($this.scopeFrameOffset, R.scopeFrameOffset), NumSub.LEN);
          result = Variable.alloc(ctx, EvalTypes.intType, boxed: false);
          break;
        case '<':
          // Num intrinsic less than
          ctx.pushOp(NumLt.make($this.scopeFrameOffset, R.scopeFrameOffset), NumLt.LEN);
          result = Variable.alloc(ctx, EvalTypes.boolType, boxed: false);
          break;
        case '>':
          // Num intrinsic greater than
          ctx.pushOp(NumGt.make($this.scopeFrameOffset, R.scopeFrameOffset), NumGt.LEN);
          result = Variable.alloc(ctx, EvalTypes.boolType, boxed: false);
          break;
        default:
          throw CompileError('Unknown num intrinsic method "$method"');
      }

      return Pair($this, result);
    }

    final _boxed = boxUnboxMultiple(ctx, [$this, ...args], true);
    $this = _boxed[0];
    final _args = _boxed.sublist(1);
    for (final _arg in _args) {
      ctx.pushOp(PushArg.make(_arg.scopeFrameOffset), PushArg.LEN);
    }
    final invokeOp = InvokeDynamic.make($this.scopeFrameOffset, method);
    ctx.pushOp(invokeOp, InvokeDynamic.len(invokeOp));
    ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);
    final returnType =
        AlwaysReturnType.fromInstanceMethodOrBuiltin(ctx, $this.type, method, [..._args.map((e) => e.type)], {});
    return Pair($this, Variable.alloc(ctx, returnType?.type ?? EvalTypes.dynamicType, boxed: true));
  }

  static List<Variable> boxUnboxMultiple(CompilerContext ctx, List<Variable> variables, bool boxed) {
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

class PossiblyValuedParameter {
  PossiblyValuedParameter(this.parameter, this.V);

  NormalFormalParameter parameter;
  Variable? V;
}
