import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/analysis/utilities.dart' show parseString;
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/helpers/async.dart';
import 'package:dart_eval/src/eval/compiler/helpers/generators.dart';
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
import '../invocation/bound_call.dart';
import '../invocation/targets.dart';
import '../helpers/external.dart';

final _restrictedForwarders = Expando<bool>(
  'restricted noSuchMethod forwarder',
);

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
    parentName,
    extensionTypeParameters,
    () {
      // Capture the extension parameter refs before the method scope
      // opens — a method parameter may shadow an extension parameter's
      // name, and the callable env must carry the extension's defs in
      // their declared positions.
      final extensionRefs = declaredTypeParameterRefs(
        ctx,
        TypeParameterOwner(
          TypeParameterOwnerKind.extension,
          ctx.library,
          parentName,
        ),
        extensionTypeParameters,
      );
      // The `on` clause likewise resolves in the extension parameter
      // scope so `#this` and the body's `T` references use the same
      // parameter.
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
      // Folded mixin members are compiled under their applied class scope.
      // Preserve that scope before a method parameter can shadow its names.
      final declaringHost = d.parent?.parent;
      final memberTypeParameters = {
        if (!d.isStatic && declaringHost is Declaration)
          for (final parameter
              in classLikeClauses(declaringHost).$4?.typeParameters ??
                  const <TypeParameter>[])
            if (!isWildcardTypeParameter(ctx, parameter))
              parameter.name.lexeme:
                  ctx.typeScopes[ctx.library]![parameter.name.lexeme]!,
        for (var i = 0; i < extensionTypeParameters.length; i++)
          if (!isWildcardTypeParameter(ctx, extensionTypeParameters[i]))
            extensionTypeParameters[i].name.lexeme: extensionRefs[i],
      };
      final methodOwner = TypeParameterOwner(
        TypeParameterOwnerKind.method,
        ctx.library,
        '$parentName.$methodName',
        pos,
      );
      return ctx.withTypeParameters(
        ctx.library,
        methodOwner,
        methodTypeParameters,
        () {
          ctx.functionTypeParameters[pos] = [
            for (final ref in extensionRefs) ref.parameter,
            for (final ref in declaredTypeParameterRefs(
              ctx,
              methodOwner,
              methodTypeParameters,
            ))
              ref.parameter,
          ];
          ctx.functionRuntimeTypes[pos] = ctx.typeFactory.declaredMethodType(
            ctx.library,
            d,
            memberTypeParameters: memberTypeParameters,
            ownTypeParameterOwner: methodOwner,
          );

          ctx.beginScope();
          final hasReceiver = !d.isStatic;
          ctx.currentExtension = parent is ExtensionDeclaration ? parent : null;
          if (hasReceiver) {
            ctx.pushOp(Parameter(SSA('arg_0'), 0));
            // `this` binds the method's declaring link only when the class has
            // no subclasses — otherwise the receiver may be a subclass link
            // whose field storage lives elsewhere in the chain.
            final thisType =
                receiverType ?? (isExtensionMember ? null : TypeRef.$this(ctx));
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

          final expectedReturnType =
              (ctx.functionRuntimeTypes[pos] as FunctionTypeRef)
                  .signature
                  .returnType;
          final parameterTypes = d.parameters == null
              ? const <TypeRef>[]
              : ctx.functionParameterTypes[pos]!;
          final abi = CallableAbi.ofMethod(
            d,
            parameterTypes,
            expectedReturnType,
          );

          if (b.isGenerator) {
            setupGenerator(
              ctx,
              asynchronous: b.isAsynchronous,
              returnType: expectedReturnType,
            );
          } else if (b.isAsynchronous && !b.isGenerator) {
            setupAsyncFunction(ctx, returnType: expectedReturnType);
          }

          var i = hasReceiver ? 1 : 0;

          for (final p in resolvedParams) {
            final type = parameterTypes[i - (hasReceiver ? 1 : 0)];

            // `_` parameters are wildcards: non-binding and repeatable.
            if (p.name!.lexeme != '_') {
              ctx
                  .setLocal(
                    p.name!.lexeme,
                    Variable.of(
                      ctx,
                      SSA('arg_$i'),
                      type,
                      rep: abi.parameters[i],
                    ),
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
            if (d.externalKeyword != null) {
              final firstArgument = hasReceiver ? 1 : 0;
              Variable argument(int index) => Variable.of(
                ctx,
                SSA('arg_${index + firstArgument}'),
                parameterTypes[index],
                rep: abi.parameters[index + firstArgument],
              );
              emitMissingExternal(
                ctx,
                methodName,
                kind: d.isGetter
                    ? InvocationKind.getter
                    : d.isSetter
                    ? InvocationKind.setter
                    : InvocationKind.method,
                receiver: hasReceiver ? ctx.lookupLocal('#this') : null,
                positional: [
                  for (var j = 0; j < resolvedParams.length; j++)
                    if (!resolvedParams[j].isNamed) argument(j),
                ],
                named: [
                  for (var j = 0; j < resolvedParams.length; j++)
                    if (resolvedParams[j].isNamed)
                      (resolvedParams[j].name!.lexeme, argument(j)),
                ],
              );
              ctx.endScope();
              return StatementInfo(willAlwaysThrow: true);
            }
            // A missing abstract member on a concrete class still has its
            // declared callable boundary before forwarding to noSuchMethod.
            final restricted = _restrictedForwarders[d] == true;
            if (!restricted && !_forwardsAbstractMember(d, ctx, parent)) {
              ctx.endScope();
              return null;
            }
            Variable parameterValue(int index) => Variable.of(
              ctx,
              SSA('arg_${index + 1}'),
              parameterTypes[index],
              rep: abi.parameters[index + 1],
            );
            final target = NoSuchMethodCall(
              name: methodName,
              restricted: restricted,
            );
            if (d.isSetter) {
              target.emitSetter(ctx, parameterValue(0));
              stInfo = restricted
                  ? StatementInfo(willAlwaysThrow: true)
                  : doReturn(ctx, expectedReturnType, null);
            } else {
              final forwarded = d.isGetter
                  ? target.emitGetterValue(ctx)
                  : target.emit(
                      ctx,
                      BoundCall(
                        positional: [
                          for (var i = 0; i < resolvedParams.length; i++)
                            if (!resolvedParams[i].isNamed) parameterValue(i),
                        ],
                        named: [
                          for (var i = 0; i < resolvedParams.length; i++)
                            if (resolvedParams[i].isNamed)
                              (
                                resolvedParams[i].name!.lexeme,
                                parameterValue(i),
                              ),
                        ],
                        runtimeTypeArguments: [
                          for (final ref in declaredTypeParameterRefs(
                            ctx,
                            methodOwner,
                            methodTypeParameters,
                          ))
                            ctx.runtimeTypes.idOf(ref),
                        ],
                        returnType: CoreTypes.dynamic.ref(ctx),
                      ),
                    );
              stInfo = doReturn(ctx, expectedReturnType, forwarded);
            }
          } else {
            throw CompileError('Unknown function body type ${b.runtimeType}');
          }

          if (!(stInfo.willAlwaysReturn || stInfo.willAlwaysThrow)) {
            if (b.isAsynchronous && !b.isGenerator) {
              asyncComplete(ctx, null);
            } else {
              ctx.pushOp(Return(null));
            }
          }

          ctx.endScope();
          return stInfo;
        },
      );
    },
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

bool _forwardsAbstractMember(
  MethodDeclaration method,
  CompilerContext ctx,
  Declaration parent,
) {
  // Object's concrete identity operator remains inherited.
  if (method.isStatic ||
      method.name.lexeme == '==' ||
      parent is! ClassDeclaration ||
      parent.abstractKeyword != null) {
    return false;
  }
  final receiver = TypeRef.$this(ctx)!;
  final lookup = ctx.memberLookup;
  return lookup.implementationOwner(
            receiver,
            MemberName('noSuchMethod', MemberKind.method),
          ) !=
          null &&
      lookup.implementationOwner(
            receiver,
            MemberName(
              method.name.lexeme,
              method.isGetter
                  ? MemberKind.getter
                  : method.isSetter
                  ? MemberKind.setter
                  : MemberKind.method,
            ),
          ) ==
          null;
}

/// Materializes source interface members through the same checked boundary as
/// an explicitly declared abstract method. Class-generic interfaces still
/// require a substituted declaring scope; inferred returns and nonliteral
/// defaults retain their original source.
void compileInterfaceNoSuchMethodForwarders(
  CompilerContext ctx,
  Declaration host,
) {
  if (host is! ClassDeclaration ||
      host.abstractKeyword != null ||
      host.sealedKeyword != null ||
      host.namePart.typeParameters != null) {
    return;
  }
  _compileInterfaceNoSuchMethodRequirements(ctx, host);
}

/// Imported signatures resolve in their own library while registering their
/// checked bodies on the host. Foreign private members throw directly.
void _compileInterfaceNoSuchMethodRequirements(
  CompilerContext ctx,
  ClassDeclaration host,
) {
  final hostLibrary = ctx.library;
  final hostName = declarationName(host);
  final requirements =
      ctx.interfaceNoSuchMethodForwarderRequirements[(hostLibrary, hostName)];
  if (requirements == null) return;
  final emitted = <(int, String, MemberKind)>{};
  for (final (member, sourceLibrary, kind, name, restricted) in requirements) {
    final owner = member.parent?.parent;
    if (owner is Declaration && classLikeClauses(owner).$4 != null) continue;
    final sources = <(MemberKind, String)>[];
    if (member is MethodDeclaration) {
      if (!member.isGetter &&
          !member.isSetter &&
          !_canCloneForwarderSignature(member)) {
        continue;
      }
      if (member.isGetter &&
          member.returnType == null &&
          member.body is! EmptyFunctionBody) {
        continue;
      }
      final parameters =
          member.parameters?.parameters ?? const <FormalParameter>[];
      final groups = [
        ...parameters
            .where((p) => p.isRequiredPositional)
            .map(_forwarderParameter),
        if (parameters.any((p) => p.isOptionalPositional))
          '[${parameters.where((p) => p.isOptionalPositional).map(_forwarderParameter).join(', ')}]',
        if (parameters.any((p) => p.isNamed))
          '{${parameters.where((p) => p.isNamed).map(_forwarderParameter).join(', ')}}',
      ];
      final signature = member.isGetter
          ? '${member.returnType?.toSource() ?? 'dynamic'} get $name'
          : member.isSetter
          ? 'set $name(${groups.join(', ')})'
          : '${member.returnType?.toSource() ?? 'dynamic'} ${member.operatorKeyword == null ? '' : 'operator '}$name${member.typeParameters?.toSource() ?? ''}(${groups.join(', ')})';
      sources.add((
        kind,
        '${member.metadata.map((a) => a.toSource()).join(' ')} $signature;',
      ));
    } else if (member is FieldDeclaration) {
      if (member.fields.type == null &&
          member.fields.variables.any((v) => v.initializer != null)) {
        continue;
      }
      final type = member.fields.type?.toSource() ?? 'dynamic';
      sources.add((MemberKind.getter, '$type get $name;'));
      if (!member.fields.isFinal && !member.fields.isConst) {
        sources.add((MemberKind.setter, 'set $name($type value);'));
      }
    }
    for (final (view, source) in sources) {
      if (!emitted.add((sourceLibrary, name, view))) continue;
      final positionKey = name.startsWith('_') && sourceLibrary != hostLibrary
          ? '${ctx.libraryUri(sourceLibrary)}::$name'
          : name;
      if (ctx.instanceDeclarationPositions[hostLibrary]![hostName]![view]!
          .containsKey(positionKey)) {
        continue;
      }
      if (ctx.memberLookup.implementationOwner(
            TypeRef.lookupDeclaration(ctx, hostLibrary, host),
            MemberName(
              name,
              view,
              privateLibraryUri: ctx.libraryUri(sourceLibrary),
            ),
          ) !=
          null) {
        continue;
      }
      final version = member
          .thisOrAncestorOfType<CompilationUnit>()
          ?.languageVersionToken;
      final directive = version == null
          ? ''
          : '// @dart=${version.major}.${version.minor}\n';
      final stub =
          (parseString(
                        content: '${directive}class $hostName { $source }',
                      ).unit.declarations.single
                      as ClassDeclaration)
                  .body
                  .members
                  .single
              as MethodDeclaration;
      final oldEnclosingLibrary = ctx.enclosingLibrary;
      if (restricted) _restrictedForwarders[stub] = true;
      try {
        ctx.library = sourceLibrary;
        ctx.enclosingLibrary = hostLibrary;
        ctx.currentClass = host;
        compileMethodDeclaration(stub, ctx, host);
      } finally {
        ctx.library = hostLibrary;
        ctx.enclosingLibrary = oldEnclosingLibrary;
      }
    }
  }
}

bool _canCloneForwarderSignature(MethodDeclaration declaration) {
  if (declaration.isGetter ||
      declaration.isSetter ||
      declaration.returnType == null ||
      declaration.externalKeyword != null) {
    return false;
  }
  for (final parameter in declaration.parameters!.parameters) {
    final defaultValue = parameter.defaultClause?.value;
    if (defaultValue != null &&
        defaultValue is! IntegerLiteral &&
        defaultValue is! DoubleLiteral &&
        defaultValue is! BooleanLiteral &&
        defaultValue is! NullLiteral &&
        defaultValue is! SimpleStringLiteral) {
      return false;
    }
    if (!parameter.isRequired &&
        defaultValue == null &&
        parameter.functionTypedSuffix != null) {
      return false;
    }
  }
  return true;
}

String _forwarderParameter(FormalParameter parameter) {
  final annotation = parameter.type;
  if (parameter.isRequired ||
      parameter.defaultClause != null ||
      annotation == null ||
      annotation.toSource().endsWith('?')) {
    return parameter.toSource();
  }
  return [
    ...parameter.metadata.map((annotation) => annotation.toSource()),
    if (parameter.covariantKeyword != null) 'covariant',
    if (parameter.constFinalOrVarKeyword case final keyword?) keyword.lexeme,
    '${annotation.toSource()}?',
    parameter.name!.lexeme,
  ].join(' ');
}

/// Extension parameters belong to the extension's own scope, not the
/// member's callable parameters. A signature may intern the method owner
/// before its body compiles; combining both lists under that owner can leave
/// the extension parameters absent when the two numeric positions coincide.
T _withExtensionTypeParameters<T>(
  CompilerContext ctx,
  String extensionName,
  List<TypeParameter> parameters,
  T Function() body,
) {
  if (parameters.isEmpty) return body();
  return ctx.withTypeParameters(
    ctx.library,
    TypeParameterOwner(
      TypeParameterOwnerKind.extension,
      ctx.library,
      extensionName,
    ),
    parameters,
    body,
  );
}
