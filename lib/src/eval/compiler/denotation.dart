part of 'reference.dart';

/// What a name refers to — the compile-time meaning of an identifier,
/// independent of how the reference is used (read, written, or called).
/// Emission lives on the denotation so `getValue`/`setValue`/`resolveType`
/// share one name-resolution cascade.
sealed class Denotation {
  const Denotation();

  /// The type a read of this denotation produces.
  TypeRef readType(CompilerContext ctx, {AstNode? source});

  /// The write context of an assignment to this denotation.
  TypeRef writeType(CompilerContext ctx, {AstNode? source}) =>
      readType(ctx, source: source);

  /// Emits the read.
  Variable read(CompilerContext ctx, {AstNode? source});

  /// Emits `this denotation = value`; returns the stored variable.
  Variable write(CompilerContext ctx, Variable value, {AstNode? source});

  /// Compile-time call dispatch when this denotation is invoked directly.
  StaticDispatch? staticDispatch(CompilerContext ctx, {AstNode? source}) =>
      null;
}

/// The special receivers a member access can target.
sealed class Receiver {
  const Receiver();
}

/// A member access on an ordinary value: `v.name`.
final class ValueReceiver extends Receiver {
  const ValueReceiver(this.value);

  final Variable value;
}

/// `super.name` — resolves starting above the current mixin/layer.
final class SuperReceiver extends Receiver {
  const SuperReceiver(this.self);

  final Variable self;
}

/// A member access on a `Type` literal (`C.name`, `E.name`): statics, enum
/// values, constructors, and extension-namespace members. [value] is the
/// `Type` object itself, needed when the denotation is a type parameter
/// (`T.name` dispatches dynamically on the runtime Type).
final class TypeLiteralReceiver extends Receiver {
  const TypeLiteralReceiver(this.type, this.value);

  final TypeRef type;
  final Variable value;
}

/// `E(x).name` — member resolution pinned to [ext]'s members.
final class ExtensionApplicationReceiver extends Receiver {
  const ExtensionApplicationReceiver(this.ext, this.onBindings, this.value);

  final EvalExtension ext;
  final List<TypeRef> onBindings;
  final Variable value;
}

/// `p.name` — member access into an import prefix's namespace.
final class PrefixReceiver extends Receiver {
  const PrefixReceiver(this.prefix);

  final PrefixDenotation prefix;
}

/// Classifies a receiver value for member access.
Receiver receiverOf(CompilerContext ctx, Variable v) {
  if (v.boundExtension case final bound?) {
    return ExtensionApplicationReceiver(bound.ext, bound.onBindings, v);
  }
  if (v.type.isSpec(CoreTypes.type) && v.concreteTypes.length == 1) {
    return TypeLiteralReceiver(v.concreteTypes.first, v);
  }
  return ValueReceiver(v);
}

/// A local variable or parameter.
final class LocalDenotation extends Denotation {
  const LocalDenotation(this.binding);

  final LocalBinding binding;

  @override
  TypeRef readType(CompilerContext ctx, {AstNode? source}) =>
      binding.current.type;

  @override
  TypeRef writeType(CompilerContext ctx, {AstNode? source}) =>
      binding.current.declaredType;

  @override
  Variable read(CompilerContext ctx, {AstNode? source}) => binding.read(ctx);

  @override
  Variable write(CompilerContext ctx, Variable value, {AstNode? source}) {
    final local = binding.current;
    if (local.isFinal && local.concreteTypes.isNotEmpty) {
      throw CompileError(
        'Cannot modify value of final variable ${binding.name}',
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
          'Cannot assign value of type ${value.type} to variable '
          '"${binding.name}" of type ${local.declaredType}',
    );

    final stored = local.representation == MachineRepresentation.object
        ? value.boxIfNeeded(ctx)
        : value.unboxIfNeeded(ctx, false);
    final storage = binding.storage;
    // A binding whose cell is preserved in an exception slot still
    // receives writes through the cell — only the cell itself is
    // restore-loaded by the trampoline.
    if (storage is ExceptionSlotStorage && storage.cell != null) {
      ctx.pushOp(
        WriteCaptureCell(storage.cell!, stored.ssa, local.representation),
      );
      binding.rebind(local.widened());
      return stored;
    }
    if (storage is ExceptionSlotStorage) {
      ctx.pushOp(StoreExceptionSlot(storage.slot, stored.ssa));
      // Slot reads after a handler edge can observe a value written before
      // the exception — allocation proofs can't be trusted across it.
      binding.rebind(local.widened());
      return stored;
    }
    final cell = binding.captureCell;
    if (cell != null) {
      ctx.pushOp(WriteCaptureCell(cell, stored.ssa, local.representation));
      // The cell can also be written by a closure invocation — allocation
      // proofs can't be trusted across it.
      binding.rebind(local.widened());
      return stored;
    }
    ctx.pushOp(Assign(local.ssa, stored.ssa));
    // Assignment keeps the promoted type only when the stored value still
    // conforms to it; otherwise the variable is demoted to its declared
    // type (a `dynamic` local stays dynamic).
    final storedType = stored.type;
    final localType = local.declaredType.isSpec(CoreTypes.dynamic)
        ? local.declaredType
        : storedType.isAssignableTo(ctx, local.type)
        ? local.type
        : local.declaredType;
    local
            .copyWithUpdate(
              ctx,
              type: localType,
              concreteTypes: stored.concreteTypes,
            )
            .exactType =
        stored.exactType;
    return stored;
  }

  @override
  StaticDispatch? staticDispatch(CompilerContext ctx, {AstNode? source}) {
    final current = binding.current;
    if (current.methodOffset != null &&
        current.callingConvention != CallingConvention.dynamic) {
      return StaticDispatch(current.methodOffset!, current.methodReturnType!);
    }
    return null;
  }
}

/// A top-level or static-field global: `x`, `p.x`, `C.x`, `E.x` (static
/// extension fields). [name] is the qualified global name (`C.x`), while
/// [displayName] names the SSA slot.
final class GlobalDenotation extends Denotation {
  const GlobalDenotation(this.library, this.name, {this.displayName});

  final int library;
  final String name;
  final String? displayName;

  @override
  TypeRef readType(CompilerContext ctx, {AstNode? source}) =>
      resolveGlobalType(ctx, library, name);

  @override
  Variable read(CompilerContext ctx, {AstNode? source}) =>
      _loadGlobalVariable(ctx, library, name, displayName);

