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
      : callingConvention = callingConvention ??
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

  Variable boxIfNeeded(ScopeContext ctx, [AstNode? source]) {
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
    } else if (type == CoreTypes.set.ref(ctx)) {
      ctx.pushOp(BoxSet.make(scopeFrameOffset), BoxSet.LEN);
    } else if (type == CoreTypes.string.ref(ctx)) {
      ctx.pushOp(BoxString.make(scopeFrameOffset), BoxString.LEN);
    } else if (type == CoreTypes.nullType.ref(ctx)) {
      ctx.pushOp(BoxNull.make(scopeFrameOffset), BoxNull.LEN);
    } else {
      throw CompileError('Cannot box $type', source);
    }

    return copyWithUpdate(ctx, type: type.copyWith(boxed: true));
  }

  Variable unboxIfNeeded(ScopeContext ctx, [bool update = true]) {
    if (!boxed) {
      return this;
    }
    ctx.pushOp(Unbox.make(scopeFrameOffset), Unbox.LEN);
    if (!update) {
      return copyWith(type: type.copyWith(boxed: false));
    }
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
      bool? isFinal,
      String? name,
      int? frameIndex,
      List<TypeRef>? concreteTypes}) {
    return Variable(
        scopeFrameOffset ?? this.scopeFrameOffset, type ?? this.type,
        methodOffset: methodOffset ?? this.methodOffset,
        isFinal: isFinal ?? this.isFinal,
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

  void inferType(CompilerContext ctx, TypeRef type) {
    if (name != null && ctx.typeInferenceSaveStates.isNotEmpty) {
      final locals = ctx.typeInferenceSaveStates.last.locals;
      locals[frameIndex!][name!] =
          locals[frameIndex!][name!]!.copyWith(type: type);
    }
  }

  Variable getProperty(CompilerContext ctx, String name, {AstNode? source}) {
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
    final fieldType = TypeRef.lookupFieldType(ctx, type, name, source: source)
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
        final op =
            PushObjectPropertyImpl.make(scopeFrameOffset, offset.offset ?? -1);
        final loc = ctx.pushOp(op, PushObjectPropertyImpl.length);
        ctx.offsetTracker.setOffset(loc, offset);
        return Variable.alloc(ctx, fieldType);
      }
    }
    final op = PushObjectProperty.make(
        scopeFrameOffset, ctx.constantPool.addOrGet(name));
    ctx.pushOp(op, PushObjectProperty.len(op));

    ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);
    return Variable.alloc(ctx, fieldType);
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
    final varName = name == null ? 'unnamed' : '"$name"';
    return 'Variable{$varName at L$scopeFrameOffset, $type, '
        '${methodOffset == null ? '' : 'method: $methodReturnType $methodOffset, '}'
        '${boxed ? 'boxed' : 'unboxed'}, F[$frameIndex]}';
  }
}

class InvokeResult {
  const InvokeResult(this.target, this.result, this.args,
      {this.namedArgs = const {}});

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
