import 'package:analyzer/dart/ast/ast.dart';
import 'package:collection/collection.dart';
import 'package:control_flow_graph/control_flow_graph.dart' show SSA;
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/backend/representation.dart'
    show MachineRepresentation;
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/dispatch.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/function.dart';
import 'package:dart_eval/src/eval/compiler/expression/identifier.dart'
    show resolveInstanceDeclaration;
import 'package:dart_eval/src/eval/compiler/helpers/conversion.dart';
import 'package:dart_eval/src/eval/compiler/helpers/extension.dart';
import 'package:dart_eval/src/eval/compiler/helpers/tearoff.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';
import 'package:dart_eval/src/eval/compiler/member/member_name.dart';
import 'package:dart_eval/src/eval/compiler/model/function_type.dart'
    show declaredFunctionType, formalParameterAnnotationType;
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/collection.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/ir/objects.dart';
import 'package:dart_eval/src/eval/ir/string.dart';
import 'package:dart_eval/src/eval/ir/types.dart';
import '../values/abi.dart';

/// How a member read `o.name` lowers. [GetTarget.resolve] picks the target
/// from the receiver's static type, representations, and facts; [emit]
/// produces the ops. No argument binding — an accessor target stands alone.
sealed class GetTarget {
  const GetTarget();

  /// Member-read resolution: intrinsics (`length`, `runtimeType`), bound
  /// extensions, extension getters and method tear-offs, link-relative
  /// field storage, direct getter calls, and the dynamic fallback.
  static GetTarget resolve(
    CompilerContext ctx,
    Variable receiver,
    String name, {
    AstNode? source,
    BoundExtension? extensionPin,
    bool isSuperReceiver = false,
  }) {
    // A bare function reference has no SSA value; materialize the tear-off
    // first so members like `hashCode`/`runtimeType` resolve on it.
    if (receiver.unmaterializedCallable != null) {
      return resolve(ctx, receiver.tearOff(ctx), name, source: source);
    }
    if (name == 'length' && !receiver.type.nullable) {
      final isString = receiver.type.isAssignableTo(
        ctx,
        CoreTypes.string.ref(ctx),
        forceAllowDynamic: false,
      );
      // A declared List may be an evaluated class with an overridden
      // getter. Only a natively-held core List proves native storage.
      final isList =
          receiver.rep == ValueRep.nativeList &&
          receiver.type.isSpec(CoreTypes.list);
      if (isString || isList) {
        return IntrinsicGet(receiver.unboxIfNeeded(ctx, false), name,
            string: isString);
      }
    }
    final resolvedReceiver = ctx.typeSystem.throughTypeParameters(
      receiver.type,
    );
    if (name == 'runtimeType') {
      // `runtimeType` is overridable like any other getter — only
      // intrinsify it when the receiver's class doesn't declare it and no
      // descendant overrides it (otherwise dispatch normally).
      final declaredLocally =
          ctx
              .instanceDeclarationPositions[resolvedReceiver
                  .file]?[resolvedReceiver.name]?[0]
              ?.containsKey('runtimeType') ??
          false;
      final overridable =
          declaredLocally ||
          memberOwner(ctx, resolvedReceiver, 'runtimeType', kind: 0) != null ||
          ctx.memberOverriddenInSubclass(
            resolvedReceiver.file,
            resolvedReceiver.name,
            'runtimeType',
          );
      if (!overridable) {
        if (receiver.concreteTypes.isNotEmpty) {
          final concrete = receiver.concreteTypes[0];
          return IntrinsicGet(
            receiver,
            name,
            constantType: (
              ctx.runtimeTypes.idOf(concrete),
              concrete.requiresTypeEnvironment,
            ),
          );
        }
        return IntrinsicGet(receiver, name, loadRuntime: true);
      }
    }
    // Explicit application `E(x)` pins member resolution to E's members.
    if (extensionPin case final bound?) {
      final getter = extensionMember(bound.ext, name, getter: true);
      if (getter != null) {
        return ExtensionGetterCall(receiver, bound.ext, getter,
            bound.onBindings);
      }
      final member = extensionMember(bound.ext, name);
      if (member == null) {
        throw CompileError(
          'Extension ${bound.ext.name} has no member $name',
          source,
        );
      }
      return ExtensionMethodTearOff(
        receiver,
        bound.ext,
        member,
        extBindingsMap(bound.ext, bound.onBindings),
      );
    }
    final resolvedField = TypeRef.lookupFieldType(
      ctx,
      resolvedReceiver,
      name,
      source: source,
    );
    final member =
        resolvedField == null && !resolvedReceiver.isSpec(CoreTypes.dynamic)
        ? resolveInstanceDeclaration(
            ctx,
            resolvedReceiver.file,
            resolvedReceiver.name,
            name,
            instantiated: resolvedReceiver,
          )
        : null;
    if (resolvedField == null &&
        !resolvedReceiver.isSpec(CoreTypes.dynamic) &&
        member == null) {
      // An extension getter may apply.
      final found = resolveExtensionMember(
        ctx,
        resolvedReceiver,
        name,
        getter: true,
      );
      if (found != null) {
        return ExtensionGetterCall(receiver, found.$1, found.$2, found.$3);
      }
      // An extension method read produces a bound tear-off.
      final foundMethod = resolveExtensionMember(ctx, resolvedReceiver, name);
      if (foundMethod != null) {
        return ExtensionMethodTearOff(
          receiver,
          foundMethod.$1,
          foundMethod.$2,
          extBindingsMap(foundMethod.$1, foundMethod.$3),
        );
      }
      throw CompileError(
        'Member "$name" is not defined for type $resolvedReceiver',
        source,
      );
    }
    final method = member?.$2.declaration;
    final bridge = member?.$2.bridge;
    // Generic method signatures can't be resolved outside their own scope.
    final isDeclaredMethod =
        method is MethodDeclaration &&
        !method.isGetter &&
        !method.isSetter &&
        method.typeParameters == null;
    final isBridgeMethod = bridge is BridgeMethodDef;

    // A method member read produces a tear-off; carry its signature so
    // calls through the result stay typed.
    final TypeRef fieldType;
    final ReturnType? methodReturnType;
    if (isDeclaredMethod) {
      // The declaring class's type parameters bind to its instantiated
      // view (`member.$1`) — `b.remove` on `B extends A<int>` sees `T: int`.
      final methodHost = method.parent?.parent;
      final hostParams = methodHost is Declaration
          ? classLikeClauses(methodHost).$4?.typeParameters ?? const []
          : const <TypeParameter>[];
      final hostArgs = member!.$1.typeArguments;
      fieldType = declaredFunctionType(
        ctx,
        resolvedReceiver.file,
        method.parameters,
        method.returnType,
        method.typeParameters,
        memberTypeParameters: {
          for (var i = 0; i < hostParams.length && i < hostArgs.length; i++)
            hostParams[i].name.lexeme: hostArgs[i],
        },
      );
      methodReturnType = AlwaysReturnType.fromInstanceMethod(
        ctx,
        resolvedReceiver,
        name,
        CoreTypes.dynamic.ref(ctx),
      );
    } else if (isBridgeMethod) {
      fieldType = CoreTypes.function.ref(ctx);
      methodReturnType = bridgeFunctionReturnType(
        ctx,
        bridge.functionDescriptor,
        specifiedType: resolvedReceiver,
      );
    } else {
      fieldType = resolvedField ?? CoreTypes.dynamic.ref(ctx);
      methodReturnType = null;
    }
    final boxed = receiver.boxIfNeeded(ctx);
    final exact = receiver.exactType;
    if (exact != null && !hasBridgeSuperclass(ctx, exact)) {
      // Storage for an inherited field lives on its declaring class's
      // link, reached from the receiver by LoadSuper hops. First locate
      // the owning link, then emit the hops.
      final links = [exact, ...ctx.typeSystem.superclassChain(exact)];
      var depth = -1;
      int? fieldIndex;
      for (var i = 0; i < links.length; i++) {
        final link = links[i];
        final index = ctx.instanceGetterIndices[link.file]?[link
            .name]?[name];
        if (index != null) {
          fieldIndex = index;
          depth = i;
          break;
        }
        final key = name.startsWith('_')
            ? MemberName(
                name,
                MemberKind.method,
                privateLibraryUri: ctx.libraryUri(link.file),
              ).nameKey
            : name;
        if ((ctx.instanceDeclarationPositions[link.file]?[link
                            .name]?[0] as Map?)
                    ?.containsKey(key) ==
                true &&
            concreteMemberDecl(ctx, link, name, kind: 0) != null) {
          depth = i;
          break;
        }
      }
      if (depth >= 0) {
        final link = links[depth];
        // Field members resolve to their [VariableDeclaration]; real
        // accessors resolve to [MethodDeclaration]. Field storage is
        // link-relative so it always needs the declaring link; a real
        // accessor needs it only when its body uses `super`.
        final decl = resolveInstanceDeclaration(
          ctx,
          link.file,
          link.name,
          name,
          instantiated: link,
        )?.$2.declaration;
        final fieldDecl = decl is VariableDeclaration
            ? decl.parent?.parent
            : null;
        final needsLink =
            fieldIndex != null ||
            memberNeedsOwnerLink(ctx, link, name, kind: 0);
        if (fieldIndex != null) {
          final isLate =
              fieldDecl is FieldDeclaration && fieldDecl.fields.isLate;
          return FieldSlotGet(
            boxed,
            name,
            hops: needsLink ? links.sublist(1, depth + 1) : const [],
            index: fieldIndex,
            isLate: isLate,
            fieldType: fieldType,
          );
        }
        final key = name.startsWith('_')
            ? MemberName(
                name,
                MemberKind.method,
                privateLibraryUri: ctx.libraryUri(link.file),
              ).nameKey
            : name;
        return DirectGetterCall(
          boxed,
          hops: needsLink ? links.sublist(1, depth + 1) : const [],
          file: link.file,
          className: link.name,
          nameKey: key,
          fieldType: fieldType,
          typeEnvironmentReceiver: boxed.ssa,
        );
      }
    }
    if (exact == null &&
        receiver.concreteTypes.length == 1 &&
        !hasBridgeSuperclass(ctx, receiver.concreteTypes.first)) {
      // The receiver may hold a subclass: a getter can be called directly
      // on the dispatch root only when it isn't overridden and its body
      // never touches `super` (so any link works as `this`).
      final owner = directMemberOwner(
        ctx,
        receiver.concreteTypes.first,
        name,
        kind: 0,
      );
      if (owner != null &&
          !memberNeedsOwnerLink(ctx, owner, name, kind: 0)) {
        final key = name.startsWith('_')
            ? '${ctx.libraryUri(owner.file)}::$name'
            : name;
        return DirectGetterCall(
          boxed,
          hops: const [],
          file: owner.file,
          className: owner.name,
          nameKey: key,
          fieldType: fieldType,
          typeEnvironmentReceiver: boxed.ssa,
        );
      }
    }
    return DynamicGet(
      boxed,
      name,
      fieldType: fieldType,
      methodReturnType: methodReturnType,
      callingConvention: isDeclaredMethod || isBridgeMethod
          ? CallingConvention.dynamic
          : CallingConvention.static,
      isSuperReceiver: isSuperReceiver,
    );
  }

