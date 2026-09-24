import 'const.dart';
import 'default_value.dart';
import 'extension.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/function.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/closures.dart';
import '../member/call_signature.dart';
import '../values/abi.dart';
import '../member/member_name.dart';

extension TearOff on Variable {
  /// Materializes this function reference. When [boundContext] supplies a
  /// [FunctionTypeRef] (the assignment's destination type), a generic
  /// callable's own type parameters instantiate from it — `bar` used as a
  /// `double Function(double)` becomes `bar<double>` — and the binding is
  /// recorded on the closure so invocations see the bound arguments.
  Variable tearOff(CompilerContext ctx, {TypeRef? boundContext}) {
    if (!type.isFunctionLike || methodOffset == null) {
      throw CompileError('Cannot tear off non-function or unresolved function');
    }
    final offset = methodOffset!;
    final Declaration declaration;
    if (offset.className != null) {
      declaration =
          ctx.instanceDeclarationsMap[offset.file]![offset.className!]![offset
                  .name]!
              as MethodDeclaration;
    } else {
      final declared = ctx.topLevelDeclarationsMap[offset.file]?[offset.name];
      if (declared == null) {
        throw CompileError(
          'Cannot tear off unresolved member ${offset.name} (file ${offset.file})',
        );
      }
      if (declared.isBridge) {
        throw CompileError('Cannot tear off bridged function');
      }
      declaration = declared.declaration!;
    }
    final parameters = switch (declaration) {
      MethodDeclaration() => declaration.parameters,
      ConstructorDeclaration() => declaration.parameters,
      _ => (declaration as FunctionDeclaration).functionExpression.parameters,
    };
    final positional =
        parameters?.parameters.where((param) => param.isPositional).toList() ??
        <FormalParameter>[];
    final named =
        parameters?.parameters.where((param) => param.isNamed).toList() ??
        <FormalParameter>[];
    var functionId = offset.offset;
    if (functionId == null) {
      if (offset.className == null) {
        final positions = ctx.topLevelDeclarationPositions[offset.file];
        if (positions != null && offset.name != null) {
          functionId = positions[offset.name];
        }
      } else {
        final classes = ctx.instanceDeclarationPositions[offset.file];
        final memberGroups = classes == null ? null : classes[offset.className];
        functionId = memberGroups == null
            ? null
            : memberGroups[MemberKind.method]?[offset.name];
      }
    }
    final parameterTypes = functionId == null
        ? const <TypeRef>[]
        : ctx.functionParameterTypes[functionId] ?? const <TypeRef>[];
    final allParameters = [...positional, ...named];
    final parameterTypeByNode = <FormalParameter, TypeRef>{
      for (
        var index = 0;
        index < allParameters.length && index < parameterTypes.length;
        index++
      )
        allParameters[index]: parameterTypes[index],
    };
    // Class member tear-offs resolve the class's own type parameters as
    // uninstantiated references (`L.foo` on `class L<T>` keeps `T`); a
    // generic function's own parameters stay resolvable too (`f<X>(X x)`).
    final memberHost = switch (declaration) {
      MethodDeclaration() => declaration.parent?.parent,
      ConstructorDeclaration() => declaration.parent?.parent,
      _ => null,
    };
    // An extension member's host is the extension; its type parameters bind
    // to the `on` bindings of the tear-off receiver, not the enclosing class.
    final memberExt = declaration is MethodDeclaration && !declaration.isStatic
        ? extensionOfMember(ctx, declaration)
        : null;
    final memberParams = <String, TypeRef>{
      if (memberExt != null && implicitReceiver != null)
        ...memberExtParams(ctx, memberExt, implicitReceiver!.type)
      else if (memberHost is Declaration)
        ...classTypeParameterRefs(
          ctx,
          offset.file ?? ctx.library,
          declarationName(memberHost),
          classLikeClauses(memberHost).$4,
        ),
    };
    final ownTypeParams =
        (switch (declaration) {
          MethodDeclaration() => declaration.typeParameters,
          FunctionDeclaration() =>
            declaration.functionExpression.typeParameters,
          _ => null,
        })?.typeParameters ??
        const <TypeParameter>[];
    declareTypeParameters(
      ctx,
      TypeParameterOwner(
        TypeParameterOwnerKind.tearOff,
        offset.file ?? ctx.library,
        offset.name ?? '',
      ),
      ownTypeParams,
      memberParams,
    );

    TypeRef parameterType(FormalParameter parameter) {
      final compiledType = parameterTypeByNode[parameter];
      if (compiledType != null) return compiledType;
      final annotation = parameter.type;
      return annotation == null
          ? CoreTypes.dynamic.ref(ctx)
          : ctx.typeFactory.formalParameterAnnotationType(
              offset.file ?? ctx.library,
              parameter,
              typeParameters: memberParams,
            );
    }

    (Object?, int) parameterDefault(FormalParameter parameter) {
      final (value, thunk) = compileParameterDefault(
        ctx,
        offset.file ?? ctx.library,
        parameter,
        bound: parameterType(parameter),
      );
      return (
        value is int && parameterType(parameter).isSpec(CoreTypes.double)
            ? value.toDouble()
            : value,
        thunk,
      );
    }

    final functionType = switch (declaration) {
      MethodDeclaration() => ctx.typeFactory.declaredFunctionType(
        offset.file ?? ctx.library,
        declaration.parameters,
        declaration.returnType,
        declaration.typeParameters,
        memberTypeParameters: memberParams,
        ownTypeParameterOwner: TypeParameterOwner(
          TypeParameterOwnerKind.tearOff,
          offset.file ?? ctx.library,
          offset.name ?? '',
        ),
      ),
      FunctionDeclaration() => ctx.typeFactory.declaredFunctionType(
        offset.file ?? ctx.library,
        declaration.functionExpression.parameters,
        declaration.returnType,
        declaration.functionExpression.typeParameters,
        memberTypeParameters: memberParams,
        ownTypeParameterOwner: TypeParameterOwner(
          TypeParameterOwnerKind.tearOff,
          offset.file ?? ctx.library,
          offset.name ?? '',
        ),
      ),
      ConstructorDeclaration() => ctx.typeFactory.declaredFunctionType(
        offset.file ?? ctx.library,
        declaration.parameters,
        null,
        null,
        memberTypeParameters: memberParams,
      ),
      _ => CoreTypes.function.ref(ctx),
    };

    // Downward instantiation: the context's signature binds this callable's
    // own type parameters (`bar` as `double Function(double)` → `bar<double>`).
    var boundCallableTypeArguments = const <int>[];
    var materializedType = functionType;
    if (boundContext is FunctionTypeRef &&
        functionType is FunctionTypeRef &&
        functionType.signature.typeParameters.isNotEmpty) {
      final signature = functionType.signature;
      final bindings = <TypeParameterDef, TypeRef>{};
      ctx.typeSystem.unify(functionType, boundContext, bindings);
      var fullyBound = true;
      boundCallableTypeArguments = [
        for (final def in signature.typeParameters)
          () {
            final bound = bindings[def];
            if (bound == null || bound.isTypeParameter) {
              fullyBound = false;
              return ctx.runtimeTypes.idOf(bound ?? CoreTypes.dynamic.ref(ctx));
            }
            return ctx.runtimeTypes.idOf(bound);
          }(),
      ];
      if (fullyBound) {
        final substitution = Substitution.of(bindings);
        materializedType = FunctionTypeRef(
          FunctionSignature(
            positional: [
              for (final t in signature.positional)
                t.substituteTypeParameters(substitution),
            ],
            requiredPositional: signature.requiredPositional,
            named: {
              for (final e in signature.named.entries)
                e.key: (
                  type: e.value.type.substituteTypeParameters(substitution),
                  required: e.value.required,
                ),
            },
            returnType: signature.returnType.substituteTypeParameters(
              substitution,
            ),
          ),
          decl: functionType.decl,
          nullable: functionType.nullable,
        );
      }
    }

    final captures = <SSA>[];
    if (declaration is MethodDeclaration && !declaration.isStatic) {
      final receiver = implicitReceiver != null
          ? implicitReceiver!.boxIfNeeded(ctx).ssa
          : ctx.lookupBinding('#this')?.read(ctx).ssa;
      if (receiver == null) {
        throw CompileError('Missing receiver for method tearoff');
      }
      captures.add(receiver);
    }
    final positionalDefaults = positional.map(parameterDefault).toList();
    final namedDefaults = named.map(parameterDefault).toList();
    final created = Variable.ssa(
      ctx,
      CreateClosure(
        ctx.svar('tearoff'),
        offset,
        captures,
        requiredPositional: positional
            .where((param) => param.isRequired)
            .length,
        positionalCount: positional.length,
        namedNames: named.map((param) => param.name!.lexeme).toList(),
        hasEnvironment: false,
        positionalDefaults: [for (final d in positionalDefaults) d.$1],
        namedDefaults: [for (final d in namedDefaults) d.$1],
        defaultThunks: [
          for (final d in positionalDefaults) d.$2,
          for (final d in namedDefaults) d.$2,
        ],
        requiredNamed: [
          for (final parameter in named)
            if (parameter.isRequired) parameter.name!.lexeme,
        ],
        boundReceiver:
            declaration is MethodDeclaration && !declaration.isStatic,
        positionalUnboxed: positional
            .map(
              (param) =>
                  declaration is FunctionDeclaration &&
                  !Abi.unboxedAcrossCalls(parameterType(param)).isBoxed,
            )
            .toList(),
        namedUnboxed: named
            .map(
              (param) =>
                  declaration is FunctionDeclaration &&
                  !Abi.unboxedAcrossCalls(parameterType(param)).isBoxed,
            )
            .toList(),
        runtimeTypeId: ctx.runtimeTypes.idOf(materializedType),
        boundCallableTypeArguments: boundCallableTypeArguments,
      ),
      materializedType,
      callable: CallableValue(
        offset: offset,
        signature:
            methodSignature ??
            CallSignature.returnOnly(CoreTypes.dynamic.ref(ctx)),
        convention: CallingConvention.dynamic,
        materialized: true,
      ),
    );
    // A captureless tear-off is a constant: the VM canonicalizes them, so
    // `identical(main, main)` is true.
    return captures.isEmpty ? internConst(ctx, created, functionType) : created;
  }
}
