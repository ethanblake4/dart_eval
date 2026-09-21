import 'helpers/global.dart';
import 'helpers/conversion.dart';
import '../ir/closures.dart';
import '../ir/exception.dart';
import 'backend/representation.dart' show MachineRepresentation;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/bridge/declaration.dart';
import 'package:dart_eval/src/eval/compiler/dispatch.dart';
import 'package:dart_eval/src/eval/compiler/expression/function.dart';
import 'package:dart_eval/src/eval/compiler/helpers/invoke.dart';
import 'package:dart_eval/src/eval/compiler/helpers/tearoff.dart';
import 'package:dart_eval/src/eval/ir/primitives.dart';
import 'package:dart_eval/src/eval/ir/types.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/ir/bridge.dart';
import 'package:dart_eval/src/eval/ir/collection.dart';
import 'package:dart_eval/src/eval/ir/globals.dart';
import 'package:dart_eval/src/eval/ir/memory.dart';
import 'package:dart_eval/src/eval/ir/objects.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/compiler/expression/identifier.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

/// A compile-time datum that can be - at the very least - converted to a [Variable] in the
/// future if needed. May also contain information about how to modify its value.
///
/// Using References can help prevent unnecessary bytecode generation, but be careful! Some Dart structures
/// may rely on side-effects from accessing a variable.
abstract class Reference {
  TypeRef resolveType(
    CompilerContext ctx, {
    bool forSet = false,
    AstNode? source,
  });

  Variable setValue(CompilerContext ctx, Variable value, [AstNode? source]);

  Variable getValue(CompilerContext ctx, [AstNode? source]);

  StaticDispatch? getStaticDispatch(CompilerContext ctx, [AstNode? source]);
}

/// A property whose getter and setter resolve from the lexical superclass.
class SuperPropertyReference extends IdentifierReference {
  SuperPropertyReference(Variable super.object, super.name);

  Variable _owner(CompilerContext ctx, bool forSet) {
    var receiver = object!;
    final mixinOwner = superMixinMemberOwner(ctx, name);
    if (mixinOwner != null) {
      return Variable.of(
        ctx,
        receiver.ssa,
        mixinOwner,
        concreteTypes: [mixinOwner],
      );
    }
    var type = receiver.type.resolveTypeChain(ctx);
    while (true) {
      final declarations = ctx.instanceDeclarationsMap[type.file]?[type.name];
      if (declarations == null ||
          declarations.containsKey(name) ||
          declarations.containsKey('$name*${forSet ? 's' : 'g'}')) {
        return receiver;
      }
      final parent = type.extendsType;
      if (parent == null) return receiver;
      type = parent.resolveTypeChain(ctx);
      receiver = Variable.ssa(
        ctx,
        LoadSuper(ctx.svar('super'), receiver.ssa),
        type,
      );
    }
  }

  @override
  Variable getValue(CompilerContext ctx, [AstNode? source]) {
    final receiver = _owner(ctx, false);
    // A method member read is a tear-off bound to the super receiver.
    final memberDecl = ctx
        .instanceDeclarationsMap[receiver.type.file]?[receiver.type.name]
            ?[name];
    if (memberDecl is MethodDeclaration &&
        !memberDecl.isGetter &&
        !memberDecl.isSetter) {
      return Variable(
        CoreTypes.function.ref(ctx),
        methodOffset: DeferredOrOffset(
          file: receiver.type.file,
          className: receiver.type.name,
          name: name,
          targetName: receiver.ssa.name,
        ),
        callingConvention: CallingConvention.static,
      ).tearOff(ctx);
    }
    if (ctx
            .topLevelDeclarationsMap[receiver.type.file]?[receiver.type.name]
            ?.isBridge ??
        false) {
      return receiver.getProperty(ctx, name, source: source);
    }
    return Variable.ssa(
      ctx,
      Call(
        DeferredOrOffset(
          file: receiver.type.file,
          className: receiver.type.name,
          name: name,
          methodType: 0,
        ),
        [receiver.ssa],
        result: ctx.svar(name),
      ),
      resolveType(ctx, source: source).copyWith(boxed: true),
    );
  }

