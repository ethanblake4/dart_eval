import 'package:analyzer/dart/ast/ast.dart';
import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/bridge/declaration.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/expression/method_invocation.dart';
import 'package:dart_eval/src/eval/compiler/helpers/argument_list.dart';
import 'package:dart_eval/src/eval/compiler/helpers/fpl.dart';
import 'package:dart_eval/src/eval/compiler/helpers/return.dart';
import 'package:dart_eval/src/eval/compiler/offset_tracker.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';
import 'package:dart_eval/src/eval/compiler/scope.dart';
import 'package:dart_eval/src/eval/compiler/source.dart';
import 'package:dart_eval/src/eval/compiler/statement/block.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/ir/bridge.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/ir/objects.dart';
import 'package:dart_eval/src/eval/ir/function.dart';
import 'package:dart_eval/src/eval/compiler/backend/representation.dart';

import '../variable.dart';

void compileConstructorDeclaration(
  CompilerContext ctx,
  ConstructorDeclaration d,
  NamedCompilationUnitMember parent,
  List<FieldDeclaration> fields,
) {
  final parentName = parent.name.lexeme;
  final dName = (d.name?.lexeme) ?? "";
  final n = '$parentName.$dName';
  final isEnum = parent is EnumDeclaration;

  if (d.factoryKeyword != null && d.initializers.isNotEmpty) {
    throw CompileError('Factory constructors cannot have initializers', d);
  }

  ctx.topLevelDeclarationPositions[ctx.library]![n] = beginMethod(
    ctx,
    d,
    d.offset,
    '$n()',
  );

  ctx.beginAllocScope(
    existingAllocLen: d.parameters.parameters.length + (isEnum ? 2 : 0),
  );
  ctx.scopeFrameOffset = d.parameters.parameters.length + (isEnum ? 2 : 0);

  if (isEnum) {
    ctx.pushOp(Parameter(SSA('arg_0'), 0));
    ctx.pushOp(Parameter(SSA('arg_1'), 1));
  }

  SuperConstructorInvocation? $superInitializer;
  RedirectingConstructorInvocation? $redirectingInitializer;
  final otherInitializers = <ConstructorInitializer>[];
  for (final initializer in d.initializers) {
    if (initializer is SuperConstructorInvocation) {
      $superInitializer = initializer;
    } else if (initializer is RedirectingConstructorInvocation) {
      if (d.initializers.length > 1) {
        throw CompileError(
          'Redirecting constructor invocation must be the only initializer',
          d,
        );
      }
      $redirectingInitializer = initializer;
    } else if ($superInitializer != null) {
      throw CompileError(
        'Super constructor invocation must be last in the initializer list',
        d,
      );
    } else {
      otherInitializers.add(initializer);
    }
  }

  final fieldIndices = {
    if (parent is EnumDeclaration) ...{'index': 0, 'name': 1},
    ..._getFieldIndices(fields, parent is EnumDeclaration ? 2 : 0),
  };

  final fieldIdx = fieldIndices.length;

  final fieldFormalNames = <String>[];
  final resolvedParams = resolveFPLDefaults(
    ctx,
    d.parameters,
    false,
    allowUnboxed: true,
    isEnum: parent is EnumDeclaration,
  );

  final superParams = <String>[];
  final parameterRepresentations = <MachineRepresentation>[
    if (isEnum) ...[MachineRepresentation.object, MachineRepresentation.object],
  ];
  var i = parent is EnumDeclaration ? 2 : 0;

  for (final param in resolvedParams) {
    final p = param.parameter;
    final V = param.V;
    Variable vrep;
    if ($redirectingInitializer != null && p is! SimpleFormalParameter) {
      throw CompileError(
        'Redirecting constructor invocation cannot have super or this parameters',
        d,
      );
    }
    if (p is FieldFormalParameter) {
      TypeRef? type0;
      if (p.type != null) {
        type0 = TypeRef.fromAnnotation(ctx, ctx.library, p.type!);
      }
      type0 ??= TypeRef.lookupFieldType(
        ctx,
        TypeRef.lookupDeclaration(ctx, ctx.library, parent),
        p.name.lexeme,
        source: p,
      );
      type0 ??= V?.type;
      type0 ??= CoreTypes.dynamic.ref(ctx);
      parameterRepresentations.add(
        representationForType(
          type0.copyWith(boxed: !type0.isUnboxedAcrossFunctionBoundaries),
        ),
      );

      vrep = Variable.of(
        ctx,
        SSA('arg_$i'),
        type0.copyWith(boxed: !type0.isUnboxedAcrossFunctionBoundaries),
      ).boxIfNeeded(ctx);

      fieldFormalNames.add(p.name.lexeme);
    } else if (p is SuperFormalParameter) {
      final type = resolveSuperFormalType(ctx, ctx.library, p, d);
      parameterRepresentations.add(
        representationForType(
          type.copyWith(boxed: !type.isUnboxedAcrossFunctionBoundaries),
        ),
      );
      vrep = Variable.of(
        ctx,
        SSA('arg_$i'),
        type.copyWith(boxed: !type.isUnboxedAcrossFunctionBoundaries),
      ).boxIfNeeded(ctx);
      superParams.add(p.name.lexeme);
    } else {
      p as SimpleFormalParameter;
      var type = CoreTypes.dynamic.ref(ctx);
      if (p.type != null) {
        type = TypeRef.fromAnnotation(ctx, ctx.library, p.type!);
      }
      type = type.copyWith(
        boxed: !unboxedAcrossFunctionBoundaries.contains(type),
      );
      vrep = Variable.of(ctx, SSA('arg_$i'), type);
      parameterRepresentations.add(representationForType(type));
    }

    ctx.setLocal(p.name!.lexeme, vrep.captureBinding(ctx, p));

    i++;
  }

  final clsType = TypeRef.lookupDeclaration(ctx, ctx.library, parent);
  ctx.functionSignatures[ctx.topLevelDeclarationPositions[ctx.library]![n]!] =
      MachineFunctionSignature(
        parameterRepresentations,
        MachineRepresentation.object,
      );

  // Handle factory constructor
  if (d.factoryKeyword != null) {
    final b = d.body;

    if (b.isAsynchronous || b.isGenerator) {
      throw CompileError(
        'Factory constructors cannot be async and/or generators',
        d,
      );
    }

    StatementInfo? stInfo;

    if (b is BlockFunctionBody) {
      stInfo = compileBlock(
        b.block,
        AlwaysReturnType(clsType, false),
        ctx,
        name: '$n()',
      );
    } else if (b is ExpressionFunctionBody) {
      ctx.beginAllocScope();
      final V = compileExpression(b.expression, ctx);
      stInfo = doReturn(
        ctx,
        AlwaysReturnType(clsType, false),
        V,
        isAsync: b.isAsynchronous,
      );
      ctx.endAllocScope();
    } else {
      throw CompileError('Unknown function body type ${b.runtimeType}', d);
    }

    if (!(stInfo.willAlwaysReturn || stInfo.willAlwaysThrow)) {
      throw CompileError(
        'Factory constructor must always return a value or throw',
        d,
      );
    }

    ctx.endAllocScope(popValues: false);
    return;
  }

  // Handle redirecting constructor
  if ($redirectingInitializer != null) {
    final name = $redirectingInitializer.constructorName?.name ?? '';
    final dec0 = resolveStaticMethod(ctx, clsType, name);
    final dec = dec0.declaration!;
    final fpl = (dec as ConstructorDeclaration).parameters.parameters;

    final result = compileArgumentList(
      ctx,
      $redirectingInitializer.argumentList,
      clsType.file,
      fpl,
      dec,
      source: $redirectingInitializer.argumentList,
    );

    final offset = DeferredOrOffset.lookupStatic(
      ctx,
      clsType.file,
      clsType.name,
      name,
    );
    final V = Variable.ssa(
      ctx,
      Call(offset, result.ssa, result: ctx.svar('redirected')),
      clsType,
    );
    doReturn(ctx, AlwaysReturnType(clsType, false), V);
    return;
  }

  final $extends = parent is EnumDeclaration
      ? null
      : (parent as ClassDeclaration).extendsClause;
  Variable $super;
  DeclarationOrPrefix? extendsWhat;
  DeclarationOrBridge? extendsDecl;

  final ssa = <SSA>[];
  final argTypes = <TypeRef?>[];
  final namedArgTypes = <String, TypeRef?>{};

  var constructorName = $superInitializer?.constructorName?.name ?? '';

  if ($extends == null) {
    $super = BuiltinValue().push(ctx);
  } else {
    final prefix = $extends.superclass.importPrefix;
    final clsName = $extends.superclass.name.lexeme;
    extendsWhat =
        (prefix != null
            ? ctx.visibleDeclarations[ctx.library]![prefix.name.value()]
            : ctx.visibleDeclarations[ctx.library]![clsName]) ??
        (throw CompileError('Cannot find superclass $clsName', $extends));

    extendsDecl =
        extendsWhat.declaration ??
        extendsWhat.children?[clsName] ??
        (throw CompileError('Cannot find superclass $clsName', $extends));

    if (extendsDecl.isBridge) {
      $super = Variable.ssa(
        ctx,
        NewBridgeSuperShim(ctx.svar('shim')),
        CoreTypes.dynamic.ref(ctx),
      );
    } else {
      final extendsType = TypeRef.lookupDeclaration(
        ctx,
        ctx.library,
        extendsDecl.declaration as ClassDeclaration,
        prefix: prefix?.name.lexeme,
      );

      AlwaysReturnType? mReturnType;

      if ($superInitializer != null) {
        final constructor0 =
            ctx.topLevelDeclarationsMap[extendsDecl
                .sourceLib]!['${extendsType.name}.$constructorName']!;
        final constructor = constructor0.declaration as ConstructorDeclaration;

        final argres = compileArgumentList(
          ctx,
          $superInitializer.argumentList,
          extendsDecl.sourceLib,
          constructor.parameters.parameters,
          constructor,
          superParams: superParams,
          source: $superInitializer,
        );
        final args = argres.args;
        final namedArgs = argres.namedArgs;
        ssa.addAll(argres.ssa);

        argTypes.addAll(args.map((e) => e.type).toList());
        namedArgTypes.addAll(
          namedArgs.map((key, value) => MapEntry(key, value.type)),
        );
      } else if (superParams.isNotEmpty) {
        // If there are super parameters, compile without an argument list
        final constructor0 =
            ctx.topLevelDeclarationsMap[extendsDecl
                .sourceLib]!['${extendsType.name}.$constructorName']!;
        final constructor = constructor0.declaration as ConstructorDeclaration;
        final argres = compileSuperParams(
          ctx,
          constructor.parameters.parameters,
          constructor,
          superParams: superParams,
          source: $superInitializer,
        );
        final args = argres.args;
        final namedArgs = argres.namedArgs;
        ssa.addAll(argres.ssa);

        argTypes.addAll(args.map((e) => e.type).toList());
        namedArgTypes.addAll(
          namedArgs.map((key, value) => MapEntry(key, value.type)),
        );
      }

      final method = IdentifierReference(
        null,
        '${prefix != null ? '${prefix.name.value()}.' : ''}${extendsType.name}.$constructorName',
      ).getValue(ctx);
      if (method.methodOffset == null) {
        throw CompileError(
          'Cannot call $constructorName as it is not a valid method',
        );
      }

      final offset = method.methodOffset!;

      mReturnType =
          method.methodReturnType?.toAlwaysReturnType(
            ctx,
            clsType,
            argTypes,
            namedArgTypes,
          ) ??
          AlwaysReturnType(CoreTypes.dynamic.ref(ctx), true);

      $super = Variable.ssa(
        ctx,
        Call(offset, ssa, result: ctx.svar('super')),
        mReturnType.type ?? CoreTypes.dynamic.ref(ctx),
      );
    }
  }

  final inst = Variable.ssa(
    ctx,
    CreateClass(
      ctx.svar('inst'),
      ctx.library,
      parent.name.lexeme,
      $super.ssa,
      fieldIdx,
    ),
    TypeRef.$this(ctx)!,
  );

  if (parent is EnumDeclaration) {
    _setupEnum(ctx, parent, inst.ssa);
  }

  for (final fieldFormal in fieldFormalNames) {
    ctx.pushOp(
      SetPropertyStatic(
        inst.ssa,
        fieldIndices[fieldFormal]!,
        ctx.lookupLocal(fieldFormal)!.ssa,
      ),
    );
  }

  final usedNames = {...fieldFormalNames};

  for (final init in otherInitializers) {
    if (init is ConstructorFieldInitializer) {
      final fType = TypeRef.lookupFieldType(
        ctx,
        TypeRef.lookupDeclaration(ctx, ctx.library, parent),
        init.fieldName.name,
        source: init,
      );
      final V = compileExpression(init.expression, ctx, fType).boxIfNeeded(ctx);
      ctx.pushOp(
        SetPropertyStatic(inst.ssa, fieldIndices[init.fieldName.name]!, V.ssa),
      );
      usedNames.add(init.fieldName.name);
    } else {
      throw CompileError('${init.runtimeType} initializer is not supported');
    }
  }

  _compileUnusedFields(ctx, fields, usedNames, inst.ssa, isEnum ? 2 : 0);

  final body = d.body;
  if (d.factoryKeyword == null && body is! EmptyFunctionBody) {
    ctx.beginAllocScope();
    ctx.setLocal('#this', inst);
    if (body is BlockFunctionBody) {
      compileBlock(
        body.block,
        AlwaysReturnType(CoreTypes.voidType.ref(ctx), false),
        ctx,
        name: '$n()',
      );
    } else if (body is ExpressionFunctionBody) {
      final V = compileExpression(body.expression, ctx);
      doReturn(ctx, AlwaysReturnType(CoreTypes.voidType.ref(ctx), false), V);
    }
    ctx.endAllocScope();
  }

  if ($extends != null && extendsDecl!.isBridge) {
    final bridge = extendsDecl.bridge! as BridgeClassDef;

    if (!bridge.bridge) {
      throw CompileError(
        'Bridge class ${$extends.superclass} is a wrapper, not a bridge, so you can\'t extend it',
      );
    }

    if ($superInitializer != null) {
      final constructor = bridge.constructors[constructorName]!;
      final argsPair = compileArgumentListWithBridge(
        ctx,
        $superInitializer.argumentList,
        constructor.functionDescriptor,
      );
      ssa.addAll(argsPair.ssa);
      final args = argsPair.args;
      final namedArgs = argsPair.namedArgs;
      argTypes.addAll(args.map((e) => e.type).toList());
      namedArgTypes.addAll(
        namedArgs.map((key, value) => MapEntry(key, value.type)),
      );
    } else if (superParams.isNotEmpty) {
      final constructor = bridge.constructors[constructorName]!;
      final argsPair = compileSuperParamsWithBridge(
        ctx,
        constructor.functionDescriptor,
        superParams: superParams,
      );
      ssa.addAll(argsPair.ssa);
      final args = argsPair.args;
      final namedArgs = argsPair.namedArgs;
      argTypes.addAll(args.map((e) => e.type).toList());
      namedArgTypes.addAll(
        namedArgs.map((key, value) => MapEntry(key, value.type)),
      );
    }

    final bridgeInst = Variable.ssa(
      ctx,
      BridgeInstantiate(
        ctx.svar('bridge_instance'),
        ctx.bridgeStaticFunctionIndices[extendsDecl
            .sourceLib]!['${$extends.superclass.name.lexeme}.$constructorName']!,
        inst.ssa,
        ssa,
        runtimeTypeId: TypeRef.fromAnnotation(
          ctx,
          ctx.library,
          $extends.superclass,
        ).toRuntimeType(ctx).type,
      ),
      CoreTypes.dynamic.ref(ctx),
    );
    ctx.pushOp(ParentBridgeSuperShim($super.ssa, bridgeInst.ssa));
    ctx.pushOp(Return(bridgeInst.ssa));
  } else {
    ctx.pushOp(Return(inst.ssa));
  }

  ctx.endAllocScope(popValues: false);
}

