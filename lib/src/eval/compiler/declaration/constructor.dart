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
  List<FieldDeclaration> fields, {
  Map<ClassMember, int> memberLibraries = const {},
}) {
  final parentName = declarationName(parent);
  final dName = ctorNameOf(d.name?.lexeme);
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

  final fieldIndexInfo = _getFieldIndices(
    fields,
    parent is EnumDeclaration ? 2 : 0,
  );
  final fieldIndices = {
    if (parent is EnumDeclaration) ...{'index': 0, 'name': 1},
    ...fieldIndexInfo.indices,
  };

  final fieldIdx = fieldIndexInfo.count;

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
    parameterHost: redirectTargetDecl is ConstructorDeclaration
        ? redirectTargetDecl
        : d,
    decLibrary: redirectTarget?.$2.file,
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
        for (final p
            in ctorDecl?.parameters.parameters ?? const <FormalParameter>[]) {
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
    final name = ctorNameOf($redirectingInitializer.constructorName?.name);
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
    ctx.endScope();
    return;
  }

  // Field initializers run before the superconstructor invocation — evaluate
  // them now and apply the values once the instance exists.
  final usedNames = {
    ...fieldFormalNames,
    for (final init in otherInitializers)
      if (init is ConstructorFieldInitializer) init.fieldName.name,
  };
  final evaluatedFieldInits = _evalUnusedFieldInitializers(
    ctx,
    fields,
    usedNames,
    memberLibraries,
    parent,
  );

  final $extends = parent is EnumDeclaration
      ? null
      : classLikeClauses(parent).$1;
  Variable $super;
  DeclarationOrBridge? extendsDecl;
  ImportPrefixReference? prefix;

  final constructorName = ctorNameOf($superInitializer?.constructorName?.name);

  TypeRef? extendsType;
  if ($extends == null) {
    $super = BuiltinValue().push(ctx);
  } else {
    (extendsDecl, prefix, extendsType) = _resolveSuperclass(ctx, $extends);
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
            extendsType: extendsType,
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
    } else {
      throw CompileError('${init.runtimeType} initializer is not supported');
    }
  }

  _compileUnusedFields(
    ctx,
    fields,
    usedNames,
    inst.ssa,
    isEnum ? 2 : 0,
    memberLibraries,
    parent,
    evaluatedFieldInits,
  );

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
  List<FieldDeclaration> fields, {
  Map<ClassMember, int> memberLibraries = const {},
}) {
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

  final fieldIdx = _getFieldIndices(fields).count;

  // Field initializers run before the superconstructor invocation — evaluate
  // them now and apply the values once the instance exists.
  final evaluatedFieldInits = _evalUnusedFieldInitializers(
    ctx,
    fields,
    const {},
    memberLibraries,
    parent,
  );

  final $extends = parent is EnumDeclaration
      ? null
      : classLikeClauses(parent).$1;
  Variable $super;
  DeclarationOrBridge? extendsDecl;
  ImportPrefixReference? prefix;

  const constructorName = '';

  if ($extends == null) {
    $super = BuiltinValue().push(ctx);
  } else {
    TypeRef? extendsType;
    (extendsDecl, prefix, extendsType) = _resolveSuperclass(ctx, $extends);
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
            extendsType: extendsType,
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
    memberLibraries,
    parent,
    evaluatedFieldInits,
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

/// Maps each field name to its storage slot. A class can own several fields
/// with the same name (e.g. `with A, B` where both mixins declare `foo`); the
/// name index resolves to the last one, but each still gets a slot, so [count]
/// (the total slot count) can exceed `indices.length`.
({Map<String, int> indices, int count}) _getFieldIndices(
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
  return (indices: fieldIndices, count: fieldIdx0);
}

/// Field initializers conform to the field's declared type; `dynamic`
/// initializer values defer to the runtime field store's type check.
void _checkFieldInitializerConformance(
  CompilerContext ctx,
  FieldDeclaration fd,
  VariableDeclaration field,
  Variable V,
) {
  final annotation = fd.fields.type;
  if (annotation == null) return;
  final declared = TypeRef.fromAnnotation(ctx, ctx.library, annotation);
  if (!V.type.isAssignableTo(ctx, declared, forceAllowDynamic: true)) {
    throw CompileError(
      "A value of type '${V.type}' can't be assigned to a field of type "
      "'$declared'",
      field.initializer,
      ctx.library,
      ctx,
    );
  }
}

/// Evaluates the initializer expressions of fields not bound by the
/// constructor's initializer list, storing each result in a local. Field
/// initializers run before the superconstructor invocation (initializer list
/// semantics), but the instance does not exist yet — the values are applied
/// by [_compileUnusedFields] after the instance is created.
Map<String, Variable> _evalUnusedFieldInitializers(
  CompilerContext ctx,
  List<FieldDeclaration> fields,
  Set<String> usedNames,
  Map<ClassMember, int> memberLibraries,
  Declaration? parent,
) {
  final evaluated = <String, Variable>{};
  for (final fd in fields) {
    for (final field in fd.fields.variables) {
      if (usedNames.contains(field.name.lexeme) ||
          field.initializer == null) {
        continue;
      }
      // A folded mixin field's initializer resolves in the mixin's library
      // and lexical class scope.
      final prevLibrary = ctx.library;
      final memberLibrary = memberLibraries[fd];
      ctx.library = memberLibrary ?? prevLibrary;
      final memberOwner = fd.parent?.parent;
      ctx.memberDeclaringClass =
          memberLibrary != null && memberOwner is Declaration
          ? memberOwner
          : null;
      if (memberLibrary != null && parent != null) {
        seedFoldedMemberTypeParams(
          ctx,
          parent,
          fd,
          memberLibrary,
          prevLibrary,
        );
      }
      final Variable V;
      try {
        V = compileExpression(field.initializer!, ctx).boxIfNeeded(ctx);
        _checkFieldInitializerConformance(ctx, fd, field, V);
      } finally {
        ctx.library = prevLibrary;
        ctx.memberDeclaringClass = null;
      }
      ctx.inferredFieldTypes
          .putIfAbsent(ctx.library, () => {})
          .putIfAbsent(ctx.currentClassName!, () => {})[field.name.lexeme] = V
          .type;
      evaluated[field.name.lexeme] = V;
    }
  }
  return evaluated;
}

void _compileUnusedFields(
  CompilerContext ctx,
  List<FieldDeclaration> fields,
  Set<String> usedNames,
  SSA inst, [
  int fieldIdx = 0,
  Map<ClassMember, int> memberLibraries = const {},
  Declaration? parent,
  Map<String, Variable> evaluated = const {},
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
        final V = evaluated[field.name.lexeme];
        if (V != null) {
          ctx.pushOp(SetPropertyStatic(inst, fieldIdx0, V.ssa));
        } else {
          // A folded mixin field's initializer resolves in the mixin's
          // library and lexical class scope.
          final prevLibrary = ctx.library;
          final memberLibrary = memberLibraries[fd];
          ctx.library = memberLibrary ?? prevLibrary;
          final memberOwner = fd.parent?.parent;
          ctx.memberDeclaringClass =
              memberLibrary != null && memberOwner is Declaration
              ? memberOwner
              : null;
          if (memberLibrary != null && parent != null) {
            seedFoldedMemberTypeParams(
              ctx,
              parent,
              fd,
              memberLibrary,
              prevLibrary,
            );
          }
          final Variable v0;
          try {
            v0 = compileExpression(field.initializer!, ctx).boxIfNeeded(ctx);
            _checkFieldInitializerConformance(ctx, fd, field, v0);
          } finally {
            ctx.library = prevLibrary;
            ctx.memberDeclaringClass = null;
          }
          ctx.inferredFieldTypes
              .putIfAbsent(ctx.library, () => {})
              .putIfAbsent(ctx.currentClassName!, () => {})[field
                  .name
                  .lexeme] = v0.type;
          ctx.pushOp(SetPropertyStatic(inst, fieldIdx0, v0.ssa));
        }
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

/// Whether the class declares any constructor: constructor entries share the
/// `'$className.'` key prefix with static members, so filter by declaration
/// kind rather than the key alone.
bool _hasDeclaredConstructor(
  Map<String, DeclarationOrBridge> members,
  String className,
) => members.keys.any(
  (k) =>
      k.startsWith('$className.') &&
      members[k]!.declaration is ConstructorDeclaration,
);

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
(DeclarationOrBridge, ImportPrefixReference?, TypeRef?) _resolveSuperclass(
  CompilerContext ctx,
  NamedType $extends,
) {
  final prefix = $extends.importPrefix;
  final clsName = $extends.name.lexeme;
  final extendsWhat =
      (prefix != null
          ? ctx.visibleDeclarations[ctx.library]![prefix.name.value()]
          : ctx.visibleDeclarations[ctx.library]![clsName]) ??
      (throw CompileError('Cannot find superclass $clsName', $extends));

  var extendsDecl =
      extendsWhat.declaration ??
      extendsWhat.children?[clsName] ??
      (throw CompileError('Cannot find superclass $clsName', $extends));

  // `class D extends PublicClass` where `PublicClass` is a typedef — resolve
  // to the alias's target class declaration; the alias's target may be private
  // to its own file, so keep the resolved [TypeRef] for the caller.
  final extendsDeclAst = extendsDecl.declaration;
  if (extendsDeclAst is TypeAlias && extendsDeclAst is! ClassTypeAlias) {
    final resolved = resolveTypeAlias(
      ctx,
      ctx.library,
      extendsDeclAst,
      typeArgs: $extends.typeArguments?.arguments,
    );
    extendsDecl =
        ctx.topLevelDeclarationsMap[resolved.file]?[resolved.name] ??
        (throw CompileError('Cannot find superclass $clsName', $extends));
    return (extendsDecl, prefix, resolved);
  }
  // Resolve the clause's type arguments (`extends A<int>`) so the
  // superclass's parameters bind inside the super-constructor call.
  TypeRef? instantiated;
  try {
    instantiated = TypeRef.fromAnnotation(ctx, ctx.library, $extends);
  } on CompileError {
    instantiated = null;
  }
  return (extendsDecl, prefix, instantiated);
}

/// Emits the call to a non-bridge superclass constructor ([constructorName]) and
/// returns the resulting `super` value. [superInitializer] is the explicit
/// `super(...)` call from the constructor's initializer list, if any; otherwise
/// [superParams] forwards this constructor's super parameters positionally.
Variable _invokeSuperConstructor(
  CompilerContext ctx, {
  required Declaration parent,
  required DeclarationOrBridge extendsDecl,
  TypeRef? extendsType,
  required ImportPrefixReference? prefix,
  required String constructorName,
  SuperConstructorInvocation? superInitializer,
  List<String> superParams = const [],
}) {
  extendsType ??= TypeRef.lookupDeclaration(
    ctx,
    ctx.library,
    extendsDecl.declaration!,
    prefix: prefix?.name.lexeme,
  );

  final ssa = <SSA>[];
  final argTypes = <TypeRef?>[];
  final namedArgTypes = <String, TypeRef?>{};

  final superCtors = ctx.topLevelDeclarationsMap[extendsDecl.sourceLib]!;
  final constructor0 = superCtors['${extendsType.name}.$constructorName'];
  if (constructor0 == null &&
      !(constructorName.isEmpty &&
          !_hasDeclaredConstructor(superCtors, extendsType.name))) {
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
            // `extends A<int>` — the superclass's parameters bind to the
            // clause's arguments so `T z` checks against `int`.
            resolveGenerics: _superclassGenerics(
              ctx,
              extendsDecl,
              extendsType,
            ),
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

  final methodOffset = DeferredOrOffset.lookupStatic(
    ctx,
    extendsDecl.sourceLib,
    extendsType.name,
    constructorName,
  );

  // A `super(...)` call produces the superclass's instance.
  final mReturnType = AlwaysReturnType(extendsType, true);

  final superRuntimeType = pushRuntimeTypeId(ctx, extendsType);
  return Variable.ssa(
    ctx,
    Call(methodOffset, [
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
  required NamedType? $extends,
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
      'Bridge class ${$extends!.name.lexeme} is a wrapper, not a bridge, so you can\'t extend it',
    );
  }

  final bridgeInst = ctx.svar('bridge_instance');
  ctx.pushOp(
    BridgeInstantiate(
      bridgeInst,
      ctx.bridgeStaticFunctionIndices[extendsDecl
          .sourceLib]!['${$extends!.name.lexeme}.$constructorName']!,
      inst,
      args,
      runtimeTypeId: TypeRef.fromAnnotation(
        ctx,
        ctx.library,
        $extends,
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
  final targetRef =
      ctx.visibleTypes[ctx.library]![typeName] ??
      (throw CompileError('Redirecting factory target $typeName not found', d));
  var targetType = targetRef;
  final typeArgs = redirected.type.typeArguments;
  if (typeArgs != null) {
    targetType = targetRef.copyWith(
      specifiedTypeArgs: [
        for (final arg in typeArgs.arguments)
          TypeRef.fromAnnotation(ctx, ctx.library, arg),
      ],
    );
  }
  final targetCtors = ctx.topLevelDeclarationsMap[targetRef.file]!;
  final targetCtor = targetCtors['${targetRef.name}.$ctorName'];
  if (targetCtor == null &&
      !(ctorName.isEmpty &&
          !_hasDeclaredConstructor(targetCtors, targetRef.name))) {
    // An unnamed target with no declared constructors resolves to the class's
    // implicit default constructor, which has no declaration entry.
    throw CompileError(
      'Redirecting factory target ${targetRef.name}.$ctorName not found',
      d,
    );
  }
  return (targetType, targetRef, ctorName, targetCtor);
}

/// Compiles the implicit forwarding constructor `C.name` on a class type
/// alias (`class C = S with M;`) — binds the superclass constructor's
/// parameter layout and forwards each argument to `S.name`, returning the
/// created instance.
void compileAliasForwardingConstructor(
  CompilerContext ctx,
  ClassTypeAlias parent,
  String constructorName,
  DeclarationOrBridge target,
  List<FieldDeclaration> fields,
  Map<ClassMember, int> memberLibraries,
) {
  final parentName = declarationName(parent);
  final n = '$parentName.$constructorName';
  final targetDecl = target.declaration as ConstructorDeclaration;
  final targetType = TypeRef.lookupDeclaration(
    ctx,
    target.sourceLib,
    targetDecl.parent!.parent! as Declaration,
  );
  ctx.topLevelDeclarationPositions[ctx.library]![n] = ctx.beginFunction('$n()');
  ctx.beginScope();
  // The alias ctor mirrors the callee's erased ABI: `B<T>`'s `T x` stays an
  // erased `T` even though this alias applies `T = int`. Resolving parameter
  // types through [calleeTypeParameters] also avoids `temporaryTypes` entries
  // seeded for a same-file mixin's identically-named parameters.
  final calleeTypeParameters = classTypeParameterRefs(
    target.sourceLib,
    targetType.name,
    classLikeClauses(targetDecl.parent!.parent! as Declaration).$4,
  );
  final previousLibrary = ctx.library;
  ctx.library = target.sourceLib;
  final List<FormalParameter> resolvedParams;
  try {
    resolvedParams = resolveFPLDefaults(
      ctx,
      targetDecl.parameters,
      false,
      allowUnboxed: true,
      parameterHost: targetDecl,
      decLibrary: target.sourceLib,
      typeParameters: calleeTypeParameters,
    );
  } finally {
    ctx.library = previousLibrary;
  }
  final parameterRepresentations = <MachineRepresentation>[];
  var i = 0;
  for (final p in resolvedParams) {
    final (fieldOrDeclType, _) = getFormalParameterType(
      ctx,
      p,
      target.sourceLib,
      targetDecl,
      typeParameters: calleeTypeParameters,
    );
    final type = fieldOrDeclType ??
        ctx.functionParameterTypes[ctx.currentFunctionId!]![i];
    parameterRepresentations.add(
      representationForType(type.typeAcrossFunctionBoundary),
    );
    ctx.setLocal(
      p.name!.lexeme,
      Variable.of(
        ctx,
        SSA('arg_$i'),
        type.typeAcrossFunctionBoundary,
      ).captureBinding(ctx, p),
    );
    i++;
  }
  // Generative callees receive the runtime type as a trailing int argument.
  final result = ctx.svar('instance');
  final isFactory = targetDecl.factoryKeyword != null;
  if (!isFactory) {
    parameterRepresentations.add(MachineRepresentation.integer);
    ctx.pushOp(
      Parameter(
        SSA('arg_$i'),
        i,
        representation: MachineRepresentation.integer,
      ),
    );
  }
  ctx.functionSignatures[ctx.topLevelDeclarationPositions[ctx.library]![n]!] =
      MachineFunctionSignature(
        parameterRepresentations,
        MachineRepresentation.object,
      );
  final argSsa = <SSA>[];
  for (final p in resolvedParams) {
    final (paramType, _) = getFormalParameterType(
      ctx,
      p,
      target.sourceLib,
      targetDecl,
      typeParameters: calleeTypeParameters,
    );
    argSsa.add(
      coerceArgumentForParameter(
        ctx,
        ctx.lookupLocal(p.name!.lexeme)!.boxIfNeeded(ctx),
        paramType ?? CoreTypes.dynamic.ref(ctx),
        p,
        targetDecl,
        source: parent,
      ).ssa,
    );
  }
  argSsa.add(pushRuntimeTypeId(ctx, targetType));
  // Field initializers run before the superconstructor invocation — evaluate
  // them now and apply the values once the instance exists.
  final evaluatedFieldInits = _evalUnusedFieldInitializers(
    ctx,
    fields,
    const {},
    memberLibraries,
    parent,
  );
  final superResult = ctx.svar('super');
  ctx.pushOp(
    Call(
      DeferredOrOffset.lookupStatic(
        ctx,
        target.sourceLib,
        targetType.name,
        constructorName,
      ),
      argSsa,
      result: superResult,
    ),
  );
  // The alias is itself a class: `new C.n()` produces an instance of `C`
  // whose superclass part is the `S.n` result.
  final parentType = TypeRef.$this(ctx)!;
  final inst = Variable.ssa(
    ctx,
    CreateClass(
      result,
      ctx.library,
      parentName,
      superResult,
      SSA('arg_$i'),
      _getFieldIndices(fields).count,
    ),
    parentType,
  );
  _compileUnusedFields(
    ctx,
    fields,
    {},
    inst.ssa,
    0,
    memberLibraries,
    parent,
    evaluatedFieldInits,
  );
  ctx.pushOp(Return(inst.ssa));
  ctx.endScope();
}

/// The superclass's type parameters bound to the instantiated `extends`
/// clause's arguments — `class B extends A<int>` binds `T: int` for the
/// super-constructor call's parameter types.
Map<String, TypeRef> _superclassGenerics(
  CompilerContext ctx,
  DeclarationOrBridge extendsDecl,
  TypeRef? extendsType,
) {
  final args = extendsType?.specifiedTypeArgs;
  if (args == null || args.isEmpty) return const {};
  final params =
      classLikeClauses(extendsDecl.declaration).$4?.typeParameters ??
      const <TypeParameter>[];
  return {
    for (var i = 0; i < params.length && i < args.length; i++)
      params[i].name.lexeme: args[i],
  };
}