  @override
  Variable setValue(CompilerContext ctx, Variable value, [AstNode? source]) {
    final receiver = _owner(ctx, true);
    if (ctx
            .topLevelDeclarationsMap[receiver.type.file]?[receiver.type.name]
            ?.isBridge ??
        false) {
      return IdentifierReference(receiver, name).setValue(ctx, value, source);
    }
    final type = resolveType(ctx, forSet: true, source: source);
    final boxed = convertForAssignment(
      ctx,
      value,
      type,
      representation: MachineRepresentation.object,
      source: source,
      description: 'Cannot assign ${value.type} to super.$name of type $type',
    );
    ctx.pushOp(
      Call(
        DeferredOrOffset(
          file: receiver.type.file,
          className: receiver.type.name,
          name: name,
          methodType: 1,
        ),
        [receiver.ssa, boxed.ssa],
        result: ctx.svar('super_set'),
      ),
    );
    return boxed;
  }

  @override
  StaticDispatch? getStaticDispatch(CompilerContext ctx, [AstNode? source]) =>
      null;
}

/// A local, instance, or top-level reference with an optional target object.
class IdentifierReference implements Reference {
  IdentifierReference(this.object, this.name);

  Variable? object;
  final String name;

  @override
  TypeRef resolveType(
    CompilerContext ctx, {
    bool forSet = false,
    AstNode? source,
  }) {
    if (object != null) {
      if (object!.type == CoreTypes.type.ref(ctx)) {
        return object!.concreteTypes[0].resolveTypeChain(ctx);
      }
      return TypeRef.lookupFieldType(
            ctx,
            object!.type,
            name,
            forSet: forSet,
            source: source,
          ) ??
          CoreTypes.dynamic.ref(ctx);
    }

    // Locals
    final local = ctx.lookupLocal(name);
    if (local != null) {
      return local.type;
    }

    // Instance
    if (ctx.currentClass != null) {
      final fieldType = _resolveInstanceFieldType(
        ctx,
        name,
        forSet: forSet,
        source: source,
      );
      if (fieldType != null) return fieldType;

      final staticDeclaration = resolveScopedStaticDeclaration(ctx, name);

      if (staticDeclaration != null && staticDeclaration.$1.declaration != null) {
        final (staticDecl, scopeFile, scopeName) = staticDeclaration;
        final staticDec = staticDecl.declaration!;
        if (staticDec is MethodDeclaration) {
          return CoreTypes.function.ref(ctx);
        } else if (staticDec is VariableDeclaration) {
          final name = '$scopeName.${staticDec.name.lexeme}';
          return resolveGlobalType(ctx, scopeFile, name);
        }
      }
    }

    final typeParameter = ctx.temporaryTypes[ctx.library]?[name];
    if (typeParameter != null && name != '_') {
      return CoreTypes.type.ref(ctx);
    }

    final declarationValue = _lookupVisibleValue(ctx, name, source);
    final decl = declarationValue.declaration!;

    if (decl is VariableDeclaration) {
      return resolveGlobalType(
        ctx,
        declarationValue.sourceLib,
        decl.name.lexeme,
      );
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
        return storeGlobalBinding(ctx, classType.file, fqName, value, source);
      }
      object = object!.boxIfNeeded(ctx, source);
      final fieldType =
          TypeRef.lookupFieldType(
            ctx,
            object!.type,
            name,
            forSet: true,
            source: source,
          ) ??
          CoreTypes.dynamic.ref(ctx);
      final val = convertForAssignment(
        ctx,
        value,
        fieldType,
        representation: MachineRepresentation.object,
        source: source,
        description:
            'Cannot assign value of type ${value.type} to field "$name" '
            'of type $fieldType',
      );
      final op = SetPropertyDynamic(
        object!.ssa,
        name,
        val.ssa,
        callerLibrary: ctx.library,
      );
      ctx.pushOp(op);
      return val;
    }

    var local = ctx.lookupLocal(name);