  @override
  Variable write(CompilerContext ctx, Variable value, {AstNode? source}) =>
      storeGlobalBinding(ctx, library, name, value, source);
}

/// A top-level function, getter, or setter — source or bridge.
final class FunctionDenotation extends Denotation {
  const FunctionDenotation(this.target, this.name);

  /// The member's declaration-or-bridge as found in scope.
  final DeclarationOrBridge target;

  /// The member name as referenced — accessor `*g`/`*s` keys are formed
  /// from it.
  final String name;

  Declaration? get _decl => target.declaration;
  int get _file => target.sourceLib;

  @override
  TypeRef readType(CompilerContext ctx, {AstNode? source}) {
    final decl = _decl;
    if (decl is FunctionDeclaration && decl.isGetter) {
      return decl.returnType != null
          ? TypeRef.fromAnnotation(ctx, _file, decl.returnType!)
          : CoreTypes.dynamic.ref(ctx);
    }
    return CoreTypes.type.ref(ctx);
  }

  @override
  TypeRef writeType(CompilerContext ctx, {AstNode? source}) {
    final decl = _decl;
    if (decl is FunctionDeclaration && decl.isSetter) {
      return _setterValueType(ctx, _file, decl.functionExpression.parameters) ??
          CoreTypes.dynamic.ref(ctx);
    }
    return CoreTypes.type.ref(ctx);
  }

  @override
  Variable read(CompilerContext ctx, {AstNode? source}) =>
      _declarationToVariable(target, name, ctx, source);

  @override
  Variable write(CompilerContext ctx, Variable value, {AstNode? source}) {
    final decl = _decl;
    if (decl is FunctionDeclaration && decl.isSetter) {
      return _invokeSetter(
        ctx,
        DeferredOrOffset(
          file: _file,
          name: MemberName.setter(decl.name.lexeme).key,
        ),
        value,
        _file,
        decl.functionExpression.parameters,
        isMethod: false,
        source: source,
      );
    }
    throw CompileError('Cannot find value to set: $name', source);
  }

  @override
  StaticDispatch? staticDispatch(CompilerContext ctx, {AstNode? source}) {
    final decl = _decl;
    if (target.isBridge) return null;
    // `x()` where `x` is a getter must call the getter's *result*, not the
    // getter itself — no direct dispatch.
    if (decl is FunctionDeclaration && (decl.isGetter || decl.isSetter)) {
      return null;
    }
    return _declarationToStaticDispatch(target, name, ctx, source);
  }
}

/// A static method or accessor on a class or mixin (`C.m` in scope, or a
/// scoped static visible inside the class body).
final class StaticMemberDenotation extends Denotation {
  const StaticMemberDenotation(this.file, this.ownerName, this.member);

  /// The library that registered the member.
  final int file;

  /// The owner name used to qualify static member keys (`C` in `C.m*g`).
  final String ownerName;

  final MethodDeclaration member;

  @override
  TypeRef readType(CompilerContext ctx, {AstNode? source}) {
    if (member.isGetter) {
      return member.returnType != null
          ? TypeRef.fromAnnotation(ctx, file, member.returnType!)
          : CoreTypes.dynamic.ref(ctx);
    }
    return CoreTypes.function.ref(ctx);
  }

  @override
  TypeRef writeType(CompilerContext ctx, {AstNode? source}) {
    if (member.isSetter) {
      return _setterValueType(ctx, file, member.parameters) ??
          CoreTypes.dynamic.ref(ctx);
    }
    return readType(ctx, source: source);
  }

  DeferredOrOffset _offset(CompilerContext ctx) => DeferredOrOffset.lookupStatic(
    ctx,
    file,
    ownerName,
    member.isGetter
        ? MemberName.getter(member.name.lexeme).key
        : member.isSetter
        ? MemberName.setter(member.name.lexeme).key
        : member.name.lexeme,
  );

  @override
  Variable read(CompilerContext ctx, {AstNode? source}) {
    final fn = Variable(
      CoreTypes.function.ref(ctx),
      methodOffset: _offset(ctx),
    );
    if (member.isGetter) {
      // A getter reference invokes it (the member's value, not its
      // tear-off).
      return fn.invoke(ctx, null, []).result;
    }
    return fn;
  }

  @override
  Variable write(CompilerContext ctx, Variable value, {AstNode? source}) {
    if (member.isSetter) {
      return _invokeSetter(
        ctx,
        _offset(ctx),
        value,
        file,
        member.parameters,
        isMethod: true,
        source: source,
      );
    }
    throw CompileError('Cannot find value to set: $ownerName.${member.name.lexeme}', source);
  }

  @override
  StaticDispatch? staticDispatch(CompilerContext ctx, {AstNode? source}) {
    if (member.isGetter || member.isSetter) return null;
    final rt = member.returnType == null
        ? CoreTypes.dynamic.ref(ctx)
        : ctx.withTypeParameters<TypeRef>(
            file,
            null,
            member.typeParameters?.typeParameters,
            () => TypeRef.fromAnnotation(ctx, file, member.returnType!),
          );
    return StaticDispatch(
      _offset(ctx),
      AlwaysReturnType(rt, member.returnType?.question != null),
    );
  }
}

/// An instance member `receiver.name` — dynamically dispatched when the
/// member isn't statically known. [declared] carries the
/// `resolveInstanceDeclaration` result when the member was matched on the
/// enclosing class (its own declaration only); [receiver] is null only for
/// the implicit-`this` denotation, where `#this` is resolved at emission.
final class InstanceMemberDenotation extends Denotation {
  const InstanceMemberDenotation(this.receiver, this.name, {this.declared});

  final Receiver? receiver;
  final String name;
  final (TypeRef, DeclarationOrBridge)? declared;

  @override
  TypeRef readType(CompilerContext ctx, {AstNode? source}) =>
      _memberType(ctx, forSet: false, source: source) ??
      CoreTypes.dynamic.ref(ctx);

  @override
  TypeRef writeType(CompilerContext ctx, {AstNode? source}) =>
      _memberType(ctx, forSet: true, source: source) ??
      CoreTypes.dynamic.ref(ctx);

