import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/bridge/declaration.dart';
import 'package:dart_eval/src/eval/compiler/dispatch.dart';
import 'package:dart_eval/src/eval/compiler/expression/function.dart';
import 'package:dart_eval/src/eval/compiler/helpers/invoke.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/identifier.dart';
import 'package:dart_eval/src/eval/compiler/offset_tracker.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

/// A compile-time datum that can be - at the very least - converted to a [Variable] in the
/// future if needed. May also contain information about how to modify its value.
///
/// Using References can help prevent unnecessary bytecode generation, but be careful! Some Dart structures
/// may rely on side-effects from accessing a variable.
abstract class Reference {
  TypeRef resolveType(CompilerContext ctx,
      {bool forSet = false, AstNode? source});

  Variable setValue(CompilerContext ctx, Variable value, [AstNode? source]);

  Variable getValue(CompilerContext ctx, [AstNode? source]);

  StaticDispatch? getStaticDispatch(CompilerContext ctx, [AstNode? source]);
}

/// A [Reference] with a String identifier and optional target object. Accessing its value may, depending on state and
/// context: access a local variable, access an instance field/method, or access a global variable/top-level function.
class IdentifierReference implements Reference {
  IdentifierReference(this.object, this.name);

  Variable? object;
  final String name;

  @override
  TypeRef resolveType(CompilerContext ctx,
      {bool forSet = false, AstNode? source}) {
    if (object != null) {
      if (object!.type == CoreTypes.type.ref(ctx)) {
        return object!.concreteTypes[0].resolveTypeChain(ctx);
      }
      return TypeRef.lookupFieldType(ctx, object!.type, name,
              forSet: forSet, source: source) ??
          CoreTypes.dynamic.ref(ctx);
    }

    // Locals
    final local = ctx.lookupLocal(name);
    if (local != null) {
      return local.type;
    }

    // Instance
    if (ctx.currentClass != null) {
      final instanceDeclaration = resolveInstanceDeclaration(
          ctx, ctx.library, ctx.currentClass!.name.lexeme, name);
      if (instanceDeclaration != null) {
        final $type = instanceDeclaration.first;
        return TypeRef.lookupFieldType(ctx, $type, name, forSet: forSet) ??
            CoreTypes.dynamic.ref(ctx);
      }

      final staticDeclaration = resolveStaticDeclaration(
          ctx, ctx.library, ctx.currentClass!.name.lexeme, name);

      if (staticDeclaration != null && staticDeclaration.declaration != null) {
        final staticDec = staticDeclaration.declaration!;
        if (staticDec is MethodDeclaration) {
          return CoreTypes.function.ref(ctx);
        } else if (staticDec is VariableDeclaration) {
          final name =
              '${ctx.currentClass!.name.lexeme}.${staticDec.name.lexeme}';
          return ctx.topLevelVariableInferredTypes[ctx.library]![name]!;
        }
      }
    }

    final declaration = ctx.visibleDeclarations[ctx.library]![name] ??
        (throw CompileError('Could not find declaration "$name"', source));
    final declarationValue = declaration.declaration ?? (throw PrefixError());

    final decl = declarationValue.declaration!;

    if (decl is VariableDeclaration) {
      return ctx.topLevelVariableInferredTypes[declarationValue.sourceLib]![
          decl.name.lexeme]!;
    }

    return CoreTypes.type.ref(ctx);
  }

