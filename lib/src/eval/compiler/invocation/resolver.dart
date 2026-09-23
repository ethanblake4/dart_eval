import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/method_invocation.dart';
import 'package:dart_eval/src/eval/compiler/helpers/argument_list.dart';
import 'package:dart_eval/src/eval/compiler/helpers/const.dart';
import 'package:dart_eval/src/eval/compiler/helpers/extension.dart';
import 'package:dart_eval/src/eval/compiler/helpers/invoke.dart';
import 'package:dart_eval/src/eval/compiler/dispatch.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';
import 'package:dart_eval/src/eval/bridge/declaration.dart';
import 'package:dart_eval/src/eval/ir/bridge.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:control_flow_graph/control_flow_graph.dart' show SSA;
import '../builtins.dart';
import '../values/abi.dart';
import 'binder.dart';
import 'bound_call.dart';
import 'call.dart';
import 'targets.dart';


/// Turns a [CallSite] into a [CallTarget] and emits the call. Resolution
/// consults only the receiver's static type and facts plus the syntactic
/// shape; arguments are compiled by the [ArgumentBinder].
final class CallResolver {
  const CallResolver(this.ctx);

  final CompilerContext ctx;

  /// `value(args)` — a function-expression invocation. When [ref] is given
  /// a statically-known target short-circuits to a direct [Call] without
  /// materializing the callee.
  Variable invokeValue(
    CallSite site, {
    Reference? ref,
    Variable? callee,
  }) => invokeValueWithArgs(site, ref: ref, callee: callee).$1;

  /// [invokeValue] plus the bound call — callers needing the post-coercion
  /// argument values read them from the [BoundCall].
  (Variable, BoundCall) invokeValueWithArgs(
    CallSite site, {
    Reference? ref,
    Variable? callee,
  }) {
    final dispatch = ref?.getStaticDispatch(ctx, site.source);
    final callable = dispatch == null
        ? (ref?.getValue(ctx, site.source) ?? callee!)
        : null;
    final target = ClosureCall(callee: callable, known: dispatch);
    final bound = ArgumentBinder(
      ctx,
    ).bindSuppliedOnly(target, site, callee: callable);
    return (_emitValue(target, bound, callable, site), bound);
  }

  Variable _emitValue(
    ClosureCall target,
    BoundCall bound,
    Variable? callable,
    CallSite site,
  ) {
    if (target.known != null) {
      return target.emit(ctx, bound);
    }
    final callableVar = callable!;
    // `x(...)` where `x` isn't a function is an implicit `x.call(...)` — an
    // extension `call` member applies statically before the dynamic
    // fallback.
    if (!callableVar.type.isAssignableTo(ctx, CoreTypes.function.ref(ctx))) {
      if (!hasInstanceMethod(ctx, callableVar.type, 'call') &&
          resolveExtensionMember(
                ctx,
                callableVar.type,
                'call',
                arity: bound.positional.length,
              ) !=
              null) {
        return callableVar
            .invoke(
              ctx,
              'call',
              [for (final a in bound.positional) a.value],
              namedArgs: {for (final e in bound.named) e.$1: e.$2.value},
            )
            .result;
      }
    }
    return target.emit(ctx, bound);
  }

  /// The [Variable] behind a [Receiver] that carries a concrete value.
  Variable _receiverVariable(Receiver r) => switch (r) {
    ValueReceiver(:final value) => value,
    ExtensionApplicationReceiver(:final value) => value,
    TypeLiteralReceiver(:final value) => value,
    SuperReceiver(:final self) => self,
    PrefixReceiver() =>
      throw CompileError('Unresolved import prefix'),
  };