  /// [resolve] + [emit].
  static Variable read(
    CompilerContext ctx,
    Variable receiver,
    String name, {
    AstNode? source,
    BoundExtension? extensionPin,
    bool isSuperReceiver = false,
  }) => resolve(
    ctx,
    receiver,
    name,
    source: source,
    extensionPin: extensionPin,
    isSuperReceiver: isSuperReceiver,
  ).emit(ctx);

  Variable emit(CompilerContext ctx);
}

/// A `String.length`, native-`List.length`, or `runtimeType` read.
final class IntrinsicGet extends GetTarget {
  const IntrinsicGet(
    this.receiver,
    this.name, {
    this.string = false,
    this.constantType,
    this.loadRuntime = false,
  });

  /// The (already unboxed, for lengths) receiver.
  final Variable receiver;

  /// The member name — `length` or `runtimeType`.
  final String name;

  /// `length` on a `String` (vs a native `List`).
  final bool string;

  /// `runtimeType` on a statically known concrete type: (type id, whether
  /// the descriptor needs the type environment).
  final (int, bool)? constantType;

  /// `runtimeType` on an unknown runtime value.
  final bool loadRuntime;

  @override
  Variable emit(CompilerContext ctx) => switch (name) {
    'length' => Variable.ssa(
        ctx,
        string
            ? StringOperation(
                ctx.svar('string_length'),
                StringOperator.length,
                receiver.ssa,
              )
            : ListLength(ctx.svar('list_length'), receiver.ssa),
        CoreTypes.int.ref(ctx),
        rep: ValueRep.int,
      ),
    _ when constantType != null => Variable.ssa(
        ctx,
        constantType!.$2
            ? LoadTypeParameter(ctx.svar('var_type'), constantType!.$1)
            : LoadConstantType(ctx.svar('var_type'), constantType!.$1),
        CoreTypes.type.ref(ctx),
      ),
    _ => Variable.ssa(
        ctx,
        LoadRuntimeType(ctx.svar('runtime_type'), receiver.ssa),
        CoreTypes.type.ref(ctx),
      ),
  };
}

