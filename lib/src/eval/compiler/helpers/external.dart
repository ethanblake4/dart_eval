import 'package:analyzer/dart/ast/ast.dart';
import 'package:control_flow_graph/control_flow_graph.dart'
    show SSA, BasicBlock, BasicBlockBuilder, Operation;
import 'package:dart_eval/dart_eval_bridge.dart';
import '../../ir/bridge.dart' show InvocationKind;
import '../builtins.dart';
import '../context.dart';
import '../invocation/bound_call.dart';
import '../invocation/targets.dart';
import '../type.dart';
import '../variable.dart';
import '../values/abi.dart';

export '../../ir/bridge.dart' show InvocationKind;

/// The SDK external-effect intrinsic is a nongeneric top-level void(Object?)
/// declaration annotated with dart:core's pragma, not a same-named user class.
bool isExternalEffect(
  CompilerContext ctx,
  int library,
  FunctionDeclaration declaration,
) {
  if (declaration.externalKeyword == null ||
      declaration.isGetter ||
      declaration.isSetter ||
      declaration.functionExpression.typeParameters != null) {
    return false;
  }
  final parameters = declaration.functionExpression.parameters?.parameters;
  if (parameters == null ||
      parameters.length != 1 ||
      !parameters.single.isRequiredPositional ||
      parameters.single.functionTypedSuffix != null ||
      parameters.single.type == null ||
      declaration.returnType == null) {
    return false;
  }
  if (!declaration.metadata.any((annotation) {
    final arguments = annotation.arguments?.arguments;
    return annotation.constructorName == null &&
        arguments?.length == 1 &&
        arguments!.single is SimpleStringLiteral &&
        (arguments.single as SimpleStringLiteral).value == 'external-effect' &&
        isCorePragma(ctx, library, annotation);
  })) {
    return false;
  }
  final parameterType = TypeRef.fromAnnotation(
    ctx,
    library,
    parameters.single.type!,
  );
  return parameterType.isSpec(CoreTypes.object) &&
      parameterType.nullable &&
      TypeRef.fromAnnotation(
        ctx,
        library,
        declaration.returnType!,
      ).isSpec(CoreTypes.voidType);
}

bool isCorePragma(CompilerContext ctx, int library, Annotation annotation) {
  final name = annotation.name;
  final String? prefix;
  if (name is SimpleIdentifier && name.name == 'pragma') {
    prefix = null;
  } else if (name is PrefixedIdentifier && name.identifier.name == 'pragma') {
    prefix = name.prefix.name;
  } else {
    return false;
  }
  final visible = ctx.visibleDeclarations[library];
  final entry = visible?[prefix ?? 'pragma'];
  if (prefix != null && entry?.declaration != null) return false;
  final declaration = prefix == null
      ? entry?.declaration
      : entry?.children?['pragma'];
  if (declaration != null) {
    final bridge = declaration.bridge;
    return bridge is BridgeClassDef &&
        TypeRef.fromBridgeTypeRef(
          ctx,
          bridge.type.type,
        ).isSpec(CoreTypes.pragma);
  }
  // If pragma has no visible bridge, resolve its SDK declaration through the
  // unit's core imports while respecting explicit show/hide combinators.
  final unit = annotation.thisOrAncestorOfType<CompilationUnit>();
  if (unit == null || unit.directives.any((d) => d is PartOfDirective)) {
    return false;
  }
  var explicit = false;
  for (final directive in unit.directives.whereType<ImportDirective>()) {
    if (directive.uri.stringValue != 'dart:core' ||
        directive.prefix?.name != prefix) {
      continue;
    }
    explicit = true;
    if (directive.combinators.every(
      (combinator) => switch (combinator) {
        ShowCombinator() => combinator.shownNames.any(
          (n) => n.name == 'pragma',
        ),
        HideCombinator() => !combinator.hiddenNames.any(
          (n) => n.name == 'pragma',
        ),
      },
    )) {
      return true;
    }
  }
  return prefix == null && !explicit;
}

/// Type-check the erased argument in a detached block. The existing unreachable
/// block pass removes its IR before SSA and bytecode construction.
void analyzeExternalEffectArgument(CompilerContext ctx, void Function() bind) {
  final outer = NestedFunctionState(ctx);
  final writeCaptures = {
    for (final scope in ctx.locals)
      for (final binding in scope.values) binding: binding.writeCaptured,
  };
  final detached = BasicBlock<Operation>(
    [],
    label: ctx.label('external_effect'),
  );
  ctx.builder.float(detached);
  ctx.builder = BasicBlockBuilder(ctx.activeGraph, [detached], null);
  ctx.blockCode = [];
  try {
    bind();
    ctx.flushBlock();
  } finally {
    for (final entry in writeCaptures.entries) {
      entry.key.writeCaptured = entry.value;
    }
    outer.restore();
  }
}

/// A source external declaration has no linked implementation. Throw directly,
/// even if the receiver overrides noSuchMethod.
Variable emitMissingExternal(
  CompilerContext ctx,
  String name, {
  InvocationKind kind = InvocationKind.method,
  Variable? receiver,
  List<Variable> positional = const [],
  List<(String, Variable)> named = const [],
}) {
  final target = NoSuchMethodCall(
    name: name,
    restricted: true,
    receiver: receiver ?? BuiltinValue().push(ctx),
  );
  if (kind == InvocationKind.getter) return target.emitGetterValue(ctx);
  if (kind == InvocationKind.setter) {
    target.emitSetter(ctx, positional.single);
    return Variable.never(ctx);
  }
  return target.emit(
    ctx,
    BoundCall(
      positional: positional,
      named: named,
      returnType: CoreTypes.never.ref(ctx),
    ),
  );
}

/// Reconstructs the declaration's argument slots for its missing external body.
Variable emitMissingExternalBody(
  CompilerContext ctx,
  String name,
  List<FormalParameter> parameters,
  List<TypeRef> types,
  CallableAbi abi, {
  InvocationKind kind = InvocationKind.method,
  Variable? receiver,
  int argumentOffset = 0,
}) {
  Variable argument(int index) => Variable.of(
    ctx,
    SSA('arg_${index + argumentOffset}'),
    types[index],
    rep: abi.parameters[index + argumentOffset],
  );
  return emitMissingExternal(
    ctx,
    name,
    kind: kind,
    receiver: receiver,
    positional: [
      for (var i = 0; i < parameters.length; i++)
        if (!parameters[i].isNamed) argument(i),
    ],
    named: [
      for (var i = 0; i < parameters.length; i++)
        if (parameters[i].isNamed) (parameters[i].name!.lexeme, argument(i)),
    ],
  );
}
