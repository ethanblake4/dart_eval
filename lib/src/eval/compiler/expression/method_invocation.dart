import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/funcexpr_invocation.dart';
import 'package:dart_eval/src/eval/compiler/expression/function.dart';
import 'package:dart_eval/src/eval/compiler/helpers/argument_list.dart';
import 'package:dart_eval/src/eval/compiler/helpers/equality.dart';
import 'package:dart_eval/src/eval/compiler/macros/branch.dart';
import 'package:dart_eval/src/eval/compiler/offset_tracker.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/bridge/declaration.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

import '../util.dart';
import 'expression.dart';
import 'identifier.dart';

Variable compileMethodInvocation(CompilerContext ctx, MethodInvocation e,
    {TypeRef? bound, Variable? cascadeTarget}) {
  Variable? L = cascadeTarget;
  var isPrefix = false;
  if (e.target != null && cascadeTarget == null) {
    try {
      L = compileExpression(e.target!, ctx);
    } on PrefixError {
      isPrefix = true;
    }
  }

  AlwaysReturnType? mReturnType;

  if (L != null) {
    if (e.operator?.type == TokenType.QUESTION_PERIOD) {
      var out = BuiltinValue().push(ctx).boxIfNeeded(ctx);
      if (L.concreteTypes.length == 1 &&
          L.concreteTypes[0] == CoreTypes.nullType.ref(ctx)) {
        return out;
      }
      macroBranch(ctx, null, condition: (_ctx) {
        return checkNotEqual(ctx, L!, out);
      }, thenBranch: (_ctx, rt) {
        final V = _invokeWithTarget(ctx, L!, e);
        out = out.copyWith(type: V.type.copyWith(nullable: true));
        ctx.pushOp(CopyValue.make(out.scopeFrameOffset, V.scopeFrameOffset),
            CopyValue.LEN);
        return StatementInfo(-1);
      });
      return out;
    }
    return _invokeWithTarget(ctx, L, e);
  }
  final method = isPrefix
      ? compilePrefixedIdentifier(
          (e.target as Identifier).name, e.methodName.name, ctx)
      : compileIdentifier(e.methodName, ctx);

  if (method.callingConvention == CallingConvention.dynamic ||
      (method.type == CoreTypes.function.ref(ctx) &&
          method.methodOffset == null)) {
    return invokeClosure(ctx, null, method, e.argumentList);
  }

  if (method.methodOffset == null) {
    throw CompileError(
        'Cannot call ${e.methodName.name} as it is not a valid method');
  }

  final offset = method.methodOffset!;
  if (offset.file == ctx.library &&
      offset.className != null &&
      offset.className == (ctx.currentClass?.name.lexeme)) {
    final $this = ctx.lookupLocal('#this')!;
    return _invokeWithTarget(ctx, $this, e);
  }

  var _dec = ctx.topLevelDeclarationsMap[offset.file]![e.methodName.name];
  if (_dec == null ||
      (!_dec.isBridge && _dec.declaration! is ClassDeclaration)) {
    _dec = ctx.topLevelDeclarationsMap[offset.file]![
        offset.name ?? '${e.methodName.name}.'];
    if (_dec == null) {
      // Call to default constructor
      final loc = ctx.pushOp(Call.make(offset.offset ?? -1), Call.length);
      if (offset.offset == null) {
        ctx.offsetTracker.setOffset(loc, offset);
      }
      ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);
      mReturnType = method.methodReturnType
              ?.toAlwaysReturnType(ctx, TypeRef.$this(ctx), [], {}) ??
          AlwaysReturnType(CoreTypes.dynamic.ref(ctx), true);
      final _returnType = mReturnType.type?.copyWith(
          boxed: L != null ||
              !(mReturnType.type?.isUnboxedAcrossFunctionBoundaries ?? false));
      final v = Variable.alloc(
          ctx,
          mReturnType.type?.copyWith(
                  boxed: L != null ||
                      !(mReturnType.type?.isUnboxedAcrossFunctionBoundaries ??
                          false)) ??
              CoreTypes.dynamic.ref(ctx),
          concreteTypes: _returnType == null ? [] : [_returnType]);

      return v;
    }
  }

  final List<Variable> _args;
  final Map<String, Variable> _namedArgs;

  final resolveGenerics = <String, TypeRef>{};
  var isConstructor = false;

  if (_dec.isBridge) {
    final bridge = _dec.bridge;

    /// If we're invoking a class identifier directly (like ClassName()), call
    /// its default constructor
    final fnDescriptor = bridge is BridgeClassDef
        ? (bridge.constructors['']?.functionDescriptor ??
            (throw CompileError(
                'Class "${e.methodName.name}" does not have a default constructor',
                e)))
        : (bridge as BridgeFunctionDeclaration).function;

    final argsPair = compileArgumentListWithBridge(
        ctx, e.argumentList, fnDescriptor,
        before: L != null ? [L] : []);

    _args = argsPair.first;
    _namedArgs = argsPair.second;
    isConstructor = bridge is BridgeClassDef;
  } else {
    final dec = _dec.declaration!;

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
      // Para construtores, os tipos genéricos vêm da classe pai
      final parentClass = dec.parent as ClassDeclaration;
      typeParams = parentClass.typeParameters?.typeParameters;

      // Detectar herança genérica se a classe não tem typeParameters próprios
      if (typeParams == null || typeParams.isEmpty) {
        if (parentClass.extendsClause != null) {
          final extendsClause = parentClass.extendsClause!;
          final superclass = extendsClause.superclass;

          // Se a superclass tem argumentos de tipo (ex: CustomOrderItenModel<BudgetModel>)
          if (superclass.typeArguments?.arguments != null) {
            try {
              // Obter os parâmetros genéricos da superclass
              final superclassDeclaration = ctx.topLevelDeclarationsMap[
                  offset.file!]![superclass.name2!.lexeme]!;
              if (superclassDeclaration.declaration is ClassDeclaration) {
                final superclassClass =
                    superclassDeclaration.declaration as ClassDeclaration;

                if (superclassClass.typeParameters?.typeParameters != null) {
                  final superTypeParams =
                      superclassClass.typeParameters!.typeParameters;
                  final typeArgs = superclass.typeArguments!.arguments;

                  // Mapear cada parâmetro genérico para o tipo específico
                  for (int i = 0;
                      i < superTypeParams.length && i < typeArgs.length;
                      i++) {
                    final paramName = superTypeParams[i].name.lexeme;
                    final argType =
                        TypeRef.fromAnnotation(ctx, offset.file!, typeArgs[i]);
                    resolveGenerics[paramName] = argType;
                  }
                }
              }
            } catch (e) {
              print(
                  '⚠️ Erro ao resolver tipos genéricos em method_invocation: $e');
            }
          }
        }
      }
    } else {
      throw CompileError('Invalid declaration type ${dec.runtimeType}');
    }

    // Adicionar resolveGenerics aos temporaryTypes para que estejam disponíveis
    if (resolveGenerics.isNotEmpty) {
      for (final entry in resolveGenerics.entries) {
        ctx.temporaryTypes[offset.file!] ??= {};
        ctx.temporaryTypes[offset.file!]![entry.key] = entry.value;
        ctx.temporaryTypes[ctx.library] ??= {};
        ctx.temporaryTypes[ctx.library]![entry.key] = entry.value;
      }
    }

    if (typeParams != null) {
      // Se há argumentos de tipo especificados na chamada (como <int, double>)
      if (e.typeArguments != null) {
        final typeArgs = e.typeArguments!.arguments;
        for (var i = 0; i < typeParams.length && i < typeArgs.length; i++) {
          final param = typeParams[i];
          final name = param.name.lexeme;
          final typeArg = typeArgs[i];
          resolveGenerics[name] =
              TypeRef.fromAnnotation(ctx, offset.file!, typeArg);
        }
      } else {
        // Caso não haja argumentos de tipo especificados, usa bounds ou dynamic
        for (final param in typeParams) {
          final bound = param.bound;
          final name = param.name.lexeme;
          if (bound != null) {
            resolveGenerics[name] =
                TypeRef.fromAnnotation(ctx, offset.file!, bound);
          } else {
            resolveGenerics[name] = CoreTypes.dynamic.ref(ctx);
          }
        }
      }
    }

    final argsPair = compileArgumentList(
        ctx, e.argumentList, offset.file!, fpl, dec,
        before: L != null ? [L] : [],
        source: e,
        resolveGenerics: resolveGenerics);

    if (returnAnnotation != null && returnAnnotation is NamedType) {
      final g = resolveGenerics[returnAnnotation.name2.value()];
      if (g != null) {
        mReturnType = AlwaysReturnType(g, returnAnnotation.question != null);
      }
    }
    _args = argsPair.first;
    _namedArgs = argsPair.second;
  }

  final _argTypes = _args.map((e) => e.type).toList();
  final _namedArgTypes =
      _namedArgs.map((key, value) => MapEntry(key, value.type));

  if (_dec.isBridge) {
    final bridge = _dec.bridge!;
    if (bridge is BridgeClassDef && !bridge.wrap) {
      final type = TypeRef.fromBridgeTypeRef(ctx, bridge.type.type);

      final $null = BuiltinValue().push(ctx);
      final op = BridgeInstantiate.make($null.scopeFrameOffset,
          ctx.bridgeStaticFunctionIndices[type.file]!['${type.name}.']!);
      ctx.pushOp(op, BridgeInstantiate.len(op));
    } else {
      final op = InvokeExternal.make(
          ctx.bridgeStaticFunctionIndices[offset.file]![offset.name]!);
      ctx.pushOp(op, InvokeExternal.LEN);
      ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);
    }
  } else {
    final loc = ctx.pushOp(Call.make(offset.offset ?? -1), Call.length);
    if (offset.offset == null) {
      ctx.offsetTracker.setOffset(loc, offset);
    }
    ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);
  }

  TypeRef? thisType;
  if (ctx.currentClass != null) {
    thisType = ctx.visibleTypes[ctx.library]![ctx.currentClass!.name.lexeme]!;
  }

  // Para construtores, aplicar os tipos genéricos resolvidos
  if (isConstructor && resolveGenerics.isNotEmpty) {
    final constructorType = ctx.visibleTypes[offset.file]![e.methodName.name];
    if (constructorType != null) {
      final typeArgs = <TypeRef>[];

      // Buscar os parâmetros genéricos da classe
      final classDecl = ctx.topLevelDeclarationsMap[constructorType.file]![
          constructorType.name]!;
      if (classDecl.declaration is ClassDeclaration) {
        final classDeclaration = classDecl.declaration as ClassDeclaration;
        if (classDeclaration.typeParameters?.typeParameters != null) {
          for (final param in classDeclaration.typeParameters!.typeParameters) {
            final resolvedType = resolveGenerics[param.name.lexeme];
            if (resolvedType != null) {
              typeArgs.add(resolvedType);
            }
          }
        }
      }

      if (typeArgs.isNotEmpty) {
        mReturnType = AlwaysReturnType(
            constructorType.copyWith(specifiedTypeArgs: typeArgs), false);
      }
    }
  }

  mReturnType ??= method.methodReturnType
          ?.toAlwaysReturnType(ctx, thisType, _argTypes, _namedArgTypes) ??
      AlwaysReturnType(CoreTypes.dynamic.ref(ctx), true);
  final _returnType = mReturnType.type?.copyWith(
      boxed: _dec.isBridge ||
          !(mReturnType.type?.isUnboxedAcrossFunctionBoundaries ?? false));

  final v = Variable.alloc(ctx, _returnType ?? CoreTypes.dynamic.ref(ctx),
      concreteTypes: [if (isConstructor && _returnType != null) _returnType]);

  return v;
}