/// A field-slot read on a link reached by LoadSuper hops.
final class FieldSlotGet extends GetTarget {
  const FieldSlotGet(
    this.receiver,
    this.name, {
    required this.hops,
    required this.index,
    required this.isLate,
    required this.fieldType,
  });

  /// The already-boxed receiver the hop chain starts from.
  final Variable receiver;
  final String name;

  /// The links to hop through (each hop's *target* parent type), empty
  /// when the field lives on the receiver's own link.
  final List<TypeRef> hops;

  final int index;
  final bool isLate;
  final TypeRef fieldType;

  @override
  Variable emit(CompilerContext ctx) {
    var linkSsa = receiver.ssa;
    for (final parent in hops) {
      linkSsa = Variable.ssa(
        ctx,
        LoadSuper(ctx.svar('super'), linkSsa),
        parent,
        concreteTypes: [parent],
      ).ssa;
    }
    return Variable.ssa(
      ctx,
      LoadPropertyStatic(
        ctx.svar(name),
        linkSsa,
        index,
        isLate: isLate,
      ),
      fieldType,
      rep: ValueRep.boxed,
    );
  }
}

/// A getter invoked directly against a known declaring link.
final class DirectGetterCall extends GetTarget {
  const DirectGetterCall(
    this.receiver, {
    required this.hops,
    required this.file,
    required this.className,
    required this.nameKey,
    required this.fieldType,
    this.typeEnvironmentReceiver,
  });