  TypeRef? _memberType(
    CompilerContext ctx, {
    required bool forSet,
    AstNode? source,
  }) {
    final receiver = this.receiver;
    final object = switch (receiver) {
      SuperReceiver(:final self) => self,
      ValueReceiver(:final value) => value,
      _ => ctx.lookupLocal('#this'),
    };
    if (object == null) return null;
    var fieldType = TypeRef.lookupFieldType(
      ctx,
      object.type,
      name,
      forSet: forSet,
      source: source,
    );
    // Extension accessors apply when the receiver's interface has no member
    // of the matching kind.
    if (fieldType == null &&
        !hasInstanceMember(ctx, object.type, name, forSet: forSet)) {
      fieldType = _extensionMemberType(ctx, object, forSet: forSet);
    }
    return fieldType;
  }

  /// The declared type of an extension member applicable to [object]'s
  /// static type, or null.
  TypeRef? _extensionMemberType(
    CompilerContext ctx,
    Variable object, {
    required bool forSet,
  }) {
    final found = resolveExtensionMember(
      ctx,
      object.type,
      name,
      getter: !forSet,
      setter: forSet,
    );
    if (found == null) return null;
    final (ext, member, bindings) = found;
    final typeParams = extBindingsMap(ext, bindings);
    if (forSet) {
      final param = member.parameters?.parameters.firstOrNull;
      if (param?.type == null) return null;
      return formalParameterAnnotationType(
        ctx,
        ext.library,
        param!,
        typeParameters: typeParams,
      );
    }
    return member.returnType == null
        ? null
        : TypeRef.fromAnnotation(
            ctx,
            ext.library,
            member.returnType!,
            typeParameters: typeParams,
          );
  }

  /// For `super.name`: the receiver at the layer declaring the concrete
  /// member, reached by LoadSuper hops from the immediate receiver.
  Variable _superOwner(CompilerContext ctx, bool forSet) {
    final self = (receiver as SuperReceiver).self;
    var owner = self;
    final mixinOwner = superMixinMemberOwner(ctx, name);
    if (mixinOwner != null) {
      return Variable.of(
        ctx,
        owner.ssa,
        mixinOwner,
        concreteTypes: [mixinOwner],
      );
    }
    var type = owner.type;
    final kind = forSet ? 1 : 0;
    while (true) {
      // Abstract re-declarations have no body — skip them like runtime
      // dispatch does; the concrete implementation lives deeper.
      final hit =
          concreteMemberDecl(ctx, type, name, kind: 2) != null ||
          concreteMemberDecl(ctx, type, name, kind: kind) != null;
      if (hit) {
        return owner;
      }
      final parent = ctx.typeSystem.superclassOf(type);
      if (parent == null) return owner;
      type = parent;
      owner = Variable.ssa(ctx, LoadSuper(ctx.svar('super'), owner.ssa), type);
    }
  }

  /// `receiver.name` where the member is declared on the enclosing class
  /// itself — the bare-identifier-in-class-body path.
  Variable _readDeclared(CompilerContext ctx, AstNode? source) {
    final ($type, decOrBridge) = declared!;
    final $this =
        ctx.lookupLocal('#this') ??
        (throw CompileError(
          'Cannot access instance member $name in a static context',
        ));

    final refName = _refNameOf(name);
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
            name: refName,
          ),
          callingConvention: CallingConvention.static,
        )..implicitReceiver = $this;
      }
    }

    final resvar = ctx.svar(name);
    ctx.pushOp(
      LoadPropertyDynamic(resvar, $this.ssa, name, callerLibrary: ctx.library),
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
          rep: ValueRep.boxed,
          methodOffset: DeferredOrOffset(
            file: ctx.library,
            className: ctx.currentClassName!,
            name: refName,
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
          rep: ValueRep.boxed,
          methodOffset: DeferredOrOffset(
            file: ctx.library,
            className: ctx.currentClassName!,
            name: refName,
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
      rep: ValueRep.boxed,
    );
  }

  /// `super.name` read — method reads tear off bound to the super receiver.
  Variable _readSuper(CompilerContext ctx, AstNode? source) {
    final owner = _superOwner(ctx, false);
    // A method member read is a tear-off bound to the super receiver.
    final memberDecl =
        ctx.instanceDeclarationsMap[owner.type.file]?[owner
            .type
            .name]?[name];
    if (memberDecl is MethodDeclaration &&
        !memberDecl.isGetter &&
        !memberDecl.isSetter) {
      return (Variable(
            CoreTypes.function.ref(ctx),
            methodOffset: DeferredOrOffset(
              file: owner.type.file,
              className: owner.type.name,
              name: name,
            ),
            callingConvention: CallingConvention.static,
          )..implicitReceiver = owner)
          .tearOff(ctx);
    }
    if (ctx
            .topLevelDeclarationsMap[owner.type.file]?[owner.type.name]
            ?.isBridge ??
        false) {
      return GetTarget.read(ctx, owner, name, source: source);
    }
    return SuperGetterCall(
      owner,
      name,
      readType(ctx, source: source),
    ).emit(ctx);
  }

  /// `super.name = v` — write through the owning layer's setter; a bridged
  /// owner falls back to the ambient setter machinery.
  Variable _writeSuper(CompilerContext ctx, Variable value, AstNode? source) {
    final owner = _superOwner(ctx, true);
    if (ctx
            .topLevelDeclarationsMap[owner.type.file]?[owner.type.name]
            ?.isBridge ??
        false) {
      return SetTarget.write(ctx, owner, name, value, source: source);
    }
    return SuperSetterCall(
      owner,
      name,
      writeType(ctx, source: source),
    ).emit(ctx, value);
  }

  @override
  Variable read(CompilerContext ctx, {AstNode? source}) {
    if (receiver is SuperReceiver) {
      return _readSuper(ctx, source);
    }
    if (declared != null) {
      return _readDeclared(ctx, source);
    }
    final r = receiver;
    final object = r is ValueReceiver
        ? r.value
        : r is ExtensionApplicationReceiver
        ? r.value
        : ctx.lookupLocal('#this');
    if (object == null) {
      throw CompileError('Cannot access instance member $name', source);
    }
    return GetTarget.read(ctx, object.boxIfNeeded(ctx, source), name);
  }

  @override
  Variable write(CompilerContext ctx, Variable value, {AstNode? source}) {
    if (receiver is SuperReceiver) {
      return _writeSuper(ctx, value, source);
    }
    final r = receiver;
    var object = r is ValueReceiver
        ? r.value
        : r is ExtensionApplicationReceiver
        ? r.value
        : ctx.lookupLocal('#this');
    if (object == null) {
      throw CompileError('Cannot access instance member $name', source);
    }
    if (declared != null) {
      // A member declared on the enclosing class itself.
      final fieldType = _resolveInstanceFieldType(
        ctx,
        name,
        forSet: true,
        source: source,
      )!;
      return SetTarget.writeDeclared(
        ctx,
        object,
        name,
        value,
        fieldType,
        source: source,
      );
    }
    return SetTarget.write(ctx, object, name, value, source: source);
  }

  @override
  StaticDispatch? staticDispatch(CompilerContext ctx, {AstNode? source}) {
    final r = receiver;
    final object = r is ValueReceiver
        ? r.value
        : r is ExtensionApplicationReceiver
        ? r.value
        : null;
    if (object == null) return null;
    final exact = object.exactType;
    final actualType =
        exact ??
        (object.concreteTypes.length == 1 ? object.concreteTypes[0] : null);
    if (actualType == null) return null;
    // If we know the concrete type of the object, we can easily optimize to a static call
    final returnType = AlwaysReturnType.fromInstanceMethod(
      ctx,
      actualType,
      name,
      CoreTypes.dynamic.ref(ctx),
    );

    // The statically-fixed target is the nearest class at-or-above the
    // receiver type declaring the method. An exact allocation type needs
    // no override check; a merely-declared type does.
    for (final link in [
      actualType,
      ...ctx.typeSystem.superclassChain(actualType),
    ]) {
      final methodsMap =
          ctx.instanceDeclarationPositions[link.file]?[link.name]?[2];
      if (methodsMap?.containsKey(name) != true) continue;
      if (exact == null &&
          ctx.memberOverriddenInSubclass(
            actualType.file,
            actualType.name,
            name,
          )) {
        return null;
      }
      return StaticDispatch(
        DeferredOrOffset(file: link.file, offset: methodsMap![name]),
        returnType,
      );
    }
    // An inherited method needs the owner's field view as its receiver.
    // Dynamic dispatch resolves that view as well as the method offset.
    return null;
  }
}