  @override
  Variable setValue(CompilerContext ctx, Variable value, [AstNode? source]) {
    if (object != null) {
      // If the object is a class name, access static fields
      if (object!.type == CoreTypes.type.ref(ctx)) {
        final classType = object!.concreteTypes[0].resolveTypeChain(ctx);
        final fqName = '${classType.name}.$name';
        final type =
            ctx.topLevelVariableInferredTypes[classType.file]![fqName]!;
        final gIndex = ctx.topLevelGlobalIndices[classType.file]![fqName]!;
        if (!value.type.isAssignableTo(ctx, type)) {
          throw CompileError(
              'Cannot assign value of type ${value.type} to field "$name" of type $type',
              source);
        }
        final formattedValue = type.boxed
            ? value.boxIfNeeded(ctx, source)
            : value.unboxIfNeeded(ctx);
        ctx.pushOp(SetGlobal.make(gIndex, formattedValue.scopeFrameOffset),
            SetGlobal.LEN);
        return formattedValue;
      }
      object = object!.boxIfNeeded(ctx, source);
      final fieldType = TypeRef.lookupFieldType(ctx, object!.type, name,
              forSet: true, source: source) ??
          CoreTypes.dynamic.ref(ctx);
      if (!value.type.resolveTypeChain(ctx).isAssignableTo(ctx, fieldType)) {
        throw CompileError(
            'Cannot assign value of type ${value.type} to field "$name" of type $fieldType',
            source);
      }
      final val = value.boxIfNeeded(ctx, source);
      final op = SetObjectProperty.make(
          object!.scopeFrameOffset, name, val.scopeFrameOffset);
      ctx.pushOp(op, SetObjectProperty.len(op));
      return val;
    }

    var local = ctx.lookupLocal(name);

    if (local != null) {
      if (local.isFinal && local.concreteTypes.isNotEmpty) {
        throw CompileError(
            'Cannot modify value of final variable $name', source);
      }

      ctx.pushOp(CopyValue.make(local.scopeFrameOffset, value.scopeFrameOffset),
          CopyValue.LEN);
      final type = TypeRef.commonBaseType(ctx, {local.type, value.type});
      local.copyWithUpdate(ctx,
          type: type.copyWith(boxed: value.type.boxed),
          concreteTypes: value.concreteTypes);
      return value;
    }

    // Instance
    if (ctx.currentClass != null) {
      final instanceDeclaration = resolveInstanceDeclaration(
          ctx, ctx.library, ctx.currentClass!.name.lexeme, name);
      if (instanceDeclaration != null) {
        final $type = instanceDeclaration.first;
        final fieldType = TypeRef.lookupFieldType(ctx, $type, name,
                forSet: true, source: source) ??
            CoreTypes.dynamic.ref(ctx);
        if (!value.type.resolveTypeChain(ctx).isAssignableTo(ctx, fieldType)) {
          throw CompileError(
              'Cannot assign value of type ${value.type} to field "$name" of type $fieldType',
              source);
        }
        final $this = ctx.lookupLocal('#this')!;
        final op = SetObjectProperty.make($this.scopeFrameOffset, name,
            value.boxIfNeeded(ctx, source).scopeFrameOffset);
        ctx.pushOp(op, SetObjectProperty.len(op));
        return value;
      }
    }

    final declaration = ctx.visibleDeclarations[ctx.library]![name] ??
        (throw CompileError('Could not find declaration "$name"', source));
    final declarationValue = declaration.declaration ?? (throw PrefixError());

    final decl = declarationValue.declaration!;

    if (decl is VariableDeclaration) {
      //final type = ctx
      //    .topLevelVariableInferredTypes[_decl.sourceLib]![decl.name.lexeme]!;
      final gIndex = ctx.topLevelGlobalIndices[declarationValue.sourceLib]![
          decl.name.lexeme]!;
      ctx.pushOp(SetGlobal.make(gIndex, value.scopeFrameOffset), SetGlobal.LEN);
      return value;
    }

    throw CompileError(
        'Cannot find value to set: ${object != null ? '${object!}.' : ''}$name',
        source);
  }

  String get _refName {
    final split = name.split('.');
    if (split.length > 2) {
      return split.sublist(1).join('.');
    }
    return name;
  }