  /// The already-boxed receiver the hop chain starts from.
  final Variable receiver;

  /// The links to hop through before the call.
  final List<TypeRef> hops;

  final int file;
  final String className;
  final String nameKey;
  final TypeRef fieldType;

  /// The receiver used for the type environment, when the callee's body
  /// may dispatch through generic type parameters.
  final SSA? typeEnvironmentReceiver;

  @override
  Variable emit(CompilerContext ctx) {
    var linkSsa = receiver.ssa;
    for (final parent in hops) {
      linkSsa = Variable.ssa(
        ctx,
        LoadSuper(ctx.svar('super'), linkSsa),
        parent,
        concreteTypes: [parent],
      ).ssa;
    }
    return Variable.ssa(
      ctx,
      Call(
        DeferredOrOffset(
          file: file,
          className: className,
          methodType: MemberKind.getter,
          name: nameKey,
        ),
        [linkSsa],
        result: ctx.svar(nameKey),
        typeEnvironmentReceiver: typeEnvironmentReceiver,
      ),
      fieldType,
      rep: ValueRep.boxed,
    );
  }
}

/// `super.name` — a getter call on the owner link reached by the
/// denotation's mixin/superclass walk (no type-environment receiver).
final class SuperGetterCall extends GetTarget {
  const SuperGetterCall(this.owner, this.name, this.fieldType);

