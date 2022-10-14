import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/helpers/argument_list.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';
import 'package:dart_eval/src/eval/compiler/scope.dart';
import 'package:dart_eval/src/eval/compiler/source.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

import '../variable.dart';

void compileConstructorDeclaration(
    CompilerContext ctx, ConstructorDeclaration d, ClassDeclaration parent, List<FieldDeclaration> fields) {
  final parentName = parent.name2.value() as String;
  final dName = (d.name2?.value() as String?) ?? "";
  final n = '$parentName.$dName';

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

  final fieldIndices = _getFieldIndices(fields);
  final fieldIdx = fieldIndices.length;

  final fieldFormalNames = <String>[];
  final resolvedParams = resolveFPLDefaults(ctx, d.parameters, false, allowUnboxed: true);
  var i = 0;

  for (final param in resolvedParams) {
    final p = param.parameter;
    final V = param.V;
    Variable Vrep;
    if (p is FieldFormalParameter) {
      TypeRef? _type;
      if (p.type != null) {
        _type = TypeRef.fromAnnotation(ctx, ctx.library, p.type!);
      }
      _type ??= TypeRef.lookupFieldType(
          ctx, TypeRef.lookupClassDeclaration(ctx, ctx.library, parent), p.name.value() as String);
      _type ??= V?.type;
      _type ??= EvalTypes.dynamicType;

      Vrep = Variable(i, _type.copyWith(boxed: !unboxedAcrossFunctionBoundaries.contains(_type))).boxIfNeeded(ctx)
        ..name = p.name.value() as String;

      fieldFormalNames.add(p.name.value() as String);
    } else {
      p as SimpleFormalParameter;
      var type = EvalTypes.dynamicType;
      if (p.type != null) {
        type = TypeRef.fromAnnotation(ctx, ctx.library, p.type!);
      }
      type = type.copyWith(boxed: !unboxedAcrossFunctionBoundaries.contains(type));
      Vrep = Variable(i, type)..name = p.name!.value() as String;
    }

    ctx.setLocal(Vrep.name!, Vrep);

    i++;
  }

  final $extends = parent.extendsClause;
  Variable $super;
  DeclarationOrPrefix? extendsWhat;

  final argTypes = <TypeRef?>[];
  final namedArgTypes = <String, TypeRef?>{};

  var constructorName = $superInitializer?.constructorName?.name ?? '';

  if ($extends == null) {
    $super = BuiltinValue().push(ctx);
  } else {
    // ignore: deprecated_member_use
    extendsWhat = ctx.visibleDeclarations[ctx.library]![$extends.superclass2.name.name]!;

    final decl = extendsWhat.declaration!;

    if (decl.isBridge) {
      ctx.pushOp(PushBridgeSuperShim.make(), PushBridgeSuperShim.LEN);
      $super = Variable.alloc(ctx, EvalTypes.dynamicType);
    } else {
      final extendsType = TypeRef.lookupClassDeclaration(ctx, ctx.library, decl.declaration as ClassDeclaration);

      AlwaysReturnType? mReturnType;

      if ($superInitializer != null) {
        final _constructor = ctx.topLevelDeclarationsMap[decl.sourceLib]!['${extendsType.name}.$constructorName']!;
        final constructor = _constructor.declaration as ConstructorDeclaration;

        final argsPair = compileArgumentList(
            ctx, $superInitializer.argumentList, decl.sourceLib, constructor.parameters.parameters, constructor);
        final _args = argsPair.first;
        final _namedArgs = argsPair.second;

        argTypes.addAll(_args.map((e) => e.type).toList());
        namedArgTypes.addAll(_namedArgs.map((key, value) => MapEntry(key, value.type)));
      }

      final method = IdentifierReference(null, '${extendsType.name}.$constructorName').getValue(ctx);
      if (method.methodOffset == null) {
        throw CompileError('Cannot call $constructorName as it is not a valid method');
      }

      final offset = method.methodOffset!;
      final loc = ctx.pushOp(Call.make(offset.offset ?? -1), Call.LEN);
      if (offset.offset == null) {
        ctx.offsetTracker.setOffset(loc, offset);
      }
      final clsType = TypeRef.lookupClassDeclaration(ctx, ctx.library, parent);
      mReturnType = method.methodReturnType?.toAlwaysReturnType(clsType, argTypes, namedArgTypes) ??
          AlwaysReturnType(EvalTypes.dynamicType, true);

      ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);
      $super = Variable.alloc(ctx, mReturnType.type ?? EvalTypes.dynamicType);
    }
  }

  final op = CreateClass.make(ctx.library, $super.scopeFrameOffset, parent.name2.value() as String, fieldIdx);
  ctx.pushOp(op, CreateClass.len(op));
  final instOffset = ctx.scopeFrameOffset++;

  for (final fieldFormal in fieldFormalNames) {
    ctx.pushOp(
        SetObjectPropertyImpl.make(
            instOffset, fieldIndices[fieldFormal]!, ctx.lookupLocal(fieldFormal)!.scopeFrameOffset),
        SetObjectPropertyImpl.LEN);
  }

  final usedNames = {...fieldFormalNames};

  for (final init in otherInitializers) {
    if (init is ConstructorFieldInitializer) {
      final V = compileExpression(init.expression, ctx);
      ctx.pushOp(SetObjectPropertyImpl.make(instOffset, fieldIndices[init.fieldName.name]!, V.scopeFrameOffset),
          SetObjectPropertyImpl.LEN);
      usedNames.add(init.fieldName.name);
    } else {
      throw CompileError('${init.runtimeType} initializer is not supported');
    }
  }

  _compileUnusedFields(ctx, fields, {}, instOffset);

  if ($extends != null && extendsWhat!.declaration!.isBridge) {
    final decl = extendsWhat.declaration!;
    final bridge = decl.bridge! as BridgeClassDef;

    if (!bridge.bridge) {
      throw CompileError('Bridge class ${$extends.superclass} is a wrapper, not a bridge, so you can\'t extend it');
    }

    if ($superInitializer != null) {
      final constructor = bridge.constructors[constructorName]!;
      final argsPair =
          compileArgumentListWithBridge(ctx, $superInitializer.argumentList, constructor.functionDescriptor);
      final _args = argsPair.first;
      final _namedArgs = argsPair.second;
      argTypes.addAll(_args.map((e) => e.type).toList());
      namedArgTypes.addAll(_namedArgs.map((key, value) => MapEntry(key, value.type)));
    }

    final op = BridgeInstantiate.make(instOffset,
        ctx.bridgeStaticFunctionIndices[decl.sourceLib]!['${$extends.superclass.name.name}.$constructorName']!);
    ctx.pushOp(op, BridgeInstantiate.len(op));
    final bridgeInst = Variable.alloc(ctx, EvalTypes.dynamicType);

    ctx.pushOp(
        ParentBridgeSuperShim.make($super.scopeFrameOffset, bridgeInst.scopeFrameOffset), ParentBridgeSuperShim.LEN);

    ctx.pushOp(Return.make(bridgeInst.scopeFrameOffset), Return.LEN);
  } else {
    ctx.pushOp(Return.make(instOffset), Return.LEN);
  }

  ctx.endAllocScope(popValues: false);
}