  @override
  Variable getValue(CompilerContext ctx, [AstNode? source]) {
    if (object != null) {
      if (object!.type == CoreTypes.type.ref(ctx)) {
        final classType = object!.concreteTypes[0].resolveTypeChain(ctx);
        if (classType.extendsType == CoreTypes.enumType.ref(ctx)) {
          final type = classType;
          final gIndex =
              ctx.enumValueIndices[classType.file]?[type.name]?[name];
          if (gIndex != null) {
            ctx.pushOp(LoadGlobal.make(gIndex), LoadGlobal.LEN);
            ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);
            return Variable.alloc(ctx, type);
          }
        }
        final decOrBridge =
            ctx.topLevelDeclarationsMap[classType.file]![classType.name]!;
        if (decOrBridge.isBridge) {
          final br = decOrBridge.bridge;
          if (br is BridgeClassDef) {
            final getter = br.getters[name];
            if (getter != null) {
              final getterType = TypeRef.fromBridgeAnnotation(
                  ctx, getter.functionDescriptor.returns);
              ctx.pushOp(
                  InvokeExternal.make(ctx.bridgeStaticFunctionIndices[
                      classType.file]!['${classType.name}.$name*g']!),
                  InvokeExternal.LEN);
              ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);
              return Variable.alloc(ctx, getterType);
            }
            final field = br.fields[name];
            if (field != null) {
              final fieldType = TypeRef.fromBridgeAnnotation(ctx, field.type);
              ctx.pushOp(
                  InvokeExternal.make(ctx.bridgeStaticFunctionIndices[
                      classType.file]!['${classType.name}.$name*g']!),
                  InvokeExternal.LEN);
              ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);
              return Variable.alloc(ctx, fieldType);
            }

            throw CompileError(
                'Cannot find external getter or field: $name on $classType',
                source);
          }
        }
        final fqName = '${classType.name}.$name';
        final cls = ctx.topLevelVariableInferredTypes[classType.file];

        if (cls == null) {
          throw CompileError('Cannot find file types for "$classType"', source);
        }

        final type = cls[fqName];
        if (type == null) {
          throw CompileError(
              'Cannot resolve type of "$fqName" on "$classType"', source);
        }

