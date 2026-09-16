import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/function.dart';
import 'package:dart_eval/src/eval/compiler/helpers/argument_list.dart';
import 'package:dart_eval/src/eval/compiler/helpers/closure.dart';
import 'package:dart_eval/src/eval/compiler/helpers/equality.dart';
import 'package:dart_eval/src/eval/compiler/helpers/invoke.dart';
import 'package:dart_eval/src/eval/compiler/macros/branch.dart';
import 'package:dart_eval/src/eval/compiler/offset_tracker.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/bridge/declaration.dart';
import 'package:control_flow_graph/control_flow_graph.dart' show SSA;
import 'package:dart_eval/src/eval/ir/bridge.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/ir/objects.dart';
import 'package:dart_eval/src/eval/ir/memory.dart';

import 'expression.dart';
import 'identifier.dart';

Variable compileMethodInvocation(
  CompilerContext ctx,
  MethodInvocation e, {
  TypeRef? bound,
  Variable? cascadeTarget,
}) {
  Variable? L = cascadeTarget;
  var isPrefix = false;
  if (e.target != null && cascadeTarget == null) {
    try {
      L = compileExpression(e.target!, ctx);
      if (e.target is SuperExpression) {
        var owner = L.type.resolveTypeChain(ctx);
        while (!(ctx.instanceDeclarationsMap[owner.file]?[owner.name]
                ?.containsKey(e.methodName.name) ??
            false)) {
          final bridgeOwner =
              ctx.topLevelDeclarationsMap[owner.file]?[owner.name]?.bridge;
          if (bridgeOwner is BridgeClassDef &&
              bridgeOwner.methods.containsKey(e.methodName.name))
            break;
          final parent = owner.extendsType;
          if (parent == null ||
              !ctx.instanceDeclarationsMap.containsKey(parent.file)) {
            break;
          }
          owner = parent.resolveTypeChain(ctx);
          L = Variable.ssa(
            ctx,
            LoadSuper(ctx.svar('super'), L!.ssa),
            owner,
            concreteTypes: [owner],
          );
        }
      }
    } on PrefixError {
      isPrefix = true;
    }
  }

  AlwaysReturnType? mReturnType;
  bool? genericReturnBoxed;

  if (L != null) {
    if (e.operator?.type == TokenType.QUESTION_PERIOD) {
      var out = BuiltinValue().push(ctx).boxIfNeeded(ctx);
      if (L.concreteTypes.length == 1 &&
          L.concreteTypes[0] == CoreTypes.nullType.ref(ctx)) {
        return out;
      }
      macroBranch(
        ctx,
        null,
        condition: (ctx) {
          return checkNotEqual(ctx, L!, out);
        },
        thenBranch: (ctx, rt) {
          final V = _invokeWithTarget(ctx, L!, e);
          out = out.copyWith(type: V.type.copyWith(nullable: true));
          ctx.pushOp(Assign(out.ssa, V.boxIfNeeded(ctx).ssa));
          return StatementInfo(-1);
        },
      );
      return out;
    }
    return _invokeWithTarget(ctx, L, e);
  }
  final method = isPrefix
      ? compilePrefixedIdentifier(
          (e.target as Identifier).name,
          e.methodName.name,
          ctx,
        )
      : compileIdentifier(e.methodName, ctx);

  if (method.type == CoreTypes.dynamic.ref(ctx) ||
      method.callingConvention == CallingConvention.dynamic ||
      (method.type == CoreTypes.function.ref(ctx) &&
          method.methodOffset == null)) {
    return invokeClosure(ctx, null, method, e.argumentList).result;
  }

  if (method.methodOffset == null) {
    throw CompileError(
      'Cannot call ${e.methodName.name} as it is not a valid method',
    );
  }

  final offset = method.methodOffset!;
  if (offset.file == ctx.library &&
      offset.className != null &&
      offset.className == (ctx.currentClass?.name.lexeme)) {
    final $this = ctx.lookupLocal('#this')!;
    return _invokeWithTarget(ctx, $this, e);
  }

  var dec0 = ctx.topLevelDeclarationsMap[offset.file]![e.methodName.name];
  if (dec0 == null ||
      (!dec0.isBridge && dec0.declaration! is ClassDeclaration)) {
    dec0 =
        ctx.topLevelDeclarationsMap[offset.file]![offset.name ??
            '${e.methodName.name}.'];
    if (dec0 == null) {
      // Call to default constructor
      final result = ctx.svar('constructor');
      ctx.pushOp(Call(offset, [], result: result));
      mReturnType =
          method.methodReturnType?.toAlwaysReturnType(
            ctx,
            TypeRef.$this(ctx),
            [],
            {},
          ) ??
          AlwaysReturnType(CoreTypes.dynamic.ref(ctx), true);
      final returnType = mReturnType.type?.copyWith(
        boxed:
            L != null ||
            !(mReturnType.type?.isUnboxedAcrossFunctionBoundaries ?? false),
      );
      final v = Variable.of(
        ctx,
        result,
        mReturnType.type?.copyWith(
              boxed:
                  L != null ||
                  !(mReturnType.type?.isUnboxedAcrossFunctionBoundaries ??
                      false),
            ) ??
            CoreTypes.dynamic.ref(ctx),
        concreteTypes: returnType == null ? [] : [returnType],
      );

      return v;
    }
  }

  final List<Variable> args;
  final Map<String, Variable> namedArgs;
  final List<SSA> callArgs;

  final resolveGenerics = <String, TypeRef>{};
  var isConstructor = false;

  if (dec0.isBridge) {
    final bridge = dec0.bridge;

    /// If we're invoking a class identifier directly (like ClassName()), call
    /// its default constructor
    final fnDescriptor = bridge is BridgeClassDef
        ? (bridge.constructors['']?.functionDescriptor ??
              (throw CompileError(
                'Class "${e.methodName.name}" does not have a default constructor',
                e,
              )))
        : (bridge as BridgeFunctionDeclaration).function;

    final argsPair = compileArgumentListWithBridge(
      ctx,
      e.argumentList,
      fnDescriptor,
      before: L != null ? [L] : [],
    );

    args = argsPair.args;
    namedArgs = argsPair.namedArgs;
    callArgs = argsPair.ssa;
    isConstructor = bridge is BridgeClassDef;
  } else {
    final dec = dec0.declaration!;

    List<FormalParameter> fpl;
    List<TypeParameter>? typeParams;
    TypeAnnotation? returnAnnotation;
    if (dec is FunctionDeclaration) {
      fpl =
          dec.functionExpression.parameters?.parameters ?? <FormalParameter>[];
      typeParams = dec.functionExpression.typeParameters?.typeParameters;
      returnAnnotation = dec.returnType;
    } else if (dec is MethodDeclaration) {
      fpl = dec.parameters?.parameters ?? <FormalParameter>[];
      typeParams = dec.typeParameters?.typeParameters;
      returnAnnotation = dec.returnType;
    } else if (dec is ConstructorDeclaration) {
      fpl = dec.parameters.parameters;
      isConstructor = true;
    } else {
      throw CompileError('Invalid declaration type ${dec.runtimeType}');
    }

    if (typeParams != null) {
      for (final param in typeParams) {
        final bound = param.bound;
        final name = param.name.lexeme;
        if (bound != null) {
          resolveGenerics[name] = TypeRef.fromAnnotation(
            ctx,
            offset.file!,
            bound,
          );
        } else {
          resolveGenerics[name] = CoreTypes.dynamic.ref(ctx);
        }
      }
    }

    if (returnAnnotation is NamedType) {
      final declaredBound = resolveGenerics[returnAnnotation.name.value()];
      if (declaredBound != null) {
        // Inference narrows the language type, not the compiled callee's ABI.
        genericReturnBoxed = !declaredBound.isUnboxedAcrossFunctionBoundaries;
      }
    }
    final argsPair = compileArgumentList(
      ctx,
      e.argumentList,
      offset.file!,
      fpl,
      dec,
      before: L != null ? [L] : [],
      source: e,
      resolveGenerics: resolveGenerics,
    );

    if (returnAnnotation != null && returnAnnotation is NamedType) {
      final g = resolveGenerics[returnAnnotation.name.value()];
      if (g != null) {
        mReturnType = AlwaysReturnType(g, returnAnnotation.question != null);
      }
    }
    args = argsPair.args;
    namedArgs = argsPair.namedArgs;
    callArgs = argsPair.ssa;
  }

  final argTypes = args.map((e) => e.type).toList();
  final namedArgTypes = namedArgs.map(
    (key, value) => MapEntry(key, value.type),
  );

  final result = ctx.svar('call');
  if (dec0.isBridge) {
    final bridge = dec0.bridge!;
    if (bridge is BridgeClassDef && !bridge.wrap) {
      final type = TypeRef.fromBridgeTypeRef(ctx, bridge.type.type);
      final subclass = BuiltinValue().push(ctx);
      ctx.pushOp(
        BridgeInstantiate(
          result,
          ctx.bridgeStaticFunctionIndices[type.file]!['${type.name}.']!,
          subclass.ssa,
          callArgs,
          runtimeTypeId: type.toRuntimeType(ctx).type,
        ),
      );
    } else {
      ctx.pushOp(
        InvokeExternal(
          result,
          ctx.bridgeStaticFunctionIndices[offset.file]![offset.name]!,
          callArgs,
        ),
      );
    }
  } else {
    ctx.pushOp(Call(offset, callArgs, result: result));
  }

  TypeRef? thisType;
  if (ctx.currentClass != null) {
    thisType = ctx.visibleTypes[ctx.library]![ctx.currentClass!.name.lexeme]!;
  }

  mReturnType ??=
      method.methodReturnType?.toAlwaysReturnType(
        ctx,
        thisType,
        argTypes,
        namedArgTypes,
      ) ??
      AlwaysReturnType(CoreTypes.dynamic.ref(ctx), true);
  final returnType = mReturnType.type?.copyWith(
    boxed:
        dec0.isBridge ||
        (genericReturnBoxed ??
            !(mReturnType.type?.isUnboxedAcrossFunctionBoundaries ?? false)),
  );

  final v = Variable.of(
    ctx,
    result,
    returnType ?? CoreTypes.dynamic.ref(ctx),
    concreteTypes: [if (isConstructor && returnType != null) returnType],
  );

  return v;
}

