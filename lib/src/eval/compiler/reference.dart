import 'helpers/global.dart';
import 'helpers/conversion.dart';
import 'model/function_type.dart';
import '../ir/closures.dart';
import '../ir/exception.dart';
import 'backend/representation.dart' show MachineRepresentation;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/bridge/declaration.dart';
import 'package:dart_eval/src/eval/compiler/dispatch.dart';
import 'package:dart_eval/src/eval/compiler/expression/function.dart';
import 'package:dart_eval/src/eval/compiler/expression/method_invocation.dart';
import 'package:dart_eval/src/eval/compiler/helpers/invoke.dart';
import 'package:dart_eval/src/eval/compiler/helpers/tearoff.dart';
import 'package:dart_eval/src/eval/ir/primitives.dart';
import 'package:dart_eval/src/eval/ir/types.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/ir/bridge.dart';
import 'package:collection/collection.dart';
import 'package:dart_eval/src/eval/ir/collection.dart';
import 'package:dart_eval/src/eval/ir/globals.dart';
import 'package:dart_eval/src/eval/ir/memory.dart';
import 'package:dart_eval/src/eval/ir/objects.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/compiler/expression/identifier.dart';
import 'package:dart_eval/src/eval/compiler/helpers/extension.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'values/abi.dart';

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
    var type = receiver.type;
    final kind = forSet ? 1 : 0;
    while (true) {
      // Abstract re-declarations have no body — skip them like runtime
      // dispatch does; the concrete implementation lives deeper.
      final hit =
          concreteMemberDecl(ctx, type, name, kind: 2) != null ||
          concreteMemberDecl(ctx, type, name, kind: kind) != null;
      if (hit) {
        return receiver;
      }
      final parent = ctx.typeSystem.superclassOf(type);
      if (parent == null) return receiver;
      type = parent;
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
    final memberDecl =
        ctx.instanceDeclarationsMap[receiver.type.file]?[receiver
            .type
            .name]?[name];
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
      resolveType(ctx, source: source),
      rep: ValueRep.boxed,
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

  /// The static type an extension accessor named [name] on [object]
  /// contributes — the setter's parameter type or the getter's return type —
  /// or null when no extension member applies.
  TypeRef? _extensionMemberType(CompilerContext ctx, {required bool forSet}) {
    final found = resolveExtensionMember(
      ctx,
      object!.type,
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

  @override
  TypeRef resolveType(
    CompilerContext ctx, {
    bool forSet = false,
    AstNode? source,
  }) {
    if (object != null) {
      if (object!.type.isSpec(CoreTypes.type)) {
        final concrete = object!.concreteTypes[0];
        if (extensionForType(ctx, concrete) != null) {
          // `E.member` — a tear-off (or getter invocation) through the
          // extension namespace; precise typing isn't needed here.
          return CoreTypes.function.ref(ctx);
        }
        final concreteType = concrete;
        // Static accessors (`C.x*g`/`C.x*s`) report the value type —
        // the getter's return type or the setter's parameter type — so
        // compound-assignment and boxing decisions see the real member.
        final accessor = ctx
            .topLevelDeclarationsMap[concreteType
                .file]?['${concreteType.name}.$name${forSet ? '*s' : '*g'}']
            ?.declaration;
        if (accessor is MethodDeclaration) {
          if (accessor.isSetter && forSet) {
            return _setterValueType(
                  ctx,
                  concreteType.file,
                  accessor.parameters,
                ) ??
                CoreTypes.dynamic.ref(ctx);
          }
          if (accessor.isGetter && !forSet) {
            return accessor.returnType != null
                ? TypeRef.fromAnnotation(
                    ctx,
                    concreteType.file,
                    accessor.returnType!,
                  )
                : CoreTypes.dynamic.ref(ctx);
          }
        }
        return concreteType;
      }
      var fieldType = TypeRef.lookupFieldType(
        ctx,
        object!.type,
        name,
        forSet: forSet,
        source: source,
      );
      // Extension accessors apply when the receiver's interface has no
      // member of the matching kind — same gate as [setValue].
      if (fieldType == null &&
          !_hasInstanceMember(ctx, object!.type, name, forSet: forSet)) {
        fieldType = _extensionMemberType(ctx, forSet: forSet);
      }
      return fieldType ?? CoreTypes.dynamic.ref(ctx);
    }

    // Locals
    final local = ctx.lookupLocal(name);
    if (local != null) {
      // The write context of an assignment is the variable's declared
      // type — a promoted type doesn't narrow what may be stored into it.
      return forSet ? local.declaredType : local.type;
    }

    // Inside an anonymous-method body, member names resolve on the
    // anonymous receiver rather than the enclosing class. The receiver is
    // read through the `#this` local so nested closures capture it.
    final anonymousReceiver = ctx.anonymousThisReceiver;
    final receiverVar = anonymousReceiver == null
        ? null
        : ctx.lookupLocal('#this') ?? anonymousReceiver;
    if (receiverVar != null &&
        _hasReceiverMember(ctx, receiverVar, name, forSet: forSet)) {
      final fieldType = TypeRef.lookupFieldType(
        ctx,
        receiverVar.type,
        name,
        forSet: forSet,
        source: source,
      );
      if (fieldType != null) return fieldType;
      // Methods produce tear-offs when referenced without a call.
      return CoreTypes.function.ref(ctx);
    }

    // Instance
    if (anonymousReceiver == null && ctx.currentClass != null) {
      final fieldType = _resolveInstanceFieldType(
        ctx,
        name,
        forSet: forSet,
        source: source,
      );
      if (fieldType != null) return fieldType;

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
          if (staticDec.isGetter && !forSet) {
            return staticDec.returnType != null
                ? TypeRef.fromAnnotation(ctx, scopeFile, staticDec.returnType!)
                : CoreTypes.dynamic.ref(ctx);
          }
          if (staticDec.isSetter && forSet) {
            return _setterValueType(ctx, scopeFile, staticDec.parameters) ??
                CoreTypes.dynamic.ref(ctx);
          }
          return CoreTypes.function.ref(ctx);
        } else if (staticDec is VariableDeclaration) {
          final name = '$scopeName.${staticDec.name.lexeme}';
          return resolveGlobalType(ctx, scopeFile, name);
        }
      }
    }

    final typeParameter = ctx.typeScopes[ctx.library]?[name];
    if (typeParameter != null && name != '_') {
      return CoreTypes.type.ref(ctx);
    }

    // A bare identifier inside an extension body or instance method can
    // denote a member of the implicit receiver. The members that outrank
    // globals are the extension's own members, and — in a class method —
    // the members the enclosing class itself declares; inherited members
    // and members of other extensions only apply after globals miss.
    final $this = (ctx.currentExtension == null && ctx.currentClass == null)
        ? null
        : ctx.lookupLocal('#this');
    final currentExtension = ctx.currentExtension;
    if (currentExtension is ExtensionDeclaration) {
      final ext = ctx.extensions.firstWhereOrNull(
        (e) => e.declaration == currentExtension,
      );
      if (ext != null) {
        final member =
            extensionMember(ext, name, getter: !forSet, setter: forSet) ??
            extensionStaticMember(ext, name, getter: !forSet, setter: forSet);
        if (member != null) {
          if (forSet) {
            return _setterValueType(ctx, ext.library, member.parameters) ??
                CoreTypes.dynamic.ref(ctx);
          }
          return AlwaysReturnType.fromAnnotation(
                ctx,
                ext.library,
                member.returnType,
                CoreTypes.dynamic.ref(ctx),
              ).type ??
              CoreTypes.dynamic.ref(ctx);
        }
        if (extensionStaticField(ext, name) != null) {
          return resolveGlobalType(ctx, ext.library, '${ext.name}.$name');
        }
      }
    } else if ($this != null &&
        ctx.currentClass != null &&
        ctx.instanceDeclarationsMap[ctx.enclosingLibrary ??
                ctx.library]?[ctx.currentClassName!]?[name] !=
            null) {
      final memberType = TypeRef.lookupFieldType(
        ctx,
        $this.type,
        name,
        forSet: forSet,
        source: source,
      );
      if (memberType != null) return memberType;
    }

    DeclarationOrBridge? declarationValue;
    try {
      declarationValue = _lookupVisibleValue(ctx, name, source, forSet: forSet);
    } on CompileError {
      // `this.` members apply after globals miss: instance members
      // (inherited included), then members of applicable extensions.
      if ($this != null) {
        final memberType = TypeRef.lookupFieldType(
          ctx,
          $this.type,
          name,
          forSet: forSet,
          source: source,
        );
        if (memberType != null) return memberType;
        final extMember = resolveExtensionMember(
          ctx,
          $this.type,
          name,
          getter: !forSet,
          setter: forSet,
        );
        if (extMember != null) {
          if (forSet) {
            return _setterValueType(
                  ctx,
                  extMember.$1.library,
                  extMember.$2.parameters,
                ) ??
                CoreTypes.dynamic.ref(ctx);
          }
          return AlwaysReturnType.fromAnnotation(
                ctx,
                extMember.$1.library,
                extMember.$2.returnType,
                CoreTypes.dynamic.ref(ctx),
              ).type ??
              CoreTypes.dynamic.ref(ctx);
        }
      }
      rethrow;
    }
    final decl = declarationValue.declaration!;

    if (decl is VariableDeclaration) {
      return resolveGlobalType(
        ctx,
        declarationValue.sourceLib,
        decl.name.lexeme,
      );
    }
    if (decl is FunctionDeclaration && decl.isGetter && !forSet) {
      return decl.returnType != null
          ? TypeRef.fromAnnotation(
              ctx,
              declarationValue.sourceLib,
              decl.returnType!,
            )
          : CoreTypes.dynamic.ref(ctx);
    }
    if (decl is FunctionDeclaration && decl.isSetter && forSet) {
      return _setterValueType(
            ctx,
            declarationValue.sourceLib,
            decl.functionExpression.parameters,
          ) ??
          CoreTypes.dynamic.ref(ctx);
    }

    return CoreTypes.type.ref(ctx);
  }

  @override
  Variable setValue(CompilerContext ctx, Variable value, [AstNode? source]) {
    if (object != null) {
      // If the object is a class name, access static fields
      if (object!.type.isSpec(CoreTypes.type)) {
        final classType = object!.concreteTypes[0];
        // A static setter (`C.x*s`) takes precedence over a static field
        // global of the same base name.
        final setter = ctx
            .topLevelDeclarationsMap[classType
                .file]?['${classType.name}.$name*s']
            ?.declaration;
        if (setter is MethodDeclaration && setter.isSetter) {
          return _invokeSetter(
            ctx,
            DeferredOrOffset(
              file: classType.file,
              name: '${classType.name}.$name*s',
            ),
            value,
            classType.file,
            setter.parameters,
            isMethod: true,
            source: source,
          );
        }
        final fqName = '${classType.name}.$name';
        return storeGlobalBinding(ctx, classType.file, fqName, value, source);
      }
      object = object!.boxIfNeeded(ctx, source);
      // Explicit application `E(x).s = v` pins member resolution to E.
      if (object!.boundExtension case final bound?) {
        final member = extensionMember(bound.ext, name, setter: true);
        if (member == null) {
          throw CompileError(
            'Extension ${bound.ext.name} has no setter $name',
            source,
          );
        }
        final paramType =
            member.parameters?.parameters.firstOrNull?.type == null
            ? null
            : formalParameterAnnotationType(
                ctx,
                bound.ext.library,
                member.parameters!.parameters.first,
                typeParameters: extBindingsMap(bound.ext, bound.onBindings),
              );
        final arg = paramType == null
            ? value.boxIfNeeded(ctx)
            : convertForAssignment(
                ctx,
                value,
                paramType,
                representation: MachineRepresentation.object,
                source: source,
              );
        ctx.pushOp(
          Call(
            DeferredOrOffset(
              file: bound.ext.library,
              name: bound.ext.memberKey(member),
            ),
            [object!.ssa, arg.ssa],
            result: ctx.svar('setter_result'),
            typeArguments:
                extensionCallTypeArguments(
                  ctx,
                  bound.ext,
                  member,
                  bound.onBindings,
                  const {},
                ) ??
                const [],
          ),
        );
        return arg;
      }
      final declaredFieldType = TypeRef.lookupFieldType(
        ctx,
        object!.type,
        name,
        forSet: true,
        source: source,
      );
      if (declaredFieldType == null &&
          !_hasInstanceMember(ctx, object!.type, name, forSet: true)) {
        // No instance member by this name: an extension setter may apply
        // (`e.name = v` where `set name` lives in `extension on T`).
        final extSetter = resolveExtensionMember(
          ctx,
          object!.type,
          name,
          setter: true,
        );
        if (extSetter != null) {
          final (ext, member, bindings) = extSetter;
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
                  source: source,
                  description:
                      'Cannot assign ${value.type} to setter '
                      '${ext.name}.$name on ${object!.type}',
                );
          ctx.pushOp(
            Call(
              DeferredOrOffset(file: ext.library, name: ext.memberKey(member)),
              [object!.boxIfNeeded(ctx).ssa, arg.ssa],
              result: ctx.svar('setter_result'),
              typeArguments:
                  extensionCallTypeArguments(
                    ctx,
                    ext,
                    member,
                    bindings,
                    const {},
                  ) ??
                  const [],
            ),
          );
          // The assignment's value is the value as converted for the
          // setter's parameter — e.g. an implicit `.call` tear-off.
          return arg;
        }
      }
      final fieldType = declaredFieldType ?? CoreTypes.dynamic.ref(ctx);
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
      final exact = object!.exactType;
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
              (ctx.instanceDeclarationPositions[link.file]?[link.name]?[1]
                          as Map?)
                      ?.containsKey(key) ==
                  true &&
              concreteMemberDecl(ctx, link, name, kind: 1) != null;
          final index = ctx.instanceGetterIndices[link.file]?[link.name]?[name];
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
          var linkSsa = object!.ssa;
          if (needsLink) {
            for (var i = 0; i < depth; i++) {
              final parent = links[i + 1];
              linkSsa = Variable.ssa(
                ctx,
                LoadSuper(ctx.svar('super'), linkSsa),
                parent,
                concreteTypes: [parent],
              ).ssa;
            }
          }
          if (fieldIndex != null) {
            final isLateFinal =
                fieldDecl is FieldDeclaration &&
                fieldDecl.fields.isLate &&
                fieldDecl.fields.variables.any(
                  (v) => v.name.lexeme == name && (v.isFinal || v.isConst),
                );
            ctx.pushOp(
              SetPropertyStatic(
                linkSsa,
                fieldIndex,
                val.ssa,
                isLateFinal: isLateFinal,
              ),
            );
            return val;
          }
          final key = name.startsWith('_')
              ? '${ctx.libraryUri(link.file)}::$name'
              : name;
          ctx.pushOp(
            Call(
              DeferredOrOffset(
                file: link.file,
                className: link.name,
                methodType: 1,
                name: key,
              ),
              [linkSsa, val.ssa],
              result: ctx.svar(name),
              typeEnvironmentReceiver: object!.ssa,
            ),
          );
          return val;
        }
      }
      if (exact == null &&
          object!.concreteTypes.length == 1 &&
          !hasBridgeSuperclass(ctx, object!.concreteTypes.first)) {
        // The receiver may hold a subclass: a setter can be called directly
        // on the dispatch root only when it isn't overridden and its body
        // never touches `super` (so any link works as `this`).
        final owner = directMemberOwner(
          ctx,
          object!.concreteTypes.first,
          name,
          kind: 1,
        );
        if (owner != null && !memberNeedsOwnerLink(ctx, owner, name, kind: 1)) {
          final key = name.startsWith('_')
              ? '${ctx.libraryUri(owner.file)}::$name'
              : name;
          ctx.pushOp(
            Call(
              DeferredOrOffset(
                file: owner.file,
                className: owner.name,
                methodType: 1,
                name: key,
              ),
              [object!.ssa, val.ssa],
              result: ctx.svar(name),
              typeEnvironmentReceiver: object!.ssa,
            ),
          );
          return val;
        }
      }
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
        // Slot reads after a handler edge can observe a value written before
        // the exception — allocation proofs can't be trusted across it.
        ctx.locals[local.frameIndex!][local.localName!] = local.widened();
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
        // The cell can also be written by a closure invocation — allocation
        // proofs can't be trusted across it.
        ctx.locals[local.frameIndex!][local.localName!] = local.widened();
        return stored;
      }
      ctx.pushOp(Assign(local.ssa, stored.ssa));
      // Assignment keeps the promoted type only when the stored value
      // still conforms to it; otherwise the variable is demoted to its
      // declared type (a `dynamic` local stays dynamic).
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

    // Inside an anonymous-method body, unqualified assignments target
    // the anonymous receiver — the enclosing class scope does not apply.
    final anonymousReceiver = ctx.anonymousThisReceiver;
    final receiverVar = anonymousReceiver == null
        ? null
        : ctx.lookupLocal('#this') ?? anonymousReceiver;
    if (receiverVar != null &&
        _hasReceiverMember(ctx, receiverVar, name, forSet: true)) {
      return IdentifierReference(
        receiverVar,
        name,
      ).setValue(ctx, value, source);
    }

    // Inside an extension body, unqualified assignments first target the
    // extension's own setters. In either an extension body or an instance
    // method, remaining names resolve through the implicit receiver —
    // instance members and other applicable extensions (`this.name = v`).
    final currentExtension = ctx.currentExtension;
    if (anonymousReceiver == null &&
        (currentExtension is ExtensionDeclaration ||
            ctx.currentClass != null)) {
      final $this = ctx.lookupLocal('#this');
      if (currentExtension is ExtensionDeclaration) {
        final ext = ctx.extensions.firstWhereOrNull(
          (e) => e.declaration == currentExtension,
        );
        if (ext != null) {
          for (final member in ext.members) {
            if (member is FieldDeclaration) {
              if (member.isStatic &&
                  member.fields.variables.any((v) => v.name.lexeme == name)) {
                return storeGlobalBinding(
                  ctx,
                  ext.library,
                  '${ext.name}.$name',
                  value,
                  source,
                );
              }
              continue;
            }
            if (member is! MethodDeclaration || member.name.lexeme != name) {
              continue;
            }
            if (member.isSetter) {
              // Box into fresh slots: `value` flows on as the assignment
              // result and must keep its unboxed representation.
              final boxedValue = value.boxIntoFreshSlot(ctx);
              // Static members take no receiver argument.
              final args = member.isStatic || $this == null
                  ? [boxedValue.ssa]
                  : [$this.boxIfNeeded(ctx).ssa, boxedValue.ssa];
              ctx.pushOp(
                Call(
                  DeferredOrOffset(
                    file: ext.library,
                    name: ext.memberKey(member),
                  ),
                  args,
                  result: ctx.svar('setter_result'),
                ),
              );
              return value;
            }
            // A same-named non-setter member shadows the `on` type's members.
            break;
          }
        }
      }
    }

    // Instance — declared on the enclosing class only, as for getValue.
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
      final staticDeclaration = resolveScopedStaticDeclaration(
        ctx,
        name,
        forSet: true,
      );
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
      if (declaration is MethodDeclaration && declaration.isSetter) {
        return _invokeSetter(
          ctx,
          DeferredOrOffset.lookupStatic(
            ctx,
            staticDeclaration!.$2,
            staticDeclaration.$3,
            '$name*s',
          ),
          value,
          staticDeclaration.$2,
          declaration.parameters,
          isMethod: true,
          source: source,
        );
      }
    }

    // Otherwise a global or import — or, in an extension body/instance
    // method, an extension member applied through the implicit `this`
    // (`this.name = v`), which only applies after globals miss.
    DeclarationOrBridge? declarationValue;
    try {
      declarationValue = _lookupVisibleValue(ctx, name, source, forSet: true);
    } on CompileError {
      if (anonymousReceiver == null &&
          (currentExtension is ExtensionDeclaration ||
              ctx.currentClass != null)) {
        final $this = ctx.lookupLocal('#this');
        if ($this != null &&
            _hasReceiverMember(ctx, $this, name, forSet: true)) {
          return IdentifierReference($this, name).setValue(ctx, value, source);
        }
      }
      rethrow;
    }
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

    if (decl is FunctionDeclaration && decl.isSetter) {
      return _invokeSetter(
        ctx,
        DeferredOrOffset(
          file: declarationValue.sourceLib,
          name: '${decl.name.lexeme}*s',
        ),
        value,
        declarationValue.sourceLib,
        decl.functionExpression.parameters,
        isMethod: false,
        source: source,
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
      if (object!.type.isSpec(CoreTypes.type) &&
          object!.concreteTypes.isNotEmpty) {
        final ext = extensionForType(ctx, object!.concreteTypes[0]);
        if (ext != null) {
          // `E.member` through the extension namespace: the function (or
          // getter) is a static callable registered under its member key.
          final member = ext.members
              .whereType<MethodDeclaration>()
              .firstWhereOrNull((m) => m.name.lexeme == name);
          if (member == null) {
            throw CompileError(
              'Extension member not found: ${ext.name}.$name',
              source,
            );
          }
          if (member.isGetter || member.isSetter) {
            // `E.m` where m is a static accessor: evaluating the expression
            // invokes it (accessors can't be torn off).
            if (member.isSetter) {
              throw CompileError(
                'Cannot read extension setter ${ext.name}.$name',
                source,
              );
            }
            final s = ctx.svar('getter_result');
            ctx.pushOp(
              Call(
                DeferredOrOffset(
                  file: ext.library,
                  name: ext.memberKey(member),
                ),
                const [],
                result: s,
              ),
            );
            final returnType =
                AlwaysReturnType.fromAnnotation(
                  ctx,
                  ext.library,
                  member.returnType,
                  CoreTypes.dynamic.ref(ctx),
                ).type ??
                CoreTypes.dynamic.ref(ctx);
            return Variable.of(ctx, s, returnType, rep: ValueRep.boxed);
          }
          return Variable(
            CoreTypes.function.ref(ctx),
            methodOffset: DeferredOrOffset(
              file: ext.library,
              name: ext.memberKey(member),
            ),
            callingConvention: CallingConvention.static,
          );
        }
        final classType = object!.concreteTypes[0];
        if (classType.isTypeParameter) {
          // `T.member` is an instance access on T's runtime `Type` object,
          // not a static access — dispatch dynamically.
          object = object!.boxIfNeeded(ctx, source);
          return object!.getProperty(ctx, name);
        }
        final superclass = ctx.typeSystem.superclassOf(classType);
        if (superclass != null && superclass.isSpec(CoreTypes.enumType)) {
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
                rep: ValueRep.boxed,
              );
            }

            throw CompileError(
              'Cannot find external getter or field: $name on $classType',
              source,
            );
          }
        }
        final fqName = '${classType.name}.${ctorNameOf(name)}';
        // Static accessors register under `*g`/`*s` keys — a getter
        // reference invokes it.
        final getterMember =
            ctx.topLevelDeclarationsMap[classType.file]?['$fqName*g'];
        final member =
            getterMember ??
            ctx.topLevelDeclarationsMap[classType.file]![fqName];
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
            file: classType.file,
            name: memberDecl is MethodDeclaration && memberDecl.isGetter
                ? '$fqName*g'
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

    // Inside an extension body, the extension's own members shadow both
    // outer scopes and the receiver's members.
    final currentExtension = ctx.currentExtension;
    if (currentExtension is ExtensionDeclaration) {
      final ext = ctx.extensions.firstWhereOrNull(
        (e) => e.declaration == currentExtension,
      );
      final $this = ctx.lookupLocal('#this');
      if (ext != null) {
        for (final member in ext.members) {
          if (member is FieldDeclaration) {
            if (member.isStatic &&
                member.fields.variables.any((v) => v.name.lexeme == name)) {
              return _loadGlobalVariable(ctx, ext.library, '${ext.name}.$name');
            }
            continue;
          }
          if (member is! MethodDeclaration || member.name.lexeme != name) {
            continue;
          }
          if (member.isStatic) {
            // Static members resolve through the extension's namespace —
            // no receiver.
            final offset = DeferredOrOffset(
              file: ext.library,
              name: ext.memberKey(member),
            );
            if (member.isGetter) {
              final resvar = ctx.svar('call_result');
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
            if (member.isSetter) break;
            return Variable(
              CoreTypes.function.ref(ctx),
              methodOffset: offset,
              callingConvention: CallingConvention.static,
            );
          }
          if ($this == null) break;
          if (member.isGetter) {
            return invokeExtensionGetter(
              ctx,
              $this,
              ext,
              member,
              matchExtensionOn(ctx, $this.type, ext) ?? const [],
            );
          }
          if (member.isSetter) break;
          return Variable(
            CoreTypes.function.ref(ctx),
            methodOffset: DeferredOrOffset(
              file: ext.library,
              name: ext.memberKey(member),
            ),
            methodReturnType: AlwaysReturnType.fromAnnotation(
              ctx,
              ext.library,
              member.returnType,
              CoreTypes.dynamic.ref(ctx),
            ),
            callingConvention: CallingConvention.static,
          )..implicitReceiver = $this;
        }
      }
    }

    // Inside an anonymous-method body, unqualified names resolve against
    // the anonymous receiver — the enclosing class scope does not apply.
    final anonymousReceiver = ctx.anonymousThisReceiver;
    final receiverVar = anonymousReceiver == null
        ? null
        : ctx.lookupLocal('#this') ?? anonymousReceiver;
    if (receiverVar != null && _hasReceiverMember(ctx, receiverVar, name)) {
      return IdentifierReference(receiverVar, name).getValue(ctx, source);
    }

    // Next, the instance (if available). Unqualified names only reach
    // members the enclosing class itself declares; inherited members lose
    // to globals and resolve through `this` after globals miss.
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
        final $type = instanceDeclaration.$1;
        final decOrBridge = instanceDeclaration.$2;

        final $this =
            ctx.lookupLocal('#this') ??
            (throw CompileError(
              'Cannot access instance member $name in a static context',
            ));

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
              rep: ValueRep.boxed,
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
              rep: ValueRep.boxed,
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
          rep: ValueRep.boxed,
        );
      }

      // A bare identifier inside an enum member can name one of the enum's
      // own values (`static _E get getter => e1`) — they live in
      // enumValueIndices rather than the declaration maps.
      final currentDecl = ctx.memberDeclaringClass ?? ctx.currentClass;
      if (currentDecl is EnumDeclaration) {
        final enumType = TypeRef.lookupDeclaration(
          ctx,
          ctx.library,
          currentDecl,
        );
        final gIndex = ctx.enumValueIndices[ctx.library]?[enumType.name]?[name];
        if (gIndex != null) {
          return Variable.ssa(
            ctx,
            LoadGlobal(ctx.svar(name), gIndex),
            enumType,
            rep: ValueRep.boxed,
          );
        }
      }

      final staticDeclaration = resolveScopedStaticDeclaration(ctx, name);

      if (staticDeclaration != null &&
          staticDeclaration.$1.declaration != null) {
        final (staticDecl, scopeFile, scopeName) = staticDeclaration;
        final staticDec = staticDecl.declaration!;
        if (staticDec is MethodDeclaration) {
          // Static accessors live under `*g`/`*s` keys; a getter reference
          // invokes it (the member's value, not its tear-off).
          if (staticDec.isGetter) {
            final fn = Variable(
              CoreTypes.function.ref(ctx),
              methodOffset: DeferredOrOffset.lookupStatic(
                ctx,
                scopeFile,
                scopeName,
                '$name*g',
              ),
            );
            return fn.invoke(ctx, null, []).result;
          }
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
    final typeParameter = ctx.typeScopes[ctx.library]?[name];
    if (typeParameter != null && name != '_') {
      return Variable.ssa(
        ctx,
        LoadTypeParameter(
          ctx.svar('type'),
          ctx.runtimeTypes.idOf(typeParameter),
        ),
        CoreTypes.type.ref(ctx),
        concreteTypes: [typeParameter],
      );
    }

    final declaration =
        ctx.visibleDeclarations[ctx.library]![name] ??
        ctx.visibleDeclarations[ctx.library]!['$name*g'] ??
        ctx.visibleDeclarations[ctx.library]![name.split('.')[0]];

    // A bare identifier inside an extension body or instance method can
    // denote a member of the receiver — lowest precedence, after globals.
    // `this.m` lookup also applies extension members of the receiver type.
    if (declaration == null &&
        (currentExtension != null || ctx.currentClass != null)) {
      final $this = ctx.lookupLocal('#this');
      if ($this != null) {
        try {
          return $this.getProperty(ctx, name);
        } on CompileError {
          // Not a member of the receiver type either.
        }
      }
    }

    final activeDeclaration =
        declaration ??
        (throw CompileError('Could not find declaration "$name"', source));

    // Prefix children are keyed by declaration name ('B'), so a prefixed
    // member reference 'p.B.ctor' resolves 'B' here; [_declarationToVariable]
    // handles the member suffix via _refName.
    final split = name.split('.');
    final children = activeDeclaration.children;
    final viaPrefix = activeDeclaration.declaration == null;
    if (viaPrefix && split.length > 1 && split[1] == 'loadLibrary') {
      final stub = _deferredLoadLibrary(ctx, split[0]);
      if (stub != null) return stub;
    }
    final activeDec =
        activeDeclaration.declaration ??
        (split.length > 1 && children != null
            ? (children['${split[1]}*g'] ?? children[split[1]])
            : null) ??
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
      final exact = object!.exactType;
      final actualType =
          exact ??
          (object!.concreteTypes.length == 1 ? object!.concreteTypes[0] : null);
      if (actualType != null) {
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

    final declaration =
        ctx.visibleDeclarations[ctx.library]![name] ??
        ctx.visibleDeclarations[ctx.library]![name.split('.')[0]];
    final decOrBridge = declaration?.declaration;
    if (decOrBridge == null) return null;
    final topDecl = decOrBridge.declaration;
    // `x()` where `x` is a getter must call the getter's *result*, not the
    // getter itself — no direct dispatch.
    if (topDecl is FunctionDeclaration &&
        (topDecl.isGetter || topDecl.isSetter)) {
      return null;
    }
    return _declarationToStaticDispatch(decOrBridge, name, ctx, source);
  }
}

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
    methodReturnType: AlwaysReturnType(
      CoreTypes.future
          .ref(ctx)
          .copyWith(specifiedTypeArgs: [CoreTypes.nullType.ref(ctx)]),
      false,
    ),
  );
}