    if (local != null) {
      if (local.isFinal && local.concreteTypes.isNotEmpty) {
        throw CompileError(
          'Cannot modify value of final variable $name',
          source,
        );
      }

      value = convertForAssignment(
        ctx,
        value,
        local.declaredType,
        representation: local.representation,
        source: source,
        description:
            'Cannot assign value of type ${value.type} to variable "$name" '
            'of type ${local.declaredType}',
      );

      final stored = local.representation == MachineRepresentation.object
          ? value.boxIfNeeded(ctx)
          : value.unboxIfNeeded(ctx, false);
      if (local.exceptionSlot != null) {
        ctx.pushOp(StoreExceptionSlot(local.exceptionSlot!, stored.ssa));
        return stored;
      }
      if (local.captureCell != null) {
        ctx.pushOp(
          WriteCaptureCell(
            local.captureCell!,
            stored.ssa,
            local.representation,
          ),
        );
        return stored;
      }
      ctx.pushOp(Assign(local.ssa, stored.ssa));
      local.copyWithUpdate(
        ctx,
        type:
            (local.declaredType == CoreTypes.dynamic.ref(ctx)
                    ? local.declaredType
                    : stored.type)
                .copyWith(boxed: local.boxed),
        concreteTypes: stored.concreteTypes,
      );
      return stored;
    }

    // Instance
    if (ctx.currentClass != null) {
      final instanceDeclaration = resolveInstanceDeclaration(
        ctx,
        ctx.enclosingLibrary ?? ctx.library,
        ctx.currentClassName!,
        name,
      );
      if (instanceDeclaration != null) {
        final fieldType = _resolveInstanceFieldType(
          ctx,
          name,
          forSet: true,
          source: source,
        )!;
        final $this = ctx.lookupLocal('#this')!;
        final stored = convertForAssignment(
          ctx,
          value,
          fieldType,
          representation: MachineRepresentation.object,
          source: source,
          description:
              'Cannot assign value of type ${value.type} to field "$name" '
              'of type $fieldType',
        );
        final op = SetPropertyDynamic(
          $this.ssa,
          name,
          stored.ssa,
          callerLibrary: ctx.library,
        );
        ctx.pushOp(op);
        return stored;
      }
    }

    if (ctx.currentClass != null) {
      final staticDeclaration = resolveScopedStaticDeclaration(ctx, name);
      final declaration = staticDeclaration?.$1.declaration;
      if (declaration is VariableDeclaration) {
        return storeGlobalBinding(
          ctx,
          staticDeclaration!.$2,
          '${staticDeclaration.$3}.${declaration.name.lexeme}',
          value,
          source,
        );
      }
    }

    final declarationValue = _lookupVisibleValue(ctx, name, source);
    final decl = declarationValue.declaration!;

    if (decl is VariableDeclaration) {
      return storeGlobalBinding(
        ctx,
        declarationValue.sourceLib,
        decl.name.lexeme,
        value,
        source,
      );
    }

