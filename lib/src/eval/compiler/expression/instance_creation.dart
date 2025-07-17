import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/method_invocation.dart';
import 'package:dart_eval/src/eval/compiler/helpers/argument_list.dart';
import 'package:dart_eval/src/eval/compiler/offset_tracker.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

Variable compileInstanceCreation(
    CompilerContext ctx, InstanceCreationExpression e) {
  final type = e.constructorName.type;
  final name = type.importPrefix == null
      ? (e.constructorName.name?.name ?? '')
      : type.name2.lexeme;
  final typeName = type.importPrefix?.name.lexeme ?? type.name2.lexeme;
  final $resolved = IdentifierReference(null, typeName).getValue(ctx);

  if ($resolved.concreteTypes.isEmpty) {
    throw CompileError('Cannot create instance of a non-type $typeName');
  }

  final staticType = $resolved.concreteTypes.first;
  final _dec = resolveStaticMethod(ctx, staticType, name);

  //final List<Variable> _args;
  //final Map<String, Variable> _namedArgs;

  if (_dec.isBridge) {
    final bridge = _dec.bridge;
    final fnDescriptor = (bridge as BridgeConstructorDef).functionDescriptor;
    compileArgumentListWithBridge(ctx, e.argumentList, fnDescriptor);

    //_args = argsPair.first;
    //_namedArgs = argsPair.second;
  } else {
    final dec = _dec.declaration!;
    final fpl = (dec as ConstructorDeclaration).parameters.parameters;

    // Preparar tipos genéricos especializados baseado na herança
    final resolveGenerics = <String, TypeRef>{};

    // Verificar se há argumentos de tipo explícitos
    if (type.typeArguments != null) {
      final parentClass = dec.parent as ClassDeclaration;
      if (parentClass.typeParameters?.typeParameters != null) {
        final typeParams = parentClass.typeParameters!.typeParameters;
        final typeArgs = type.typeArguments!.arguments;

        for (var i = 0; i < typeParams.length && i < typeArgs.length; i++) {
          final param = typeParams[i];
          final arg = typeArgs[i];
          resolveGenerics[param.name.lexeme] =
              TypeRef.fromAnnotation(ctx, staticType.file, arg);
        }
      }
    }

    // Verificar tipos genéricos especializados baseado na herança
    final parentClass = dec.parent as ClassDeclaration;
    if (parentClass.extendsClause != null) {
      final extendsClause = parentClass.extendsClause!;
      final superclass = extendsClause.superclass;

      // Se a superclass tem argumentos de tipo (ex: CustomOrderItenModel<OrderModel>)
      if (superclass.typeArguments?.arguments != null) {
        try {
          // Obter os parâmetros genéricos da superclass
          final superclassName = superclass.name2.lexeme;
          final staticTypeFile = staticType.file;

          final topLevelDeclarations =
              ctx.topLevelDeclarationsMap[staticTypeFile];
          if (topLevelDeclarations != null) {
            final superclassDeclaration = topLevelDeclarations[superclassName];
            if (superclassDeclaration != null &&
                superclassDeclaration.declaration is ClassDeclaration) {
              final superclassClass =
                  superclassDeclaration.declaration as ClassDeclaration;

              final typeParams = superclassClass.typeParameters?.typeParameters;
              final typeArgs = superclass.typeArguments?.arguments;

              if (typeParams != null && typeArgs != null) {
                // Mapear cada parâmetro genérico para o tipo específico
                for (int i = 0;
                    i < typeParams.length && i < typeArgs.length;
                    i++) {
                  final paramName = typeParams[i].name.lexeme;
                  final argType =
                      TypeRef.fromAnnotation(ctx, ctx.library, typeArgs[i]);
                  resolveGenerics[paramName] = argType;
                }
              }
            }
          }
        } catch (e) {
          print('⚠️ Erro ao resolver tipos genéricos: $e');
        }
      }
    }

    if (resolveGenerics.isNotEmpty) {
      for (final entry in resolveGenerics.entries) {
        ctx.temporaryTypes[ctx.library] ??= {};
        ctx.temporaryTypes[ctx.library]![entry.key] = entry.value;
      }
    }

    compileArgumentList(ctx, e.argumentList, staticType.file, fpl, dec,
        source: e, resolveGenerics: resolveGenerics);
    //_args = argsPair.first;
    //_namedArgs = argsPair.second;
  }

  //final _argTypes = _args.map((e) => e.type).toList();
  //final _namedArgTypes = _namedArgs.map((key, value) => MapEntry(key, value.type));

  if (_dec.isBridge) {
    final bridge = _dec.bridge!;
    if (bridge is BridgeClassDef && !bridge.wrap) {
      final type = TypeRef.fromBridgeTypeRef(ctx, bridge.type.type);

      final $null = BuiltinValue().push(ctx);
      final op = BridgeInstantiate.make($null.scopeFrameOffset,
          ctx.bridgeStaticFunctionIndices[type.file]!['${type.name}.']!);
      ctx.pushOp(op, BridgeInstantiate.len(op));
    } else {
      final op = InvokeExternal.make(ctx.bridgeStaticFunctionIndices[
          staticType.file]!['${staticType.name}.$name']!);
      ctx.pushOp(op, InvokeExternal.LEN);
      ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);
    }
  } else {
    final offset = DeferredOrOffset.lookupStatic(
        ctx, staticType.file, staticType.name, name);
    final loc = ctx.pushOp(Call.make(offset.offset ?? -1), Call.length);
    if (offset.offset == null) {
      ctx.offsetTracker.setOffset(loc, offset);
    }
    ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);
  }

  // Processar argumentos de tipo genérico se presentes
  var returnType = $resolved.concreteTypes.first;
  if (type.typeArguments != null) {
    final typeArgs = <TypeRef>[];
    for (final arg in type.typeArguments!.arguments) {
      typeArgs.add(TypeRef.fromAnnotation(ctx, staticType.file, arg));
    }
    returnType = returnType.copyWith(specifiedTypeArgs: typeArgs);
  }

  return Variable.alloc(ctx, returnType.copyWith(boxed: true));
}
