import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:collection/collection.dart';
import 'package:dart_eval/src/eval/bindgen/bridge.dart';
import 'package:dart_eval/src/eval/bindgen/config.dart';
import 'package:dart_eval/src/eval/bindgen/context.dart';
import 'package:dart_eval/src/eval/bindgen/type.dart';

String namedParameters(
  BindgenContext ctx, {
  required ExecutableElement element,
  BindgenMemberConfig? member,
}) {
  final params = element.formalParameters.where((e) => e.isNamed);
  if (params.isEmpty) {
    return '';
  }

  return parameters(ctx, params.toList(), member: member);
}

String positionalParameters(
  BindgenContext ctx, {
  required ExecutableElement element,
  BindgenMemberConfig? member,
}) {
  final params = element.formalParameters.where((e) => e.isPositional);
  if (params.isEmpty) {
    return '';
  }

  return parameters(ctx, params.toList(), member: member);
}

String parameters(
  BindgenContext ctx,
  List<FormalParameterElement> params, {
  BindgenMemberConfig? member,
}) {
  return List.generate(
    params.length,
    (index) => _parameterFrom(
      ctx,
      params[index],
      paramConfig: member?.params[params[index].name],
    ),
  ).join('\n');
}

String _parameterFrom(
  BindgenContext ctx,
  FormalParameterElement parameter, {
  BindgenParamConfig? paramConfig,
}) {
  return '''
    BridgeParameter(
      '${parameter.isNamed ? parameter.name?.replaceFirst(RegExp('^_'), '') : parameter.name}',
      ${paramConfig?.type != null ? bridgeTypeAnnotationFromName(ctx, paramConfig!.type!) : bridgeTypeAnnotationFrom(ctx, parameter.type)},
      ${(paramConfig?.optional ?? parameter.isOptional) ? 'true' : 'false'},
    ),
  ''';
}

/// SDK member names that would collide with members every wrapper class
/// defines (`$value`, `$reified`, ...). Their generated wrapper statics are
/// renamed to `$_<name>` (e.g. `RangeError.value` → `$RangeError.$_value`).
const _reservedWrapperNames = {
  'value',
  'reified',
  'type',
  'spec',
  'declaration',
  'getProperty',
  'setProperty',
  'getRuntimeType',
  'methods',
};

/// The generated static member name for an SDK member — `\$name`, or
/// `\$_name` when it would collide with a wrapper member.
String memberWrapperName(String name) =>
    _reservedWrapperNames.contains(name) ? '\$_$name' : '\$$name';

