import 'helpers/global.dart';
import 'package:dart_eval/src/eval/compiler/variable/binding.dart';
import 'helpers/conversion.dart';
import 'helpers/tearoff.dart';
import 'member/call_signature.dart';
import 'member/member.dart';
import 'member/member_name.dart';
import 'member/resolved_member.dart';
import 'backend/representation.dart' show MachineRepresentation;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/bridge/declaration.dart';
import 'invocation/deferred.dart';
import 'invocation/targets.dart';
import 'invocation/bound_call.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/ir/types.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/ir/bridge.dart';
import 'package:collection/collection.dart';
import 'package:dart_eval/src/eval/ir/globals.dart';
import 'package:dart_eval/src/eval/ir/objects.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/compiler/expression/identifier.dart';
import 'package:dart_eval/src/eval/compiler/helpers/extension.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'values/abi.dart';
import 'invocation/accessors.dart';
import 'variable/value_facts.dart';
import 'reference.dart';

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
  Variable read(
    CompilerContext ctx, {
    AstNode? source,
    TypeRef? boundContext,
    List<TypeRef>? typeArguments,
  }) => instantiateRuntimeCallable(
    ctx,
    _read(
      ctx,
      source: source,
      boundContext: boundContext,
      typeArguments: typeArguments,
    ),
    boundContext: boundContext,
    typeArguments: typeArguments,
  );

  Variable _read(
    CompilerContext ctx, {
    AstNode? source,
    TypeRef? boundContext,
    List<TypeRef>? typeArguments,
  });

  /// Emits `this denotation = value`; returns the stored variable.
  Variable write(CompilerContext ctx, Variable value, {AstNode? source});

  /// Compile-time call dispatch when this denotation is invoked directly.
  CallTarget? call(CompilerContext ctx, {AstNode? source}) => null;
}

/// The special receivers a member access can target.
sealed class Receiver {
  const Receiver();

  /// The runtime receiver, absent for compile-time namespaces.
  Variable? get value => switch (this) {
    ValueReceiver(:final value) => value,
    SuperReceiver(:final self) => self,
    TypeLiteralReceiver(:final value) => value,
    ExtensionApplicationReceiver(:final value) => value,
    ExtensionNamespaceReceiver() => null,
    PrefixReceiver() => null,
  };

  /// Retains the receiver's meaning when a null guard narrows its value.
  Receiver withValue(Variable value) => switch (this) {
    ValueReceiver() => ValueReceiver(value),
    SuperReceiver() => SuperReceiver(value),
    TypeLiteralReceiver(:final type) => TypeLiteralReceiver(type, value),
    ExtensionApplicationReceiver(:final ext, :final onBindings) =>
      ExtensionApplicationReceiver(ext, onBindings, value),
    ExtensionNamespaceReceiver() => this,
    PrefixReceiver() => this,
  };
}

/// A member access on an ordinary value: `v.name`.
final class ValueReceiver extends Receiver {
  const ValueReceiver(this.value);

  @override
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
  const TypeLiteralReceiver(this.type, [this.value]);

  final TypeRef type;
  @override
  final Variable? value;
}

/// `E(x).name` — member resolution pinned to [ext]'s members.
final class ExtensionApplicationReceiver extends Receiver {
  const ExtensionApplicationReceiver(this.ext, this.onBindings, this.value);

  final EvalExtension ext;
  final List<TypeRef> onBindings;
  @override
  final Variable value;
}

/// `E.name` — an extension namespace, with no runtime value.
final class ExtensionNamespaceReceiver extends Receiver {
  const ExtensionNamespaceReceiver(this.ext);

  final EvalExtension ext;
}

/// `p.name` — member access into an import prefix's namespace.
final class PrefixReceiver extends Receiver {
  const PrefixReceiver(this.prefix);

  final PrefixDenotation prefix;
}