/// A member of an extension applied through the `E(x)` receiver or
/// resolved as an implicit extension member — or a static/own member when
/// [receiver] is null.
final class ExtensionMemberDenotation extends Denotation {
  const ExtensionMemberDenotation(
    this.ext,
    this.member, {
    this.onBindings = const [],
    this.receiver,
    this.applied = false,
  });

  final EvalExtension ext;
  final MethodDeclaration member;
  final List<TypeRef> onBindings;
  final Variable? receiver;

  /// Whether this denotation came from an application (`E(x)` or an
  /// applicable-extension resolution) — writes then convert the value to
  /// the setter's parameter type and pass type arguments.
  final bool applied;

  @override
  TypeRef readType(CompilerContext ctx, {AstNode? source}) {
    if (member.isGetter) {
      return AlwaysReturnType.fromAnnotation(
            ctx,
            ext.library,
            member.returnType,
            CoreTypes.dynamic.ref(ctx),
          ).type ??
          CoreTypes.dynamic.ref(ctx);
    }
    return CoreTypes.function.ref(ctx);
  }

  @override
  TypeRef writeType(CompilerContext ctx, {AstNode? source}) {
    if (member.isSetter) {
      return _setterValueType(ctx, ext.library, member.parameters) ??
          CoreTypes.dynamic.ref(ctx);
    }
    return readType(ctx, source: source);
  }

  @override
  Variable read(CompilerContext ctx, {AstNode? source}) {
    final recv = receiver;
    final offset = DeferredOrOffset(
      file: ext.library,
      name: ext.memberKey(member),
    );
    if (member.isStatic || recv == null) {
      // Static members resolve through the extension's namespace — no
      // receiver.
      if (member.isGetter) {
        final resvar = ctx.svar(member.isStatic ? 'call_result' : 'getter_result');
        ctx.pushOp(Call(offset, const [], result: resvar));
        return Variable.of(
          ctx,
          resvar,
          (AlwaysReturnType.fromAnnotation(
                ctx,
                ext.library,
                member.returnType,
                CoreTypes.dynamic.ref(ctx),
              ).type ??
              CoreTypes.dynamic.ref(ctx)),
          rep: ValueRep.boxed,
        );
      }
      if (member.isSetter) {
        throw CompileError(
          'Cannot read extension setter ${ext.name}.${member.name.lexeme}',
          source,
        );
      }
      return Variable(
        CoreTypes.function.ref(ctx),
        methodOffset: offset,
        callingConvention: CallingConvention.static,
      );
    }
    if (member.isGetter) {
      return invokeExtensionGetter(
        ctx,
        recv,
        ext,
        member,
        onBindings.isNotEmpty
            ? onBindings
            : matchExtensionOn(ctx, recv.type, ext) ?? const [],
      );
    }
    if (member.isSetter) {
      throw CompileError(
        'Cannot read extension setter ${ext.name}.${member.name.lexeme}',
        source,
      );
    }
    return Variable(
      CoreTypes.function.ref(ctx),
      methodOffset: offset,
      methodReturnType: AlwaysReturnType.fromAnnotation(
        ctx,
        ext.library,
        member.returnType,
        CoreTypes.dynamic.ref(ctx),
      ),
      callingConvention: CallingConvention.static,
    )..implicitReceiver = recv;
  }

  @override
  Variable write(CompilerContext ctx, Variable value, {AstNode? source}) {
    if (!member.isSetter) {
      throw CompileError(
        'Extension ${ext.name} has no setter ${member.name.lexeme}',
        source,
      );
    }
    final recv = receiver;
    if (applied && recv != null) {
      // An applied setter (`E(x).s = v` or `x.s = v` through an applicable
      // extension) converts to the parameter's declared type.
      final paramType =
          member.parameters?.parameters.firstOrNull?.type == null
          ? null
          : formalParameterAnnotationType(
              ctx,
              ext.library,
              member.parameters!.parameters.first,
              typeParameters: extBindingsMap(ext, onBindings),
            );
      final arg = paramType == null
          ? value.boxIfNeeded(ctx)
          : convertForAssignment(
              ctx,
              value,
              paramType,
              representation: MachineRepresentation.object,
              source: source,
              description:
                  'Cannot assign ${value.type} to setter '
                  '${ext.name}.${member.name.lexeme} on ${recv.type}',
            );
      ctx.pushOp(
        Call(
          DeferredOrOffset(file: ext.library, name: ext.memberKey(member)),
          [recv.boxIfNeeded(ctx).ssa, arg.ssa],
          result: ctx.svar('setter_result'),
          typeArguments:
              extensionCallTypeArguments(
                ctx,
                ext,
                member,
                onBindings,
                const {},
              ) ??
              const [],
        ),
      );
      // The assignment's value is the value as converted for the setter's
      // parameter — e.g. an implicit `.call` tear-off.
      return arg;
    }
    // Box into fresh slots: `value` flows on as the assignment result and
    // must keep its unboxed representation.
    final boxedValue = value.boxIntoFreshSlot(ctx);
    // Static members take no receiver argument.
    final args = member.isStatic || recv == null
        ? [boxedValue.ssa]
        : [recv.boxIfNeeded(ctx).ssa, boxedValue.ssa];
    ctx.pushOp(
      Call(
        DeferredOrOffset(file: ext.library, name: ext.memberKey(member)),
        args,
        result: ctx.svar('setter_result'),
      ),
    );
    return value;
  }
}