String argumentAccessor(
  BindgenContext ctx,
  int index,
  FormalParameterElement param, {
  Map<String, String> paramMapping = const {},
  bool isBridgeMethod = false,
  String? argumentSource,
  String? primitiveSource,
  BindgenParamConfig? paramConfig,
}) {
  final paramBuffer = StringBuffer();
  final idx = index + (isBridgeMethod ? 1 : 0);
  // Optional params may be absent when the call site sends only provided
  // arguments, so access must be bounds-safe.
  final source =
      argumentSource ??
      (param.isOptional
          ? '(args.length > $idx ? args[$idx] : null)'
          : 'args[$idx]');
  if (param.isNamed) {
    paramBuffer.write(
      '${paramMapping[param.name] ?? param.name?.replaceFirst(RegExp('^_'), '')}: ',
    );
  }
  final type = param.type;
  final defaultExpr = paramConfig?.defaultValue ?? param.defaultValueCode;
  if (defaultExpr != null) {
    paramBuffer.write('$source == null ? $defaultExpr : ');
  }
  if (type.isDartCoreFunction || type is FunctionType) {
    if (type.nullabilitySuffix == NullabilitySuffix.question) {
      paramBuffer.write('$source == null || $source is \$null ? null : ');
    }
    if (type is FunctionType) {
      paramBuffer.write('(');
      paramBuffer.write(parameterHeader(type.formalParameters));
      paramBuffer.write(') {\n');
      if (type.returnType is! VoidType) {
        paramBuffer.write('return ');
      }
      final q = (param.isRequired ? '' : '?');
      final call = (param.isRequired ? '' : '?.call');
      final wrapped = [
        for (var j = 0; j < type.formalParameters.length; j++)
          wrapVar(
            ctx,
            type.formalParameters[j].type,
            type.formalParameters[j].name == null ||
                    type.formalParameters[j].name!.isEmpty
                ? 'arg$j'
                : type.formalParameters[j].name!,
            forCollection: true,
          ),
      ];
      final exprs = wrapped.map((e) => _asExpression(e!)).toList();
      final callableArgs = switch (exprs.length) {
        0 => 'null, null, 0',
        1 => '${exprs[0]}, null, 1',
        2 => '${exprs[0]}, ${exprs[1]}, 2',
        _ => '${exprs[0]}, ${exprs[1]}, [${exprs.skip(2).join(', ')}]',
      };
      paramBuffer.write(
        '($source! as EvalCallable$q)$call(runtime, null, $callableArgs)',
      );
      if (type.returnType is! VoidType) {
        paramBuffer.write('?.\$value');
      }
      paramBuffer.write(';\n}');
    } else {
      // Untyped `Function` parameter (e.g. `StreamSubscription.onError`):
      // the host may call it with 1-3 positional arguments. Accept up to
      // three and forward the ones that were actually passed.
      final q = (param.isRequired ? '' : '?');
      final call = (param.isRequired ? '' : '?.call');
      paramBuffer.write(
        '(a0, [a1, a2]) {\n'
        'final _a0 = runtime.wrapAlways(a0);\n'
        '($source! as EvalCallable$q)$call(runtime, null, _a0,\n'
        'a1 != null ? runtime.wrapAlways(a1) : null,\n'
        'a2 != null ? [runtime.wrapAlways(a2)] : a1 != null ? 2 : 1);\n}',
      );
    }
  } else {
    final primitiveName = type.element?.name;
    if (primitiveSource != null &&
        type.nullabilitySuffix == NullabilitySuffix.none &&
        type.element?.library?.uri.toString() == 'dart:core' &&
        const {
          'int',
          'double',
          'num',
          'bool',
          'String',
        }.contains(primitiveName)) {
      paramBuffer.write('($primitiveSource as \$$primitiveName).\$value');
      return paramBuffer.toString();
    }
    final needsCast =
        type.isDartCoreList || type.isDartCoreMap || type.isDartCoreSet;
    final reify = needsCast || type.isDartCoreObject || type is DynamicType;
    if (needsCast) {
      paramBuffer.write('(');
    }
    paramBuffer.write(source);
    final accessor = reify ? 'reified' : 'value';
    if (param.isRequired) {
      paramBuffer.write('!.\$$accessor');
    } else {
      paramBuffer.write('?.\$$accessor');
    }
    if (needsCast) {
      final q = (param.isRequired ? '' : '?');
      paramBuffer.write(' as ${type.element!.name}$q');
      final typeArgs = type is ParameterizedType
          ? type.typeArguments.map(dartTypeErased).join(', ')
          : '';
      paramBuffer.write(')$q.cast${typeArgs.isEmpty ? '()' : '<$typeArgs>()'}');
    }
  }
  return paramBuffer.toString();
}

List<String> argumentAccessors(
  BindgenContext ctx,
  List<FormalParameterElement> params, {
  Map<String, String> paramMapping = const {},
  bool isBridgeMethod = false,
  bool registers = false,
  bool callable = false,
  BindgenMemberConfig? member,
}) {
  final offset = isBridgeMethod ? 1 : 0;
  return params
      .mapIndexed(
        (i, p) => argumentAccessor(
          ctx,
          i,
          p,
          paramMapping: paramMapping,
          isBridgeMethod: isBridgeMethod,
          argumentSource: registers
              ? registerArgumentSource(i, params.length, optional: p.isOptional)
              : callable
              ? callSlotSource(i + offset, optional: p.isOptional)
              : null,
          primitiveSource: registers
              ? registerRawArgumentSource(
                  i,
                  params.length,
                  optional: p.isOptional,
                )
              : callable
              ? callRawSlotSource(i + offset, optional: p.isOptional)
              : null,
          paramConfig: member?.params[p.name],
        ),
      )
      .toList();
}