  final Variable owner;
  final String name;
  final TypeRef fieldType;

  @override
  Variable emit(CompilerContext ctx) => Variable.ssa(
    ctx,
    Call(
      DeferredOrOffset(
        file: owner.type.file,
        className: owner.type.name,
        name: name,
        methodType: MemberKind.getter,
      ),
      [owner.ssa],
      result: ctx.svar(name),
    ),
    fieldType,
    rep: ValueRep.boxed,
  );
}

/// `InvokeExternal`-backed extension getter.
final class ExtensionGetterCall extends GetTarget {
  const ExtensionGetterCall(
    this.receiver,
    this.ext,
    this.member,
    this.bindings,
  );

  final Variable receiver;
  final EvalExtension ext;
  final MethodDeclaration member;
  final List<TypeRef> bindings;

  @override
  Variable emit(CompilerContext ctx) =>
      invokeExtensionGetter(ctx, receiver, ext, member, bindings);
}

/// A bound tear-off of an extension method; the receiver travels through
/// [Variable.implicitReceiver] so a direct invocation prepends it.
final class ExtensionMethodTearOff extends GetTarget {
  const ExtensionMethodTearOff(
    this.receiver,
    this.ext,
    this.member,
    this.typeParameters,
  );

  final Variable receiver;
  final EvalExtension ext;
  final MethodDeclaration member;
  final Map<String, TypeRef> typeParameters;

  @override
  Variable emit(CompilerContext ctx) {
    return Variable(
      CoreTypes.function.ref(ctx),
      callable: CallableValue(
        offset: DeferredOrOffset(
          file: ext.library,
          name: ext.memberKey(member),
        ),
        returnType: AlwaysReturnType.fromAnnotation(
          ctx,
          ext.library,
          member.returnType,
          CoreTypes.dynamic.ref(ctx),
          typeParameters: {
            ...typeParameters,
            for (final param
                in member.typeParameters?.typeParameters ??
                    const <TypeParameter>[])
              param.name.lexeme: TypeRef.unresolved(ext.library, param.name.lexeme),
          },
        ),
        implicitReceiver: receiver,
      ),
    );
  }
}

/// The dynamic member read — `LoadPropertyDynamic`.
final class DynamicGet extends GetTarget {
  const DynamicGet(
    this.receiver,
    this.name, {
    required this.fieldType,
    this.methodReturnType,
    this.callingConvention = CallingConvention.static,
    this.isSuperReceiver = false,
  });

  /// The already-boxed receiver.
  final Variable receiver;
  final String name;
  final TypeRef fieldType;

  /// The signature a method read carries so calls through the result stay
  /// typed.
  final ReturnType? methodReturnType;
  final CallingConvention callingConvention;

  /// `super.name` read: the receiver is a mid-chain link, so the runtime
  /// resolves the member at-or-below that link, not at the dispatch root.
  final bool isSuperReceiver;

  @override
  Variable emit(CompilerContext ctx) => Variable.ssa(
    ctx,
    LoadPropertyDynamic(
      ctx.svar(name),
      receiver.ssa,
      name,
      callerLibrary: ctx.library,
      superReceiver: isSuperReceiver,
    ),
    fieldType,
    rep: ValueRep.boxed,
    callable: CallableValue(
      returnType: methodReturnType,
      convention: callingConvention,
    ),
  );
}