/// A `Type` literal — `C` evaluates to the `Type` object (or its
/// constructor tear-off variable). [constructorKey] is the name used in
/// [DeferredOrOffset] to resolve the constructor (e.g. `ClassName.` or, for
/// bridged enums, `EnumName#wrap`).
final class TypeLiteralDenotation extends Denotation {
  const TypeLiteralDenotation(this.type, this.constructorKey, {this.declaration});

  final TypeRef type;
  final String constructorKey;

  /// The declaration the literal was built from — the constructor path
  /// inspects aliases and class generics through it.
  final Declaration? declaration;

  @override
  TypeRef readType(CompilerContext ctx, {AstNode? source}) =>
      CoreTypes.type.ref(ctx);

  @override
  Variable read(CompilerContext ctx, {AstNode? source}) =>
      _typeLiteral(ctx, type, constructorKey);

  @override
  Variable write(CompilerContext ctx, Variable value, {AstNode? source}) =>
      throw CompileError('Cannot assign to a type literal', source);

  @override
  StaticDispatch? staticDispatch(CompilerContext ctx, {AstNode? source}) =>
      StaticDispatch(
        DeferredOrOffset(file: type.file, name: constructorKey),
        AlwaysReturnType(type, false),
      );
}

/// A type parameter in scope — evaluates to its bound `Type` object.
/// (`_` is a wildcard type parameter: non-binding.)
final class TypeParameterDenotation extends Denotation {
  const TypeParameterDenotation(this.typeParameter);

  final TypeRef typeParameter;

  @override
  TypeRef readType(CompilerContext ctx, {AstNode? source}) =>
      CoreTypes.type.ref(ctx);

  @override
  Variable read(CompilerContext ctx, {AstNode? source}) => Variable.ssa(
    ctx,
    LoadTypeParameter(
      ctx.svar('type'),
      ctx.runtimeTypes.idOf(typeParameter),
    ),
    CoreTypes.type.ref(ctx),
    concreteTypes: [typeParameter],
  );

  @override
  Variable write(CompilerContext ctx, Variable value, {AstNode? source}) =>
      throw CompileError('Cannot assign to a type parameter', source);
}

/// An import prefix. Member access resolves through [children].
final class PrefixDenotation extends Denotation {
  const PrefixDenotation(this.prefix, this.children);

  final String prefix;
  final Map<String, DeclarationOrBridge> children;

  @override
  TypeRef readType(CompilerContext ctx, {AstNode? source}) =>
      throw const PrefixError();

  @override
  Variable read(CompilerContext ctx, {AstNode? source}) =>
      throw const PrefixError();

  @override
  Variable write(CompilerContext ctx, Variable value, {AstNode? source}) =>
      throw CompileError('Cannot assign to prefix $prefix', source);

  /// `prefix.name` — resolves the child and produces its denotation.
  Denotation memberAccess(
    CompilerContext ctx,
    String name, {
    required bool forSet,
    AstNode? source,
  }) {
    if (name == 'loadLibrary') {
      final stub = _deferredLoadLibrary(ctx, prefix);
      if (stub != null) return _SyntheticDenotation(stub);
    }
    final child =
        children[forSet ? MemberName.setter(name).key : MemberName.getter(name).key] ??
        children[name] ??
        children[name.split('.')[0]] ??
        (throw CompileError(
          "'$name' isn't defined for the prefix '$prefix'",
          source,
        ));
    return _denotationOf(ctx, child, name, forSet: forSet);
  }
}

/// A member denotation already materialized as a [Variable] — used for
/// synthetic members like a deferred prefix's `loadLibrary` stub.
final class _SyntheticDenotation extends Denotation {
  const _SyntheticDenotation(this.value);

  final Variable value;

  @override
  TypeRef readType(CompilerContext ctx, {AstNode? source}) => value.type;

  @override
  Variable read(CompilerContext ctx, {AstNode? source}) => value;

  @override
  Variable write(CompilerContext ctx, Variable v, {AstNode? source}) =>
      throw CompileError('Cannot assign to ${value.name}', source);
}

/// An enum value — `E.v1` or a bare value name inside the enum body.
final class EnumValueDenotation extends Denotation {
  const EnumValueDenotation(this.enumType, this.index, this.name);

  final TypeRef enumType;
  final int index;
  final String name;

  @override
  TypeRef readType(CompilerContext ctx, {AstNode? source}) => enumType;

  @override
  Variable read(CompilerContext ctx, {AstNode? source}) => Variable.ssa(
    ctx,
    LoadGlobal(ctx.svar(name), index),
    enumType,
    rep: ValueRep.boxed,
  );

  @override
  Variable write(CompilerContext ctx, Variable value, {AstNode? source}) =>
      throw CompileError('Cannot assign to enum value $name', source);
}

/// An extension used as a namespace — `E` evaluates to a marker variable
/// whose member accesses resolve through the extension's members.
final class ExtensionNamespaceDenotation extends Denotation {
  const ExtensionNamespaceDenotation(this.ext, this.markerName);

  final EvalExtension ext;
  final String markerName;

  @override
  TypeRef readType(CompilerContext ctx, {AstNode? source}) =>
      CoreTypes.type.ref(ctx);

  @override
  Variable read(CompilerContext ctx, {AstNode? source}) {
    // `E` as an expression is the extension's namespace: `E.m(recv, ...)`
    // (explicit application) and `E.staticM(...)` resolve through it. The
    // pseudo-type `E` exists only in the declarations map, never as a class.
    final extType = TypeRef.unresolved(ext.library, ext.name);
    return Variable(
      CoreTypes.type.ref(ctx),
      concreteTypes: [extType],
      methodOffset: DeferredOrOffset(
        file: ext.library,
        name: '${ext.name}.',
      ),
      callingConvention: CallingConvention.static,
    );
  }