/// Converts a collection element produced by [wrapVar] (`if (cond) a else b`)
/// into an expression usable outside list literals.
String _asExpression(String element) {
  if (!element.startsWith('if (')) return element;
  var depth = 0;
  var i = 3;
  for (; i < element.length; i++) {
    final ch = element[i];
    if (ch == '(') depth++;
    if (ch == ')' && --depth == 0) break;
  }
  final cond = element.substring(4, i);
  final rest = element.substring(i + 2);
  depth = 0;
  for (var j = 0; j < rest.length; j++) {
    final ch = rest[j];
    if (ch == '(' || ch == '[' || ch == '{') depth++;
    if (ch == ')' || ch == ']' || ch == '}') depth--;
    if (depth == 0 && rest.startsWith(' else ', j)) {
      return '($cond ? ${rest.substring(0, j)} : ${rest.substring(j + 6)})';
    }
  }
  return '($cond ? $rest : null)';
}

/// Sources in the [EvalCallable.call] ABI: R/S are arguments 0 and 1, and C
/// is the `int` argument count below three arguments or a `List<Object?>` of
/// arguments 2..n-1 otherwise. [slot] is the flat argument index — bridge
/// super-method vectors shift parameters by one to reserve slot 0 for the
/// guest receiver.
String callSlotSource(int slot, {bool optional = false}) => switch (slot) {
  0 when optional => '(r is \$Value ? r : null)',
  1 when optional => '(s is \$Value ? s : null)',
  0 => '(r as \$Value?)',
  1 => '(s as \$Value?)',
  _ when optional =>
    '(c is List && (c as List).length > ${slot - 2} '
        '? (c as List)[${slot - 2}] as \$Value? : null)',
  _ => '((c as List<Object?>)[${slot - 2}] as \$Value?)',
};

String callRawSlotSource(int slot, {bool optional = false}) => switch (slot) {
  0 => 'r',
  1 => 's',
  _ when optional =>
    '(c is List && (c as List).length > ${slot - 2} '
        '? (c as List)[${slot - 2}] : null)',
  _ => '(c as List)[${slot - 2}]',
};

/// Sources in the canonical register-call ABI. Overflow values are captured in
/// scalar locals so a generated native callback never retains the borrowed C list.
/// Optional parameters guard against stale register contents because the call
/// site only assigns the provided arguments.
String registerArgumentSource(int index, int count, {bool optional = false}) =>
    switch (index) {
      0 when optional => '(r is \$Value ? r : null)',
      1 when optional => '(s is \$Value ? s : null)',
      0 => '(r as \$Value?)',
      1 => '(s as \$Value?)',
      2 when count <= 3 && optional => '(c is \$Value ? c : null)',
      2 when count <= 3 => '(c as \$Value?)',
      _ when optional => '_arg${index}OrNull',
      _ => '_arg$index',
    };

String registerArgumentPreamble(List<FormalParameterElement> params) => [
  for (var index = 2; index < params.length && params.length > 3; index++)
    params[index].isOptional
        ? 'final _arg${index}OrNull = c is List && '
              'c.length > ${index - 2} ? c[${index - 2}] as \$Value? : null;'
        : 'final _arg$index = (c as List<Object?>)[${index - 2}] as \$Value?;',
].join('\n');

String registerRawArgumentSource(
  int index,
  int count, {
  bool optional = false,
}) => switch (index) {
  0 => 'r',
  1 => 's',
  2 when count <= 3 => 'c',
  _ when optional => '_arg${index}OrNull',
  _ => '_arg$index',
};
