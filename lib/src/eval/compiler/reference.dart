import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/dispatch.dart';
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
  TypeRef resolveType(CompilerContext ctx);

  void setValue(CompilerContext ctx, Variable value);

  Variable getValue(CompilerContext ctx);

  StaticDispatch? getStaticDispatch(CompilerContext ctx);
}

/// A [Reference] with a String identifier and optional target object. Accessing its value may, depending on state and
/// context: access a local variable, access an instance field/method, or access a global variable/top-level function.
class IdentifierReference implements Reference {
  IdentifierReference(this.object, this.name);

  Variable? object;
  final String name;

  @override
  TypeRef resolveType(CompilerContext ctx) {
    if (object != null) {
      return TypeRef.lookupFieldType(ctx, object!.type, name) ?? EvalTypes.dynamicType;
    }

    // Locals
    final local = ctx.lookupLocal(name);
    if (local != null) {
      return local.type;
    }

    // Instance
    if (ctx.currentClass != null) {
      final instanceDeclaration =
          resolveInstanceDeclaration(ctx, ctx.library, ctx.currentClass!.name2.value() as String, name);
      if (instanceDeclaration != null) {
        final $type = instanceDeclaration.first;
        return TypeRef.lookupFieldType(ctx, $type, name) ?? EvalTypes.dynamicType;
      }
    }

    //final declaration = ctx.visibleDeclarations[ctx.library]![name]!;
    //final decl = declaration.declaration!;

    // TODO
    return EvalTypes.typeType;
  }

  @override
  void setValue(CompilerContext ctx, Variable value) {
    if (object != null) {
      object = object!.boxIfNeeded(ctx);
      final fieldType = TypeRef.lookupFieldType(ctx, object!.type, name) ?? EvalTypes.dynamicType;
      if (!value.type.resolveTypeChain(ctx).isAssignableTo(ctx, fieldType)) {
        throw CompileError('Cannot assign value of type ${value.type} to field "$name" of type $fieldType');
      }
      final op = SetObjectProperty.make(object!.scopeFrameOffset, name, value.boxIfNeeded(ctx).scopeFrameOffset);
      ctx.pushOp(op, SetObjectProperty.len(op));
      return;
    }

    var local = ctx.lookupLocal(name);

    if (local != null) {
      if (local.isFinal && local.concreteTypes.isNotEmpty) {
        throw CompileError('Cannot change value of a final variable');
      }

      ctx.pushOp(CopyValue.make(local.scopeFrameOffset, value.scopeFrameOffset), CopyValue.LEN);
      return;
    }

    // Instance
    if (ctx.currentClass != null) {
      final instanceDeclaration =
          resolveInstanceDeclaration(ctx, ctx.library, ctx.currentClass!.name2.value() as String, name);
      if (instanceDeclaration != null) {
        final $type = instanceDeclaration.first;
        final fieldType = TypeRef.lookupFieldType(ctx, $type, name) ?? EvalTypes.dynamicType;
        if (!value.type.resolveTypeChain(ctx).isAssignableTo(ctx, fieldType)) {
          throw CompileError('Cannot assign value of type ${value.type} to field "$name" of type $fieldType');
        }
        final $this = ctx.lookupLocal('#this')!;
        final op = SetObjectProperty.make($this.scopeFrameOffset, name, value.boxIfNeeded(ctx).scopeFrameOffset);
        ctx.pushOp(op, SetObjectProperty.len(op));
        return;
      }
    }

    throw CompileError('Cannot find value to set: ${object != null ? object!.toString() + '.' : ''}$name');
  }