        final gIndex = ctx.topLevelGlobalIndices[classType.file]![fqName]!;
        ctx.pushOp(LoadGlobal.make(gIndex), LoadGlobal.LEN);
        ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);
        return Variable.alloc(ctx, type);
      }
      object = object!.boxIfNeeded(ctx, source);
      return object!.getProperty(ctx, name);
    }

    // First look at locals
    final local = ctx.lookupLocal(name);
    if (local != null) {
      return local;
    }

    // Next, the instance (if available)
    if (ctx.currentClass != null) {
      final instanceDeclaration = resolveInstanceDeclaration(
          ctx, ctx.library, ctx.currentClass!.name.lexeme, name);
      if (instanceDeclaration != null) {
        final $type = instanceDeclaration.first;
        final decOrBridge = instanceDeclaration.second;

        final $this = ctx.lookupLocal('#this')!;

        if (!decOrBridge.isBridge) {
          final declaration = decOrBridge.declaration;
          if (declaration is MethodDeclaration &&
              !declaration.isGetter &&
              !declaration.isSetter) {
            return Variable(-1, CoreTypes.function.ref(ctx),
                methodOffset: DeferredOrOffset(
                    file: ctx.library,
                    className: ctx.currentClass!.name.lexeme,
                    name: _refName,
                    targetScopeFrameOffset: $this.scopeFrameOffset),
                callingConvention: CallingConvention.static);
          }
        }

        final op = PushObjectProperty.make(
            $this.scopeFrameOffset, ctx.constantPool.addOrGet(name));
        ctx.pushOp(op, PushObjectProperty.len(op));
        ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);

        if (decOrBridge.isBridge) {
          if (decOrBridge is GetSet) {
            final getter = decOrBridge.bridge ??
                (throw CompileError(
                    'Property "$name" has a setter but no getter, so it cannot be accessed',
                    source));
            return Variable.alloc(
                ctx,
                TypeRef.fromBridgeAnnotation(
                    ctx, getter.functionDescriptor.returns,
                    specifiedType: $type, specifyingType: $this.type),
                methodOffset: DeferredOrOffset(
                    file: ctx.library,
                    className: ctx.currentClass!.name.lexeme,
                    name: _refName));
          }
          final bridge = decOrBridge.bridge!;
          if (bridge is BridgeMethodDef) {
            return Variable.alloc(ctx, CoreTypes.function.ref(ctx),
                methodOffset: DeferredOrOffset(
                    file: ctx.library,
                    className: ctx.currentClass!.name.lexeme,
                    name: name));
          }
          if (bridge is BridgeFieldDef) {
            return Variable.alloc(
                ctx,
                TypeRef.fromBridgeAnnotation(ctx, bridge.type,
                    specifiedType: $type, specifyingType: $this.type),
                methodOffset: DeferredOrOffset(
                    file: ctx.library,
                    className: ctx.currentClass!.name.lexeme,
                    name: _refName));
          }
          throw CompileError(
              'Ref: cannot resolve bridge declaration "$name" of type ${decOrBridge.runtimeType}',
              source);
        }

        return Variable.alloc(
            ctx,
            TypeRef.lookupFieldType(ctx, $type, name, source: source) ??
                CoreTypes.dynamic.ref(ctx));
      }

      final staticDeclaration = resolveStaticDeclaration(
          ctx, ctx.library, ctx.currentClass!.name.lexeme, name);

      if (staticDeclaration != null && staticDeclaration.declaration != null) {
        final staticDec = staticDeclaration.declaration!;
        if (staticDec is MethodDeclaration) {
          return Variable(-1, CoreTypes.function.ref(ctx),
              methodOffset: DeferredOrOffset.lookupStatic(
                  ctx, ctx.library, ctx.currentClass!.name.lexeme, _refName));
        } else if (staticDec is VariableDeclaration) {
          final name =
              '${ctx.currentClass!.name.lexeme}.${staticDec.name.lexeme}';
          final type = ctx.topLevelVariableInferredTypes[ctx.library]![name]!;
          final gIndex = ctx.topLevelGlobalIndices[ctx.library]![name]!;
          ctx.pushOp(LoadGlobal.make(gIndex), LoadGlobal.LEN);
          ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);

          return Variable.alloc(ctx, type);
        }
      }
    }

    final declaration = ctx.visibleDeclarations[ctx.library]![name] ??
        ctx.visibleDeclarations[ctx.library]![name.split('.')[0]] ??
        (throw CompileError('Could not find declaration "$name"', source));

    final activeDec = declaration.declaration ??
        declaration.children?[name.split('.').sublist(1).join('.')] ??
        (throw PrefixError());

    return _declarationToVariable(activeDec, _refName, ctx, source);
  }

  @override
  StaticDispatch? getStaticDispatch(CompilerContext ctx, [AstNode? source]) {
    if (object != null) {
      if (object!.concreteTypes.length == 1) {
        // If we know the concrete type of the object, we can easily optimize to a static call
        final actualType = object!.concreteTypes[0];
        DeferredOrOffset offset;

        final returnType = AlwaysReturnType.fromInstanceMethod(
            ctx, actualType, name, CoreTypes.dynamic.ref(ctx));

        final methodsMap = ctx.instanceDeclarationPositions[actualType.file]![
            actualType.name]![2];
        if (methodsMap.containsKey(name)) {
          offset =
              DeferredOrOffset(file: actualType.file, offset: methodsMap[name]);
        } else {
          offset = DeferredOrOffset(
              file: actualType.file,
              className: actualType.name,
              methodType: 2,
              name: name);
        }

        return StaticDispatch(offset, returnType);
      }
      return null;
    }

    // First look at locals
    final local = ctx.lookupLocal(name);
    if (local != null) {
      if (local.methodOffset != null) {
        return StaticDispatch(local.methodOffset!, local.methodReturnType!);
      }
      return null;
    }

    // Next, the instance (if available)
    if (ctx.currentClass != null) {
      // No static dispatch because any method could be overridden in a subclass
      return null;
    }

    final declaration = ctx.visibleDeclarations[ctx.library]![name]!;
    final decOrBridge = declaration.declaration!;
    return _declarationToStaticDispatch(decOrBridge, name, ctx, source);
  }
}

/// A [Reference] with a prefixed String identifier, for accessing prefixed imports.
class PrefixedIdentifierReference implements Reference {
  final String prefix;
  final String identifier;

  const PrefixedIdentifierReference(this.prefix, this.identifier);

  @override
  StaticDispatch? getStaticDispatch(CompilerContext ctx, [AstNode? source]) {
    final dec = ctx.visibleDeclarations[ctx.library]![prefix] ??
        (throw CompileError('Cannot find prefix $prefix', source));
    if (dec.declaration != null) {
      throw CompileError('Cannot use a declaration as a prefix', source);
    }
    final children = dec.children!;
    return _declarationToStaticDispatch(
        children[identifier]!, identifier, ctx, source);
  }