/// How a member write `o.name = v` lowers. [SetTarget.resolve] picks the
/// target; [emit] converts the value for the member's type and produces
/// the ops, returning the stored variable.
sealed class SetTarget {
  const SetTarget();

  /// Member-write resolution: extension setters, link-relative field
  /// storage, direct setter calls, and the dynamic fallback.
  static SetTarget resolve(
    CompilerContext ctx,
    Variable object,
    String name, {
    AstNode? source,
    bool isSuperReceiver = false,
  }) {
    final boxed = object.boxIfNeeded(ctx, source);
    final declaredFieldType = TypeRef.lookupFieldType(
      ctx,
      boxed.type,
      name,
      forSet: true,
      source: source,
    );
    if (declaredFieldType == null &&
        !hasInstanceMember(ctx, boxed.type, name, forSet: true)) {
      // No instance member by this name: an extension setter may apply
      // (`e.name = v` where `set name` lives in `extension on T`).
      final extSetter = resolveExtensionMember(
        ctx,
        boxed.type,
        name,
        setter: true,
      );
      if (extSetter != null) {
        final (ext, member, bindings) = extSetter;
        return ExtensionSetterCall(boxed, ext, member, bindings, name);
      }
    }
    final fieldType = declaredFieldType ?? CoreTypes.dynamic.ref(ctx);
    final exact = boxed.exactType;
    if (exact != null && !hasBridgeSuperclass(ctx, exact)) {
      // Storage for an inherited field lives on its declaring class's
      // link, reached from the receiver by LoadSuper hops.
      final links = [exact, ...ctx.typeSystem.superclassChain(exact)];
      var depth = -1;
      int? fieldIndex;
      for (var i = 0; i < links.length; i++) {
        final link = links[i];
        final key = name.startsWith('_')
            ? '${ctx.libraryUri(link.file)}::$name'
            : name;
        final hasSetter =
            (ctx.instanceDeclarationPositions[link.file]?[link
                            .name]?[1] as Map?)
                    ?.containsKey(key) ==
                true &&
            concreteMemberDecl(ctx, link, name, kind: 1) != null;
        final index = ctx.instanceGetterIndices[link.file]?[link
            .name]?[name];
        if (hasSetter && index != null) {
          fieldIndex = index;
          depth = i;
          break;
        }
        if (hasSetter) {
          depth = i;
          break;
        }
      }
      if (depth >= 0) {
        final link = links[depth];
        final decl = resolveInstanceDeclaration(
          ctx,
          link.file,
          link.name,
          name,
          instantiated: link,
        )?.$2.declaration;
        // Field storage is link-relative so it always needs the declaring
        // link; a real setter needs it only when its body uses `super`.
        final fieldDecl = decl is VariableDeclaration
            ? decl.parent?.parent
            : null;
        final needsLink =
            fieldIndex != null ||
            memberNeedsOwnerLink(ctx, link, name, kind: 1);
        if (fieldIndex != null) {
          final isLateFinal =
              fieldDecl is FieldDeclaration &&
              fieldDecl.fields.isLate &&
              fieldDecl.fields.variables.any(
                (v) => v.name.lexeme == name && (v.isFinal || v.isConst),
              );
          return FieldSlotSet(
            boxed,
            hops: needsLink ? links.sublist(1, depth + 1) : const [],
            index: fieldIndex,
            isLateFinal: isLateFinal,
            fieldType: fieldType,
            name: name,
          );
        }
        final key = name.startsWith('_')
            ? '${ctx.libraryUri(link.file)}::$name'
            : name;
        return DirectSetterCall(
          boxed,
          hops: needsLink ? links.sublist(1, depth + 1) : const [],
          file: link.file,
          className: link.name,
          nameKey: key,
          fieldType: fieldType,
          name: name,
        );
      }
    }
    if (exact == null &&
        boxed.concreteTypes.length == 1 &&
        !hasBridgeSuperclass(ctx, boxed.concreteTypes.first)) {
      // The receiver may hold a subclass: a setter can be called directly
      // on the dispatch root only when it isn't overridden and its body
      // never touches `super` (so any link works as `this`).
      final owner = directMemberOwner(
        ctx,
        boxed.concreteTypes.first,
        name,
        kind: 1,
      );
      if (owner != null &&
          !memberNeedsOwnerLink(ctx, owner, name, kind: 1)) {
        final key = name.startsWith('_')
            ? '${ctx.libraryUri(owner.file)}::$name'
            : name;
        return DirectSetterCall(
          boxed,
          hops: const [],
          file: owner.file,
          className: owner.name,
          nameKey: key,
          fieldType: fieldType,
          name: name,
        );
      }
    }
    return DynamicSet(boxed, name, fieldType, isSuperReceiver: isSuperReceiver);
  }