  @override
  Variable write(CompilerContext ctx, Variable value, {AstNode? source}) =>
      throw CompileError('Cannot assign to extension ${ext.name}', source);
}

/// Maps a scope-visible declaration to its denotation.
Denotation _denotationOf(
  CompilerContext ctx,
  DeclarationOrBridge decOrBridge,
  String name, {
  required bool forSet,
}) {
  if (decOrBridge.isBridge) {
    return BridgeDenotation(decOrBridge, name);
  }
  final decl = decOrBridge.declaration!;
  if (decl is VariableDeclaration) {
    return GlobalDenotation(
      decOrBridge.sourceLib,
      decl.name.lexeme,
      displayName: name.split('.').last,
    );
  }
  if (decl is FunctionDeclaration || decl is ConstructorDeclaration) {
    return FunctionDenotation(decOrBridge, name);
  }
  if (decl is ExtensionDeclaration) {
    final ext = ctx.extensions.firstWhere(
      (e) => e.declaration == decl,
      orElse: () => EvalExtension(
        decOrBridge.sourceLib,
        decl,
        declarationName(decl),
      ),
    );
    return ExtensionNamespaceDenotation(ext, name);
  }
  final type = decl is TypeAlias && decl is! ClassTypeAlias
      ? resolveTypeAlias(ctx, decOrBridge.sourceLib, decl)
      : TypeRef.lookupDeclaration(ctx, decOrBridge.sourceLib, decl);
  return TypeLiteralDenotation(type, '${declarationName(decl)}.', declaration: decl);
}

/// A bridge-visible entity (external class, method, or accessor).
final class BridgeDenotation extends Denotation {
  const BridgeDenotation(this.target, this.name);

  final DeclarationOrBridge target;
  final String name;

  @override
  TypeRef readType(CompilerContext ctx, {AstNode? source}) {
    final bridge = target.bridge;
    if (bridge is BridgeClassDef || bridge is BridgeEnumDef) {
      return CoreTypes.type.ref(ctx);
    }
    return CoreTypes.function.ref(ctx);
  }

  @override
  Variable read(CompilerContext ctx, {AstNode? source}) =>
      _declarationToVariable(target, name, ctx, source);

  @override
  Variable write(CompilerContext ctx, Variable value, {AstNode? source}) =>
      throw CompileError('Cannot assign to bridged $name', source);
}

/// The reference tail for a possibly qualified name — strips a leading
/// qualifier segment for prefix member paths like `p.C.ctor` → `C.ctor`.
String _refNameOf(String name) {
  final split = name.split('.');
  if (split.length > 2) {
    return split.sublist(1).join('.');
  }
  return name;
}

/// The single name-resolution cascade for a bare identifier, in Dart's
/// lexical order (locals → extension members → anonymous receiver →
/// enclosing-class members → type parameters → library scope → implicit
/// `this`). [forSet] selects the write view of each scope.
Denotation resolveIdentifier(
  CompilerContext ctx,
  String name, {
  required bool forSet,
  AstNode? source,
}) {
  // 1 — local bindings, innermost scope first.
  final binding = ctx.lookupBinding(name);
  if (binding != null) return LocalDenotation(binding);

  final $this = ctx.lookupLocal('#this');
  final currentExtension = ctx.currentExtension;

  // 2 — inside an extension body: the extension's own members (instance
  // members apply with `#this` as the receiver; statics and static fields
  // behave like namespace members).
  if (currentExtension is ExtensionDeclaration) {
    final ext = ctx.extensions.firstWhereOrNull(
      (e) => e.declaration == currentExtension,
    );
    if (ext != null) {
      for (final member in ext.members) {
        if (member is FieldDeclaration) {
          if (member.isStatic &&
              member.fields.variables.any((v) => v.name.lexeme == name)) {
            return GlobalDenotation(
              ext.library,
              '${ext.name}.$name',
              displayName: name,
            );
          }
          continue;
        }
        if (member is! MethodDeclaration || member.name.lexeme != name) {
          continue;
        }
        // The first same-named member decides.
        if (member.isStatic) {
          if (forSet) {
            if (member.isSetter) {
              return ExtensionMemberDenotation(ext, member);
            }
            break;
          }
          if (member.isGetter) {
            return ExtensionMemberDenotation(ext, member);
          }
          if (member.isSetter) break;
          return ExtensionMemberDenotation(ext, member);
        }
        if (forSet) {
          if (member.isSetter) {
            return ExtensionMemberDenotation(ext, member, receiver: $this);
          }
          // A same-named non-setter member shadows the `on` type's members.
          break;
        }
        if ($this == null) break;
        if (member.isGetter) {
          return ExtensionMemberDenotation(ext, member, receiver: $this);
        }
        if (member.isSetter) break;
        return ExtensionMemberDenotation(ext, member, receiver: $this);
      }
    }
  }

  // 3 — inside an anonymous-method body: members of the anonymous receiver.
  final anonymousReceiver = ctx.anonymousThisReceiver;
  final receiverVar = anonymousReceiver == null
      ? null
      : $this ?? anonymousReceiver;
  if (receiverVar != null &&
      _hasReceiverMember(ctx, receiverVar, name, forSet: forSet)) {
    return InstanceMemberDenotation(ValueReceiver(receiverVar), name);
  }

  // 4 — members the enclosing class itself declares (not inherited), then
  // enum values of an enclosing enum, then statics of the class and its
  // transitive mixins.
  if (anonymousReceiver == null && ctx.currentClass != null) {
    final instanceDeclaration = resolveInstanceDeclaration(
      ctx,
      ctx.enclosingLibrary ?? ctx.library,
      ctx.currentClassName!,
      name,
    );
    if (instanceDeclaration != null &&
        instanceDeclaration.$1.name == ctx.currentClassName &&
        instanceDeclaration.$1.file ==
            (ctx.enclosingLibrary ?? ctx.library)) {
      return InstanceMemberDenotation(null, name, declared: instanceDeclaration);
    }

    if (!forSet) {
      // A bare identifier inside an enum member can name one of the enum's
      // own values.
      final currentDecl = ctx.memberDeclaringClass ?? ctx.currentClass;
      if (currentDecl is EnumDeclaration) {
        final enumType = TypeRef.lookupDeclaration(
          ctx,
          ctx.library,
          currentDecl,
        );
        final gIndex =
            ctx.enumValueIndices[ctx.library]?[enumType.name]?[name];
        if (gIndex != null) {
          return EnumValueDenotation(enumType, gIndex, name);
        }
      }
    }

    final staticDeclaration = resolveScopedStaticDeclaration(
      ctx,
      name,
      forSet: forSet,
    );
    if (staticDeclaration != null &&
        staticDeclaration.$1.declaration != null) {
      final (staticDecl, scopeFile, scopeName) = staticDeclaration;
      final staticDec = staticDecl.declaration!;
      if (staticDec is MethodDeclaration) {
        if ((forSet && staticDec.isSetter) || (!forSet && staticDec.isGetter) ||
            (!staticDec.isGetter && !staticDec.isSetter)) {
          return StaticMemberDenotation(scopeFile, scopeName, staticDec);
        }
      } else if (staticDec is VariableDeclaration) {
        return GlobalDenotation(
          scopeFile,
          '$scopeName.${staticDec.name.lexeme}',
          displayName: staticDec.name.lexeme,
        );
      }
    }
  }

  // 5 — type parameters in scope (`_` is non-binding).
  final typeParameter = ctx.typeScopes[ctx.library]?[name];
  if (typeParameter != null && name != '_') {
    return TypeParameterDenotation(typeParameter);
  }

  // 6 — library scope: visible declarations including prefixes and
  // accessor keys.
  final firstSeg = name.split('.').first;
  final topEntry = ctx.visibleDeclarations[ctx.library]![firstSeg];
  if (topEntry != null &&
      topEntry.declaration == null &&
      topEntry.children != null) {
    final prefix = PrefixDenotation(firstSeg, topEntry.children!);
    if (name == firstSeg) return prefix;
    return prefix.memberAccess(
      ctx,
      name.substring(firstSeg.length + 1),
      forSet: forSet,
      source: source,
    );
  }
  DeclarationOrBridge? declarationValue;
  try {
    declarationValue = _lookupVisibleValue(ctx, name, source, forSet: forSet);
  } on CompileError {
    declarationValue = null;
  }
  if (declarationValue != null) {
    return _denotationOf(ctx, declarationValue, name, forSet: forSet);
  }

  // 7 — implicit `this`: inherited instance members, then applicable
  // extension members.
  if (anonymousReceiver == null &&
      (currentExtension != null || ctx.currentClass != null)) {
    final t = $this;
    if (t != null &&
        _hasReceiverMember(ctx, t, name, forSet: forSet, source: source)) {
      return InstanceMemberDenotation(ValueReceiver(t), name);
    }
  }

  throw CompileError('Could not find declaration "$name"', source);
}