  /// `f(args)` / `p.f(args)` — a call whose callee is a bare or
  /// prefix-qualified identifier, resolved through the denotation cascade
  /// rather than by materializing a callee [Variable].
  Variable invokeBare(
    String name,
    CallSite site, {
    String? prefix,
    TypeRef? bound,
  }) {
    final e = site.source as MethodInvocation;
    final Reference ref;
    final Denotation d;
    if (prefix == null) {
      final r = IdentifierReference(null, name);
      ref = r;
      d = r.denotation(ctx, source: e);
    } else {
      final r = PrefixedIdentifierReference(prefix, name);
      ref = r;
      d = r.denotation(ctx, source: e);
    }
    // `E(x)` — the namespace literal applied to a receiver.
    if (d is ExtensionNamespaceDenotation) {
      return applyExtension(ctx, e, d.ext);
    }
    // A member of the enclosing scope invoked bare — re-enter through the
    // implicit receiver (declared member, implicit `this`, or the
    // anonymous receiver).
    if (d is InstanceMemberDenotation) {
      final recv = d.receiver == null
          ? ctx.lookupLocal('#this')!
          : _receiverVariable(d.receiver!);
      return invokeMethodWithTarget(ctx, recv, e, bound: bound);
    }
    // A bound extension-method tear-off invoked directly — `x.m(args)`
    // lowers to `E.m(x, args)`; covers `m(args)` inside the extension body
    // where the receiver is `this`.
    if (d is ExtensionMemberDenotation &&
        !d.member.isStatic &&
        !d.member.isGetter &&
        !d.member.isSetter &&
        d.receiver != null) {
      return invokeExtensionMethod(
        ctx,
        d.receiver!,
        e,
        d.ext,
        d.member,
        matchExtensionOn(ctx, d.receiver!.type, d.ext) ?? const [],
      );
    }
    // Values invoke through the value-call path (closure, `.call` member,
    // or dynamic dispatch).
    if (d is LocalDenotation ||
        d is GlobalDenotation ||
        d is TypeParameterDenotation ||
        d is EnumValueDenotation ||
        d is PrefixDenotation) {
      return invokeValue(site, ref: ref);
    }
    return _invokeBareDispatch(d, name, ref, site, e, bound: bound);
  }