  @override
  Variable getValue(CompilerContext ctx) {
    if (object != null) {
      if (object!.type == EvalTypes.typeType) {
        final classType = object!.concreteTypes[0].resolveTypeChain(ctx);
        if (classType.extendsType == EvalTypes.enumType) {
          final type = classType;
          final gIndex = ctx.enumValueIndices[classType.file]![type.name]![name]!;
          ctx.pushOp(LoadGlobal.make(gIndex), LoadGlobal.LEN);
          ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);
          return Variable.alloc(ctx, type);
        }
        final _dec = ctx.topLevelDeclarationsMap[classType.file]![classType.name]!;
        if (_dec.isBridge) {
          final br = _dec.bridge;
          if (br is BridgeClassDef) {
            final getter = br.getters[name];
            if (getter != null) {
              final getterType = TypeRef.fromBridgeAnnotation(ctx, getter.functionDescriptor.returns);
              ctx.pushOp(
                  InvokeExternal.make(ctx.bridgeStaticFunctionIndices[classType.file]!['${classType.name}.$name*g']!),
                  InvokeExternal.LEN);
              ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);
              return Variable.alloc(ctx, getterType);
            }
            final field = br.fields[name];
            if (field != null) {
              final fieldType = TypeRef.fromBridgeAnnotation(ctx, field.type);
              ctx.pushOp(
                  InvokeExternal.make(ctx.bridgeStaticFunctionIndices[classType.file]!['${classType.name}.$name*g']!),
                  InvokeExternal.LEN);
              ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);
              return Variable.alloc(ctx, fieldType);
            }

            throw CompileError('Cannot find external getter or field: $name on ${classType}');
          }
        }
        final _name = classType.name + '.' + name;
        final type = ctx.topLevelVariableInferredTypes[classType.file]![_name]!;
        final gIndex = ctx.topLevelGlobalIndices[classType.file]![_name]!;
        ctx.pushOp(LoadGlobal.make(gIndex), LoadGlobal.LEN);
        ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);
        return Variable.alloc(ctx, type);
      }
      object = object!.boxIfNeeded(ctx);
      final op = PushObjectProperty.make(object!.scopeFrameOffset, name);
      ctx.pushOp(op, PushObjectProperty.len(op));
      ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);
      return Variable.alloc(
          ctx, TypeRef.lookupFieldType(ctx, object!.type, name)?.copyWith(boxed: true) ?? EvalTypes.dynamicType);
    }

    // First look at locals
    final local = ctx.lookupLocal(name);
    if (local != null) {
      return local;
    }

    // Next, the instance (if available)
    if (ctx.currentClass != null) {
      final instanceDeclaration =
          resolveInstanceDeclaration(ctx, ctx.library, ctx.currentClass!.name2.value() as String, name);
      if (instanceDeclaration != null) {
        final $type = instanceDeclaration.first;

        final $this = ctx.lookupLocal('#this')!;

        final op = PushObjectProperty.make($this.scopeFrameOffset, name);
        ctx.pushOp(op, PushObjectProperty.len(op));
        ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);

        final _dec = instanceDeclaration.second;
        if (_dec.isBridge) {
          final bridge = _dec.bridge!;
          if (bridge is BridgeMethodDef) {
            return Variable.alloc(ctx, EvalTypes.functionType,
                methodOffset: DeferredOrOffset(
                    file: ctx.library, className: ctx.currentClass!.name2.value() as String, name: name));
          } else if (bridge is BridgeGetSet) {
            final getter = bridge.getter ??
                (throw CompileError('Property "$name" has a setter but no getter, so it cannot be accessed'));
            return Variable.alloc(
                ctx,
                TypeRef.fromBridgeAnnotation(ctx, getter.functionDescriptor.returns,
                    specifiedType: $type, specifyingType: $this.type),
                methodOffset: DeferredOrOffset(
                    file: ctx.library, className: ctx.currentClass!.name2.value() as String, name: name));
          }
          throw CompileError('Ref: cannot resolve bridge declaration "$name" of type ${_dec.runtimeType}');
        }

        return Variable.alloc(ctx, TypeRef.lookupFieldType(ctx, $type, name) ?? EvalTypes.dynamicType);
      }

      final staticDeclaration =
          resolveStaticDeclaration(ctx, ctx.library, ctx.currentClass!.name2.value() as String, name);

      if (staticDeclaration != null && staticDeclaration.declaration != null) {
        final _dec = staticDeclaration.declaration!;
        if (_dec is MethodDeclaration) {
          return Variable(-1, EvalTypes.functionType,
              methodOffset:
                  DeferredOrOffset.lookupStatic(ctx, ctx.library, ctx.currentClass!.name2.value() as String, name));
        } else if (_dec is VariableDeclaration) {
          final name = (ctx.currentClass!.name2.value() as String) + '.' + (_dec.name2.value() as String);
          final type = ctx.topLevelVariableInferredTypes[ctx.library]![name]!;
          final gIndex = ctx.topLevelGlobalIndices[ctx.library]![name]!;
          ctx.pushOp(LoadGlobal.make(gIndex), LoadGlobal.LEN);
          ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);

          return Variable.alloc(ctx, type);
        }
      }
    }

    final declaration =
        ctx.visibleDeclarations[ctx.library]![name] ?? (throw CompileError('Could not find declaration "$name"'));
    final _decl = declaration.declaration!;

    if (_decl.isBridge) {
      final bridge = _decl.bridge!;

      if (bridge is BridgeClassDef) {
        final type = TypeRef.fromBridgeTypeRef(ctx, bridge.type.type);

        return Variable(-1, EvalTypes.typeType,
            concreteTypes: [type],
            methodOffset: DeferredOrOffset(file: type.file, name: type.name + '.'),
            methodReturnType: AlwaysReturnType(type, false));
      }

      if (bridge is BridgeEnumDef) {
        final type = TypeRef.fromBridgeTypeRef(ctx, bridge.type);
        return Variable(-1, EvalTypes.typeType,
            concreteTypes: [type],
            methodOffset: DeferredOrOffset(file: type.file, name: type.name + '#wrap'),
            methodReturnType: AlwaysReturnType(type, false));
      }

      if (bridge is BridgeFunctionDeclaration) {
        final returnType = TypeRef.fromBridgeAnnotation(ctx, bridge.function.returns);
        return Variable(-1, EvalTypes.functionType,
            methodReturnType: AlwaysReturnType(returnType, false),
            methodOffset: DeferredOrOffset(file: _decl.sourceLib, name: name));
      }

      throw CompileError('Cannot resolve bridged ${bridge.runtimeType} in reference');
    }

    final decl = _decl.declaration!;

    if (decl is VariableDeclaration) {
      final type = ctx.topLevelVariableInferredTypes[_decl.sourceLib]![decl.name2.value() as String]!;
      final gIndex = ctx.topLevelGlobalIndices[_decl.sourceLib]![decl.name2.value() as String]!;
      ctx.pushOp(LoadGlobal.make(gIndex), LoadGlobal.LEN);
      ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);

      return Variable.alloc(ctx, type);
    }

    if (decl is! FunctionDeclaration && decl is! ConstructorDeclaration) {
      decl as ClassDeclaration;

      final returnType = TypeRef.lookupClassDeclaration(ctx, _decl.sourceLib, decl);
      final DeferredOrOffset offset;

      if (ctx.topLevelDeclarationPositions[_decl.sourceLib]?.containsKey(name + '.') ?? false) {
        offset =
            DeferredOrOffset(file: _decl.sourceLib, offset: ctx.topLevelDeclarationPositions[ctx.library]![name + '.']);
      } else {
        offset = DeferredOrOffset(file: _decl.sourceLib, name: name + '.');
      }

      return Variable(-1, EvalTypes.typeType,
          concreteTypes: [returnType], methodOffset: offset, methodReturnType: AlwaysReturnType(returnType, false));
    }

    TypeRef? returnType;
    var nullable = true;
    if (decl is FunctionDeclaration && decl.returnType != null) {
      returnType = TypeRef.fromAnnotation(ctx, _decl.sourceLib, decl.returnType!);
      nullable = decl.returnType!.question != null;
    } else {
      returnType = TypeRef.lookupClassDeclaration(ctx, _decl.sourceLib, decl.parent as ClassDeclaration);
    }

    final DeferredOrOffset offset;
    if (ctx.topLevelDeclarationPositions[_decl.sourceLib]?.containsKey(name) ?? false) {
      offset = DeferredOrOffset(file: _decl.sourceLib, offset: ctx.topLevelDeclarationPositions[ctx.library]![name]);
    } else {
      offset = DeferredOrOffset(file: _decl.sourceLib, name: name);
    }

    return Variable(-1, EvalTypes.typeType,
        concreteTypes: [returnType], methodOffset: offset, methodReturnType: AlwaysReturnType(returnType, nullable));
  }

  @override
  StaticDispatch? getStaticDispatch(CompilerContext ctx) {
    if (object != null) {
      if (object!.concreteTypes.length == 1) {
        // If we know the concrete type of the object, we can easily optimize to a static call
        final actualType = object!.concreteTypes[0];
        DeferredOrOffset offset;

        final returnType = AlwaysReturnType.fromInstanceMethod(ctx, actualType, name, EvalTypes.dynamicType);

        final methodsMap = ctx.instanceDeclarationPositions[actualType.file]![actualType.name]![2];
        if (methodsMap.containsKey(name)) {
          offset = DeferredOrOffset(file: actualType.file, offset: methodsMap[name]);
        } else {
          offset = DeferredOrOffset(file: actualType.file, className: actualType.name, methodType: 2, name: name);
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
    final _decl = declaration.declaration!;

    if (_decl.isBridge) {
      // No static dispatch for bridge
      return null;
    }

    final decl = _decl.declaration!;

    if (decl is! FunctionDeclaration && decl is! ConstructorDeclaration) {
      decl as ClassDeclaration;

      final DeferredOrOffset offset;

      if (ctx.topLevelDeclarationPositions[_decl.sourceLib]?.containsKey(name + '.') ?? false) {
        offset =
            DeferredOrOffset(file: _decl.sourceLib, offset: ctx.topLevelDeclarationPositions[ctx.library]![name + '.']);
      } else {
        offset = DeferredOrOffset(file: _decl.sourceLib, name: name + '.');
      }

      final rt = AlwaysReturnType(TypeRef.lookupClassDeclaration(ctx, _decl.sourceLib, decl), false);

      return StaticDispatch(offset, rt);
    }

    TypeRef? returnType;
    var nullable = true;
    if (decl is FunctionDeclaration && decl.returnType != null) {
      returnType = TypeRef.fromAnnotation(ctx, _decl.sourceLib, decl.returnType!);
      nullable = decl.returnType!.question != null;
    } else {
      returnType = TypeRef.lookupClassDeclaration(ctx, _decl.sourceLib, decl.parent as ClassDeclaration);
    }

    final DeferredOrOffset offset;
    if (ctx.topLevelDeclarationPositions[_decl.sourceLib]?.containsKey(name) ?? false) {
      offset = DeferredOrOffset(file: _decl.sourceLib, offset: ctx.topLevelDeclarationPositions[ctx.library]![name]);
    } else {
      offset = DeferredOrOffset(file: _decl.sourceLib, name: name);
    }

    return StaticDispatch(offset, AlwaysReturnType(returnType, nullable));
  }
}

/// A [Reference] with a variable that can be indexed into and a variable index. Accessing its value may use [IndexList]
/// [IndexMap] or [InvokeDynamic] depending on the state of the target variable.
class IndexedReference implements Reference {
  IndexedReference(this._variable, this._index);

  Variable _variable;
  Variable _index;

  @override
  TypeRef resolveType(CompilerContext ctx) {
    if (_variable.type.isAssignableTo(ctx, EvalTypes.listType)) {
      return _variable.type.specifiedTypeArgs[0];
    }
    return getValue(ctx).type;
  }

  @override
  Variable getValue(CompilerContext ctx) {
    _variable = _variable.updated(ctx);
    _index = _index.updated(ctx);

    if (_variable.type.isAssignableTo(ctx, EvalTypes.listType)) {
      if (!_index.type.isAssignableTo(ctx, EvalTypes.intType)) {
        throw CompileError('TypeError: Cannot use variable of type ${_index.type} as list index');
      }

      final list = _variable.unboxIfNeeded(ctx);
      _index = _index.unboxIfNeeded(ctx);
      ctx.pushOp(IndexList.make(list.scopeFrameOffset, _index.scopeFrameOffset), IndexList.LEN);
      return Variable.alloc(ctx, _variable.type.specifiedTypeArgs[0]);
    }

    if (_variable.type.isAssignableTo(ctx, EvalTypes.mapType)) {
      if (!_index.type.isAssignableTo(ctx, _variable.type.specifiedTypeArgs[0])) {
        throw CompileError('TypeError: Cannot use variable of type ${_index.type} as index to map of type '
            '<${_variable.type.specifiedTypeArgs[0]}, ${_variable.type.specifiedTypeArgs[1]}>');
      }

      final map = _variable.unboxIfNeeded(ctx);
      _index = _variable.type.specifiedTypeArgs[0].boxed ? _index.boxIfNeeded(ctx) : _index.unboxIfNeeded(ctx);
      ctx.pushOp(IndexMap.make(map.scopeFrameOffset, _index.scopeFrameOffset), IndexMap.LEN);
      return Variable.alloc(ctx, _variable.type.specifiedTypeArgs[1]);
    }

    final result = _variable.invoke(ctx, '[]', [_index]);
    _variable = result.target!;
    _index = result.args[0];
    return result.result;
  }

  @override
  void setValue(CompilerContext ctx, Variable value) {
    _variable = _variable.updated(ctx);
    _index = _index.updated(ctx);

    if (_variable.type.isAssignableTo(ctx, EvalTypes.listType)) {
      if (!_index.type.isAssignableTo(ctx, EvalTypes.intType)) {
        throw CompileError('TypeError: Cannot use variable of type ${_index.type} as list index');
      }

      final list = _variable.unboxIfNeeded(ctx);
      _index = _index.unboxIfNeeded(ctx);
      ctx.pushOp(
          ListSetIndexed.make(list.scopeFrameOffset, _index.scopeFrameOffset, value.scopeFrameOffset), IndexList.LEN);
      return;
    }

    final result = _variable.invoke(ctx, '[]=', [_index, value]);
    _variable = result.target!;
    _index = result.args[0];
  }

  @override
  StaticDispatch? getStaticDispatch(CompilerContext ctx) {
    return null;
  }
}