Variable _invokeWithTarget(
  CompilerContext ctx,
  Variable L,
  MethodInvocation e,
) {
  AlwaysReturnType? mReturnType;

  DeclarationOrBridge<ClassMember, BridgeDeclaration>? dec0;
  final bool isStatic;
  TypeRef? staticType;

  ArgumentListResult argsPair;

  final knownMethod = getKnownMethods(ctx)[L.type]?[e.methodName.name];

  if (knownMethod != null &&
      L.type != CoreTypes.type.ref(ctx) &&
      L.type != CoreTypes.dynamic.ref(ctx)) {
    argsPair = compileArgumentListWithKnownMethodArgs(
      ctx,
      e.argumentList,
      knownMethod.args,
      knownMethod.namedArgs,
    );
    return L
        .invoke(
          ctx,
          e.methodName.name,
          argsPair.args,
          namedArgs: argsPair.namedArgs,
        )
        .result;
  }

  if (L.type == CoreTypes.type.ref(ctx) && L.concreteTypes.length == 1) {
    // Static method
    staticType = L.concreteTypes[0];
    dec0 = resolveStaticMethod(ctx, staticType, e.methodName.name);
    isStatic = true;
  } else if (L.type != CoreTypes.dynamic.ref(ctx)) {
    dec0 = resolveInstanceMethod(ctx, L.type, e.methodName.name, e);
    isStatic = false;
  } else {
    isStatic = false;
  }

  if (dec0?.isBridge == true) {
    final br = dec0!.bridge!;
    final fd = br is BridgeMethodDef
        ? br.functionDescriptor
        : (br as BridgeConstructorDef).functionDescriptor;
    argsPair = compileArgumentListWithBridge(
      ctx,
      e.argumentList,
      fd,
      before: [],
    );
  } else if (L.type == CoreTypes.dynamic.ref(ctx)) {
    argsPair = compileArgumentListWithDynamic(ctx, e.argumentList, before: [L]);
  } else {
    final dec = dec0!.declaration!;
    final fpl =
        (dec is MethodDeclaration
            ? dec.parameters?.parameters
            : (dec as ConstructorDeclaration).parameters.parameters) ??
        <FormalParameter>[];

    argsPair = compileArgumentList(
      ctx,
      e.argumentList,
      (isStatic ? staticType! : L.type).file,
      fpl,
      dec,
      before: [if (!isStatic) L],
      source: e,
    );
  }

  final args = argsPair.args;
  final namedArgs = argsPair.namedArgs;

  final argTypes = args.map((e) => e.type).toList();
  final namedArgTypes = namedArgs.map(
    (key, value) => MapEntry(key, value.type),
  );

  final result = ctx.svar('method_result');
  if (isStatic) {
    if (dec0!.isBridge) {
      ctx.pushOp(
        InvokeExternal(
          result,
          ctx.bridgeStaticFunctionIndices[staticType!
              .file]!['${staticType.name}.${e.methodName.name}']!,
          argsPair.ssa,
        ),
      );
    } else {
      final offset = DeferredOrOffset.lookupStatic(
        ctx,
        staticType!.file,
        staticType.name,
        e.methodName.name,
      );
      ctx.pushOp(Call(offset, argsPair.ssa, result: result));
    }
  } else if (L.concreteTypes.length == 1 &&
      dec0?.isBridge == false &&
      (e.target is SuperExpression ||
          (!_hasBridgeSuperclass(ctx, L.type) &&
              (ctx.instanceDeclarationPositions[L.concreteTypes.single.file]?[L
                              .concreteTypes
                              .single
                              .name]?[2]
                          as Map?)
                      ?.containsKey(e.methodName.name) ==
                  true))) {
    final actualType = L.concreteTypes[0];
    final offset = DeferredOrOffset(
      file: actualType.file,
      className: actualType.name,
      methodType: 2,
      name: e.methodName.name,
    );
    ctx.pushOp(Call(offset, argsPair.ssa, result: result));
  } else {
    ctx.pushOp(
      InvokeDynamic(
        result,
        L.boxIfNeeded(ctx).ssa,
        e.methodName.name,
        dec0?.isBridge == true ? argsPair.ssa : argsPair.ssa.skip(1).toList(),
      ),
    );
  }

  mReturnType = AlwaysReturnType.fromInstanceMethodOrBuiltin(
    ctx,
    isStatic ? staticType! : L.type,
    e.methodName.name,
    argTypes,
    namedArgTypes,
    $static: isStatic,
  );

  final v = Variable.of(
    ctx,
    result,
    mReturnType?.type?.copyWith(boxed: true) ?? CoreTypes.dynamic.ref(ctx),
  );

  return v;
}

