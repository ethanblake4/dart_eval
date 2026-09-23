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
import 'package:dart_eval/src/eval/compiler/model/function_type.dart';

import 'package:dart_eval/src/eval/compiler/statement/block.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';

import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/ir/function.dart';
import 'package:dart_eval/src/eval/ir/representation.dart';
import '../values/abi.dart';

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
  final previousTypes = {...?ctx.temporaryTypes[ctx.library]};
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
  TypeRef.loadTemporaryTypes(ctx, [
    ...extensionTypeParameters,
    ...methodTypeParameters,
  ], owner: 'method:${ctx.library}:$parentName.$methodName:$pos');
  ctx.functionTypeParameterBounds[pos] = [
    for (final parameter in [
      ...extensionTypeParameters,
      ...methodTypeParameters,
    ])
      ctx
              .temporaryTypes[ctx.library]![parameter.name.lexeme]!
              .typeParameterBound ??
          CoreTypes.dynamic.ref(ctx),
  ];
  ctx.functionRuntimeTypes[pos] = declaredFunctionType(
    ctx,
    ctx.library,
    d.parameters,
    d.returnType,
    d.typeParameters,
    memberTypeParameters: {
      ...switch (ctx.currentClass) {
        final host? => classTypeParameterRefs(
          ctx.library,
          ctx.currentClassName!,
          classLikeClauses(host).$4,
        ),
        _ => const <String, TypeRef>{},
      },
      for (var i = 0; i < extensionTypeParameters.length; i++)
        extensionTypeParameters[i].name.lexeme:
            ctx.temporaryTypes[ctx.library]![extensionTypeParameters[i]
                .name
                .lexeme]!,
    },
  );

  ctx.beginScope();
  final hasReceiver = !d.isStatic;
  ctx.currentExtension = parent is ExtensionDeclaration ? parent : null;
  if (hasReceiver) {
    // Re-resolve the extension's `on` clause now that its parameters share
    // this member's type-parameter keyspace, so `#this`'s declared type and
    // the body's `T` references identify the same parameter.
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
    ctx.setLocal(
      '#this',
      Variable.of(
        ctx,
        SSA('arg_0'),
        receiverType ??
            (isExtensionMember
                ? CoreTypes.dynamic.ref(ctx)
                : TypeRef.$this(ctx)!),
        rep: ValueRep.boxed,
      ),
    );
  }
  final resolvedParams = d.parameters == null
      ? <FormalParameter>[]
      : resolveFPLDefaults(ctx, d.parameters, hasReceiver, allowUnboxed: false);

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
    var type = CoreTypes.dynamic.ref(ctx);
    if (p.type != null) {
      type = formalParameterAnnotationType(ctx, ctx.library, p);
    }

    // `_` parameters are wildcards: non-binding and repeatable.
    if (p.name!.lexeme != '_') {
      ctx.setLocal(
        p.name!.lexeme,
        // Method args are always boxed to allow for bridge interop to have
        // a consistent interface
        Variable.of(
          ctx,
          SSA('arg_$i'),
          type,
          rep: Abi.parameter(type, CallableKind.method),
        ).captureBinding(ctx, p),
      );
    }

    i++;
  }

  final expectedReturnType = AlwaysReturnType.fromAnnotation(
    ctx,
    ctx.library,
    d.returnType,
    CoreTypes.dynamic.ref(ctx),
  );
  final returnType = expectedReturnType.type;
  final unboxedOperatorReturn =
      b is ExpressionFunctionBody &&
      !b.isAsynchronous &&
      (methodName == '==' || methodName == '!=') &&
      returnType != null &&
      !Abi.unboxedAcrossCalls(returnType).isBoxed;
  ctx.functionSignatures[pos] = MachineFunctionSignature(
    List.filled(
      resolvedParams.length + (hasReceiver ? 1 : 0),
      MachineRepresentation.object,
    ),
    returnType != null &&
            returnType.isSpec(CoreTypes.voidType) &&
            !b.isAsynchronous
        ? null
        : unboxedOperatorReturn
        ? Abi.result(
            returnType,
            CallableKind.method,
            unboxedBoolResult: true,
          ).bank
        : MachineRepresentation.object,
  );

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
    final bound = b.isAsynchronous && returnType != null
        ? ctx.typeSystem.flatten(returnType)
        : returnType;
    final V = compileExpression(b.expression, ctx, bound);
    stInfo = doReturn(
      ctx,
      expectedReturnType,
      V,
      isAsync: b.isAsynchronous,
      // == and != operators are statically guaranteed to return bools,
      // so we can optimize boxing away here.
      skipClassBoxing: d.name.lexeme == '==' || d.name.lexeme == '!=',
    );
    ctx.endScope();
  } else if (b is EmptyFunctionBody) {
    ctx.endScope();
    ctx.temporaryTypes[ctx.library] = previousTypes;
    return -1;
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
  ctx.temporaryTypes[ctx.library] = previousTypes;

  if (d.isStatic || isExtensionMember) {
    // Extension members and class statics register in the top-level
    // positions map; getters and setters take `*g`/`*s` suffixes matching
    // the instance-member key convention so a pair can't collide.
    final key = isExtensionMember
        ? extensionMemberKey(parentName, d)
        : '$parentName.$methodName${d.isGetter
              ? '*g'
              : d.isSetter
              ? '*s'
              : ''}';
    ctx.topLevelDeclarationPositions.putIfAbsent(ctx.library, () => {})[key] =
        pos;
    if (isExtensionMember) {
      // Extension members take a receiver argument that isn't part of their
      // declared signature, so they can't be called as entrypoint exports.
      ctx.extensionMemberFunctions.putIfAbsent(ctx.library, () => {}).add(key);
    }
  } else {
    final mapIndex = d.isGetter
        ? 0
        : d.isSetter
        ? 1
        : 2;
    ctx.instanceDeclarationPositions[ctx.enclosingLibrary ??
            ctx.library]![parentName]![mapIndex][ctx.instanceMethodKey(
          methodName,
          positionalArityOf(d),
        )] =
        pos;
  }

  return pos;
}