void compileDefaultConstructor(CompilerContext ctx, ClassDeclaration parent, List<FieldDeclaration> fields) {
  final parentName = parent.name2.value() as String;
  final n = '$parentName.';

  ctx.topLevelDeclarationPositions[ctx.library]![n] = beginMethod(ctx, parent, parent.offset, '$n()');

  ctx.beginAllocScope();

  final fieldIndices = _getFieldIndices(fields);
  final fieldIdx = fieldIndices.length;

  final $extends = parent.extendsClause;
  Variable $super;
  DeclarationOrPrefix? extendsWhat;

  final argTypes = <TypeRef?>[];
  final namedArgTypes = <String, TypeRef?>{};

  final constructorName = '';

  if ($extends == null) {
    $super = BuiltinValue().push(ctx);
  } else {
    // ignore: deprecated_member_use
    extendsWhat = ctx.visibleDeclarations[ctx.library]![$extends.superclass2.name.name]!;

    final decl = extendsWhat.declaration!;

    if (decl.isBridge) {
      ctx.pushOp(PushBridgeSuperShim.make(), PushBridgeSuperShim.LEN);
      $super = Variable.alloc(ctx, EvalTypes.dynamicType);
    } else {
      final extendsType = TypeRef.lookupClassDeclaration(ctx, ctx.library, decl.declaration as ClassDeclaration);

      AlwaysReturnType? mReturnType;

      final method = IdentifierReference(null, '${extendsType.name}.$constructorName').getValue(ctx);
      if (method.methodOffset == null) {
        throw CompileError('Cannot call $constructorName as it is not a valid method');
      }

      final offset = method.methodOffset!;
      final loc = ctx.pushOp(Call.make(offset.offset ?? -1), Call.LEN);
      if (offset.offset == null) {
        ctx.offsetTracker.setOffset(loc, offset);
      }
      final clsType = TypeRef.lookupClassDeclaration(ctx, ctx.library, parent);
      mReturnType = method.methodReturnType?.toAlwaysReturnType(clsType, argTypes, namedArgTypes) ??
          AlwaysReturnType(EvalTypes.dynamicType, true);

      ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);
      $super = Variable.alloc(ctx, mReturnType.type ?? EvalTypes.dynamicType);
    }
  }

  final op = CreateClass.make(ctx.library, $super.scopeFrameOffset, parent.name2.value() as String, fieldIdx);
  ctx.pushOp(op, CreateClass.len(op));
  final instOffset = ctx.scopeFrameOffset++;

  _compileUnusedFields(ctx, fields, {}, instOffset);

  if ($extends != null && extendsWhat!.declaration!.isBridge) {
    final decl = extendsWhat.declaration!;
    final bridge = decl.bridge! as BridgeClassDef;

    if (!bridge.bridge) {
      throw CompileError('Bridge class ${$extends.superclass} is a wrapper, not a bridge, so you can\'t extend it');
    }

    final op = BridgeInstantiate.make(instOffset,
        ctx.bridgeStaticFunctionIndices[decl.sourceLib]!['${$extends.superclass.name.name}.$constructorName']!);
    ctx.pushOp(op, BridgeInstantiate.len(op));
    final bridgeInst = Variable.alloc(ctx, EvalTypes.dynamicType);

    ctx.pushOp(
        ParentBridgeSuperShim.make($super.scopeFrameOffset, bridgeInst.scopeFrameOffset), ParentBridgeSuperShim.LEN);

    ctx.pushOp(Return.make(bridgeInst.scopeFrameOffset), Return.LEN);
  } else {
    ctx.pushOp(Return.make(instOffset), Return.LEN);
  }

  ctx.endAllocScope(popValues: false);
}