  /// `this.name = v` where `name` is declared on the enclosing class —
  /// always dynamic dispatch on `#this`.
  static Variable writeDeclared(
    CompilerContext ctx,
    Variable object,
    String name,
    Variable value,
    TypeRef fieldType, {
    AstNode? source,
  }) => DynamicSet(object, name, fieldType).emit(ctx, value);

  /// [resolve] + [emit].
  static Variable write(
    CompilerContext ctx,
    Variable object,
    String name,
    Variable value, {
    AstNode? source,
    bool isSuperReceiver = false,
  }) => resolve(
    ctx,
    object,
    name,
    source: source,
    isSuperReceiver: isSuperReceiver,
  ).emit(ctx, value);

  Variable emit(CompilerContext ctx, Variable value);
}

/// The conversion a field-shaped set applies to the incoming value.
Variable _convertForMember(
  CompilerContext ctx,
  Variable value,
  TypeRef fieldType,
  String name,
) => convertForAssignment(
  ctx,
  value,
  fieldType,
  representation: MachineRepresentation.object,
  description:
      'Cannot assign value of type ${value.type} to field "$name" '
      'of type $fieldType',
);

/// A field-slot write on a link reached by LoadSuper hops.
final class FieldSlotSet extends SetTarget {
  const FieldSlotSet(
    this.object, {
    required this.hops,
    required this.index,
    required this.isLateFinal,
    required this.fieldType,
    required this.name,
  });

  /// The already-boxed receiver the hop chain starts from.
  final Variable object;
  final List<TypeRef> hops;
  final int index;
  final bool isLateFinal;
  final TypeRef fieldType;
  final String name;

  @override
  Variable emit(CompilerContext ctx, Variable value) {
    final val = _convertForMember(ctx, value, fieldType, name);
    var linkSsa = object.ssa;
    for (final parent in hops) {
      linkSsa = Variable.ssa(
        ctx,
        LoadSuper(ctx.svar('super'), linkSsa),
        parent,
        concreteTypes: [parent],
      ).ssa;
    }
    ctx.pushOp(
      SetPropertyStatic(linkSsa, index, val.ssa, isLateFinal: isLateFinal),
    );
    return val;
  }
}

/// A setter invoked directly against a known declaring link.
final class DirectSetterCall extends SetTarget {
  const DirectSetterCall(
    this.object, {
    required this.hops,
    required this.file,
    required this.className,
    required this.nameKey,
    required this.fieldType,
    required this.name,
  });

  /// The already-boxed receiver the hop chain starts from.
  final Variable object;
  final List<TypeRef> hops;
  final int file;
  final String className;
  final String nameKey;
  final TypeRef fieldType;
  final String name;