  @override
  Variable getValue(CompilerContext ctx, [AstNode? source]) {
    final dec = ctx.visibleDeclarations[ctx.library]![prefix] ??
        (throw CompileError('Cannot find prefix $prefix', source));
    if (dec.declaration != null) {
      throw CompileError('Cannot use a declaration as a prefix', source);
    }
    final children = dec.children!;
    return _declarationToVariable(
        children[identifier]!, identifier, ctx, source);
  }

  @override
  TypeRef resolveType(CompilerContext ctx,
      {bool forSet = false, AstNode? source}) {
    return CoreTypes.type.ref(ctx);
  }

  @override
  Variable setValue(CompilerContext ctx, Variable value, [AstNode? source]) {
    throw CompileError('Cannot set value on prefixed identifier', source);
  }
}

/// A [Reference] with a variable that can be indexed into and a variable index. Accessing its value may use [IndexList]
/// [IndexMap] or [InvokeDynamic] depending on the state of the target variable.
class IndexedReference implements Reference {
  IndexedReference(this._variable, this._index);

  Variable _variable;
  Variable _index;

  @override
  TypeRef resolveType(CompilerContext ctx,
      {bool forSet = false, AstNode? source}) {
    if (_variable.type.isAssignableTo(ctx, CoreTypes.list.ref(ctx))) {
      return _variable.type.specifiedTypeArgs.isNotEmpty
          ? _variable.type.specifiedTypeArgs[0]
          : CoreTypes.dynamic.ref(ctx);
    }
    return getValue(ctx).type;
  }

  @override
  Variable getValue(CompilerContext ctx, [AstNode? source]) {
    _variable = _variable.updated(ctx);
    _index = _index.updated(ctx);

    if (_variable.type.isAssignableTo(ctx, CoreTypes.list.ref(ctx),
        forceAllowDynamic: false)) {
      if (!_index.type.isAssignableTo(ctx, CoreTypes.int.ref(ctx))) {
        throw CompileError(
            'TypeError: Cannot use variable of type ${_index.type} as list index');
      }

      final list = _variable.unboxIfNeeded(ctx);
      _index = _index.unboxIfNeeded(ctx);
      ctx.pushOp(IndexList.make(list.scopeFrameOffset, _index.scopeFrameOffset),
          IndexList.LEN);
      final listElementType = _variable.type.specifiedTypeArgs.isNotEmpty
          ? _variable.type.specifiedTypeArgs[0]
          : CoreTypes.dynamic.ref(ctx);
      return Variable.alloc(ctx, listElementType);
    }

    if (_variable.type.isAssignableTo(ctx, CoreTypes.map.ref(ctx),
        forceAllowDynamic: false)) {
      if (_variable.type.specifiedTypeArgs.isNotEmpty &&
          !_index.type
              .isAssignableTo(ctx, _variable.type.specifiedTypeArgs[0])) {
        throw CompileError(
            'TypeError: Cannot use variable of type ${_index.type} as index to map of type '
            '<${_variable.type.specifiedTypeArgs[0]}, ${_variable.type.specifiedTypeArgs[1]}>');
      }

      final map = _variable.unboxIfNeeded(ctx);
      _index = (_variable.type.specifiedTypeArgs.isEmpty ||
              _variable.type.specifiedTypeArgs[0].boxed)
          ? _index.boxIfNeeded(ctx, source)
          : _index.unboxIfNeeded(ctx);
      ctx.pushOp(IndexMap.make(map.scopeFrameOffset, _index.scopeFrameOffset),
          IndexMap.LEN);

      final mapResult = Variable.alloc(
          ctx,
          _variable.type.specifiedTypeArgs.length < 2
              ? CoreTypes.dynamic.ref(ctx)
              : _variable.type.specifiedTypeArgs[1]);

      if (_variable.type.specifiedTypeArgs.isEmpty ||
          _variable.type.specifiedTypeArgs[1].boxed) {
        ctx.pushOp(
            MaybeBoxNull.make(mapResult.scopeFrameOffset), MaybeBoxNull.LEN);
      }

      return mapResult;
    }

    final result = _variable.invoke(ctx, '[]', [_index]);
    _variable = result.target!;
    _index = result.args[0];

    return result.result;
  }