Variable _invokeWithTarget(
    CompilerContext ctx, Variable L, MethodInvocation e) {
  AlwaysReturnType? mReturnType;

  final DeclarationOrBridge<ClassMember, BridgeDeclaration> _dec;
  final bool isStatic;
  TypeRef? staticType;

  Pair<List<Variable>, Map<String, Variable>> argsPair;

  final knownMethod = getKnownMethods(ctx)[L.type]?[e.methodName.name];

  if (knownMethod != null &&
      L.type != CoreTypes.type.ref(ctx) &&
      L.type != CoreTypes.dynamic.ref(ctx)) {
    argsPair = compileArgumentListWithKnownMethodArgs(
        ctx, e.argumentList, knownMethod.args, knownMethod.namedArgs);
    return L.invoke(ctx, e.methodName.name, []).result;
  }

  if (L.type == CoreTypes.type.ref(ctx) && L.concreteTypes.length == 1) {
    // Static method
    staticType = L.concreteTypes[0];
    _dec = resolveStaticMethod(ctx, staticType, e.methodName.name);
    isStatic = true;
  } else {
    _dec = resolveInstanceMethod(ctx, L.type, e.methodName.name, e);
    isStatic = false;
  }

  if (_dec.isBridge) {
    final br = _dec.bridge!;
    final fd = br is BridgeMethodDef
        ? br.functionDescriptor
        : (br as BridgeConstructorDef).functionDescriptor;
    argsPair =
        compileArgumentListWithBridge(ctx, e.argumentList, fd, before: []);
  } else {
    final dec = _dec.declaration!;
    final fpl = (dec is MethodDeclaration
            ? dec.parameters?.parameters
            : (dec as ConstructorDeclaration).parameters.parameters) ??
        <FormalParameter>[];

    // Processar argumentos de tipo genérico se existirem
    final resolveGenerics = <String, TypeRef>{};
    if (dec is MethodDeclaration) {
      final typeParams = dec.typeParameters?.typeParameters;
      if (typeParams != null) {
        if (e.typeArguments != null) {
          final typeArgs = e.typeArguments!.arguments;
          for (var i = 0; i < typeParams.length && i < typeArgs.length; i++) {
            final param = typeParams[i];
            final name = param.name.lexeme;
            final typeArg = typeArgs[i];
            resolveGenerics[name] = TypeRef.fromAnnotation(
                ctx, (isStatic ? staticType! : L.type).file, typeArg);
          }
        } else {
          // Caso não haja argumentos de tipo especificados, usa bounds ou dynamic
          for (final param in typeParams) {
            final bound = param.bound;
            final name = param.name.lexeme;
            if (bound != null) {
              resolveGenerics[name] = TypeRef.fromAnnotation(
                  ctx, (isStatic ? staticType! : L.type).file, bound);
            } else {
              resolveGenerics[name] = CoreTypes.dynamic.ref(ctx);
            }
          }
        }
      }
    }

    argsPair = compileArgumentList(
        ctx, e.argumentList, (isStatic ? staticType! : L.type).file, fpl, dec,
        before: [if (!isStatic) L],
        source: e,
        resolveGenerics: resolveGenerics);
  }

  final _args = argsPair.first;
  final _namedArgs = argsPair.second;

  final _argTypes = _args.map((e) => e.type).toList();
  final _namedArgTypes =
      _namedArgs.map((key, value) => MapEntry(key, value.type));

  if (isStatic) {
    if (_dec.isBridge) {
      final ix = InvokeExternal.make(ctx.bridgeStaticFunctionIndices[
          staticType!.file]!['${staticType.name}.${e.methodName.name}']!);
      ctx.pushOp(ix, InvokeExternal.LEN);
    } else {
      final offset = DeferredOrOffset.lookupStatic(
          ctx, staticType!.file, staticType.name, e.methodName.name);
      final loc = ctx.pushOp(Call.make(offset.offset ?? -1), Call.length);
      if (offset.offset == null) {
        ctx.offsetTracker.setOffset(loc, offset);
      }
    }
  } else if (L.concreteTypes.length == 1 && !_dec.isBridge) {
    // If the concrete type is known we can use a static call
    final actualType = L.concreteTypes[0];
    final offset = DeferredOrOffset(
        file: actualType.file,
        className: actualType.name,
        methodType: 2,
        name: e.methodName.name);
    final loc = ctx.pushOp(Call.make(-1), Call.length);
    ctx.offsetTracker.setOffset(loc, offset);
  } else {
    final op = InvokeDynamic.make(L.boxIfNeeded(ctx).scopeFrameOffset,
        ctx.constantPool.addOrGet(e.methodName.name));
    ctx.pushOp(op, InvokeDynamic.len(op));
  }

  mReturnType = AlwaysReturnType.fromInstanceMethodOrBuiltin(
      ctx,
      isStatic ? staticType! : L.type,
      e.methodName.name,
      _argTypes,
      _namedArgTypes,
      $static: isStatic);

  ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);

  final v = Variable.alloc(ctx,
      mReturnType?.type?.copyWith(boxed: true) ?? CoreTypes.dynamic.ref(ctx));

  return v;
}

