import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/helpers/argument_list.dart';
import 'package:dart_eval/src/eval/compiler/helpers/fpl.dart';
import 'package:dart_eval/src/eval/compiler/helpers/return.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';
import 'package:dart_eval/src/eval/compiler/scope.dart';
import 'package:dart_eval/src/eval/compiler/source.dart';
import 'package:dart_eval/src/eval/compiler/statement/block.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

import '../variable.dart';

void compileConstructorDeclaration(
    CompilerContext ctx,
    ConstructorDeclaration d,
    NamedCompilationUnitMember parent,
    List<FieldDeclaration> fields) {
  final parentName = parent.name.lexeme;
  final dName = (d.name?.lexeme) ?? "";
  final n = '$parentName.$dName';
  final isEnum = parent is EnumDeclaration;

  if (d.factoryKeyword != null && d.initializers.isNotEmpty) {
    throw CompileError('Factory constructors cannot have initializers', d);
  }

  ctx.topLevelDeclarationPositions[ctx.library]![n] =
      beginMethod(ctx, d, d.offset, '$n()');

  ctx.beginAllocScope(
      existingAllocLen: d.parameters.parameters.length + (isEnum ? 2 : 0));
  ctx.scopeFrameOffset = d.parameters.parameters.length + (isEnum ? 2 : 0);

  SuperConstructorInvocation? $superInitializer;
  final otherInitializers = <ConstructorInitializer>[];
  for (final initializer in d.initializers) {
    if (initializer is SuperConstructorInvocation) {
      $superInitializer = initializer;
    } else if ($superInitializer != null) {
      throw CompileError(
          'Super constructor invocation must be last in the initializer list',
          d);
    } else {
      otherInitializers.add(initializer);
    }
  }

  final fieldIndices = {
    if (parent is EnumDeclaration) ...{'index': 0, 'name': 1},
    ..._getFieldIndices(fields, parent is EnumDeclaration ? 2 : 0)
  };

  final fieldIdx = fieldIndices.length;

  final fieldFormalNames = <String>[];
  final resolvedParams = resolveFPLDefaults(ctx, d.parameters, false,
      allowUnboxed: true, isEnum: parent is EnumDeclaration);

  final superParams = <String>[];
  var i = parent is EnumDeclaration ? 2 : 0;

  for (final param in resolvedParams) {
    final p = param.parameter;
    final V = param.V;
    Variable Vrep;
    if (p is FieldFormalParameter) {
      TypeRef? _type;
      if (p.type != null) {
        _type = TypeRef.fromAnnotation(ctx, ctx.library, p.type!);
      }
      _type ??= TypeRef.lookupFieldType(ctx,
          TypeRef.lookupDeclaration(ctx, ctx.library, parent), p.name.lexeme);
      _type ??= V?.type;
      _type ??= CoreTypes.dynamic.ref(ctx);

      Vrep = Variable(i,
              _type.copyWith(boxed: !_type.isUnboxedAcrossFunctionBoundaries))
          .boxIfNeeded(ctx)
        ..name = p.name.lexeme;

      fieldFormalNames.add(p.name.lexeme);
    } else if (p is SuperFormalParameter) {
      final type = resolveSuperFormalType(ctx, ctx.library, p, d);
      Vrep = Variable(
              i, type.copyWith(boxed: !type.isUnboxedAcrossFunctionBoundaries))
          .boxIfNeeded(ctx)
        ..name = p.name.lexeme;
      superParams.add(p.name.lexeme);
    } else {
      p as SimpleFormalParameter;
      var type = CoreTypes.dynamic.ref(ctx);
      if (p.type != null) {
        type = TypeRef.fromAnnotation(ctx, ctx.library, p.type!);
      }
      type =
          type.copyWith(boxed: !unboxedAcrossFunctionBoundaries.contains(type));
      Vrep = Variable(i, type)..name = p.name!.lexeme;
    }

    ctx.setLocal(Vrep.name!, Vrep);

    i++;
  }

  final clsType = TypeRef.lookupDeclaration(ctx, ctx.library, parent);

  if (d.factoryKeyword != null) {
    final b = d.body;

    if (b.isAsynchronous || b.isGenerator) {
      throw CompileError(
          'Factory constructors cannot be async and/or generators', d);
    }

    StatementInfo? stInfo;

    if (b is BlockFunctionBody) {
      stInfo = compileBlock(b.block, AlwaysReturnType(clsType, false), ctx,
          name: '$n()');
    } else if (b is ExpressionFunctionBody) {
      ctx.beginAllocScope();
      final V = compileExpression(b.expression, ctx);
      stInfo = doReturn(ctx, AlwaysReturnType(clsType, false), V,
          isAsync: b.isAsynchronous);
      ctx.endAllocScope();
    } else {
      throw CompileError('Unknown function body type ${b.runtimeType}', d);
    }

    if (!(stInfo.willAlwaysReturn || stInfo.willAlwaysThrow)) {
      throw CompileError(
          'Factory constructor must always return a value or throw', d);
    }

    ctx.endAllocScope(popValues: false);
    return;
  }

  final $extends = parent is EnumDeclaration
      ? null
      : (parent as ClassDeclaration).extendsClause;
  Variable $super;
  DeclarationOrPrefix? extendsWhat;

  final argTypes = <TypeRef?>[];
  final namedArgTypes = <String, TypeRef?>{};

  var constructorName = $superInitializer?.constructorName?.name ?? '';

  if ($extends == null) {
    $super = BuiltinValue().push(ctx);
  } else {
    extendsWhat = ctx
        .visibleDeclarations[ctx.library]![$extends.superclass.name2.lexeme]!;

    final decl = extendsWhat.declaration!;

    if (decl.isBridge) {
      ctx.pushOp(PushBridgeSuperShim.make(), PushBridgeSuperShim.LEN);
      $super = Variable.alloc(ctx, CoreTypes.dynamic.ref(ctx));
    } else {
      final extendsType = TypeRef.lookupDeclaration(
          ctx, ctx.library, decl.declaration as ClassDeclaration);

      AlwaysReturnType? mReturnType;

      if ($superInitializer != null) {
        final _constructor = ctx.topLevelDeclarationsMap[decl.sourceLib]![
            '${extendsType.name}.$constructorName']!;
        final constructor = _constructor.declaration as ConstructorDeclaration;

        final argsPair = compileArgumentList(
            ctx,
            $superInitializer.argumentList,
            decl.sourceLib,
            constructor.parameters.parameters,
            constructor,
            superParams: superParams,
            source: $superInitializer);
        final _args = argsPair.first;
        final _namedArgs = argsPair.second;

        argTypes.addAll(_args.map((e) => e.type).toList());
        namedArgTypes
            .addAll(_namedArgs.map((key, value) => MapEntry(key, value.type)));
      }

      final method =
          IdentifierReference(null, '${extendsType.name}.$constructorName')
              .getValue(ctx);
      if (method.methodOffset == null) {
        throw CompileError(
            'Cannot call $constructorName as it is not a valid method');
      }

      final offset = method.methodOffset!;
      final loc = ctx.pushOp(Call.make(offset.offset ?? -1), Call.LEN);
      if (offset.offset == null) {
        ctx.offsetTracker.setOffset(loc, offset);
      }

      mReturnType = method.methodReturnType
              ?.toAlwaysReturnType(ctx, clsType, argTypes, namedArgTypes) ??
          AlwaysReturnType(CoreTypes.dynamic.ref(ctx), true);

      ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);
      $super =
          Variable.alloc(ctx, mReturnType.type ?? CoreTypes.dynamic.ref(ctx));
    }
  }

  final op = CreateClass.make(ctx.library, $super.scopeFrameOffset,
      parent.name.lexeme, fieldIdx + (isEnum ? 2 : 0));
  ctx.pushOp(op, CreateClass.len(op));
  final instOffset = ctx.scopeFrameOffset++;

  if (parent is EnumDeclaration) {
    /// Add implicit index and name fields
    ctx.inferredFieldTypes
        .putIfAbsent(ctx.library, () => {})
        .putIfAbsent(ctx.currentClass!.name.lexeme, () => {})
      ..['index'] = CoreTypes.int.ref(ctx)
      ..['name'] = CoreTypes.string.ref(ctx);
  }

  if (parent is EnumDeclaration) {
    ctx.pushOp(SetObjectPropertyImpl.make(instOffset, 0, 0),
        SetObjectPropertyImpl.LEN);
    ctx.pushOp(SetObjectPropertyImpl.make(instOffset, 1, 1),
        SetObjectPropertyImpl.LEN);
  }

  for (final fieldFormal in fieldFormalNames) {
    ctx.pushOp(
        SetObjectPropertyImpl.make(instOffset, fieldIndices[fieldFormal]!,
            ctx.lookupLocal(fieldFormal)!.scopeFrameOffset),
        SetObjectPropertyImpl.LEN);
  }

  final usedNames = {...fieldFormalNames};

  for (final init in otherInitializers) {
    if (init is ConstructorFieldInitializer) {
      final V = compileExpression(init.expression, ctx).boxIfNeeded(ctx);
      ctx.pushOp(
          SetObjectPropertyImpl.make(instOffset,
              fieldIndices[init.fieldName.name]!, V.scopeFrameOffset),
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
      throw CompileError(
          'Bridge class ${$extends.superclass} is a wrapper, not a bridge, so you can\'t extend it');
    }

    if ($superInitializer != null) {
      final constructor = bridge.constructors[constructorName]!;
      final argsPair = compileArgumentListWithBridge(
          ctx, $superInitializer.argumentList, constructor.functionDescriptor);
      final _args = argsPair.first;
      final _namedArgs = argsPair.second;
      argTypes.addAll(_args.map((e) => e.type).toList());
      namedArgTypes
          .addAll(_namedArgs.map((key, value) => MapEntry(key, value.type)));
    }

    final op = BridgeInstantiate.make(
        instOffset,
        ctx.bridgeStaticFunctionIndices[decl.sourceLib]![
            '${$extends.superclass.name2.value()}.$constructorName']!);
    ctx.pushOp(op, BridgeInstantiate.len(op));
    final bridgeInst = Variable.alloc(ctx, CoreTypes.dynamic.ref(ctx));

    ctx.pushOp(
        ParentBridgeSuperShim.make(
            $super.scopeFrameOffset, bridgeInst.scopeFrameOffset),
        ParentBridgeSuperShim.LEN);

    ctx.pushOp(Return.make(bridgeInst.scopeFrameOffset), Return.LEN);
  } else {
    ctx.pushOp(Return.make(instOffset), Return.LEN);
  }

  ctx.endAllocScope(popValues: false);
}

