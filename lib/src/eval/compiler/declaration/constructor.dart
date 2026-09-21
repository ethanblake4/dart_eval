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
import 'package:dart_eval/src/eval/compiler/dispatch.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';
import 'package:dart_eval/src/eval/compiler/statement/block.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/ir/bridge.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/ir/objects.dart';
import 'package:dart_eval/src/eval/ir/types.dart';
import 'package:dart_eval/src/eval/ir/function.dart';
import 'package:dart_eval/src/eval/compiler/backend/representation.dart';

import '../variable.dart';

void compileConstructorDeclaration(
  CompilerContext ctx,
  ConstructorDeclaration d,
  Declaration parent,
  List<FieldDeclaration> fields,
) {
  final parentName = declarationName(parent);
  final dName = d.name?.lexeme == "new" ? "" : (d.name?.lexeme) ?? "";
  final n = '$parentName.$dName';
  final isEnum = parent is EnumDeclaration;

  if (d.factoryKeyword != null && d.initializers.isNotEmpty) {
    throw CompileError('Factory constructors cannot have initializers', d);
  }

  ctx.topLevelDeclarationPositions[ctx.library]![n] = ctx.beginFunction('$n()');

  ctx.beginScope();

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
  // A redirecting factory's call ABI is its redirect target's parameter
  // list: callers bind arguments in the target's declaration order and pad
  // omitted slots with the target's defaults, so bind incoming slots to the
  // target's parameters.
  final redirectTarget = _redirectTarget(ctx, d);
  final redirectTargetDecl = redirectTarget?.$4?.declaration;

  final resolvedParams = resolveFPLDefaults(
    ctx,
    redirectTargetDecl is ConstructorDeclaration
        ? redirectTargetDecl.parameters
        : d.parameters,
    false,
    allowUnboxed: true,
    isEnum: parent is EnumDeclaration,
  );

  final superParams = <String>[];
  final parameterRepresentations = <MachineRepresentation>[
    if (isEnum) ...[MachineRepresentation.object, MachineRepresentation.object],
  ];
  var i = parent is EnumDeclaration ? 2 : 0;

  for (final p in resolvedParams) {
    Variable vrep;
    if ($redirectingInitializer != null && p is! RegularFormalParameter) {
      throw CompileError(
        'Redirecting constructor invocation cannot have super or this parameters',
        d,
      );
    }
    if (p is FieldFormalParameter) {
      TypeRef? type0;
      if (redirectTargetDecl != null) {
        // Bound against the redirect target's fields, not this class's.
        type0 = getFormalParameterType(
          ctx,
          p,
          redirectTarget!.$2.file,
          redirectTargetDecl,
        ).$1;
      } else if (p.type != null) {
        type0 = TypeRef.fromAnnotation(ctx, ctx.library, p.type!);
      }
      if (redirectTargetDecl == null) {
        type0 ??= TypeRef.lookupFieldType(
          ctx,
          TypeRef.lookupDeclaration(ctx, ctx.library, parent),
          p.name.lexeme,
          source: p,
        );
      }
      type0 ??= CoreTypes.dynamic.ref(ctx);
      parameterRepresentations.add(
        representationForType(type0.typeAcrossFunctionBoundary),
      );

      vrep = Variable.of(
        ctx,
        SSA('arg_$i'),
        type0.typeAcrossFunctionBoundary,
      ).boxIfNeeded(ctx);

      fieldFormalNames.add(p.name.lexeme);
    } else if (p is SuperFormalParameter) {
      final type = resolveSuperFormalType(ctx, ctx.library, p, d);
      parameterRepresentations.add(
        representationForType(type.typeAcrossFunctionBoundary),
      );
      vrep = Variable.of(
        ctx,
        SSA('arg_$i'),
        type.typeAcrossFunctionBoundary,
      ).boxIfNeeded(ctx);
      superParams.add(p.name.lexeme);
    } else {
      var type = CoreTypes.dynamic.ref(ctx);
      if (p.type != null) {
        type = TypeRef.fromAnnotation(
          ctx,
          redirectTarget?.$2.file ?? ctx.library,
          p.type!,
        );
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
  SSA? runtimeTypeArgument;
  if (d.factoryKeyword == null) {
    runtimeTypeArgument = SSA('arg_$i');
    ctx.pushOp(
      Parameter(
        runtimeTypeArgument,
        i,
        representation: MachineRepresentation.integer,
      ),
    );
    ctx.pushOp(SetTypeEnvironment(runtimeTypeArgument));
    parameterRepresentations.add(MachineRepresentation.integer);
  }
  ctx.functionSignatures[ctx.topLevelDeclarationPositions[ctx.library]![n]!] =
      MachineFunctionSignature(
        parameterRepresentations,
        MachineRepresentation.object,
      );

  // Handle factory constructor
  if (d.factoryKeyword != null) {
    final b = d.body;

    if (redirectTarget != null) {
      // `factory C.f(...) = D.g;` forwards its parameters along the target's
      // parameter layout; omitted slots use the target's defaults.
      final (targetType, targetRef, ctorName, targetCtor) = redirectTarget;
      final result = ctx.svar('instance');
      if (targetCtor != null && targetCtor.isBridge) {
        final argSsa = <SSA>[];
        final namedParams = <FormalParameter>[];
        for (final p in d.parameters.parameters) {
          if (p.isNamed) {
            namedParams.add(p);
          } else {
            argSsa.add(ctx.lookupLocal(p.name!.lexeme)!.boxIfNeeded(ctx).ssa);
          }
        }
        namedParams.sort((a, b) => a.name!.lexeme.compareTo(b.name!.lexeme));
        argSsa.addAll(
          namedParams.map(
            (p) => ctx.lookupLocal(p.name!.lexeme)!.boxIfNeeded(ctx).ssa,
          ),
        );
        final externalId =
            ctx.bridgeStaticFunctionIndices[targetRef
                .file]!['${targetRef.name}.$ctorName']!;
        ctx.pushOp(InvokeExternal(result, externalId, argSsa));
      } else {
        final ctorDecl = targetCtor?.declaration as ConstructorDeclaration?;
        // The callee binds the target's parameter layout, so forwarding is
        // a pass-through of each local in declaration order.
        final argSsa = <SSA>[];
        for (final p in ctorDecl?.parameters.parameters ?? const <FormalParameter>[]) {
          final (paramType, _) = getFormalParameterType(
            ctx,
            p,
            targetRef.file,
            ctorDecl ?? d,
          );
          argSsa.add(
            coerceArgumentForParameter(
              ctx,
              ctx.lookupLocal(p.name!.lexeme)!,
              paramType ?? CoreTypes.dynamic.ref(ctx),
              p,
              redirectTargetDecl ?? d,
              source: d,
            ).ssa,
          );
        }
        if (ctorDecl?.factoryKeyword == null) {
          argSsa.add(pushRuntimeTypeId(ctx, targetType));
        }
        ctx.pushOp(
          Call(
            DeferredOrOffset.lookupStatic(
              ctx,
              targetRef.file,
              targetRef.name,
              ctorName,
            ),
            argSsa,
            result: result,
            // A factory callee has no receiver, so the class's instantiated
            // type arguments go through the callable-type-argument channel.
            typeArguments: ctorDecl?.factoryKeyword != null
                ? [
                    for (final arg in targetType.specifiedTypeArgs)
                      arg.runtimeTypeId(ctx),
                  ]
                : const [],
          ),
        );
      }
      ctx.pushOp(Return(result));
      ctx.endScope();
      return;
    }

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
      ctx.beginScope();
      final V = compileExpression(b.expression, ctx);
      stInfo = doReturn(
        ctx,
        AlwaysReturnType(clsType, false),
        V,
        isAsync: b.isAsynchronous,
      );
      ctx.endScope();
    } else {
      throw CompileError('Unknown function body type ${b.runtimeType}', d);
    }

    if (!(stInfo.willAlwaysReturn || stInfo.willAlwaysThrow)) {
      throw CompileError(
        'Factory constructor must always return a value or throw',
        d,
      );
    }

    ctx.endScope();
    return;
  }

  // Handle redirecting constructor
  if ($redirectingInitializer != null) {
    final ctorName0 = $redirectingInitializer.constructorName?.name;
    final name = ctorName0 == 'new' ? '' : ctorName0 ?? '';
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
      Call(offset, [
        ...result.ssa,
        runtimeTypeArgument!,
      ], result: ctx.svar('redirected')),
      clsType,
    );
    doReturn(ctx, AlwaysReturnType(clsType, false), V);
    return;
  }

  final $extends = parent is EnumDeclaration
      ? null
      : (parent as ClassDeclaration).extendsClause;
  Variable $super;
  DeclarationOrBridge? extendsDecl;
  ImportPrefixReference? prefix;

  final ctorName1 = $superInitializer?.constructorName?.name;
    final constructorName = ctorName1 == 'new' ? '' : ctorName1 ?? '';

  if ($extends == null) {
    $super = BuiltinValue().push(ctx);
  } else {
    (extendsDecl, prefix) = _resolveSuperclass(ctx, $extends);
    if (extendsDecl.isBridge && _isObjectWrapper(ctx, extendsDecl.bridge!)) {
      // `extends Object` is the implicit superclass already — elide the
      // wrapper so the class is created as a plain (non-bridge) instance.
      extendsDecl = null;
    }
    $super = extendsDecl == null
        ? BuiltinValue().push(ctx)
        : extendsDecl.isBridge
        ? Variable.ssa(
            ctx,
            NewBridgeSuperShim(ctx.svar('shim')),
            CoreTypes.dynamic.ref(ctx),
          )
        : _invokeSuperConstructor(
            ctx,
            parent: parent,
            extendsDecl: extendsDecl,
            prefix: prefix,
            constructorName: constructorName,
            superInitializer: $superInitializer,
            superParams: superParams,
          );
  }

  final inst = Variable.ssa(
    ctx,
    CreateClass(
      ctx.svar('inst'),
      ctx.library,
      parentName,
      $super.ssa,
      runtimeTypeArgument!,
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
    ctx.beginScope();
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
    ctx.endScope();
  }

  var ssa = <SSA>[];
  if ($extends != null && extendsDecl != null && extendsDecl.isBridge) {
    ssa = _bridgeSuperArgs(
      ctx,
      extendsDecl,
      constructorName,
      superInitializer: $superInitializer,
      superParams: superParams,
    );
  }
  _emitConstructorReturn(
    ctx,
    $extends: $extends,
    extendsDecl: extendsDecl,
    constructorName: constructorName,
    inst: inst.ssa,
    $super: $super.ssa,
    args: ssa,
  );

  ctx.endScope();
}

void compileDefaultConstructor(
  CompilerContext ctx,
  Declaration parent,
  List<FieldDeclaration> fields,
) {
  final parentName = declarationName(parent);
  final n = '$parentName.';

  ctx.topLevelDeclarationPositions[ctx.library]![n] = ctx.beginFunction('$n()');

  final isEnum = parent is EnumDeclaration;
  ctx.functionSignatures[ctx.topLevelDeclarationPositions[ctx
      .library]![n]!] = MachineFunctionSignature([
    if (isEnum) ...[MachineRepresentation.object, MachineRepresentation.object],
    MachineRepresentation.integer,
  ], MachineRepresentation.object);
  ctx.beginScope();
  if (isEnum) {
    ctx.pushOp(Parameter(SSA('arg_0'), 0));
    ctx.pushOp(Parameter(SSA('arg_1'), 1));
  }
  final runtimeTypeArgument = SSA('arg_${isEnum ? 2 : 0}');
  ctx.pushOp(
    Parameter(
      runtimeTypeArgument,
      isEnum ? 2 : 0,
      representation: MachineRepresentation.integer,
    ),
  );
  ctx.pushOp(SetTypeEnvironment(runtimeTypeArgument));

  final fieldIndices = _getFieldIndices(fields);
  final fieldIdx = fieldIndices.length;

  final $extends = parent is EnumDeclaration
      ? null
      : (parent as ClassDeclaration).extendsClause;
  Variable $super;
  DeclarationOrBridge? extendsDecl;
  ImportPrefixReference? prefix;

  const constructorName = '';

  if ($extends == null) {
    $super = BuiltinValue().push(ctx);
  } else {
    (extendsDecl, prefix) = _resolveSuperclass(ctx, $extends);
    if (extendsDecl.isBridge && _isObjectWrapper(ctx, extendsDecl.bridge!)) {
      // `extends Object` is the implicit superclass already — elide the
      // wrapper so the class is created as a plain (non-bridge) instance.
      extendsDecl = null;
    }
    $super = extendsDecl == null
        ? BuiltinValue().push(ctx)
        : extendsDecl.isBridge
        ? Variable.ssa(
            ctx,
            NewBridgeSuperShim(ctx.svar('shim')),
            CoreTypes.dynamic.ref(ctx),
          )
        : _invokeSuperConstructor(
            ctx,
            parent: parent,
            extendsDecl: extendsDecl,
            prefix: prefix,
            constructorName: constructorName,
          );
  }

  final inst = ctx.svar('instance');
  ctx.pushOp(
    CreateClass(
      inst,
      ctx.library,
      parentName,
      $super.ssa,
      runtimeTypeArgument,
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

  _emitConstructorReturn(
    ctx,
    $extends: $extends,
    extendsDecl: extendsDecl,
    constructorName: constructorName,
    inst: inst,
    $super: $super.ssa,
    args: const [],
  );

  ctx.endScope();
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
            .putIfAbsent(ctx.currentClassName!, () => {})[field.name.lexeme] = V
            .type;
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
      .putIfAbsent(ctx.currentClassName!, () => {})
    ..['index'] = CoreTypes.int.ref(ctx)
    ..['name'] = CoreTypes.string.ref(ctx);

  ctx.pushOp(SetPropertyStatic(inst, 0, SSA('arg_0')));
  ctx.pushOp(SetPropertyStatic(inst, 1, SSA('arg_1')));
}

/// Whether [bridge] is the `dart:core` `Object` wrapper — the one wrapper a
/// class may name in an `extends` clause, where it means the same thing as no
/// superclass at all.
bool _isObjectWrapper(CompilerContext ctx, BridgeDeclaration bridge) =>
    bridge is BridgeClassDef &&
    !bridge.bridge &&
    TypeRef.fromBridgeTypeRef(ctx, bridge.type.type) ==
        CoreTypes.object.ref(ctx);

/// Resolves a class's `extends` clause to the superclass's declaration and the
/// import prefix (if any) it was named through.
(DeclarationOrBridge, ImportPrefixReference?) _resolveSuperclass(
  CompilerContext ctx,
  ExtendsClause $extends,
) {
  final prefix = $extends.superclass.importPrefix;
  final clsName = $extends.superclass.name.lexeme;
  final extendsWhat =
      (prefix != null
          ? ctx.visibleDeclarations[ctx.library]![prefix.name.value()]
          : ctx.visibleDeclarations[ctx.library]![clsName]) ??
      (throw CompileError('Cannot find superclass $clsName', $extends));

  final extendsDecl =
      extendsWhat.declaration ??
      extendsWhat.children?[clsName] ??
      (throw CompileError('Cannot find superclass $clsName', $extends));
  return (extendsDecl, prefix);
}

/// Emits the call to a non-bridge superclass constructor ([constructorName]) and
/// returns the resulting `super` value. [superInitializer] is the explicit
/// `super(...)` call from the constructor's initializer list, if any; otherwise
/// [superParams] forwards this constructor's super parameters positionally.
Variable _invokeSuperConstructor(
  CompilerContext ctx, {
  required Declaration parent,
  required DeclarationOrBridge extendsDecl,
  required ImportPrefixReference? prefix,
  required String constructorName,
  SuperConstructorInvocation? superInitializer,
  List<String> superParams = const [],
}) {
  final extendsType = TypeRef.lookupDeclaration(
    ctx,
    ctx.library,
    extendsDecl.declaration as ClassDeclaration,
    prefix: prefix?.name.lexeme,
  );

  final ssa = <SSA>[];
  final argTypes = <TypeRef?>[];
  final namedArgTypes = <String, TypeRef?>{};

  final superCtors = ctx.topLevelDeclarationsMap[extendsDecl.sourceLib]!;
  final constructor0 = superCtors['${extendsType.name}.$constructorName'];
  if (constructor0 == null &&
      !(constructorName.isEmpty &&
          !superCtors.keys.any((k) => k.startsWith('${extendsType.name}.')))) {
    // An unnamed super constructor on a class that declares none is the
    // implicit default constructor — it has no declaration entry.
    throw CompileError(
      "The superclass '${extendsType.name}' has no constructor "
      "'$constructorName'",
      superInitializer ?? parent,
      ctx.library,
      ctx,
    );
  }
  final constructor = constructor0?.declaration as ConstructorDeclaration?;
  if (constructor != null) {
    // `super()` and the implicit super call bind the callee's declared
    // defaults; only an implicit target takes no arguments at all.
    final argres = superInitializer != null
        ? compileArgumentList(
            ctx,
            superInitializer.argumentList,
            extendsDecl.sourceLib,
            constructor.parameters.parameters,
            constructor,
            superParams: superParams,
            source: superInitializer,
          )
        : compileSuperParams(
            ctx,
            constructor.parameters.parameters,
            constructor,
            superParams: superParams,
          );
    ssa.addAll(argres.ssa);
    argTypes.addAll(argres.args.map((e) => e.type));
    namedArgTypes.addAll(
      argres.namedArgs.map((key, value) => MapEntry(key, value.type)),
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

  final clsType = TypeRef.lookupDeclaration(ctx, ctx.library, parent);
  final mReturnType =
      method.methodReturnType?.toAlwaysReturnType(
        ctx,
        clsType,
        argTypes,
        namedArgTypes,
      ) ??
      AlwaysReturnType(CoreTypes.dynamic.ref(ctx), true);

  final superRuntimeType = pushRuntimeTypeId(ctx, extendsType);
  return Variable.ssa(
    ctx,
    Call(method.methodOffset!, [
      ...ssa,
      superRuntimeType,
    ], result: ctx.svar('super')),
    mReturnType.type ?? CoreTypes.dynamic.ref(ctx),
  );
}

/// Compiles the argument list for an explicit `super(...)` call (or super
/// parameters) targeting a *bridge* superclass constructor.
List<SSA> _bridgeSuperArgs(
  CompilerContext ctx,
  DeclarationOrBridge extendsDecl,
  String constructorName, {
  SuperConstructorInvocation? superInitializer,
  List<String> superParams = const [],
}) {
  final bridge = extendsDecl.bridge! as BridgeClassDef;
  final constructor = bridge.constructors[constructorName]!;
  return superInitializer != null
      ? compileArgumentListWithBridge(
          ctx,
          superInitializer.argumentList,
          constructor.functionDescriptor,
        ).ssa
      : superParams.isNotEmpty
      ? compileSuperParamsWithBridge(
          ctx,
          constructor.functionDescriptor,
          superParams: superParams,
        ).ssa
      : <SSA>[];
}

/// Emits the constructor's return. For a bridged superclass this instantiates
/// the runtime bridge object and returns it; otherwise it returns the newly
/// created instance.
void _emitConstructorReturn(
  CompilerContext ctx, {
  required ExtendsClause? $extends,
  required DeclarationOrBridge? extendsDecl,
  required String constructorName,
  required SSA inst,
  required SSA $super,
  required List<SSA> args,
}) {
  if (extendsDecl == null || !extendsDecl.isBridge) {
    ctx.pushOp(Return(inst));
    return;
  }

  final bridge = extendsDecl.bridge! as BridgeClassDef;
  if (!bridge.bridge) {
    throw CompileError(
      'Bridge class ${$extends!.superclass} is a wrapper, not a bridge, so you can\'t extend it',
    );
  }

  final bridgeInst = ctx.svar('bridge_instance');
  ctx.pushOp(
    BridgeInstantiate(
      bridgeInst,
      ctx.bridgeStaticFunctionIndices[extendsDecl
          .sourceLib]!['${$extends!.superclass.name.lexeme}.$constructorName']!,
      inst,
      args,
      runtimeTypeId: TypeRef.fromAnnotation(
        ctx,
        ctx.library,
        $extends.superclass,
      ).runtimeTypeId(ctx),
    ),
  );
  ctx.pushOp(ParentBridgeSuperShim($super, bridgeInst));
  ctx.pushOp(Return(bridgeInst));
}

/// Resolves `factory C.f(...) = T.g` to (instantiated target type, raw target
/// type, target ctor name, target ctor entry) — or null when [d] isn't a
/// redirecting factory or the target can't be resolved.
(TypeRef, TypeRef, String, DeclarationOrBridge?)? _redirectTarget(
  CompilerContext ctx,
  ConstructorDeclaration d,
) {
  final redirected = d.redirectedConstructor;
  if (d.factoryKeyword == null || redirected == null) return null;
  final (typeName, ctorName) = splitConstructorTypeName(
    ctx,
    ctx.library,
    redirected.type,
    redirected.name?.name,
  );
  final targetType = TypeRef.fromAnnotation(ctx, ctx.library, redirected.type);
  final targetRef =
      ctx.visibleTypes[ctx.library]![typeName] ??
      (throw CompileError(
        'Redirecting factory target $typeName not found',
        d,
      ));
  final targetCtors = ctx.topLevelDeclarationsMap[targetRef.file]!;
  final targetCtor = targetCtors['${targetRef.name}.$ctorName'];
  if (targetCtor == null &&
      !(ctorName.isEmpty &&
          !targetCtors.keys.any((k) => k.startsWith('${targetRef.name}.')))) {
    // An unnamed target with no declared constructors resolves to the class's
    // implicit default constructor, which has no declaration entry.
    throw CompileError(
      'Redirecting factory target ${targetRef.name}.$ctorName not found',
      d,
    );
  }
  return (targetType, targetRef, ctorName, targetCtor);
}