/// Resolves `receiver.name` to the member denotation.
Denotation resolveMemberAccess(
  CompilerContext ctx,
  Receiver receiver,
  String name, {
  required bool forSet,
  AstNode? source,
}) {
  switch (receiver) {
    case PrefixReceiver(:final prefix):
      return prefix.memberAccess(ctx, name, forSet: forSet, source: source);
    case ExtensionApplicationReceiver():
      // Member resolution pinned to the applied extension's members: a
      // getter for reads, a setter for writes, a method tear-off otherwise.
      final member = forSet
          ? extensionMember(receiver.ext, name, setter: true)
          : extensionMember(receiver.ext, name, getter: true) ??
                extensionMember(receiver.ext, name);
      if (member == null) {
        throw CompileError(
          'Extension ${receiver.ext.name} has no '
          '${forSet ? 'setter' : 'member'} $name',
          source,
        );
      }
      return ExtensionMemberDenotation(
        receiver.ext,
        member,
        onBindings: receiver.onBindings,
        receiver: receiver.value,
        applied: true,
      );
    case SuperReceiver():
      return InstanceMemberDenotation(receiver, name);
    case ValueReceiver(:final value):
      return InstanceMemberDenotation(ValueReceiver(value), name);
    case TypeLiteralReceiver(:final type, :final value):
      // `E.member` — access through the extension namespace.
      final ext = extensionForType(ctx, type);
      if (ext != null) {
        final member = ext.members
            .whereType<MethodDeclaration>()
            .firstWhereOrNull((m) => m.name.lexeme == name);
        if (member == null) {
          throw CompileError(
            'Extension member not found: ${ext.name}.$name',
            source,
          );
        }
        return ExtensionMemberDenotation(ext, member);
      }
      if (type.isTypeParameter) {
        // `T.member` is an instance access on T's runtime `Type` object,
        // not a static access — dispatch dynamically.
        return InstanceMemberDenotation(ValueReceiver(value), name);
      }
      final superclass = ctx.typeSystem.superclassOf(type);
      if (!forSet && superclass != null && superclass.isSpec(CoreTypes.enumType)) {
        final gIndex = ctx.enumValueIndices[type.file]?[type.name]?[name];
        if (gIndex != null) {
          return EnumValueDenotation(type, gIndex, name);
        }
      }
      final decOrBridge = ctx.topLevelDeclarationsMap[type.file]?[type.name];
      if (decOrBridge != null && decOrBridge.isBridge) {
        return _StaticBridgeDenotation(decOrBridge, type, name);
      }
      final fqName = '${type.name}.${ctorNameOf(name)}';
      return _TypeMemberDenotation(type, fqName, name);
  }
}

/// A bridged class's static member (`C.name` where `C` is external).
final class _StaticBridgeDenotation extends Denotation {
  const _StaticBridgeDenotation(this.owner, this.type, this.name);

  final DeclarationOrBridge owner;
  final TypeRef type;
  final String name;

  @override
  TypeRef readType(CompilerContext ctx, {AstNode? source}) {
    final br = owner.bridge;
    if (br is BridgeClassDef) {
      final getter = br.getters[name];
      final field = br.fields[name];
      if (getter != null) {
        return TypeRef.fromBridgeAnnotation(
          ctx,
          getter.functionDescriptor.returns,
        );
      }
      if (field != null) {
        return TypeRef.fromBridgeAnnotation(ctx, field.type);
      }
    }
    return CoreTypes.dynamic.ref(ctx);
  }

