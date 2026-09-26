import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/helpers/async.dart';
import 'package:dart_eval/src/eval/compiler/helpers/extension.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/helpers/fpl.dart';
import 'package:dart_eval/src/eval/compiler/helpers/return.dart';

import 'package:dart_eval/src/eval/compiler/statement/block.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';

import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/compiler/variable/value_facts.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/ir/function.dart';
import '../values/abi.dart';
import '../member/member_name.dart';

int compileMethodDeclaration(
  MethodDeclaration d,
  CompilerContext ctx,
  Declaration parent, {
  // For extension members: the extension's registration name. The member
  // keeps instance-parameter layout (arg_0 is the receiver) but registers
  // like a static member.
  String? extensionName,
}) {
  final isExtensionMember = extensionName != null;
  final b = d.body;
  final parentName = extensionName ?? declarationName(parent);
  final methodName = d.name.lexeme;
  final pos = ctx.beginFunction('$parentName.$methodName()');
  // An extension member's callable type parameters are the extension's own
  // parameters followed by the method's — call sites pass the resolved `on`
  // bindings first, then the method's type arguments.
  // Static extension members cannot reference the extension's type
  // parameters — they are not in scope for them.
  final extensionTypeParameters = switch (parent) {
    ExtensionDeclaration(:final typeParameters) when !d.isStatic =>
      typeParameters?.typeParameters ?? const <TypeParameter>[],
    _ => const <TypeParameter>[],
  };
  final methodTypeParameters =
      d.typeParameters?.typeParameters ?? const <TypeParameter>[];
  final stInfo = _withExtensionTypeParameters(
    ctx,
    parent,
    extensionTypeParameters,
    () => ctx.withTypeParameters(
      ctx.library,
      TypeParameterOwner(
        TypeParameterOwnerKind.method,
        ctx.library,
        '$parentName.$methodName',
        pos,
      ),
      methodTypeParameters,
      () {
        ctx.functionTypeParameterBounds[pos] = [
          for (final parameter in [
            ...extensionTypeParameters,
            ...methodTypeParameters,
          ])
            (ctx.typeScopes[ctx.library]![parameter.name.lexeme]!
                        as TypeParameterTypeRef)
                    .parameter
                    .bound ??
                CoreTypes.dynamic.ref(ctx),
        ];
        ctx.functionRuntimeTypes[pos] = ctx.typeFactory.declaredFunctionType(
          ctx.library,
          d.parameters,
          d.returnType,
          d.typeParameters,
          memberTypeParameters: {
            ...switch (ctx.currentClass) {
              final host? => classTypeParameterRefs(
                ctx,
                ctx.library,
                ctx.currentClassName!,
                classLikeClauses(host).$4,
              ),
              _ => const <String, TypeRef>{},
            },
            for (var i = 0; i < extensionTypeParameters.length; i++)
              extensionTypeParameters[i].name.lexeme:
                  ctx.typeScopes[ctx.library]![extensionTypeParameters[i]
                      .name
                      .lexeme]!,
          },
          ownTypeParameterOwner: TypeParameterOwner(
            TypeParameterOwnerKind.method,
            ctx.library,
            '$parentName.$methodName',
            pos,
          ),
        );

        ctx.beginScope();
        final hasReceiver = !d.isStatic;
        ctx.currentExtension = parent is ExtensionDeclaration ? parent : null;
        if (hasReceiver) {
          // Resolve the `on` clause inside the extension parameter scope, so
          // `#this` and the body's `T` references use the same parameter.
          final receiverType = switch (parent) {
            ExtensionDeclaration(:final onClause) =>
              onClause == null
                  ? null
                  : () {
                      try {
                        return TypeRef.fromAnnotation(
                          ctx,
                          ctx.library,
                          onClause.extendedType,
                        );
                      } catch (_) {
                        return null;
                      }
                    }(),
            _ => null,
          };
          ctx.pushOp(Parameter(SSA('arg_0'), 0));
          // `this` binds the method's declaring link only when the class has
          // no subclasses — otherwise the receiver may be a subclass link
          // whose field storage lives elsewhere in the chain.
          final thisType =
              receiverType ??
              (isExtensionMember ? null : TypeRef.$this(ctx));
          final concrete =
              thisType != null &&
                  !ctx.hasSubclasses(thisType.file, thisType.name)
              ? thisType
              : null;
          ctx.setLocal(
            '#this',
            Variable.of(
              ctx,
              SSA('arg_0'),
              thisType ?? CoreTypes.dynamic.ref(ctx),
              rep: ValueRep.boxed,
              facts: concrete != null
                  ? ValueFacts(possibleClasses: [concrete])
                  : null,
            ),
          );
        }
        final resolvedParams = d.parameters == null
            ? <FormalParameter>[]
            : resolveFPLDefaults(
                ctx,
                d.parameters,
                hasReceiver,
                allowUnboxed: false,
                parameterHost: parent is ExtensionDeclaration ? null : parent,
                decLibrary: ctx.library,
              );

        final expectedReturnType = d.returnType == null
            ? CoreTypes.dynamic.ref(ctx)
            : TypeRef.fromAnnotation(ctx, ctx.library, d.returnType!);
        final parameterTypes = d.parameters == null
            ? const <TypeRef>[]
            : ctx.functionParameterTypes[pos]!;
        final abi = CallableAbi.ofMethod(d, parameterTypes, expectedReturnType);

        if (b.isAsynchronous) {
          setupAsyncFunction(
            ctx,
            returnType: d.returnType == null
                ? null
                : TypeRef.fromAnnotation(ctx, ctx.library, d.returnType!),
          );
        }

        var i = hasReceiver ? 1 : 0;

        for (final p in resolvedParams) {
          final type = parameterTypes[i - (hasReceiver ? 1 : 0)];

          // `_` parameters are wildcards: non-binding and repeatable.
          if (p.name!.lexeme != '_') {
            ctx
                .setLocal(
                  p.name!.lexeme,
                  Variable.of(ctx, SSA('arg_$i'), type, rep: abi.parameters[i]),
                )
                .captureBinding(ctx, p);
          }

          i++;
        }

        final returnType = expectedReturnType;
        ctx.functionSignatures[pos] = abi.machine;

        StatementInfo? stInfo;
        if (b is BlockFunctionBody) {
          stInfo = compileBlock(
            b.block,
            expectedReturnType,
            ctx,
            name: '$methodName()',
          );
        } else if (b is ExpressionFunctionBody) {
          ctx.beginScope();
          // An async body's context type is the *flattened* return type: in
          // `Future<List<int>> f() async => []` the literal sees `List<int>`.
          final bound = b.isAsynchronous
              ? ctx.typeSystem.flatten(returnType)
              : returnType;
          final V = compileExpression(b.expression, ctx, bound);
          stInfo = doReturn(
            ctx,
            expectedReturnType,
            V,
            isAsync: b.isAsynchronous,
            skipClassBoxing: abi.result?.isBoxed == false,
          );
          ctx.endScope();
        } else if (b is EmptyFunctionBody) {
          ctx.endScope();
          return null;
        } else {
          throw CompileError('Unknown function body type ${b.runtimeType}');
        }

        if (!(stInfo.willAlwaysReturn || stInfo.willAlwaysThrow)) {
          if (b.isAsynchronous) {
            asyncComplete(ctx, null);
          } else {
            ctx.pushOp(Return(null));
          }
        }

        ctx.endScope();
        return stInfo;
      },
    ),
  );
  if (stInfo == null) return -1;

  if (d.isStatic || isExtensionMember) {
    // Extension members and class statics register in the top-level
    // positions map; getters and setters take `*g`/`*s` suffixes matching
    // the instance-member key convention so a pair can't collide.
    final key = isExtensionMember
        ? extensionMemberKey(parentName, d)
        : '$parentName.${MemberName(methodName, d.isGetter
              ? MemberKind.getter
              : d.isSetter
              ? MemberKind.setter
              : MemberKind.method).key}';
    ctx.topLevelDeclarationPositions.putIfAbsent(ctx.library, () => {})[key] =
        pos;
    if (isExtensionMember) {
      // Extension members take a receiver argument that isn't part of their
      // declared signature, so they can't be called as entrypoint exports.
      ctx.extensionMemberFunctions.putIfAbsent(ctx.library, () => {}).add(key);
    }
  } else {
    final kind = d.isGetter
        ? MemberKind.getter
        : d.isSetter
        ? MemberKind.setter
        : MemberKind.method;
    ctx.instanceDeclarationPositions[ctx.enclosingLibrary ??
            ctx.library]![parentName]![kind]![ctx.instanceMethodKey(
          methodName,
          positionalArityOf(d),
        )] =
        pos;
  }

  return pos;
}

/// Extension parameters belong to the extension's own scope, not the
/// member's callable parameters. A signature may intern the method owner
/// before its body compiles; combining both lists under that owner can leave
/// the extension parameters absent when the two numeric positions coincide.
T _withExtensionTypeParameters<T>(
  CompilerContext ctx,
  Declaration parent,
  List<TypeParameter> parameters,
  T Function() body,
) {
  if (parent is! ExtensionDeclaration || parameters.isEmpty) return body();
  return ctx.withTypeParameters(
    ctx.library,
    TypeParameterOwner(
      TypeParameterOwnerKind.extension,
      ctx.library,
      parent.name?.lexeme ?? '',
    ),
    parameters,
    body,
  );
}