/// Classifies a receiver value for member access. [pin] is the
/// explicit-application pin `E(receiver)` imposes on member resolution.
Receiver receiverOf(CompilerContext ctx, Variable v, {BoundExtension? pin}) {
  if (pin case final bound?) {
    return ExtensionApplicationReceiver(bound.ext, bound.onBindings, v);
  }
  final denoted = v.denotedType;
  if (denoted != null) return TypeLiteralReceiver(denoted, v);
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
      binding.declaredType;

  @override
  Variable _read(
    CompilerContext ctx, {
    AstNode? source,
    TypeRef? boundContext,
    List<TypeRef>? typeArguments,
  }) => binding.read(ctx);

  @override
  Variable write(CompilerContext ctx, Variable value, {AstNode? source}) =>
      binding.write(ctx, value, source: source);
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
  Variable _read(
    CompilerContext ctx, {
    AstNode? source,
    TypeRef? boundContext,
    List<TypeRef>? typeArguments,
  }) => loadGlobalVariable(ctx, library, name, displayName);

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
    if (decl is FunctionDeclaration) {
      return CallSignature.forDeclaration(ctx, _file, decl).toFunctionType(ctx);
    }
    if (target.bridge case BridgeFunctionDeclaration bridge) {
      return CallSignature.bridge(
        ctx,
        bridge.function,
        returnFallback: CoreTypes.dynamic.ref(ctx),
      ).toFunctionType(ctx);
    }
    return CoreTypes.type.ref(ctx);
  }

  @override
  TypeRef writeType(CompilerContext ctx, {AstNode? source}) {
    final decl = _decl;
    if (decl is FunctionDeclaration && decl.isSetter) {
      return setterValueType(ctx, _file, decl.functionExpression.parameters) ??
          CoreTypes.dynamic.ref(ctx);
    }
    return CoreTypes.type.ref(ctx);
  }

  @override
  Variable _read(
    CompilerContext ctx, {
    AstNode? source,
    TypeRef? boundContext,
    List<TypeRef>? typeArguments,
  }) => _declarationToVariable(
    target,
    name,
    ctx,
    source,
    boundContext,
    typeArguments,
  );

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
  CallTarget? call(CompilerContext ctx, {AstNode? source}) {
    final decl = _decl;
    if (target.isBridge) return null;
    // `x()` where `x` is a getter must call the getter's *result*, not the
    // getter itself — no direct dispatch.
    if (decl is FunctionDeclaration && (decl.isGetter || decl.isSetter)) {
      return null;
    }
    return _declarationToCallTarget(target, name, ctx, source);
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
      return setterValueType(ctx, file, member.parameters) ??
          CoreTypes.dynamic.ref(ctx);
    }
    return readType(ctx, source: source);
  }

  DeferredOrOffset _offset(CompilerContext ctx) =>
      DeferredOrOffset.lookupStatic(
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
  Variable _read(
    CompilerContext ctx, {
    AstNode? source,
    TypeRef? boundContext,
    List<TypeRef>? typeArguments,
  }) {
    if (member.isGetter) {
      // A getter reference invokes it (the member's value, not its
      // tear-off).
      return StaticCall(_offset(ctx)).emit(
        ctx,
        BoundCall(
          positional: const [],
          named: const [],
          returnType: readType(ctx),
        ),
      );
    }
    return materializeTearOff(
      ctx,
      _offset(ctx),
      boundContext: boundContext,
      typeArguments: typeArguments,
    );
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
    throw CompileError(
      'Cannot find value to set: $ownerName.${member.name.lexeme}',
      source,
    );
  }

  @override
  CallTarget? call(CompilerContext ctx, {AstNode? source}) {
    if (member.isGetter || member.isSetter) return null;
    final rt = member.returnType == null
        ? CoreTypes.dynamic.ref(ctx)
        : ctx.withTypeParameters<TypeRef>(
            file,
            null,
            member.typeParameters?.typeParameters,
            () => TypeRef.fromAnnotation(ctx, file, member.returnType!),
          );
    return StaticCall(_offset(ctx), signature: CallSignature.returnOnly(rt));
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
  final ResolvedMember? declared;

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
    if (receiver is SuperReceiver) {
      final body = ctx.memberLookup.lexicalSuperBody(
        name,
        forSet ? MemberKind.setter : MemberKind.getter,
      );
      if (body != null) {
        return forSet
            ? ctx.memberLookup.lexicalSuperSetterType(body)
            : ctx.memberLookup.lexicalSuperResultType(body);
      }
    }
    final object = switch (receiver) {
      SuperReceiver(:final self) => self,
      ValueReceiver(:final value) => value,
      _ => ctx.lookupLocal('#this'),
    };
    if (object == null) return null;
    if (!forSet) {
      final method = ctx.memberLookup.tryInterfaceMember(
        object.type,
        MemberName.method(name),
        source: source,
      );
      final declaration = method?.member;
      if (declaration is SourceMember &&
          declaration.node is MethodDeclaration) {
        final node = declaration.node as MethodDeclaration;
        if (!node.isGetter && !node.isSetter) {
          return method!.signature.toFunctionType(ctx);
        }
      }
    }
    var fieldType = ctx.memberLookup.fieldType(
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
      return ctx.typeFactory.formalParameterAnnotationType(
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
    final target = ctx.memberLookup.superMemberTarget(
      self.type,
      name,
      kind: forSet ? MemberKind.setter : MemberKind.getter,
    );
    if (target.hops.isEmpty && target.owner != self.type) {
      return Variable.of(
        ctx,
        owner.ssa,
        target.owner,
        rep: owner.rep,
        facts: ValueFacts(possibleClasses: [target.owner]),
      );
    }
    for (final parent in target.hops) {
      owner = Variable.ssa(
        ctx,
        LoadSuper(ctx.svar('super'), owner.ssa),
        parent,
      );
    }
    return owner;
  }

  /// `receiver.name` where the member is declared on the enclosing class
  /// itself — the bare-identifier-in-class-body path.
  Variable _readDeclared(
    CompilerContext ctx,
    AstNode? source,
    TypeRef? boundContext,
    List<TypeRef>? typeArguments,
  ) {
    final resolvedMember = declared!;
    final $type = resolvedMember.viewedAs;
    final member = resolvedMember.member;
    final $this =
        ctx.lookupLocal('#this') ??
        (throw CompileError(
          'Cannot access instance member $name in a static context',
        ));

    final refName = _refNameOf(name);
    if (member is SourceMember) {
      final declaration = member.node;
      if (declaration is MethodDeclaration &&
          !declaration.isGetter &&
          !declaration.isSetter) {
        return materializeTearOff(
          ctx,
          DeferredOrOffset(
            file: ctx.library,
            className: ctx.currentClassName!,
            name: refName,
          ),
          implicitReceiver: $this,
          boundContext: boundContext,
          typeArguments: typeArguments,
        );
      }
    }

    final resvar = ctx.svar(name);
    ctx.pushOp(
      LoadPropertyDynamic(resvar, $this.ssa, name, callerLibrary: ctx.library),
    );

    return Variable.of(
      ctx,
      resvar,
      ctx.memberLookup.fieldType($type, name, source: source) ??
          CoreTypes.dynamic.ref(ctx),
      rep: ValueRep.boxed,
    );
  }

  /// `super.name` read — method reads tear off bound to the super receiver.
  Variable _readSuper(
    CompilerContext ctx,
    AstNode? source,
    TypeRef? boundContext,
    List<TypeRef>? typeArguments,
  ) {
    final foldedMethod = ctx.memberLookup.lexicalSuperBody(
      name,
      MemberKind.method,
    );
    if (foldedMethod != null) {
      final owner = foldedMethod.declaration.parent?.parent;
      if (owner is Declaration) {
        return materializeTearOff(
          ctx,
          DeferredOrOffset(
            offset: foldedMethod.offset,
            file: foldedMethod.library,
            className: declarationName(owner),
            name: name,
          ),
          implicitReceiver: ctx.lookupLocal('#this')!,
          boundContext: boundContext,
          typeArguments: typeArguments,
          memberTypeParameters: ctx.memberLookup.lexicalSuperTypeParameters(
            foldedMethod,
          ),
        );
      }
    }
    final foldedGetter = ctx.memberLookup.lexicalSuperBody(
      name,
      MemberKind.getter,
    );
    if (foldedGetter != null) {
      return FoldedMixinGetterCall(
        foldedGetter,
        ctx.lookupLocal('#this')!,
      ).emit(ctx);
    }
    final owner = _superOwner(ctx, false);
    // A method member read is a tear-off bound to the super receiver.
    final memberDecl =
        ctx.instanceDeclarationsMap[owner.type.file]?[owner.type.name]?[name];
    if (memberDecl is MethodDeclaration &&
        !memberDecl.isGetter &&
        !memberDecl.isSetter) {
      return materializeTearOff(
        ctx,
        DeferredOrOffset(
          file: owner.type.file,
          className: owner.type.name,
          name: name,
        ),
        implicitReceiver: owner,
        boundContext: boundContext,
        typeArguments: typeArguments,
      );
    }
    if (ctx
            .topLevelDeclarationsMap[owner.type.file]?[owner.type.name]
            ?.isBridge ??
        false) {
      return GetTarget.read(
        ctx,
        owner,
        name,
        source: source,
        isSuperReceiver: true,
      );
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
    final foldedSetter = ctx.memberLookup.lexicalSuperBody(
      name,
      MemberKind.setter,
    );
    if (foldedSetter != null) {
      return FoldedMixinSetterCall(
        foldedSetter,
        ctx.lookupLocal('#this')!,
      ).emit(ctx, value);
    }
    final owner = _superOwner(ctx, true);
    if (ctx
            .topLevelDeclarationsMap[owner.type.file]?[owner.type.name]
            ?.isBridge ??
        false) {
      return SetTarget.write(
        ctx,
        owner,
        name,
        value,
        source: source,
        isSuperReceiver: true,
      );
    }
    return SuperSetterCall(
      owner,
      name,
      writeType(ctx, source: source),
    ).emit(ctx, value);
  }

  @override
  Variable _read(
    CompilerContext ctx, {
    AstNode? source,
    TypeRef? boundContext,
    List<TypeRef>? typeArguments,
  }) {
    if (receiver is SuperReceiver) {
      return _readSuper(ctx, source, boundContext, typeArguments);
    }
    if (declared != null) {
      return _readDeclared(ctx, source, boundContext, typeArguments);
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
    return GetTarget.read(
      ctx,
      object,
      name,
      source: source,
      boundContext: boundContext,
      typeArguments: typeArguments,
    );
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
  CallTarget? call(CompilerContext ctx, {AstNode? source}) {
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
    final returnType = ctx.memberLookup
        .interfaceMember(
          actualType,
          MemberName(name, MemberKind.method),
          source: source,
        )
        .signature
        .returnType;

    // The statically-fixed target is the nearest class at-or-above the
    // receiver type declaring the method. An exact allocation type needs
    // no override check; a merely-declared type does.
    for (final link in [
      actualType,
      ...ctx.typeSystem.superclassChain(actualType),
    ]) {
      final methodsMap =
          ctx.instanceDeclarationPositions[link.file]?[link.name]?[MemberKind
              .method];
      if (methodsMap?.containsKey(name) != true) continue;
      if (exact == null &&
          ctx.memberOverriddenInSubclass(
            actualType.file,
            actualType.name,
            name,
          )) {
        return null;
      }
      return StaticCall(
        DeferredOrOffset(file: link.file, offset: methodsMap![name]),
        signature: CallSignature.returnOnly(returnType),
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
  CallTarget? call(CompilerContext ctx, {AstNode? source}) {
    if (!member.isStatic || member.isGetter || member.isSetter) return null;
    return StaticCall(
      DeferredOrOffset(file: ext.library, name: ext.memberKey(member)),
      signature: CallSignature.forDeclaration(ctx, ext.library, member),
    );
  }

  @override
  TypeRef readType(CompilerContext ctx, {AstNode? source}) {
    if (member.isGetter) {
      return member.returnType == null
          ? CoreTypes.dynamic.ref(ctx)
          : TypeRef.fromAnnotation(ctx, ext.library, member.returnType!);
    }
    return CoreTypes.function.ref(ctx);
  }

  @override
  TypeRef writeType(CompilerContext ctx, {AstNode? source}) {
    if (member.isSetter) {
      return setterValueType(ctx, ext.library, member.parameters) ??
          CoreTypes.dynamic.ref(ctx);
    }
    return readType(ctx, source: source);
  }

  @override
  Variable _read(
    CompilerContext ctx, {
    AstNode? source,
    TypeRef? boundContext,
    List<TypeRef>? typeArguments,
  }) {
    final recv = receiver;
    final offset = DeferredOrOffset(
      file: ext.library,
      name: ext.memberKey(member),
    );
    if (member.isStatic || recv == null) {
      // Static members resolve through the extension's namespace — no
      // receiver.
      if (member.isGetter) {
        final resvar = ctx.svar(
          member.isStatic ? 'call_result' : 'getter_result',
        );
        ctx.pushOp(Call(offset, const [], result: resvar));
        return Variable.of(
          ctx,
          resvar,
          member.returnType == null
              ? CoreTypes.dynamic.ref(ctx)
              : TypeRef.fromAnnotation(ctx, ext.library, member.returnType!),
          rep: ValueRep.boxed,
        );
      }
      if (member.isSetter) {
        throw CompileError(
          'Cannot read extension setter ${ext.name}.${member.name.lexeme}',
          source,
        );
      }
      return materializeTearOff(
        ctx,
        offset,
        boundContext: boundContext,
        typeArguments: typeArguments,
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
    return materializeTearOff(
      ctx,
      offset,
      implicitReceiver: recv,
      boundContext: boundContext,
      typeArguments: typeArguments,
    );
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
      final paramType = member.parameters?.parameters.firstOrNull?.type == null
          ? null
          : ctx.typeFactory.formalParameterAnnotationType(
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
  const TypeLiteralDenotation(
    this.type,
    this.constructorKey, {
    this.declaration,
  });

  final TypeRef type;
  final String constructorKey;

  /// The declaration the literal was built from — the constructor path
  /// inspects aliases and class generics through it.
  final Declaration? declaration;

  @override
  TypeRef readType(CompilerContext ctx, {AstNode? source}) =>
      CoreTypes.type.ref(ctx);

  @override
  Variable _read(
    CompilerContext ctx, {
    AstNode? source,
    TypeRef? boundContext,
    List<TypeRef>? typeArguments,
  }) => typeLiteral(ctx, type, constructorKey);

  @override
  Variable write(CompilerContext ctx, Variable value, {AstNode? source}) =>
      throw CompileError('Cannot assign to a type literal', source);

  @override
  CallTarget? call(CompilerContext ctx, {AstNode? source}) => StaticCall(
    DeferredOrOffset(file: type.file, name: constructorKey),
    signature: CallSignature.returnOnly(type),
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
  Variable _read(
    CompilerContext ctx, {
    AstNode? source,
    TypeRef? boundContext,
    List<TypeRef>? typeArguments,
  }) => Variable.ssa(
    ctx,
    LoadTypeParameter(ctx.svar('type'), ctx.runtimeTypes.idOf(typeParameter)),
    CoreTypes.type.ref(ctx),
    facts: ValueFacts(
      denotedType: typeParameter,
      possibleClasses: [typeParameter],
    ),
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
      throw CompileError('Import prefix "$prefix" is not a type', source);

  @override
  Variable _read(
    CompilerContext ctx, {
    AstNode? source,
    TypeRef? boundContext,
    List<TypeRef>? typeArguments,
  }) => throw CompileError('Import prefix "$prefix" is not a value', source);

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
        children[forSet
            ? MemberName.setter(name).key
            : MemberName.getter(name).key] ??
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
  Variable _read(
    CompilerContext ctx, {
    AstNode? source,
    TypeRef? boundContext,
    List<TypeRef>? typeArguments,
  }) => value;

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
  Variable _read(
    CompilerContext ctx, {
    AstNode? source,
    TypeRef? boundContext,
    List<TypeRef>? typeArguments,
  }) => Variable.ssa(
    ctx,
    LoadGlobal(ctx.svar(name), index),
    enumType,
    rep: ValueRep.boxed,
  );

  @override
  Variable write(CompilerContext ctx, Variable value, {AstNode? source}) =>
      throw CompileError('Cannot assign to enum value $name', source);
}

/// An extension used as a compile-time namespace.
final class ExtensionNamespaceDenotation extends Denotation {
  const ExtensionNamespaceDenotation(this.ext, this.markerName);

  final EvalExtension ext;
  final String markerName;

  @override
  TypeRef readType(CompilerContext ctx, {AstNode? source}) =>
      CoreTypes.type.ref(ctx);

  @override
  Variable _read(
    CompilerContext ctx, {
    AstNode? source,
    TypeRef? boundContext,
    List<TypeRef>? typeArguments,
  }) => throw CompileError('An extension namespace is not a value', source);

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
      orElse: () =>
          EvalExtension(decOrBridge.sourceLib, decl, declarationName(decl)),
    );
    return ExtensionNamespaceDenotation(ext, name);
  }
  final type = decl is TypeAlias && decl is! ClassTypeAlias
      ? ctx.typeFactory.resolveTypeAlias(decOrBridge.sourceLib, decl)
      : TypeRef.lookupDeclaration(ctx, decOrBridge.sourceLib, decl);
  return TypeLiteralDenotation(
    type,
    '${declarationName(decl)}.',
    declaration: decl,
  );
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
    if (bridge is BridgeFunctionDeclaration) {
      return CallSignature.bridge(
        ctx,
        bridge.function,
        returnFallback: CoreTypes.dynamic.ref(ctx),
      ).toFunctionType(ctx);
    }
    return CoreTypes.function.ref(ctx);
  }

  @override
  Variable _read(
    CompilerContext ctx, {
    AstNode? source,
    TypeRef? boundContext,
    List<TypeRef>? typeArguments,
  }) => _declarationToVariable(
    target,
    name,
    ctx,
    source,
    boundContext,
    typeArguments,
  );

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
    final selfDecl = ctx.types.find(
      ctx.enclosingLibrary ?? ctx.library,
      ctx.currentClassName!,
    );
    final selfMember = selfDecl == null
        ? null
        : ctx.memberLookup.declaredAccessor(selfDecl, name);
    if (selfDecl != null && selfMember != null) {
      return InstanceMemberDenotation(
        null,
        name,
        declared: ResolvedMember(selfMember, selfDecl.thisType),
      );
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
        final gIndex = ctx.enumValueIndices[ctx.library]?[enumType.name]?[name];
        if (gIndex != null) {
          return EnumValueDenotation(enumType, gIndex, name);
        }
      }
    }

    final staticMember = ctx.memberLookup.scopedStaticMember(
      name,
      forSet: forSet,
    );
    if (staticMember != null && staticMember.$1 is SourceMember) {
      final (member, scopeFile, scopeName) = staticMember;
      final staticDec = (member as SourceMember).sourceDeclaration;
      if (staticDec is MethodDeclaration) {
        if ((forSet && staticDec.isSetter) ||
            (!forSet && staticDec.isGetter) ||
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
    case ExtensionNamespaceReceiver(:final ext):
      for (final field in ext.members.whereType<FieldDeclaration>()) {
        if (field.isStatic &&
            field.fields.variables.any(
              (variable) => variable.name.lexeme == name,
            )) {
          return GlobalDenotation(
            ext.library,
            '${ext.name}.$name',
            displayName: name,
          );
        }
      }
      final member = ext.members
          .whereType<MethodDeclaration>()
          .firstWhereOrNull(
            (m) => m.name.lexeme == name && (forSet ? m.isSetter : !m.isSetter),
          );
      if (member == null) {
        throw CompileError(
          'Extension member not found: ${ext.name}.$name',
          source,
        );
      }
      return ExtensionMemberDenotation(ext, member);
    case TypeLiteralReceiver(:final type, :final value):
      // A type literal sharing its name with an extension still resolves
      // members through the extension namespace.
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
        return InstanceMemberDenotation(
          ValueReceiver(value ?? typeLiteral(ctx, type, type.name)),
          name,
        );
      }
      final superclass = ctx.typeSystem.superclassOf(type);
      if (!forSet &&
          superclass != null &&
          superclass.isSpec(CoreTypes.enumType)) {
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
  Variable _read(
    CompilerContext ctx, {
    AstNode? source,
    TypeRef? boundContext,
    List<TypeRef>? typeArguments,
  }) {
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
            ctx.bridgeStaticFunctionIndices[type
                .file]!['${type.name}.${MemberName.getter(name).key}']!,
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
    final accessor = ctx
        .topLevelDeclarationsMap[type.file]?[MemberName.getter(fqName).key]
        ?.declaration;
    if (accessor is MethodDeclaration) {
      return accessor.returnType != null
          ? TypeRef.fromAnnotation(ctx, type.file, accessor.returnType!)
          : CoreTypes.dynamic.ref(ctx);
    }
    final member = ctx.topLevelDeclarationsMap[type.file]?[fqName]?.declaration;
    if (member is MethodDeclaration && !member.isGetter && !member.isSetter) {
      return CallSignature.forDeclaration(
        ctx,
        type.file,
        member,
      ).toFunctionType(ctx);
    }
    return resolveGlobalType(ctx, type.file, fqName);
  }

  @override
  TypeRef writeType(CompilerContext ctx, {AstNode? source}) {
    final setter = ctx
        .topLevelDeclarationsMap[type.file]?[MemberName.setter(fqName).key]
        ?.declaration;
    if (setter is MethodDeclaration && setter.isSetter) {
      return setterValueType(ctx, type.file, setter.parameters) ??
          CoreTypes.dynamic.ref(ctx);
    }
    return resolveGlobalType(ctx, type.file, fqName);
  }

  @override
  Variable _read(
    CompilerContext ctx, {
    AstNode? source,
    TypeRef? boundContext,
    List<TypeRef>? typeArguments,
  }) {
    // Static accessors register under `*g`/`*s` keys — a getter reference
    // invokes it.
    final getterMember =
        ctx.topLevelDeclarationsMap[type.file]?[MemberName.getter(fqName).key];
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
      if (memberDecl is MethodDeclaration && memberDecl.isGetter) {
        return StaticCall(memberOffset).emit(
          ctx,
          BoundCall(
            positional: const [],
            named: const [],
            returnType: readType(ctx),
          ),
        );
      }
      // Static method tear-off.
      return materializeTearOff(
        ctx,
        memberOffset,
        boundContext: boundContext,
        typeArguments: typeArguments,
      );
    }
    return loadGlobalVariable(ctx, type.file, fqName, name);
  }

  @override
  Variable write(CompilerContext ctx, Variable value, {AstNode? source}) {
    // A static setter (`C.x*s`) takes precedence over a static field
    // global of the same base name.
    final setter = ctx
        .topLevelDeclarationsMap[type.file]?[MemberName.setter(fqName).key]
        ?.declaration;
    if (setter is MethodDeclaration && setter.isSetter) {
      return _invokeSetter(
        ctx,
        DeferredOrOffset(file: type.file, name: MemberName.setter(fqName).key),
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
Receiver compileReceiver(
  CompilerContext ctx,
  Expression target, {
  TypeRef? bound,
}) {
  if (target is SuperExpression) {
    return SuperReceiver(compileExpression(target, ctx));
  }
  if (target is Identifier) {
    final reference = compileIdentifierAsReference(target, ctx);
    final denotation = switch (reference) {
      IdentifierReference() => reference.denotation(ctx, source: target),
      PrefixedIdentifierReference() => reference.denotation(
        ctx,
        source: target,
      ),
      _ => null,
    };
    if (denotation is PrefixDenotation) return PrefixReceiver(denotation);
    if (denotation is ExtensionNamespaceDenotation) {
      return ExtensionNamespaceReceiver(denotation.ext);
    }
    if (denotation != null) {
      return receiverOf(
        ctx,
        denotation.read(ctx, source: target, boundContext: bound),
      );
    }
  }
  // The expression compiler already distinguishes p.name from value.name,
  // materializes function references, and preserves contextual typing.
  final value = compileExpression(target, ctx, bound);
  return receiverOf(ctx, value, pin: extensionPinOf(ctx, target, value.type));
}

/// Field-wise equality for shadow comparison of dispatch results.

/// A deferred import prefix exposes an implicit `loadLibrary` member. Since
/// all libraries are compiled eagerly, it resolves to a stub closure
/// returning an already-completed `Future<Null>` — and it shadows any
/// `loadLibrary` declared by the imported library itself.
Variable? _deferredLoadLibrary(CompilerContext ctx, String prefix) {
  if (!(ctx.deferredPrefixes[ctx.library]?.contains(prefix) ?? false)) {
    return null;
  }
  final idx =
      ctx.bridgeStaticFunctionIndices[ctx
          .libraryMap['dart:core']]?['deferred_loadLibrary'];
  if (idx == null) return null;
  return Variable.ssa(
    ctx,
    InvokeExternal(ctx.svar('loadLibrary'), idx, []),
    CoreTypes.function.ref(ctx),
    facts: ValueFacts(
      callableSignature: CallSignature.returnOnly(
        CoreTypes.future
            .ref(ctx)
            .copyWith(arguments: [CoreTypes.nullType.ref(ctx)]),
      ),
    ),
  );
}

Variable _declarationToVariable(
  DeclarationOrBridge decOrBridge,
  String name,
  CompilerContext ctx, [
  AstNode? source,
  TypeRef? boundContext,
  List<TypeRef>? typeArguments,
]) {
  if (decOrBridge.isBridge) {
    final bridge = decOrBridge.bridge!;

    if (bridge is BridgeClassDef) {
      final type = TypeRef.fromBridgeTypeRef(ctx, bridge.type.type);
      return typeLiteral(ctx, type, '${type.name}.');
    }

    if (bridge is BridgeEnumDef) {
      final type = TypeRef.fromBridgeTypeRef(ctx, bridge.type);
      return typeLiteral(ctx, type, '${type.name}#wrap');
    }

    if (bridge is BridgeFunctionDeclaration) {
      return materializeTearOff(
        ctx,
        DeferredOrOffset(file: decOrBridge.sourceLib, name: name),
        boundContext: boundContext,
        typeArguments: typeArguments,
      );
    }

    throw CompileError(
      'Cannot resolve bridged ${bridge.runtimeType} in reference',
      source,
    );
  }

  final decl = decOrBridge.declaration!;

  if (decl is VariableDeclaration) {
    return loadGlobalVariable(ctx, decOrBridge.sourceLib, decl.name.lexeme);
  }

  if (decl is ExtensionDeclaration) {
    throw CompileError('An extension namespace is not a value', source);
  }

  if (decl is! FunctionDeclaration && decl is! ConstructorDeclaration) {
    final type = decl is TypeAlias && decl is! ClassTypeAlias
        ? ctx.typeFactory.resolveTypeAlias(decOrBridge.sourceLib, decl)
        : TypeRef.lookupDeclaration(ctx, decOrBridge.sourceLib, decl);
    return typeLiteral(ctx, type, '${declarationName(decl)}.');
  }

  TypeRef? returnType;
  if (decl is FunctionDeclaration && decl.returnType != null) {
    returnType = ctx.withTypeParameters<TypeRef>(
      decOrBridge.sourceLib,
      null,
      decl.functionExpression.typeParameters?.typeParameters,
      () =>
          TypeRef.fromAnnotation(ctx, decOrBridge.sourceLib, decl.returnType!),
    );
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

  // Accessors compile under `*g`/`*s` keys — use the accessor's own key so
  // deferred resolution finds the right function entry.
  final offset = DeferredOrOffset(
    file: decOrBridge.sourceLib,
    name: decl is FunctionDeclaration
        ? (decl.isGetter
              ? MemberName.getter(decl.name.lexeme).key
              : decl.isSetter
              ? MemberName.setter(decl.name.lexeme).key
              : name)
        : name,
  );

  if (decl is FunctionDeclaration && decl.isGetter) {
    return StaticCall(offset).emit(
      ctx,
      BoundCall(
        positional: const [],
        named: const [],
        returnType: returnType,
        rep: Abi.unboxedAcrossCalls(returnType),
      ),
    );
  }
  return materializeTearOff(
    ctx,
    offset,
    boundContext: boundContext,
    typeArguments: typeArguments,
  );
}

CallTarget? _declarationToCallTarget(
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
    if (decl is! ClassDeclaration) {
      // Variables, enums and other non-function decls have no static
      // dispatch target.
      return null;
    }

    final offset = DeferredOrOffset(
      file: decOrBridge.sourceLib,
      name: '$name.',
    );

    final rt = TypeRef.lookupDeclaration(ctx, decOrBridge.sourceLib, decl);

    return StaticCall(offset, signature: CallSignature.returnOnly(rt));
  }

  TypeRef? returnType;
  if (decl is FunctionDeclaration && decl.returnType != null) {
    returnType = ctx.withTypeParameters<TypeRef>(
      decOrBridge.sourceLib,
      null,
      decl.functionExpression.typeParameters?.typeParameters,
      () =>
          TypeRef.fromAnnotation(ctx, decOrBridge.sourceLib, decl.returnType!),
    );
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

  // Accessors compile under `*g`/`*s` keys — use the accessor's own key so
  // deferred resolution finds the right function entry.
  final offset = DeferredOrOffset(
    file: decOrBridge.sourceLib,
    name: decl is FunctionDeclaration
        ? (decl.isGetter
              ? MemberName.getter(decl.name.lexeme).key
              : decl.isSetter
              ? MemberName.setter(decl.name.lexeme).key
              : name)
        : name,
  );

  return StaticCall(offset, signature: CallSignature.returnOnly(returnType));
}

/// The declared type of instance member [name] on the enclosing class, or null
/// when the current class has no such member.
TypeRef? _resolveInstanceFieldType(
  CompilerContext ctx,
  String name, {
  bool forSet = false,
  AstNode? source,
}) {
  final selfDecl = ctx.types.find(ctx.library, ctx.currentClassName!);
  if (selfDecl == null ||
      ctx.memberLookup.declaredAccessor(selfDecl, name) == null) {
    return null;
  }
  return ctx.memberLookup.fieldType(
        selfDecl.thisType,
        name,
        forSet: forSet,
        source: source,
      ) ??
      CoreTypes.dynamic.ref(ctx);
}

/// Resolves [name] to a top-level declaration visible in the current library.
/// Throws a [CompileError] when the name resolves to an import prefix rather than
/// a concrete declaration.
DeclarationOrBridge _lookupVisibleValue(
  CompilerContext ctx,
  String name,
  AstNode? source, {
  bool forSet = false,
}) {
  final visible = ctx.visibleDeclarations[ctx.library]!;
  Map<String, DeclarationOrBridge>? children;
  var key = name;
  // `prefix.member` — descend into the prefix's children.
  if (name.contains('.')) {
    final split = name.split('.');
    final prefixEntry = visible[split[0]];
    if (prefixEntry != null &&
        prefixEntry.declaration == null &&
        prefixEntry.children != null) {
      children = prefixEntry.children;
      key = split.sublist(1).join('.');
    }
  }
  // Top-level accessors register under `*g`/`*s` — reads prefer the getter
  // key, writes the setter key, falling back to the plain name (variables,
  // functions, classes).
  DeclarationOrBridge? found;
  if (children != null) {
    found = forSet
        ? children[MemberName.setter(key).key] ?? children[key]
        : children[MemberName.getter(key).key] ?? children[key];
  } else {
    found = forSet
        ? visible[MemberName.setter(key).key]?.declaration ??
              visible[key]?.declaration
        : visible[MemberName.getter(key).key]?.declaration ??
              visible[key]?.declaration;
  }
  if (found == null) {
    if (children == null && visible[key] != null) {
      throw CompileError(
        '"$name" is an import prefix, not a declaration',
        source,
      );
    }
    throw CompileError('Could not find declaration "$name"', source);
  }
  return found;
}

/// Emits a `Call` to a setter taking [value] as its argument. The value is
/// first converted to the setter's declared parameter type (which can apply
/// coercions like the implicit `.call` tear-off), then adapted to the
/// parameter's representation across the call boundary. Returns the converted
/// variable — the assignment expression's value.
Variable _invokeSetter(
  CompilerContext ctx,
  DeferredOrOffset offset,
  Variable value,
  int file,
  FormalParameterList? parameters, {
  required bool isMethod,
  AstNode? source,
}) {
  final paramType = setterValueType(ctx, file, parameters);
  final converted = paramType == null
      ? value
      : convertForAssignment(
          ctx,
          value,
          paramType,
          representation: isMethod
              ? MachineRepresentation.object
              : Abi.unboxedAcrossCalls(paramType).bank,
          source: source,
        );
  ctx.pushOp(
    Call(offset, [
      _setterArgument(ctx, converted, file, parameters, isMethod: isMethod).ssa,
    ], result: ctx.svar('setter_result')),
  );
  return converted;
}

bool _hasReceiverMember(
  CompilerContext ctx,
  Variable receiver,
  String name, {
  bool forSet = false,
  AstNode? source,
}) {
  final resolvedReceiver = ctx.typeSystem.throughTypeParameters(receiver.type);
  if (resolvedReceiver.isSpec(CoreTypes.dynamic)) return true;
  if (ctx.memberLookup.fieldType(
        resolvedReceiver,
        name,
        forSet: forSet,
        source: source,
      ) !=
      null) {
    return true;
  }
  if (hasInstanceMember(ctx, resolvedReceiver, name, forSet: forSet)) {
    return true;
  }
  return resolveExtensionMember(
            ctx,
            resolvedReceiver,
            name,
            getter: !forSet,
            setter: forSet,
          ) !=
          null ||
      resolveExtensionMember(ctx, resolvedReceiver, name) != null;
}

/// Adapts [value] to the physical representation a setter's `value` parameter
/// travels in across the call boundary. A direct `Call` constrains argument
/// representations to the callee signature, so the caller must emit the
/// conversion itself. Method parameters are always boxed (bridge interop);
/// top-level function parameters travel in their boundary representation
/// (unboxed `int`/`double`/`bool`, boxed otherwise).
Variable _setterArgument(
  CompilerContext ctx,
  Variable value,
  int file,
  FormalParameterList? parameters, {
  required bool isMethod,
}) {
  if (isMethod) {
    return value.boxIntoFreshSlot(ctx);
  }
  final paramType = setterValueType(ctx, file, parameters);
  final rep = Abi.unboxedAcrossCalls(
    paramType ?? CoreTypes.dynamic.ref(ctx),
  ).bank;
  return rep == MachineRepresentation.object
      ? value.boxIntoFreshSlot(ctx)
      : value.unboxIfNeeded(ctx, false);
}