  @override
  Variable read(CompilerContext ctx, {AstNode? source}) {
    final br = owner.bridge;
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
            ctx.bridgeStaticFunctionIndices[type.file]!['${type.name}.${MemberName.getter(name).key}']!,
            [],
          ),
          type,
          rep: ValueRep.boxed,
        );
      }
      throw CompileError(
        'Cannot find external getter or field: $name on $type',
        source,
      );
    }
    throw CompileError('Cannot access bridged member $name', source);
  }

  @override
  Variable write(CompilerContext ctx, Variable value, {AstNode? source}) =>
      throw CompileError('Cannot set bridged member $name', source);
}

/// A static member or constructor of a non-bridge type (`C.name`) — covers
/// getters, methods (tear-offs), static fields, and constructor
/// tear-off errors.
final class _TypeMemberDenotation extends Denotation {
  const _TypeMemberDenotation(this.type, this.fqName, this.name);

  final TypeRef type;
  final String fqName;
  final String name;

  @override
  TypeRef readType(CompilerContext ctx, {AstNode? source}) {
    final accessor =
        ctx
            .topLevelDeclarationsMap[type
                .file]?[MemberName.getter(fqName).key]
            ?.declaration;
    if (accessor is MethodDeclaration) {
      return accessor.returnType != null
          ? TypeRef.fromAnnotation(ctx, type.file, accessor.returnType!)
          : CoreTypes.dynamic.ref(ctx);
    }
    final member =
        ctx.topLevelDeclarationsMap[type.file]?[fqName]?.declaration;
    if (member is MethodDeclaration &&
        !member.isGetter &&
        !member.isSetter) {
      return CoreTypes.function.ref(ctx);
    }
    return resolveGlobalType(ctx, type.file, fqName);
  }

  @override
  TypeRef writeType(CompilerContext ctx, {AstNode? source}) {
    final setter =
        ctx
            .topLevelDeclarationsMap[type
                .file]?[MemberName.setter(fqName).key]
            ?.declaration;
    if (setter is MethodDeclaration && setter.isSetter) {
      return _setterValueType(ctx, type.file, setter.parameters) ??
          CoreTypes.dynamic.ref(ctx);
    }
    return resolveGlobalType(ctx, type.file, fqName);
  }

  @override
  Variable read(CompilerContext ctx, {AstNode? source}) {
    // Static accessors register under `*g`/`*s` keys — a getter reference
    // invokes it.
    final getterMember =
        ctx.topLevelDeclarationsMap[type
            .file]?[MemberName.getter(fqName).key];
    final member =
        getterMember ?? ctx.topLevelDeclarationsMap[type.file]![fqName];
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
      final memberOffset = DeferredOrOffset(
        file: type.file,
        name: memberDecl is MethodDeclaration && memberDecl.isGetter
            ? MemberName.getter(fqName).key
            : fqName,
      );
      final fn = Variable(
        CoreTypes.function.ref(ctx),
        methodOffset: memberOffset,
        callingConvention: CallingConvention.static,
      );
      if (memberDecl is MethodDeclaration && memberDecl.isGetter) {
        return fn.invoke(ctx, null, []).result;
      }
      // Static method tear-off.
      return fn;
    }
    return _loadGlobalVariable(ctx, type.file, fqName, name);
  }

  @override
  Variable write(CompilerContext ctx, Variable value, {AstNode? source}) {
    // A static setter (`C.x*s`) takes precedence over a static field
    // global of the same base name.
    final setter = ctx
        .topLevelDeclarationsMap[type
            .file]?[MemberName.setter(fqName).key]
        ?.declaration;
    if (setter is MethodDeclaration && setter.isSetter) {
      return _invokeSetter(
        ctx,
        DeferredOrOffset(
          file: type.file,
          name: MemberName.setter(fqName).key,
        ),
        value,
        type.file,
        setter.parameters,
        isMethod: true,
        source: source,
      );
    }
    return storeGlobalBinding(ctx, type.file, fqName, value, source);
  }
}

/// Builds the [Receiver] for a member-access or invocation target
/// expression. Identifiers, prefixed identifiers, and property accesses go
/// through references; `super` becomes a [SuperReceiver]; `E(x)` becomes
/// an [ExtensionApplicationReceiver]; the cascade target and everything
/// else become a [ValueReceiver].
Receiver compileReceiver(CompilerContext ctx, Expression target) {
  if (target is SuperExpression) {
    return SuperReceiver(
      ctx.lookupLocal('#this') ??
          (throw CompileError('Invalid super call', target)),
    );
  }
  if (target is SimpleIdentifier) {
    final denotation = resolveIdentifier(
      ctx,
      target.name,
      forSet: false,
      source: target,
    );
    return switch (denotation) {
      PrefixDenotation p => PrefixReceiver(p),
      TypeLiteralDenotation t => TypeLiteralReceiver(
        t.type,
        t.read(ctx, source: target),
      ),
      ExtensionNamespaceDenotation e => TypeLiteralReceiver(
        TypeRef.unresolved(e.ext.library, e.ext.name),
        e.read(ctx, source: target),
      ),
      _ => ValueReceiver(denotation.read(ctx, source: target)),
    };
  }
  if (target is PrefixedIdentifier) {
    final denotation = resolveIdentifier(
      ctx,
      '${target.prefix.name}.${target.identifier.name}',
      forSet: false,
      source: target,
    );
    return switch (denotation) {
      TypeLiteralDenotation t => TypeLiteralReceiver(
        t.type,
        t.read(ctx, source: target),
      ),
      ExtensionNamespaceDenotation e => TypeLiteralReceiver(
        TypeRef.unresolved(e.ext.library, e.ext.name),
        e.read(ctx, source: target),
      ),
      _ => ValueReceiver(denotation.read(ctx, source: target)),
    };
  }
  return ValueReceiver(compileExpression(target, ctx));
}

/// Field-wise equality for shadow comparison of dispatch results.
bool _staticDispatchEquals(StaticDispatch? a, StaticDispatch? b) {
  if (a == null || b == null) return a == b;
  bool offsetEq(DeferredOrOffset x, DeferredOrOffset y) =>
      x.offset == y.offset &&
      x.file == y.file &&
      x.name == y.name &&
      x.className == y.className &&
      x.methodType == y.methodType;
  TypeRef? rt(ReturnType r) =>
      r is AlwaysReturnType ? r.type : null;
  return offsetEq(a.offset, b.offset) &&
      (a.returnType == b.returnType ||
          (rt(a.returnType) != null &&
              rt(a.returnType) == rt(b.returnType)));
}