  @override
  Variable setValue(CompilerContext ctx, Variable value, [AstNode? source]) {
    _variable = _variable.updated(ctx);
    _index = _index.updated(ctx);

    if (_variable.type.isAssignableTo(ctx, CoreTypes.list.ref(ctx))) {
      if (!_index.type.isAssignableTo(ctx, CoreTypes.int.ref(ctx))) {
        throw CompileError(
            'TypeError: Cannot use variable of type ${_index.type} as list index',
            source);
      }

      final list = _variable.unboxIfNeeded(ctx);
      final elementType = list.type.specifiedTypeArgs[0];
      var formattedValue = value;
      if (elementType.boxed) {
        formattedValue = formattedValue.boxIfNeeded(ctx, source);
      } else {
        formattedValue = formattedValue.unboxIfNeeded(ctx);
      }
      ctx.pushOp(
          ListSetIndexed.make(list.scopeFrameOffset, _index.scopeFrameOffset,
              value.scopeFrameOffset),
          IndexList.LEN);
      return formattedValue;
    }

    final result = _variable.invoke(ctx, '[]=', [_index, value]);
    _variable = result.target!;
    _index = result.args[0];
    return result.args[1];
  }

  @override
  StaticDispatch? getStaticDispatch(CompilerContext ctx, [AstNode? source]) {
    return null;
  }
}

Variable _declarationToVariable(
    DeclarationOrBridge decOrBridge, String name, CompilerContext ctx,
    [AstNode? source]) {
  if (decOrBridge.isBridge) {
    final bridge = decOrBridge.bridge!;

    if (bridge is BridgeClassDef) {
      final type = TypeRef.fromBridgeTypeRef(ctx, bridge.type.type);

      return Variable(-1, CoreTypes.type.ref(ctx),
          concreteTypes: [type],
          methodOffset:
              DeferredOrOffset(file: type.file, name: '${type.name}.'),
          methodReturnType: AlwaysReturnType(type, false));
    }

    if (bridge is BridgeEnumDef) {
      final type = TypeRef.fromBridgeTypeRef(ctx, bridge.type);
      return Variable(-1, CoreTypes.type.ref(ctx),
          concreteTypes: [type],
          methodOffset:
              DeferredOrOffset(file: type.file, name: '${type.name}#wrap'),
          methodReturnType: AlwaysReturnType(type, false));
    }

    if (bridge is BridgeFunctionDeclaration) {
      final returnType =
          TypeRef.fromBridgeAnnotation(ctx, bridge.function.returns);
      return Variable(-1, CoreTypes.function.ref(ctx),
          methodReturnType: AlwaysReturnType(returnType, false),
          methodOffset:
              DeferredOrOffset(file: decOrBridge.sourceLib, name: name));
    }

    throw CompileError(
        'Cannot resolve bridged ${bridge.runtimeType} in reference', source);
  }

  final decl = decOrBridge.declaration!;

  if (decl is VariableDeclaration) {
    final type = ctx.topLevelVariableInferredTypes[decOrBridge.sourceLib]![
        decl.name.lexeme]!;
    final gIndex =
        ctx.topLevelGlobalIndices[decOrBridge.sourceLib]![decl.name.lexeme]!;
    ctx.pushOp(LoadGlobal.make(gIndex), LoadGlobal.LEN);
    ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);

    return Variable.alloc(ctx, type);
  }

  if (decl is! FunctionDeclaration && decl is! ConstructorDeclaration) {
    decl as NamedCompilationUnitMember;

    final returnType =
        TypeRef.lookupDeclaration(ctx, decOrBridge.sourceLib, decl);
    final DeferredOrOffset offset;

    if (ctx.topLevelDeclarationPositions[decOrBridge.sourceLib]
            ?.containsKey('$name.') ??
        false) {
      offset = DeferredOrOffset(
          file: decOrBridge.sourceLib,
          offset: ctx
              .topLevelDeclarationPositions[decOrBridge.sourceLib]!['$name.']);
    } else {
      offset = DeferredOrOffset(file: decOrBridge.sourceLib, name: '$name.');
    }

    return Variable(-1, CoreTypes.type.ref(ctx),
        concreteTypes: [returnType],
        methodOffset: offset,
        methodReturnType: AlwaysReturnType(returnType, false));
  }

  TypeRef? returnType;
  var nullable = true;
  if (decl is FunctionDeclaration && decl.returnType != null) {
    TypeRef.loadTemporaryTypes(
        ctx,
        decl.functionExpression.typeParameters?.typeParameters,
        decOrBridge.sourceLib);
    returnType =
        TypeRef.fromAnnotation(ctx, decOrBridge.sourceLib, decl.returnType!);
    nullable = decl.returnType!.question != null;
    ctx.temporaryTypes[ctx.library]?.clear();
  } else {
    returnType = TypeRef.lookupDeclaration(
        ctx, decOrBridge.sourceLib, decl.parent as ClassDeclaration);
  }

  final DeferredOrOffset offset;
  if (ctx.topLevelDeclarationsMap[decOrBridge.sourceLib]?.containsKey(name) ??
      false) {
    offset = DeferredOrOffset(file: decOrBridge.sourceLib, name: name);
  } else {
    final cls = decl.parent;
    String? className;
    if (cls is NamedCompilationUnitMember) {
      className = cls.name.lexeme;
    }
    offset = DeferredOrOffset(
        file: decOrBridge.sourceLib, name: name, className: className);
  }

  final fn = Variable(
      -1,
      decl is FunctionDeclaration
          ? CoreTypes.function.ref(ctx)
          : CoreTypes.type.ref(ctx),
      concreteTypes: [returnType],
      methodOffset: offset,
      methodReturnType: AlwaysReturnType(returnType, nullable));

  if (decl is FunctionDeclaration && decl.isGetter) {
    return fn.invoke(ctx, null, []).result;
  }
  return fn;
}