    throw CompileError(
      'Cannot find value to set: ${object != null ? '${object!}.' : ''}$name',
      source,
    );
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
            return Variable.ssa(ctx, LoadGlobal(ctx.svar(name), gIndex), type);
          }
        }
        final decOrBridge =
            ctx.topLevelDeclarationsMap[classType.file]![classType.name]!;
        if (decOrBridge.isBridge) {
          final br = decOrBridge.bridge;
          if (br is BridgeClassDef) {
            final getter = br.getters[name];
            final field = br.fields[name];
            if (getter != null || field != null) {
              final type = getter != null
                  ? TypeRef.fromBridgeAnnotation(
                      ctx,
                      getter.functionDescriptor.returns,
                    )
                  : TypeRef.fromBridgeAnnotation(ctx, field!.type);
              return Variable.ssa(
                ctx,
                InvokeExternal(
                  ctx.svar(name),
                  ctx.bridgeStaticFunctionIndices[classType
                      .file]!['${classType.name}.$name*g']!,
                  [],
                ),
                type,
              );
            }

            throw CompileError(
              'Cannot find external getter or field: $name on $classType',
              source,
            );
          }
        }
        final fqName = '${classType.name}.${ctorNameOf(name)}';
        final member = ctx.topLevelDeclarationsMap[classType.file]![fqName];
        final memberDecl = member?.declaration;
        if (member != null &&
            !member.isBridge &&
            memberDecl is! VariableDeclaration) {
          if (memberDecl is ConstructorDeclaration) {
            throw CompileError(
              'Constructor tear-off "$fqName" is not supported',
              source,
            );
          }
          // Static method tear-off.
          return Variable(
            CoreTypes.function.ref(ctx),
            methodOffset: DeferredOrOffset(
              file: classType.file,
              name: fqName,
            ),
            callingConvention: CallingConvention.static,
          );
        }
        return _loadGlobalVariable(ctx, classType.file, fqName, name);
      }
      object = object!.boxIfNeeded(ctx, source);
      return object!.getProperty(ctx, name);
    }

    // First look at locals
    final local = ctx.lookupLocal(name);
    if (local != null) {
      return local.readBinding(ctx);
    }

    // Next, the instance (if available)
    if (ctx.currentClass != null) {
      final instanceDeclaration = resolveInstanceDeclaration(
        ctx,
        ctx.enclosingLibrary ?? ctx.library,
        ctx.currentClassName!,
        name,
      );
      if (instanceDeclaration != null) {
        final $type = instanceDeclaration.$1;
        final decOrBridge = instanceDeclaration.$2;

        final $this = ctx.lookupLocal('#this')!;

        if (!decOrBridge.isBridge) {
          final declaration = decOrBridge.declaration;
          if (declaration is MethodDeclaration &&
              !declaration.isGetter &&
              !declaration.isSetter) {
            return Variable(
              CoreTypes.function.ref(ctx),
              methodOffset: DeferredOrOffset(
                file: ctx.library,
                className: ctx.currentClassName!,
                name: _refName,
                targetName: $this.name,
              ),
              callingConvention: CallingConvention.static,
            );
          }
        }

        final resvar = ctx.svar(name);
        ctx.pushOp(
          LoadPropertyDynamic(
            resvar,
            $this.ssa,
            name,
            callerLibrary: ctx.library,
          ),
        );

        if (decOrBridge.isBridge) {
          if (decOrBridge is GetSet) {
            final getter =
                decOrBridge.bridge ??
                (throw CompileError(
                  'Property "$name" has a setter but no getter, so it cannot be accessed',
                  source,
                ));
            return Variable.of(
              ctx,
              resvar,
              TypeRef.fromBridgeAnnotation(
                ctx,
                getter.functionDescriptor.returns,
                specifiedType: $type,
                specifyingType: $this.type,
              ),
              methodOffset: DeferredOrOffset(
                file: ctx.library,
                className: ctx.currentClassName!,
                name: _refName,
              ),
            );
          }
          final bridge = decOrBridge.bridge!;
          if (bridge is BridgeMethodDef) {
            return Variable(
              CoreTypes.function.ref(ctx),
              methodOffset: DeferredOrOffset(
                file: ctx.library,
                className: ctx.currentClassName!,
                name: name,
              ),
            );
          }
          if (bridge is BridgeFieldDef) {
            return Variable.of(
              ctx,
              resvar,
              TypeRef.fromBridgeAnnotation(
                ctx,
                bridge.type,
                specifiedType: $type,
                specifyingType: $this.type,
              ),
              methodOffset: DeferredOrOffset(
                file: ctx.library,
                className: ctx.currentClassName!,
                name: _refName,
              ),
            );
          }
          throw CompileError(
            'Ref: cannot resolve bridge declaration "$name" of type ${decOrBridge.runtimeType}',
            source,
          );
        }

        return Variable.of(
          ctx,
          resvar,
          TypeRef.lookupFieldType(ctx, $type, name, source: source) ??
              CoreTypes.dynamic.ref(ctx),
        );
      }

      final staticDeclaration = resolveScopedStaticDeclaration(ctx, name);

      if (staticDeclaration != null && staticDeclaration.$1.declaration != null) {
        final (staticDecl, scopeFile, scopeName) = staticDeclaration;
        final staticDec = staticDecl.declaration!;
        if (staticDec is MethodDeclaration) {
          return Variable(
            CoreTypes.function.ref(ctx),
            methodOffset: DeferredOrOffset.lookupStatic(
              ctx,
              scopeFile,
              scopeName,
              _refName,
            ),
          );
        } else if (staticDec is VariableDeclaration) {
          final name = '$scopeName.${staticDec.name.lexeme}';
          return _loadGlobalVariable(
            ctx,
            scopeFile,
            name,
            staticDec.name.lexeme,
          );
        }
      }
    }

    // A type parameter in scope evaluates to its bound `Type` object.
    // (`_` is a wildcard type parameter: non-binding.)
    final typeParameter = ctx.temporaryTypes[ctx.library]?[name];
    if (typeParameter != null && name != '_') {
      return Variable.ssa(
        ctx,
        LoadTypeParameter(
          ctx.svar('type'),
          typeParameter.runtimeTypeId(ctx),
        ),
        CoreTypes.type.ref(ctx),
        concreteTypes: [typeParameter],
      );
    }

    final declaration =
        ctx.visibleDeclarations[ctx.library]![name] ??
        ctx.visibleDeclarations[ctx.library]![name.split('.')[0]] ??
        (throw CompileError('Could not find declaration "$name"', source));

    // Prefix children are keyed by declaration name ('B'), so a prefixed
    // member reference 'p.B.ctor' resolves 'B' here; [_declarationToVariable]
    // handles the member suffix via _refName.
    final split = name.split('.');
    final children = declaration.children;
    final viaPrefix = declaration.declaration == null;
    final activeDec = declaration.declaration ??
        (split.length > 1 && children != null ? children[split[1]] : null) ??
        (throw PrefixError());

    return _declarationToVariable(
      activeDec,
      viaPrefix ? split.sublist(1).join('.') : _refName,
      ctx,
      source,
    );
  }

  @override
  StaticDispatch? getStaticDispatch(CompilerContext ctx, [AstNode? source]) {
    if (object != null) {
      if (object!.concreteTypes.length == 1) {
        // If we know the concrete type of the object, we can easily optimize to a static call
        final actualType = object!.concreteTypes[0];
        DeferredOrOffset offset;

        final returnType = AlwaysReturnType.fromInstanceMethod(
          ctx,
          actualType,
          name,
          CoreTypes.dynamic.ref(ctx),
        );

        final methodsMap =
            ctx.instanceDeclarationPositions[actualType.file]![actualType
                .name]![2];
        if (methodsMap.containsKey(name)) {
          offset = DeferredOrOffset(
            file: actualType.file,
            offset: methodsMap[name],
          );
        } else {
          // An inherited method needs the owner's field view as its receiver.
          // Dynamic dispatch resolves that view as well as the method offset.
          return null;
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
    final dec =
        ctx.visibleDeclarations[ctx.library]![prefix] ??
        (throw CompileError('Cannot find prefix $prefix', source));
    if (dec.declaration != null) {
      throw CompileError('Cannot use a declaration as a prefix', source);
    }
    final children = dec.children!;
    final child = children[identifier] ??
        (throw CompileError(
          "'$identifier' isn't defined for the prefix '$prefix'",
          source,
        ));
    return _declarationToStaticDispatch(child, identifier, ctx, source);
  }

  @override
  Variable getValue(CompilerContext ctx, [AstNode? source]) {
    final dec =
        ctx.visibleDeclarations[ctx.library]![prefix] ??
        (throw CompileError('Cannot find prefix $prefix', source));
    if (dec.declaration != null) {
      throw CompileError('Cannot use a declaration as a prefix', source);
    }
    final children = dec.children!;
    final child = children[identifier] ??
        (throw CompileError(
          "'$identifier' isn't defined for the prefix '$prefix'",
          source,
        ));
    return _declarationToVariable(child, identifier, ctx, source);
  }

  @override
  TypeRef resolveType(
    CompilerContext ctx, {
    bool forSet = false,
    AstNode? source,
  }) {
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
  TypeRef resolveType(
    CompilerContext ctx, {
    bool forSet = false,
    AstNode? source,
  }) {
    if (_variable.type.isAssignableTo(
      ctx,
      CoreTypes.list.ref(ctx),
      forceAllowDynamic: false,
    )) {
      return _variable.type.specifiedTypeArgs.isNotEmpty
          ? _variable.type.specifiedTypeArgs[0]
          : CoreTypes.dynamic.ref(ctx);
    }
    if (_variable.type.isAssignableTo(
      ctx,
      CoreTypes.map.ref(ctx),
      forceAllowDynamic: false,
    )) {
      return _variable.type.specifiedTypeArgs.length >= 2
          ? _variable.type.specifiedTypeArgs[1]
          : CoreTypes.dynamic.ref(ctx);
    }
    // A write's contextual type must not execute the indexed getter. Dynamic
    // receivers and custom operators are checked by their invocation path.
    if (forSet) return CoreTypes.dynamic.ref(ctx);
    return getValue(ctx).type;
  }

  @override
  Variable getValue(CompilerContext ctx, [AstNode? source]) {
    _variable = _variable.updated(ctx);
    _index = _index.updated(ctx);

    if (_variable.type.isAssignableTo(
      ctx,
      CoreTypes.list.ref(ctx),
      forceAllowDynamic: false,
    )) {
      if (!_index.type.isAssignableTo(ctx, CoreTypes.int.ref(ctx))) {
        throw CompileError(
          'TypeError: Cannot use variable of type ${_index.type} as list index',
        );
      }

      final list = _variable.unboxIfNeeded(ctx);
      _index = _index.unboxIfNeeded(ctx);
      final listElementType = _variable.type.specifiedTypeArgs.isNotEmpty
          ? _variable.type.specifiedTypeArgs[0]
          : CoreTypes.dynamic.ref(ctx);
      return Variable.ssa(
        ctx,
        IndexList(ctx.svar('list'), list.ssa, _index.ssa),
        listElementType.copyWith(boxed: true),
      );
    }

    if (_variable.type.isAssignableTo(
      ctx,
      CoreTypes.map.ref(ctx),
      forceAllowDynamic: false,
    )) {
      if (_variable.type.specifiedTypeArgs.isNotEmpty &&
          !_index.type.isAssignableTo(
            ctx,
            _variable.type.specifiedTypeArgs[0],
          )) {
        throw CompileError(
          'TypeError: Cannot use variable of type ${_index.type} as index to map of type '
          '<${_variable.type.specifiedTypeArgs[0]}, ${_variable.type.specifiedTypeArgs[1]}>',
        );
      }

      final map = _variable.unboxIfNeeded(ctx);
      _index =
          (_variable.type.specifiedTypeArgs.isEmpty ||
              _variable.type.specifiedTypeArgs[0].boxed)
          ? _index.boxIfNeeded(ctx, source)
          : _index.unboxIfNeeded(ctx);

      final mapType = _variable.type.specifiedTypeArgs.length < 2
          ? CoreTypes.dynamic.ref(ctx)
          : _variable.type.specifiedTypeArgs[1];

      final mapResult = Variable.ssa(
        ctx,
        IndexMap(ctx.svar('map'), map.ssa, _index.ssa),
        mapType,
      );

      if (_variable.type.specifiedTypeArgs.isEmpty ||
          _variable.type.specifiedTypeArgs[1].boxed) {
        return Variable.ssa(
          ctx,
          MaybeBoxNull(ctx.svar('map'), mapResult.ssa),
          mapType,
        );
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

    if (_variable.type.isAssignableTo(
      ctx,
      CoreTypes.list.ref(ctx),
      forceAllowDynamic: false,
    )) {
      if (!_index.type.isAssignableTo(ctx, CoreTypes.int.ref(ctx))) {
        throw CompileError(
          'TypeError: Cannot use variable of type ${_index.type} as list index',
          source,
        );
      }

      final elementType = _variable.type.specifiedTypeArgs.isEmpty
          ? CoreTypes.dynamic.ref(ctx)
          : _variable.type.specifiedTypeArgs[0];
      final formattedValue = convertForAssignment(
        ctx,
        value,
        elementType,
        representation: MachineRepresentation.object,
        source: source,
      );
      // Keep the reified wrapper for writes. A List<num> reference can point
      // at a List<int>; writing directly to its raw backing list would bypass
      // the actual instance's checked element type.
      final result = _variable.invoke(ctx, '[]=', [_index, formattedValue]);
      _variable = result.target!;
      _index = result.args[0];
      return result.args[1];
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
  DeclarationOrBridge decOrBridge,
  String name,
  CompilerContext ctx, [
  AstNode? source,
]) {
  if (decOrBridge.isBridge) {
    final bridge = decOrBridge.bridge!;

    if (bridge is BridgeClassDef) {
      final type = TypeRef.fromBridgeTypeRef(ctx, bridge.type.type);
      return _typeLiteral(ctx, type, '${type.name}.');
    }

    if (bridge is BridgeEnumDef) {
      final type = TypeRef.fromBridgeTypeRef(ctx, bridge.type);
      return _typeLiteral(ctx, type, '${type.name}#wrap');
    }

    if (bridge is BridgeFunctionDeclaration) {
      final returnType = TypeRef.fromBridgeAnnotation(
        ctx,
        bridge.function.returns,
      );
      return Variable(
        CoreTypes.function.ref(ctx),
        methodReturnType: AlwaysReturnType(returnType, false),
        methodOffset: DeferredOrOffset(file: decOrBridge.sourceLib, name: name),
      );
    }

    throw CompileError(
      'Cannot resolve bridged ${bridge.runtimeType} in reference',
      source,
    );
  }

  final decl = decOrBridge.declaration!;

  if (decl is VariableDeclaration) {
    return _loadGlobalVariable(ctx, decOrBridge.sourceLib, decl.name.lexeme);
  }

  if (decl is! FunctionDeclaration && decl is! ConstructorDeclaration) {
    final type = decl is TypeAlias && decl is! ClassTypeAlias
        ? resolveTypeAlias(ctx, decOrBridge.sourceLib, decl)
        : TypeRef.lookupDeclaration(ctx, decOrBridge.sourceLib, decl);
    return _typeLiteral(ctx, type, '${declarationName(decl)}.');
  }

  TypeRef? returnType;
  var nullable = true;
  if (decl is FunctionDeclaration && decl.returnType != null) {
    final previousTypes = {...?ctx.temporaryTypes[decOrBridge.sourceLib]};
    TypeRef.loadTemporaryTypes(
      ctx,
      decl.functionExpression.typeParameters?.typeParameters,
      library: decOrBridge.sourceLib,
    );
    returnType = TypeRef.fromAnnotation(
      ctx,
      decOrBridge.sourceLib,
      decl.returnType!,
    );
    nullable = decl.returnType!.question != null;
    ctx.temporaryTypes[decOrBridge.sourceLib] = previousTypes;
  } else if (decl is ConstructorDeclaration) {
    returnType = TypeRef.lookupDeclaration(
      ctx,
      decOrBridge.sourceLib,
      decl.parent!.parent as ClassDeclaration,
    );
  } else {
    // A function without a return type annotation returns dynamic.
    returnType = CoreTypes.dynamic.ref(ctx);
  }

  final offset = DeferredOrOffset(file: decOrBridge.sourceLib, name: name);

  final fn = Variable(
    decl is FunctionDeclaration
        ? CoreTypes.function.ref(ctx)
        : CoreTypes.type.ref(ctx),
    concreteTypes: [returnType],
    methodOffset: offset,
    methodReturnType: AlwaysReturnType(returnType, nullable),
  );

  if (decl is FunctionDeclaration && decl.isGetter) {
    return fn.invoke(ctx, null, []).result;
  }
  return fn;
}

StaticDispatch? _declarationToStaticDispatch(
  DeclarationOrBridge decOrBridge,
  String name,
  CompilerContext ctx, [
  AstNode? source,
]) {
  if (decOrBridge.isBridge) {
    // No static dispatch for bridge
    return null;
  }

  final decl = decOrBridge.declaration!;

  if (decl is! FunctionDeclaration && decl is! ConstructorDeclaration) {
    decl as ClassDeclaration;

    final offset = DeferredOrOffset(
      file: decOrBridge.sourceLib,
      name: '$name.',
    );

    final rt = AlwaysReturnType(
      TypeRef.lookupDeclaration(ctx, decOrBridge.sourceLib, decl),
      false,
    );

    return StaticDispatch(offset, rt);
  }

  TypeRef? returnType;
  var nullable = true;
  if (decl is FunctionDeclaration && decl.returnType != null) {
    returnType = TypeRef.fromAnnotation(
      ctx,
      decOrBridge.sourceLib,
      decl.returnType!,
    );
    nullable = decl.returnType!.question != null;
  } else if (decl is ConstructorDeclaration) {
    returnType = TypeRef.lookupDeclaration(
      ctx,
      decOrBridge.sourceLib,
      decl.parent!.parent as ClassDeclaration,
    );
  } else {
    // A function without a return type annotation returns dynamic.
    returnType = CoreTypes.dynamic.ref(ctx);
  }

  final offset = DeferredOrOffset(file: decOrBridge.sourceLib, name: name);

  return StaticDispatch(offset, AlwaysReturnType(returnType, nullable));
}

/// Loads a top-level (or static field) global by its qualified [globalName],
/// using [valueName] (defaults to the unqualified name) for the SSA variable.
Variable _loadGlobalVariable(
  CompilerContext ctx,
  int sourceLib,
  String globalName, [
  String? valueName,
]) {
  ensureGlobalRegistered(ctx, sourceLib, globalName);
  final type = resolveGlobalType(ctx, sourceLib, globalName);
  final gIndex = ctx.topLevelGlobalIndices[sourceLib]![globalName]!;
  return Variable.ssa(
    ctx,
    LoadGlobal(ctx.svar(valueName ?? globalName), gIndex),
    type,
  );
}

/// A `Type` literal variable for [type]. [constructorKey] is the name used in
/// [DeferredOrOffset] to resolve the constructor (e.g. `ClassName.` or, for
/// bridged enums, `EnumName#wrap`).
Variable _typeLiteral(
  CompilerContext ctx,
  TypeRef type,
  String constructorKey,
) {
  final typeId = type.runtimeTypeId(ctx);
  final operation = type.requiresTypeEnvironment
      ? LoadTypeParameter(ctx.svar('type'), typeId)
      : LoadConstantType(ctx.svar('type'), typeId);
  return Variable.ssa(
    ctx,
    operation,
    CoreTypes.type.ref(ctx),
    concreteTypes: [type],
    methodOffset: DeferredOrOffset(file: type.file, name: constructorKey),
    methodReturnType: AlwaysReturnType(type, false),
  );
}

/// The declared type of instance member [name] on the enclosing class, or null
/// when the current class has no such member.
TypeRef? _resolveInstanceFieldType(
  CompilerContext ctx,
  String name, {
  bool forSet = false,
  AstNode? source,
}) {
  final instanceDeclaration = resolveInstanceDeclaration(
    ctx,
    ctx.library,
    ctx.currentClassName!,
    name,
  );
  if (instanceDeclaration == null) return null;
  return TypeRef.lookupFieldType(
        ctx,
        instanceDeclaration.$1,
        name,
        forSet: forSet,
        source: source,
      ) ??
      CoreTypes.dynamic.ref(ctx);
}

/// Resolves [name] to a top-level declaration visible in the current library.
/// Throws [PrefixError] when the name resolves to an import prefix rather than
/// a concrete declaration.
DeclarationOrBridge _lookupVisibleValue(
  CompilerContext ctx,
  String name,
  AstNode? source,
) {
  final declaration =
      ctx.visibleDeclarations[ctx.library]![name] ??
      (throw CompileError('Could not find declaration "$name"', source));
  return declaration.declaration ?? (throw PrefixError());
}
