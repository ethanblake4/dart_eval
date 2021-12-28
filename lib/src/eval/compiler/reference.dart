import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/identifier.dart';
import 'package:dart_eval/src/eval/compiler/offset_tracker.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

class Reference {
  const Reference(this.object, this.name);

  final Variable? object;
  final String name;

  TypeRef resolveType(CompilerContext ctx) {
    if (object != null) {
      return TypeRef.lookupFieldType(ctx, object!.type, name) ?? EvalTypes.dynamicType;
    }

    // Locals
    final local = ctx.lookupLocal(name);
    if (local != null) {
      return local.type;
    }

    // Instance
    if (ctx.currentClass != null) {
      final instanceDeclaration = resolveInstanceDeclaration(ctx, ctx.library, ctx.currentClass!.name.name, name);
      if (instanceDeclaration != null) {
        final $type = instanceDeclaration.first;
        return TypeRef.lookupFieldType(ctx, $type, name) ?? EvalTypes.dynamicType;
      }
    }

    //final declaration = ctx.visibleDeclarations[ctx.library]![name]!;
    //final decl = declaration.declaration!;

    // TODO
    return EvalTypes.functionType;
  }

  void setValue(CompilerContext ctx, Variable value) {
    if (object != null) {
      final fieldType = TypeRef.lookupFieldType(ctx, object!.type, name) ?? EvalTypes.dynamicType;
      if (!value.type.resolveTypeChain(ctx).isAssignableTo(fieldType)) {
        throw CompileError('Cannot assign value of type ${value.type} to field "$name" of type $fieldType');
      }
      final op = SetObjectProperty.make(object!.scopeFrameOffset, name, value.boxIfNeeded(ctx).scopeFrameOffset);
      ctx.pushOp(op, SetObjectProperty.len(op));
      return;
    }

    var local = ctx.lookupLocal(name);

    if (local != null) {
      ctx.pushOp(CopyValue.make(local.scopeFrameOffset, value.scopeFrameOffset), CopyValue.LEN);
      return;
    }

    // Instance
    if (ctx.currentClass != null) {
      final instanceDeclaration = resolveInstanceDeclaration(ctx, ctx.library, ctx.currentClass!.name.name, name);
      if (instanceDeclaration != null) {
        final $type = instanceDeclaration.first;
        final fieldType = TypeRef.lookupFieldType(ctx, $type, name) ?? EvalTypes.dynamicType;
        if (!value.type.resolveTypeChain(ctx).isAssignableTo(fieldType)) {
          throw CompileError('Cannot assign value of type ${value.type} to field "$name" of type $fieldType');
        }
        final op = SetObjectProperty.make(0, name, value.boxIfNeeded(ctx).scopeFrameOffset);
        ctx.pushOp(op, SetObjectProperty.len(op));
        return;
      }
    }

    throw CompileError('Cannot find value to set: ${object != null ? object!.toString() + '.' : ''}$name');
  }

  Variable getValue(CompilerContext ctx) {
    if (object != null) {
      final op = PushObjectProperty.make(object!.scopeFrameOffset, name);
      ctx.pushOp(op, PushObjectProperty.len(op));
      ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);

      return Variable.alloc(ctx, TypeRef.lookupFieldType(ctx, object!.type, name) ?? EvalTypes.dynamicType);
    }

    // First look at locals
    final local = ctx.lookupLocal(name);
    if (local != null) {
      return local;
    }

    // Next, the instance (if available)
    if (ctx.currentClass != null) {
      final instanceDeclaration = resolveInstanceDeclaration(ctx, ctx.library, ctx.currentClass!.name.name, name);
      if (instanceDeclaration != null) {
        final $type = instanceDeclaration.first;
        // TODO access super

        final op = PushObjectProperty.make(0 /* (this) */, name);
        ctx.pushOp(op, PushObjectProperty.len(op));

        ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);

        return Variable.alloc(ctx, TypeRef.lookupFieldType(ctx, $type, name) ?? EvalTypes.dynamicType);
      }
    }

    final declaration = ctx.visibleDeclarations[ctx.library]![name]!;
    final _decl = declaration.declaration!;

    if (_decl.isBridge) {
      throw CompileError('No support bridge declaration in Reference');
    }

    final decl = _decl.declaration!;

    if (!(decl is FunctionDeclaration) && !(decl is ConstructorDeclaration)) {
      decl as ClassDeclaration;

      final returnType = TypeRef.lookupClassDeclaration(ctx, declaration.sourceLib, decl);
      final DeferredOrOffset offset;

      if (ctx.topLevelDeclarationPositions[declaration.sourceLib]?.containsKey(name + '.') ?? false) {
        offset = DeferredOrOffset(
            file: declaration.sourceLib, offset: ctx.topLevelDeclarationPositions[ctx.library]![name + '.']);
      } else {
        offset = DeferredOrOffset(file: declaration.sourceLib, name: name + '.');
      }

      return Variable(-1, EvalTypes.functionType, methodOffset: offset, methodReturnType: AlwaysReturnType(returnType, false));
    }

    TypeRef? returnType;
    var nullable = true;
    if (decl is FunctionDeclaration && decl.returnType != null) {
      returnType = TypeRef.fromAnnotation(ctx, declaration.sourceLib, decl.returnType!);
      nullable = decl.returnType!.question != null;
    } else {
      returnType = TypeRef.lookupClassDeclaration(ctx, declaration.sourceLib, decl.parent as ClassDeclaration);
    }

    final DeferredOrOffset offset;
    if (ctx.topLevelDeclarationPositions[declaration.sourceLib]?.containsKey(name) ?? false) {
      offset =
          DeferredOrOffset(file: declaration.sourceLib, offset: ctx.topLevelDeclarationPositions[ctx.library]![name]);
    } else {
      offset = DeferredOrOffset(file: declaration.sourceLib, name: name);
    }

    return Variable(-1, EvalTypes.functionType, methodOffset: offset, methodReturnType: AlwaysReturnType(returnType, nullable));
  }
}