DeclarationOrBridge<MethodDeclaration, BridgeMethodDef> resolveInstanceMethod(
    CompilerContext ctx, TypeRef instanceType, String methodName,
    [AstNode? source, TypeRef? bottomType]) {
  final _dec =
      ctx.topLevelDeclarationsMap[instanceType.file]![instanceType.name]!;
  final _bottomType = bottomType ?? instanceType;
  if (_dec.isBridge) {
    // Bridge
    final bridge = _dec.bridge!;
    final method = bridge is BridgeClassDef
        ? bridge.methods[methodName]
        : (bridge as BridgeEnumDef).methods[methodName];
    if (method == null) {
      final $extendsBridgeType =
          bridge is BridgeClassDef ? bridge.type.$extends : null;
      if ($extendsBridgeType == null && bridge is! BridgeEnumDef) {
        throw CompileError('Unknown method $_bottomType.$methodName', source);
      }
      final $extendsType = bridge is BridgeEnumDef
          ? CoreTypes.enumType.ref(ctx)
          : TypeRef.fromBridgeTypeRef(ctx, $extendsBridgeType!);
      return resolveInstanceMethod(
          ctx, $extendsType, methodName, source, _bottomType);
    }
    return DeclarationOrBridge(instanceType.file, bridge: method);
  }

  final dec = ctx.instanceDeclarationsMap[instanceType.file]![
      instanceType.name]![methodName];

  if (dec != null) {
    return DeclarationOrBridge(instanceType.file,
        declaration: dec as MethodDeclaration);
  } else {
    final $class = _dec.declaration as ClassDeclaration;
    if ($class.extendsClause == null) {
      return resolveInstanceMethod(
          ctx, CoreTypes.object.ref(ctx), methodName, source, _bottomType);
    }
    final $supertype = ctx.visibleTypes[instanceType.file]![
        $class.extendsClause!.superclass.name2.value()]!;
    return resolveInstanceMethod(
        ctx, $supertype, methodName, source, _bottomType);
  }
}

DeclarationOrBridge<ClassMember, BridgeDeclaration> resolveStaticMethod(
    CompilerContext ctx, TypeRef classType, String methodName) {
  final method = ctx.topLevelDeclarationsMap[classType.file]![
      '${classType.name}.$methodName'];
  if (method != null) {
    if (method.declaration != null) {
      return DeclarationOrBridge(classType.file,
          declaration: method.declaration! as ClassMember);
    } else {
      return DeclarationOrBridge(classType.file, bridge: method.bridge!);
    }
  }

  throw CompileError('Cannot find static method $classType.$methodName');
}