/// A [Reference] with a prefixed String identifier, for accessing prefixed
/// imports.
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
    final child =
        children['$identifier*g'] ??
        children[identifier] ??
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
    if (identifier == 'loadLibrary') {
      final stub = _deferredLoadLibrary(ctx, prefix);
      if (stub != null) return stub;
    }
    final child =
        children['$identifier*g'] ??
        children[identifier] ??
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
    final dec =
        ctx.visibleDeclarations[ctx.library]![prefix] ??
        (throw CompileError('Cannot find prefix $prefix', source));
    if (dec.declaration != null) {
      throw CompileError('Cannot use a declaration as a prefix', source);
    }
    final children = dec.children!;
    // Accessors register under `*s` — writes look there before the plain
    // name (top-level variables).
    final child =
        children['$identifier*s'] ??
        children[identifier] ??
        (throw CompileError(
          "'$identifier' isn't defined for the prefix '$prefix'",
          source,
        ));
    final decl = child.declaration;
    if (decl is VariableDeclaration) {
      return storeGlobalBinding(
        ctx,
        child.sourceLib,
        decl.name.lexeme,
        value,
        source,
      );
    }
    if (decl is FunctionDeclaration && decl.isSetter) {
      return _invokeSetter(
        ctx,
        DeferredOrOffset(file: child.sourceLib, name: '${decl.name.lexeme}*s'),
        value,
        child.sourceLib,
        decl.functionExpression.parameters,
        isMethod: false,
        source: source,
      );
    }
    throw CompileError('Cannot find value to set: $prefix.$identifier', source);
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
    // A write's contextual type must not execute the indexed getter. For a
    // custom `[]=` the write type is the operator's value parameter —
    // callers use it as the RHS's context type (e.g. `a?[i] ??= e`).
    if (forSet) {
      return _setterValueType(ctx, source) ?? CoreTypes.dynamic.ref(ctx);
    }
    return getValue(ctx).type;
  }

  /// The declared value-parameter type of the receiver's `[]=` operator, or
  /// null when it cannot be resolved (dynamic receivers, missing member).
  TypeRef? _setterValueType(CompilerContext ctx, [AstNode? source]) {
    try {
      final decl0 = resolveInstanceMethod(ctx, _variable.type, '[]=', source);
      final decl = decl0.declaration;
      if (decl is MethodDeclaration) {
        final param = decl.parameters?.parameters.elementAtOrNull(1);
        if (param?.type == null) return null;
        // Bind the declaring class's type parameters through the receiver's
        // supertype chain so a `WriteType` annotation resolves concretely.
        return formalParameterAnnotationType(
          ctx,
          decl0.sourceLib,
          param!,
          typeParameters: classTypeArguments(
            ctx,
            _variable.type,
            decl0.sourceLib,
            decl,
          ),
        );
      }
    } on CompileError {
      // An extension `[]=` may apply instead.
    }
    final found = resolveExtensionMember(ctx, _variable.type, '[]=');
    if (found == null) return null;
    final (ext, member, bindings) = found;
    final param = member.parameters?.parameters.elementAtOrNull(1);
    if (param?.type == null) return null;
    return formalParameterAnnotationType(
      ctx,
      ext.library,
      param!,
      typeParameters: extBindingsMap(ext, bindings),
    );
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
        listElementType,
        rep: ValueRep.boxed,
      );
    }

    if (_variable.type.isAssignableTo(
      ctx,
      CoreTypes.map.ref(ctx),
      forceAllowDynamic: false,
    )) {
      // `Map.[]` takes `Object?` — any index type is allowed at compile
      // time; a miss returns null rather than throwing.
      final map = _variable.unboxIfNeeded(ctx);
      // Collection elements are always boxed (Abi.collectionElement), so the
      // key travels boxed and a miss must produce a boxed null.
      _index = _index.boxIfNeeded(ctx, source);

      final mapType = _variable.type.specifiedTypeArgs.length < 2
          ? CoreTypes.dynamic.ref(ctx)
          : _variable.type.specifiedTypeArgs[1];

      final mapResult = Variable.ssa(
        ctx,
        IndexMap(ctx.svar('map'), map.ssa, _index.ssa),
        mapType,
        rep: ValueRep.boxed,
      );

      return Variable.ssa(
        ctx,
        MaybeBoxNull(ctx.svar('map'), mapResult.ssa),
        mapType,
        rep: ValueRep.boxed,
      );
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

    // Coerce the value against the `[]=` signature — the implicit `.call`
    // tear-off applies when the parameter is a function type. A missing
    // instance member means an extension `[]=` may apply (handled inside
    // [Variable.invoke]).
    final valueType = _setterValueType(ctx, source);
    final converted = valueType == null
        ? value
        : convertForAssignment(
            ctx,
            value,
            valueType,
            representation: MachineRepresentation.object,
            source: source,
          );

    final result = _variable.invoke(ctx, '[]=', [_index, converted]);
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

  if (decl is ExtensionDeclaration) {
    // `E` as an expression is the extension's namespace: `E.m(recv, ...)`
    // (explicit application) and `E.staticM(...)` resolve through it. The
    // pseudo-type `E` exists only in the declarations map, never as a class.
    final extType = TypeRef(decOrBridge.sourceLib, declarationName(decl));
    return Variable(
      CoreTypes.type.ref(ctx),
      concreteTypes: [extType],
      methodOffset: DeferredOrOffset(
        file: decOrBridge.sourceLib,
        name: '${declarationName(decl)}.',
      ),
      callingConvention: CallingConvention.static,
    );
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
    returnType = ctx.withTypeParameters<TypeRef>(
      decOrBridge.sourceLib,
      null,
      decl.functionExpression.typeParameters?.typeParameters,
      () =>
          TypeRef.fromAnnotation(ctx, decOrBridge.sourceLib, decl.returnType!),
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

  // Accessors compile under `*g`/`*s` keys — use the accessor's own key so
  // deferred resolution finds the right function entry.
  final offset = DeferredOrOffset(
    file: decOrBridge.sourceLib,
    name: decl is FunctionDeclaration
        ? (decl.isGetter
              ? '${decl.name.lexeme}*g'
              : decl.isSetter
              ? '${decl.name.lexeme}*s'
              : name)
        : name,
  );

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

  // Accessors compile under `*g`/`*s` keys — use the accessor's own key so
  // deferred resolution finds the right function entry.
  final offset = DeferredOrOffset(
    file: decOrBridge.sourceLib,
    name: decl is FunctionDeclaration
        ? (decl.isGetter
              ? '${decl.name.lexeme}*g'
              : decl.isSetter
              ? '${decl.name.lexeme}*s'
              : name)
        : name,
  );

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
    rep: Abi.unboxedAcrossCalls(type),
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
  final typeId = ctx.runtimeTypes.idOf(type);
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
        ? children['$key*s'] ?? children[key]
        : children['$key*g'] ?? children[key];
  } else {
    found = forSet
        ? visible['$key*s']?.declaration ?? visible[key]?.declaration
        : visible['$key*g']?.declaration ?? visible[key]?.declaration;
  }
  if (found == null) {
    if (children == null && visible[key] != null) {
      throw PrefixError();
    }
    throw CompileError('Could not find declaration "$name"', source);
  }
  return found;
}

/// The declared type of a setter's `value` parameter, or null when the
/// parameter list is empty or untyped.
TypeRef? _setterValueType(
  CompilerContext ctx,
  int file,
  FormalParameterList? parameters,
) {
  final param = parameters?.parameters.firstOrNull;
  if (param == null || param.type == null) return null;
  return formalParameterAnnotationType(ctx, file, param);
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
  final paramType = _setterValueType(ctx, file, parameters);
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
  final paramType = _setterValueType(ctx, file, parameters);
  final rep = Abi.unboxedAcrossCalls(
    paramType ?? CoreTypes.dynamic.ref(ctx),
  ).bank;
  return rep == MachineRepresentation.object
      ? value.boxIntoFreshSlot(ctx)
      : value.unboxIfNeeded(ctx, false);
}

/// Whether [name] resolves to a field, method, or extension member of
/// [receiver]'s static type. Anonymous-method bodies use this to scope
/// unqualified names to the receiver without emitting a speculative
/// dispatch — a dynamic receiver always counts as having the member.
/// Whether [type] or one of its supertypes declares a member named [name].
/// Setters and getters register under `name*s`/`name*g` keys, so each kind is
/// probed separately when [forSet] selects one.
bool _hasInstanceMember(
  CompilerContext ctx,
  TypeRef type,
  String name, {
  bool forSet = false,
}) {
  final keys = forSet ? [name, '$name*s'] : [name, '$name*g'];
  for (final key in keys) {
    if (resolveInstanceDeclaration(
          ctx,
          type.file,
          type.name,
          key,
          instantiated: type,
        ) !=
        null) {
      return true;
    }
  }
  return false;
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
  if (TypeRef.lookupFieldType(
        ctx,
        resolvedReceiver,
        name,
        forSet: forSet,
        source: source,
      ) !=
      null) {
    return true;
  }
  if (_hasInstanceMember(ctx, resolvedReceiver, name, forSet: forSet)) {
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
