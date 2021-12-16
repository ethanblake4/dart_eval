import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/scope.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

import '../variable.dart';

void compileConstructorDeclaration(
    CompilerContext ctx, ConstructorDeclaration d, ClassDeclaration parent, List<FieldDeclaration> fields) {
  final n = '${parent.name.name}.${d.name?.name ?? ""}';

  ctx.topLevelDeclarationPositions[ctx.library]![n] = beginMethod(ctx, d, d.offset, '$n()');

  ctx.beginAllocScope(existingAllocLen: d.parameters.parameters.length);
  ctx.scopeFrameOffset = d.parameters.parameters.length;

  SuperConstructorInvocation? $superInitializer;
  final otherInitializers = <ConstructorInitializer>[];
  for (final initializer in d.initializers) {
    if (initializer is SuperConstructorInvocation) {
      $superInitializer = initializer;
    } else if ($superInitializer != null) {
      throw CompileError('Super constructor invocation must be last in the initializer list');
    } else {
      otherInitializers.add(initializer);
    }
  }

  final fieldIndices = <String, int>{};
  var i = 0;
  for (final fd in fields) {
    for (final field in fd.fields.variables) {
      fieldIndices[field.name.name] = i;
      i++;
    }
  }

  final $extends = parent.extendsClause;
  final Variable $super;

  /*if ($extends == null) {
      $super = _pushBuiltinValue(BuiltinValue(), ctx);
    } else {
      final extendsWhat = ctx.visibleDeclarations[ctx.library]![$extends.superclass.name]!;

      if ($superInitializer != null) {
        final argsPair = _parseArgumentList(ctx, $superInitializer.argumentList);
        final _args = argsPair.first;
        final _namedArgs = argsPair.second;

        AlwaysReturnType? mReturnType;
        final _argTypes = _args.map((e) => e.type).toList();
        final _namedArgTypes = _namedArgs.map((key, value) => MapEntry(key, value.type));


        //final method = _parseIdentifier($superInitializer.constructorName, ctx);
        if (method.methodOffset == null) {
          throw CompileError('Cannot call ${e.methodName.name} as it is not a valid method');
        }
        final offset = method.methodOffset!;
        final loc = pushOp(ctx, Call.make(offset.offset ?? -1), Call.LEN);
        if (offset.offset == null) {
          ctx.offsetTracker.setOffset(loc, offset);
        }
        mReturnType = method.methodReturnType?.toAlwaysReturnType(_argTypes, _namedArgTypes) ??
            AlwaysReturnType(_dynamicType, true);

        pushOp(ctx, PushReturnValue.make(), PushReturnValue.LEN);
        ctx.allocNest.last++;

        return Variable(ctx.scopeFrameOffset++, mReturnType?.type ?? _dynamicType, mReturnType?.nullable ?? true,
            boxed: L == null && !_unboxedAcrossFunctionBoundaries.contains(mReturnType?.type));
      }
    }*/

  $super = BuiltinValue().push(ctx);

  final op = CreateClass.make(ctx.library, $super.scopeFrameOffset, parent.name.name, i);
  ctx.pushOp(op, CreateClass.len(op));
  final instOffset = ctx.scopeFrameOffset++;
  final resolvedParams = _resolveFPLDefaults(ctx, d.parameters, false, allowUnboxed: true);

  i = 0;

  for (final param in resolvedParams) {
    final p = param.parameter;
    final V = param.V;
    if (p is FieldFormalParameter) {
      TypeRef? _type;
      if (p.type != null) {
        _type = TypeRef.fromAnnotation(ctx, ctx.library, p.type!);
      }
      _type ??= V?.type;
      _type ??= dynamicType;

      var Vrep = Variable(i, _type, boxed: !unboxedAcrossFunctionBoundaries.contains(_type)).boxIfNeeded(ctx);

      ctx.pushOp(SetObjectPropertyImpl.make(instOffset, fieldIndices[p.identifier.name]!, Vrep.scopeFrameOffset),
          SetObjectPropertyImpl.LEN);
    } else {
      p as SimpleFormalParameter;
      var type = dynamicType;
      if (p.type != null) {
        type = TypeRef.fromAnnotation(ctx, ctx.library, p.type!);
      }
      ctx.locals.last[p.identifier!.name] = Variable(i, type)
        ..name = p.identifier!.name;
    }

    i++;
  }

  for (final init in otherInitializers) {
    if (init is ConstructorFieldInitializer) {
      final V = compileExpression(init.expression, ctx);
      ctx.pushOp(SetObjectPropertyImpl.make(instOffset, fieldIndices[init.fieldName.name]!, V.scopeFrameOffset),
          SetObjectPropertyImpl.LEN);
    } else {
      throw CompileError('${init.runtimeType} initializer is not supported');
    }
  }

  ctx.pushOp(Return.make(instOffset), Return.LEN);
  ctx.endAllocScope(popValues: false);
}

List<PossiblyValuedParameter> _resolveFPLDefaults(CompilerContext ctx, FormalParameterList fpl, bool isInstanceMethod,
    {bool allowUnboxed = true}) {
  final normalized = <PossiblyValuedParameter>[];
  var hasEncounteredOptionalPositionalParam = false;
  var hasEncounteredNamedParam = false;
  var _paramIndex = isInstanceMethod ? 1 : 0;
  for (final param in fpl.parameters) {
    if (param.isNamed) {
      if (hasEncounteredOptionalPositionalParam) {
        throw CompileError('Cannot mix named and optional positional parameters');
      }
      hasEncounteredNamedParam = true;
    } else if (param.isOptionalPositional) {
      if (hasEncounteredNamedParam) {
        throw CompileError('Cannot mix named and optional positional parameters');
      }
      hasEncounteredOptionalPositionalParam = true;
    }

    if (param is DefaultFormalParameter) {
      if (param.defaultValue != null) {
        ctx.beginAllocScope();
        final _reserve = JumpIfNonNull.make(_paramIndex, -1);
        final _reserveOffset = ctx.pushOp(_reserve, JumpIfNonNull.LEN);
        var V = compileExpression(param.defaultValue!, ctx);
        if (!allowUnboxed) {
          V = V.boxIfNeeded(ctx);
        }
        ctx.pushOp(CopyValue.make(_paramIndex, V.scopeFrameOffset), CopyValue.LEN);
        ctx.endAllocScope();
        ctx.rewriteOp(_reserveOffset, JumpIfNonNull.make(_paramIndex, ctx.out.length), 0);
        normalized.add(PossiblyValuedParameter(param.parameter, V));
      } else {
        normalized.add(PossiblyValuedParameter(param.parameter, null));
      }
    } else {
      param as NormalFormalParameter;
      normalized.add(PossiblyValuedParameter(param, null));
    }

    _paramIndex++;
  }
  return normalized;
}