  @override
  Variable emit(CompilerContext ctx, Variable value) {
    final val = _convertForMember(ctx, value, fieldType, name);
    var linkSsa = object.ssa;
    for (final parent in hops) {
      linkSsa = Variable.ssa(
        ctx,
        LoadSuper(ctx.svar('super'), linkSsa),
        parent,
        concreteTypes: [parent],
      ).ssa;
    }
    ctx.pushOp(
      Call(
        DeferredOrOffset(
          file: file,
          className: className,
          methodType: MemberKind.setter,
          name: nameKey,
        ),
        [linkSsa, val.ssa],
        result: ctx.svar(name),
        typeEnvironmentReceiver: object.ssa,
      ),
    );
    return val;
  }
}

/// `super.name = v` — a setter call on the owner link.
final class SuperSetterCall extends SetTarget {
  const SuperSetterCall(this.owner, this.name, this.fieldType);

  final Variable owner;
  final String name;
  final TypeRef fieldType;

  @override
  Variable emit(CompilerContext ctx, Variable value) {
    final boxed = convertForAssignment(
      ctx,
      value,
      fieldType,
      representation: MachineRepresentation.object,
      description:
          'Cannot assign ${value.type} to super.$name of type $fieldType',
    );
    ctx.pushOp(
      Call(
        DeferredOrOffset(
          file: owner.type.file,
          className: owner.type.name,
          name: name,
          methodType: MemberKind.setter,
        ),
        [owner.ssa, boxed.ssa],
        result: ctx.svar('super_set'),
      ),
    );
    return boxed;
  }
}

/// An extension setter — `E.set name(v)` invoked with the receiver first.
final class ExtensionSetterCall extends SetTarget {
  const ExtensionSetterCall(
    this.object,
    this.ext,
    this.member,
    this.bindings,
    this.name,
  );

  /// The already-boxed receiver.
  final Variable object;
  final EvalExtension ext;
  final MethodDeclaration member;
  final List<TypeRef> bindings;
  final String name;

  @override
  Variable emit(CompilerContext ctx, Variable value) {
    final paramType =
        member.parameters?.parameters.firstOrNull?.type == null
        ? null
        : formalParameterAnnotationType(
            ctx,
            ext.library,
            member.parameters!.parameters.first,
            typeParameters: extBindingsMap(ext, bindings),
          );
    final arg = paramType == null
        ? value.boxIfNeeded(ctx)
        : convertForAssignment(
            ctx,
            value,
            paramType,
            representation: MachineRepresentation.object,
            description:
                'Cannot assign ${value.type} to setter '
                '${ext.name}.$name on ${object.type}',
          );
    ctx.pushOp(
      Call(
        DeferredOrOffset(file: ext.library, name: ext.memberKey(member)),
        [object.boxIfNeeded(ctx).ssa, arg.ssa],
        result: ctx.svar('setter_result'),
        typeArguments:
            extensionCallTypeArguments(ctx, ext, member, bindings, const {}) ??
            const [],
      ),
    );
    // The assignment's value is the value as converted for the setter's
    // parameter — e.g. an implicit `.call` tear-off.
    return arg;
  }
}

/// The dynamic member write — `SetPropertyDynamic`.
final class DynamicSet extends SetTarget {
  const DynamicSet(
    this.object,
    this.name,
    this.fieldType, {
    this.isSuperReceiver = false,
  });

  /// The already-boxed receiver.
  final Variable object;
  final String name;
  final TypeRef fieldType;

  /// `super.name = v`: the receiver is a mid-chain link, so the runtime
  /// resolves the member at-or-below that link, not at the dispatch root.
  final bool isSuperReceiver;

  @override
  Variable emit(CompilerContext ctx, Variable value) {
    final val = _convertForMember(ctx, value, fieldType, name);
    ctx.pushOp(
      SetPropertyDynamic(
        object.ssa,
        name,
        val.ssa,
        callerLibrary: ctx.library,
        superReceiver: isSuperReceiver,
      ),
    );
    return val;
  }
}