void compileDefaultConstructor(
  CompilerContext ctx,
  NamedCompilationUnitMember parent,
  List<FieldDeclaration> fields,
) {
  final parentName = parent.name.lexeme;
  final n = '$parentName.';

  ctx.topLevelDeclarationPositions[ctx.library]![n] = beginMethod(
    ctx,
    parent,
    parent.offset,
    '$n()',
  );

  final isEnum = parent is EnumDeclaration;
  ctx.functionSignatures[ctx.topLevelDeclarationPositions[ctx
      .library]![n]!] = MachineFunctionSignature(
    isEnum ? [MachineRepresentation.object, MachineRepresentation.object] : [],
    MachineRepresentation.object,
  );
  ctx.beginAllocScope(existingAllocLen: isEnum ? 2 : 0);
  ctx.scopeFrameOffset += isEnum ? 2 : 0;
  if (isEnum) {
    ctx.pushOp(Parameter(SSA('arg_0'), 0));
    ctx.pushOp(Parameter(SSA('arg_1'), 1));
  }

  final fieldIndices = _getFieldIndices(fields);
  final fieldIdx = fieldIndices.length;

  final $extends = parent is EnumDeclaration
      ? null
      : (parent as ClassDeclaration).extendsClause;
  Variable $super;
  DeclarationOrPrefix? extendsWhat;
  DeclarationOrBridge? extendsDecl;

  final argTypes = <TypeRef?>[];
  final namedArgTypes = <String, TypeRef?>{};

  final constructorName = '';

  if ($extends == null) {
    $super = BuiltinValue().push(ctx);
  } else {
    final prefix = $extends.superclass.importPrefix;
    final clsName = $extends.superclass.name.lexeme;
    extendsWhat =
        (prefix != null
            ? ctx.visibleDeclarations[ctx.library]![prefix.name.value()]
            : ctx.visibleDeclarations[ctx.library]![clsName]) ??
        (throw CompileError('Cannot find superclass $clsName', $extends));

    extendsDecl =
        extendsWhat.declaration ??
        extendsWhat.children?[clsName] ??
        (throw CompileError('Cannot find superclass $clsName', $extends));

    if (extendsDecl.isBridge) {
      $super = Variable.ssa(
        ctx,
        NewBridgeSuperShim(ctx.svar('shim')),
        CoreTypes.dynamic.ref(ctx),
      );
    } else {
      final extendsType = TypeRef.lookupDeclaration(
        ctx,
        ctx.library,
        extendsDecl.declaration as ClassDeclaration,
        prefix: prefix?.name.lexeme,
      );

      AlwaysReturnType? mReturnType;

      final method = IdentifierReference(
        null,
        '${prefix != null ? '${prefix.name.value()}.' : ''}${extendsType.name}.$constructorName',
      ).getValue(ctx);
      if (method.methodOffset == null) {
        throw CompileError(
          'Cannot call $constructorName as it is not a valid method',
        );
      }

      final offset = method.methodOffset!;
      final clsType = TypeRef.lookupDeclaration(ctx, ctx.library, parent);
      mReturnType =
          method.methodReturnType?.toAlwaysReturnType(
            ctx,
            clsType,
            argTypes,
            namedArgTypes,
          ) ??
          AlwaysReturnType(CoreTypes.dynamic.ref(ctx), true);

      $super = Variable.ssa(
        ctx,
        Call(offset, [], result: ctx.svar('super')),
        mReturnType.type ?? CoreTypes.dynamic.ref(ctx),
      );
    }
  }

  final inst = ctx.svar('instance');
  ctx.pushOp(
    CreateClass(
      inst,
      ctx.library,
      parent.name.lexeme,
      $super.ssa,
      fieldIdx + (isEnum ? 2 : 0),
    ),
  );

  if (parent is EnumDeclaration) {
    _setupEnum(ctx, parent, inst);
  }

  _compileUnusedFields(
    ctx,
    fields,
    parent is EnumDeclaration ? {'index', 'name'} : {},
    inst,
    parent is EnumDeclaration ? 2 : 0,
  );

  if ($extends != null && extendsDecl!.isBridge) {
    final bridge = extendsDecl.bridge! as BridgeClassDef;

    if (!bridge.bridge) {
      throw CompileError(
        'Bridge class ${$extends.superclass} is a wrapper, not a bridge, so you can\'t extend it',
      );
    }

    final bridgeInst = ctx.svar('bridge_instance');
    ctx.pushOp(
      BridgeInstantiate(
        bridgeInst,
        ctx.bridgeStaticFunctionIndices[extendsDecl
            .sourceLib]!['${$extends.superclass.name.lexeme}.$constructorName']!,
        inst,
        [],
        runtimeTypeId: TypeRef.fromAnnotation(
          ctx,
          ctx.library,
          $extends.superclass,
        ).toRuntimeType(ctx).type,
      ),
    );
    ctx.pushOp(ParentBridgeSuperShim($super.ssa, bridgeInst));
    ctx.pushOp(Return(bridgeInst));
  } else {
    ctx.pushOp(Return(inst));
  }

  ctx.endAllocScope(popValues: false);
}