void compileDefaultConstructor(CompilerContext ctx,
    NamedCompilationUnitMember parent, List<FieldDeclaration> fields) {
  final parentName = parent.name.lexeme;
  final n = '$parentName.';

  ctx.topLevelDeclarationPositions[ctx.library]![n] =
      beginMethod(ctx, parent, parent.offset, '$n()');

  final isEnum = parent is EnumDeclaration;
  ctx.beginAllocScope(existingAllocLen: isEnum ? 2 : 0);
  ctx.scopeFrameOffset += isEnum ? 2 : 0;

  final fieldIndices = _getFieldIndices(fields);
  final fieldIdx = fieldIndices.length;

  final $extends = parent is EnumDeclaration
      ? null
      : (parent as ClassDeclaration).extendsClause;
  Variable $super;
  DeclarationOrPrefix? extendsWhat;

  final argTypes = <TypeRef?>[];
  final namedArgTypes = <String, TypeRef?>{};

  final constructorName = '';

  if ($extends == null) {
    $super = BuiltinValue().push(ctx);
  } else {
    extendsWhat = ctx
        .visibleDeclarations[ctx.library]![$extends.superclass.name2.lexeme]!;

    final decl = extendsWhat.declaration!;

    if (decl.isBridge) {
      ctx.pushOp(PushBridgeSuperShim.make(), PushBridgeSuperShim.LEN);
      $super = Variable.alloc(ctx, CoreTypes.dynamic.ref(ctx));
    } else {
      final extendsType = TypeRef.lookupDeclaration(
          ctx, ctx.library, decl.declaration as ClassDeclaration);

      AlwaysReturnType? mReturnType;

      final method =
          IdentifierReference(null, '${extendsType.name}.$constructorName')
              .getValue(ctx);
      if (method.methodOffset == null) {
        throw CompileError(
            'Cannot call $constructorName as it is not a valid method');
      }

      final offset = method.methodOffset!;
      final loc = ctx.pushOp(Call.make(offset.offset ?? -1), Call.LEN);
      if (offset.offset == null) {
        ctx.offsetTracker.setOffset(loc, offset);
      }
      final clsType = TypeRef.lookupDeclaration(ctx, ctx.library, parent);
      mReturnType = method.methodReturnType
              ?.toAlwaysReturnType(ctx, clsType, argTypes, namedArgTypes) ??
          AlwaysReturnType(CoreTypes.dynamic.ref(ctx), true);

      ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);
      $super =
          Variable.alloc(ctx, mReturnType.type ?? CoreTypes.dynamic.ref(ctx));
    }
  }

  final op = CreateClass.make(ctx.library, $super.scopeFrameOffset,
      parent.name.lexeme, fieldIdx + (isEnum ? 2 : 0));
  ctx.pushOp(op, CreateClass.len(op));
  final instOffset = ctx.scopeFrameOffset++;

  if (parent is EnumDeclaration) {
    /// Add implicit index and name fields
    ctx.inferredFieldTypes
        .putIfAbsent(ctx.library, () => {})
        .putIfAbsent(ctx.currentClass!.name.lexeme, () => {})
      ..['index'] = CoreTypes.int.ref(ctx)
      ..['name'] = CoreTypes.string.ref(ctx);
  }

  if (parent is EnumDeclaration) {
    ctx.pushOp(SetObjectPropertyImpl.make(instOffset, 0, 0),
        SetObjectPropertyImpl.LEN);
    ctx.pushOp(SetObjectPropertyImpl.make(instOffset, 1, 1),
        SetObjectPropertyImpl.LEN);
  }

  _compileUnusedFields(
      ctx,
      fields,
      parent is EnumDeclaration ? {'index', 'name'} : {},
      instOffset,
      parent is EnumDeclaration ? 2 : 0);

  if ($extends != null && extendsWhat!.declaration!.isBridge) {
    final decl = extendsWhat.declaration!;
    final bridge = decl.bridge! as BridgeClassDef;

    if (!bridge.bridge) {
      throw CompileError(
          'Bridge class ${$extends.superclass} is a wrapper, not a bridge, so you can\'t extend it');
    }

    final op = BridgeInstantiate.make(
        instOffset,
        ctx.bridgeStaticFunctionIndices[decl.sourceLib]![
            '${$extends.superclass.name2.lexeme}.$constructorName']!);
    ctx.pushOp(op, BridgeInstantiate.len(op));
    final bridgeInst = Variable.alloc(ctx, CoreTypes.dynamic.ref(ctx));

    ctx.pushOp(
        ParentBridgeSuperShim.make(
            $super.scopeFrameOffset, bridgeInst.scopeFrameOffset),
        ParentBridgeSuperShim.LEN);

    ctx.pushOp(Return.make(bridgeInst.scopeFrameOffset), Return.LEN);
  } else {
    ctx.pushOp(Return.make(instOffset), Return.LEN);
  }

  ctx.endAllocScope(popValues: false);
}