Map<String, int> _getFieldIndices(List<FieldDeclaration> fields) {
  final fieldIndices = <String, int>{};
  var fieldIdx = 0;
  for (final fd in fields) {
    for (final field in fd.fields.variables) {
      fieldIndices[field.name2.value() as String] = fieldIdx;
      fieldIdx++;
    }
  }
  return fieldIndices;
}

void _compileUnusedFields(CompilerContext ctx, List<FieldDeclaration> fields, Set<String> usedNames, int instOffset) {
  var _fieldIdx = 0;
  for (final fd in fields) {
    for (final field in fd.fields.variables) {
      if (!usedNames.contains(field.name2.value() as String) && field.initializer != null) {
        final V = compileExpression(field.initializer!, ctx).boxIfNeeded(ctx);
        ctx.pushOp(SetObjectPropertyImpl.make(instOffset, _fieldIdx, V.scopeFrameOffset), SetObjectPropertyImpl.LEN);
      }
      _fieldIdx++;
    }
  }
}

List<PossiblyValuedParameter> resolveFPLDefaults(CompilerContext ctx, FormalParameterList fpl, bool isInstanceMethod,
    {bool allowUnboxed = true, bool sortNamed = false, bool ignoreDefaults = false}) {
  final normalized = <PossiblyValuedParameter>[];
  var hasEncounteredOptionalPositionalParam = false;
  var hasEncounteredNamedParam = false;
  var _paramIndex = isInstanceMethod ? 1 : 0;

  final named = <FormalParameter>[];
  final positional = <FormalParameter>[];

  for (final param in fpl.parameters) {
    if (param.isNamed) {
      if (hasEncounteredOptionalPositionalParam) {
        throw CompileError('Cannot mix named and optional positional parameters');
      }
      hasEncounteredNamedParam = true;
      named.add(param);
    } else {
      if (param.isOptionalPositional) {
        if (hasEncounteredNamedParam) {
          throw CompileError('Cannot mix named and optional positional parameters');
        }
        hasEncounteredOptionalPositionalParam = true;
      }
      positional.add(param);
    }
  }

  if (sortNamed) {
    named.sort((a, b) => (a.name!.value() as String).compareTo(b.name!.value() as String));
  }

  for (final param in [...positional, ...named]) {
    if (param is DefaultFormalParameter) {
      if (param.defaultValue != null && !ignoreDefaults) {
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