StaticDispatch? _declarationToStaticDispatch(
    DeclarationOrBridge decOrBridge, String name, CompilerContext ctx,
    [AstNode? source]) {
  if (decOrBridge.isBridge) {
    // No static dispatch for bridge
    return null;
  }

  final decl = decOrBridge.declaration!;

  if (decl is! FunctionDeclaration && decl is! ConstructorDeclaration) {
    decl as ClassDeclaration;

    final DeferredOrOffset offset;

    if (ctx.topLevelDeclarationPositions[decOrBridge.sourceLib]
            ?.containsKey('$name.') ??
        false) {
      offset = DeferredOrOffset(
          file: decOrBridge.sourceLib,
          offset: ctx
              .topLevelDeclarationPositions[decOrBridge.sourceLib]!['$name.']);
    } else {
      offset = DeferredOrOffset(file: decOrBridge.sourceLib, name: '$name.');
    }

    final rt = AlwaysReturnType(
        TypeRef.lookupDeclaration(ctx, decOrBridge.sourceLib, decl), false);

    return StaticDispatch(offset, rt);
  }

  TypeRef? returnType;
  var nullable = true;
  if (decl is FunctionDeclaration && decl.returnType != null) {
    returnType =
        TypeRef.fromAnnotation(ctx, decOrBridge.sourceLib, decl.returnType!);
    nullable = decl.returnType!.question != null;
  } else {
    returnType = TypeRef.lookupDeclaration(
        ctx, decOrBridge.sourceLib, decl.parent as ClassDeclaration);
  }

  final DeferredOrOffset offset;
  if (ctx.topLevelDeclarationPositions[decOrBridge.sourceLib]
          ?.containsKey(name) ??
      false) {
    offset = DeferredOrOffset(
        file: decOrBridge.sourceLib,
        offset: ctx.topLevelDeclarationPositions[ctx.library]![name]);
  } else {
    offset = DeferredOrOffset(file: decOrBridge.sourceLib, name: name);
  }

  return StaticDispatch(offset, AlwaysReturnType(returnType, nullable));
}