Map<String, int> _getFieldIndices(
  List<FieldDeclaration> fields, [
  int fieldIdx = 0,
]) {
  final fieldIndices = <String, int>{};
  var fieldIdx0 = fieldIdx;
  for (final fd in fields) {
    for (final field in fd.fields.variables) {
      fieldIndices[field.name.lexeme] = fieldIdx0;
      fieldIdx0++;
    }
  }
  return fieldIndices;
}

void _compileUnusedFields(
  CompilerContext ctx,
  List<FieldDeclaration> fields,
  Set<String> usedNames,
  SSA inst, [
  int fieldIdx = 0,
]) {
  var fieldIdx0 = fieldIdx;
  for (final fd in fields) {
    for (final field in fd.fields.variables) {
      if (!usedNames.contains(field.name.lexeme) &&
          fd.fields.isLate &&
          field.initializer == null) {
        final marker = ctx.svar('uninitialized_field');
        ctx.pushOp(LoadUninitializedField(marker));
        ctx.pushOp(SetPropertyStatic(inst, fieldIdx0, marker));
      }
      if (!usedNames.contains(field.name.lexeme) && field.initializer != null) {
        final V = compileExpression(field.initializer!, ctx).boxIfNeeded(ctx);
        ctx.inferredFieldTypes
                .putIfAbsent(ctx.library, () => {})
                .putIfAbsent(
                  ctx.currentClass!.name.lexeme,
                  () => {},
                )[field.name.lexeme] =
            V.type;
        ctx.pushOp(SetPropertyStatic(inst, fieldIdx0, V.ssa));
      }
      fieldIdx0++;
    }
  }
}

void _setupEnum(CompilerContext ctx, EnumDeclaration parent, SSA inst) {
  /// Add implicit index and name fields
  ctx.inferredFieldTypes
      .putIfAbsent(ctx.library, () => {})
      .putIfAbsent(ctx.currentClass!.name.lexeme, () => {})
    ..['index'] = CoreTypes.int.ref(ctx)
    ..['name'] = CoreTypes.string.ref(ctx);

  ctx.pushOp(SetPropertyStatic(inst, 0, SSA('arg_0')));
  ctx.pushOp(SetPropertyStatic(inst, 1, SSA('arg_1')));
}