bool _hasBridgeSuperclass(CompilerContext ctx, TypeRef type) {
  for (final parent in type.resolveTypeChain(ctx).extendsChain) {
    final bridge =
        ctx.topLevelDeclarationsMap[parent.file]?[parent.name]?.bridge;
    if (bridge is BridgeClassDef && bridge.bridge) return true;
  }
  return false;
}

DeclarationOrBridge<MethodDeclaration, BridgeMethodDef> resolveInstanceMethod(
  CompilerContext ctx,
  TypeRef instanceType,
  String methodName, [
  AstNode? source,
  TypeRef? bottomType,
]) {
  final dec0 =
      ctx.topLevelDeclarationsMap[instanceType.file]![instanceType.name]!;
  final bottomType0 = bottomType ?? instanceType;
  if (dec0.isBridge) {
    // Bridge
    final bridge = dec0.bridge!;
    final method = bridge is BridgeClassDef
        ? bridge.methods[methodName]
        : (bridge as BridgeEnumDef).methods[methodName];
    if (method == null) {
      final $extendsBridgeType = bridge is BridgeClassDef
          ? bridge.type.$extends
          : null;
      if ($extendsBridgeType == null && bridge is! BridgeEnumDef) {
        throw CompileError('Unknown method $bottomType0.$methodName', source);
      }
      final $extendsType = bridge is BridgeEnumDef
          ? CoreTypes.enumType.ref(ctx)
          : TypeRef.fromBridgeTypeRef(ctx, $extendsBridgeType!);
      return resolveInstanceMethod(
        ctx,
        $extendsType,
        methodName,
        source,
        bottomType0,
      );
    }
    return DeclarationOrBridge(instanceType.file, bridge: method);
  }

  final dec =
      ctx.instanceDeclarationsMap[instanceType.file]![instanceType
          .name]![methodName];

  if (dec != null) {
    return DeclarationOrBridge(
      instanceType.file,
      declaration: dec as MethodDeclaration,
    );
  } else {
    final $class = dec0.declaration as ClassDeclaration;
    if ($class.extendsClause == null) {
      return resolveInstanceMethod(
        ctx,
        CoreTypes.object.ref(ctx),
        methodName,
        source,
        bottomType0,
      );
    }
    final $supertype =
        ctx.visibleTypes[instanceType.file]![$class
            .extendsClause!
            .superclass
            .name
            .value()]!;
    return resolveInstanceMethod(
      ctx,
      $supertype,
      methodName,
      source,
      bottomType0,
    );
  }
}

DeclarationOrBridge<ClassMember, BridgeDeclaration> resolveStaticMethod(
  CompilerContext ctx,
  TypeRef classType,
  String methodName,
) {
  final method =
      ctx.topLevelDeclarationsMap[classType
          .file]!['${classType.name}.$methodName'];
  if (method != null) {
    if (method.declaration != null) {
      return DeclarationOrBridge(
        classType.file,
        declaration: method.declaration! as ClassMember,
      );
    } else {
      return DeclarationOrBridge(classType.file, bridge: method.bridge!);
    }
  }

  throw CompileError('Cannot find static method $classType.$methodName');
}