  /// The declared-target tail of a bare call: static functions and members,
  /// constructors (including aliases and implicit defaults), and bridges.
  Variable _invokeBareDispatch(
    Denotation d,
    String name,
    Reference ref,
    CallSite site,
    MethodInvocation e, {
    TypeRef? bound,
  }) {
    AlwaysReturnType? mReturnType;
    ReturnType? sigReturn;
    DeferredOrOffset offset;
    DeclarationOrBridge? dec0;
    TypeRef? aliasType;

    switch (d) {
      case BridgeDenotation(:final target, :final name):
        dec0 = target;
        final bridge = target.bridge;
        TypeRef? bridgeType;
        if (bridge is BridgeFunctionDeclaration) {
          sigReturn = AlwaysReturnType(
            TypeRef.fromBridgeAnnotation(ctx, bridge.function.returns),
            false,
          );
        } else if (bridge is BridgeClassDef) {
          bridgeType = TypeRef.fromBridgeTypeRef(ctx, bridge.type.type);
          sigReturn = AlwaysReturnType(bridgeType, false);
        } else if (bridge is BridgeEnumDef) {
          bridgeType = TypeRef.fromBridgeTypeRef(ctx, bridge.type);
        }
        offset = DeferredOrOffset(
          file: target.sourceLib,
          name: bridgeType != null ? '${bridgeType.name}.' : name,
        );
      case TypeLiteralDenotation(
          :final type,
          :final constructorKey,
          :final declaration,
        ):
        // A class or extension sharing its name with an extension applies as
        // `E(x)` — extension namespaces win over constructor calls.
        final ext = extensionForType(ctx, type);
        if (ext != null) return applyExtension(ctx, e, ext);
        if (declaration is TypeAlias && declaration is! ClassTypeAlias) {
          var resolved = resolveTypeAlias(
            ctx,
            ctx.library,
            declaration,
            typeArgs: e.typeArguments?.arguments.toList(),
            rawParams: true,
          );
          // Downward inference: `C<num> x = T(num)` instantiates `T` as
          // `C<num>` by unifying against the context type.
          final boundChain = bound;
          if (e.typeArguments == null &&
              boundChain != null &&
              boundChain.file == resolved.file &&
              boundChain.name == resolved.name &&
              boundChain.typeArguments.isNotEmpty) {
            final substitutions = Substitution.wrap(
              <TypeParameterDef, TypeRef>{},
            );
            for (
              var i = 0;
              i < resolved.typeArguments.length &&
                  i < boundChain.typeArguments.length;
              i++
            ) {
              ctx.typeSystem.unify(
                resolved.typeArguments[i],
                boundChain.typeArguments[i],
                substitutions,
              );
            }
            if (substitutions.isNotEmpty) {
              resolved = resolved.substituteTypeParameters(substitutions);
            }
          }
          aliasType = resolved;
          dec0 =
              ctx.topLevelDeclarationsMap[resolved.file]!['${resolved.name}.'];
          offset = DeferredOrOffset(
            file: resolved.file,
            name: '${resolved.name}.',
          );
          if (dec0 == null) {
            // The aliased class has an implicit default constructor — call
            // the synthesized body with just the runtime-type argument.
            final callResult = ctx.svar('constructor');
            ctx.pushOp(
              Call(
                offset,
                [pushRuntimeTypeId(ctx, resolved)],
                result: callResult,
              ),
            );
            return Variable.of(
              ctx,
              callResult,
              resolved,
              rep: ValueRep.boxed,
              concreteTypes: [resolved],
              exactType: resolved,
            );
          }
          break;
        }
        dec0 = ctx.topLevelDeclarationsMap[type.file]?[constructorKey];
        offset = DeferredOrOffset(file: type.file, name: constructorKey);
        sigReturn = AlwaysReturnType(type, false);
        if (dec0 == null) {
          // Call to an implicit default constructor.
          final result = ctx.svar('constructor');
          mReturnType = AlwaysReturnType(type, false);
          final declaredReturnType = mReturnType.type ?? type;
          final instantiatedType = instantiateConstructorType(
            ctx,
            e,
            declaredReturnType,
          );
          ctx.pushOp(
            Call(offset, [
              pushRuntimeTypeId(ctx, instantiatedType),
            ], result: result),
          );
          return Variable.of(
            ctx,
            result,
            instantiatedType,
            rep: Abi.unboxedAcrossCalls(declaredReturnType),
            concreteTypes: [instantiatedType],
            exactType: instantiatedType,
          );
        }
      case FunctionDenotation() ||
          StaticMemberDenotation() ||
          ExtensionMemberDenotation():
        final dispatch = d.staticDispatch(ctx, source: e);
        if (dispatch == null) return invokeValue(site, ref: ref);
        offset = dispatch.offset;
        sigReturn = dispatch.returnType;
        dec0 = switch (d) {
          FunctionDenotation(:final target) => target,
          StaticMemberDenotation(:final file, :final member) =>
            DeclarationOrBridge(file, declaration: member),
          ExtensionMemberDenotation(:final ext, :final member) =>
            DeclarationOrBridge(ext.library, declaration: member),
          _ => throw CompileError('Cannot call $name', e),
        };
      default:
        return invokeValue(site, ref: ref);
    }

    final List<Variable> args;
    final Map<String, Variable> namedArgs;
    final List<SSA> callArgs;

    var isConstructor = false;
    List<TypeRef>? inferredCtorArgs;
    bool? genericReturnBoxed;

    if (dec0.isBridge) {
      final bridge = dec0.bridge;

      /// If we're invoking a class identifier directly (like ClassName()),
      /// call its default constructor
      final fnDescriptor = bridge is BridgeClassDef
          ? (bridge.constructors['']?.functionDescriptor ??
                (throw CompileError(
                  'Class "${e.methodName.name}" does not have a default '
                  'constructor',
                  e,
                )))
          : (bridge as BridgeFunctionDeclaration).function;

      final argsPair = compileArgumentListWithBridge(
        ctx,
        e.argumentList,
        fnDescriptor,
      );

      args = argsPair.args;
      namedArgs = argsPair.namedArgs;
      callArgs = argsPair.ssa;
      isConstructor = bridge is BridgeClassDef;
    } else {
      final dec = dec0.declaration!;
      isConstructor = dec is ConstructorDeclaration;

      final result = compileNonBridgeArgs(
        ctx,
        offset.file!,
        dec,
        e.argumentList,
        typeArguments: e.typeArguments,
        source: e,
      );
      mReturnType = result.returnType;
      genericReturnBoxed = result.boxedBySubstitution;
      args = result.args.args;
      namedArgs = result.args.namedArgs;
      callArgs = result.args.ssa;

      // Upward inference for constructors: the class type arguments inferred
      // from the argument list (or the parameters' bounds), in declaration
      // order.
      if (isConstructor && result.classTypeParameters != null) {
        // Downward inference wins: a context type naming the constructed
        // class pins its type arguments (`A<int> get g => A(1)`).
        final boundChain = bound;
        final ctorDecl = dec.parent?.parent;
        final ctorClassName = ctorDecl is Declaration
            ? declarationName(ctorDecl)
            : null;
        if (boundChain != null &&
            e.typeArguments == null &&
            boundChain.name == ctorClassName) {
          final contextArgs = boundChain.typeArguments;
          if (contextArgs.isNotEmpty &&
              contextArgs.every((t) => !t.isTypeParameter)) {
            inferredCtorArgs = contextArgs;
          }
        }
        inferredCtorArgs ??= [
          for (final param in result.classTypeParameters!)
            result.resolveGenerics[param.name.lexeme] ??
                CoreTypes.dynamic.ref(ctx),
        ];
        if (aliasType != null && e.typeArguments == null) {
          // The alias's instantiated arguments were left as parameter
          // references for inference; bind them from what the constructor's
          // arguments gave.
          final substitutions = Substitution.wrap(
            <TypeParameterDef, TypeRef>{},
          );
          final aliasArgs = aliasType.typeArguments;
          for (
            var i = 0;
            i < aliasArgs.length && i < inferredCtorArgs.length;
            i++
          ) {
            ctx.typeSystem.unify(
              aliasArgs[i],
              inferredCtorArgs[i],
              substitutions,
            );
          }
          if (substitutions.isNotEmpty) {
            aliasType = aliasType.substituteTypeParameters(substitutions);
          }
        }
      }
    }

    final argTypes = args.map((e) => e.type).toList();
    final namedArgTypes = namedArgs.map(
      (key, value) => MapEntry(key, value.type),
    );

    TypeRef? thisType;
    if (ctx.currentClass != null) {
      thisType =
          ctx.visibleTypes[ctx.enclosingLibrary ??
              ctx.library]![ctx.currentClassName!];
    }

    mReturnType ??=
        sigReturn?.toAlwaysReturnType(ctx, thisType, argTypes, namedArgTypes) ??
        AlwaysReturnType(CoreTypes.dynamic.ref(ctx), true);
    final returnType = mReturnType.type;
    final resultRep =
        dec0.isBridge ||
            dec0.declaration is! FunctionDeclaration ||
            (genericReturnBoxed ??
                Abi.unboxedAcrossCalls(
                  mReturnType.type ?? CoreTypes.dynamic.ref(ctx),
                ).isBoxed)
        ? ValueRep.boxed
        : Abi.unboxedAcrossCalls(mReturnType.type ?? CoreTypes.dynamic.ref(ctx));
    final instantiatedReturnType = isConstructor && returnType != null
        ? (aliasType ??
              instantiateConstructorType(ctx, e, returnType, inferredCtorArgs))
        : returnType;
    final declaration = dec0.isBridge ? null : dec0.declaration;
    final effectiveCallArgs = [...callArgs];
    if (isConstructor &&
        declaration is ConstructorDeclaration &&
        declaration.factoryKeyword == null) {
      effectiveCallArgs.add(pushRuntimeTypeId(ctx, instantiatedReturnType!));
    }

    var result = ctx.svar('call');
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
            effectiveCallArgs,
            runtimeTypeId: ctx.runtimeTypes.idOf(type),
          ),
        );
      } else {
        ctx.pushOp(
          InvokeExternal(
            result,
            ctx.bridgeStaticFunctionIndices[offset.file]![offset.name]!,
            effectiveCallArgs,
          ),
        );
      }
    } else {

      ctx.pushOp(
        Call(
          offset,
          effectiveCallArgs,
          result: result,
          // Factories have no receiver, so the class's instantiated type
          // arguments are delivered through the callable-type-argument
          // channel.
          typeArguments:
              declaration is ConstructorDeclaration &&
                  declaration.factoryKeyword != null
              ? [
                  for (final arg
                      in instantiatedReturnType?.typeArguments ??
                          const <TypeRef>[])
                    ctx.runtimeTypes.idOf(arg),
                ]
              : isConstructor
              ? const []
              : runtimeTypeArguments(ctx, e),
        ),
      );
    }

    final generativeCtor =
        declaration is ConstructorDeclaration &&
        declaration.factoryKeyword == null;
    if (isConstructor && e.inConstantContext) {
      result = pushInternConst(ctx, result, instantiatedReturnType!);
    }
    final v = Variable.of(
      ctx,
      result,
      instantiatedReturnType ?? CoreTypes.dynamic.ref(ctx),
      rep: resultRep,
      concreteTypes: [
        if (isConstructor && instantiatedReturnType != null)
          instantiatedReturnType,
      ],
      // A factory may return any subtype — the result is not exactly the
      // declared class.
      exactType: generativeCtor ? instantiatedReturnType : null,
    );

    return v;
  }
}