Map<String, int> _getFieldIndices(List<FieldDeclaration> fields,
    [int fieldIdx = 0]) {
  final fieldIndices = <String, int>{};
  var _fieldIdx = fieldIdx;
  for (final fd in fields) {
    for (final field in fd.fields.variables) {
      fieldIndices[field.name.lexeme] = _fieldIdx;
      _fieldIdx++;
    }
  }
  return fieldIndices;
}

void _compileUnusedFields(CompilerContext ctx, List<FieldDeclaration> fields,
    Set<String> usedNames, int instOffset,
    [int fieldIdx = 0]) {
  var _fieldIdx = fieldIdx;
  for (final fd in fields) {
    for (final field in fd.fields.variables) {
      if (!usedNames.contains(field.name.lexeme) && field.initializer != null) {
        final V = compileExpression(field.initializer!, ctx).boxIfNeeded(ctx);
        ctx.inferredFieldTypes.putIfAbsent(ctx.library, () => {}).putIfAbsent(
                ctx.currentClass!.name.lexeme, () => {})[field.name.lexeme] =
            V.type;
        ctx.pushOp(
            SetObjectPropertyImpl.make(
                instOffset, _fieldIdx, V.scopeFrameOffset),
            SetObjectPropertyImpl.LEN);
      }
      _fieldIdx++;
    }
  }
}
