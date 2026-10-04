import 'dart:convert';

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
      ${parameter.defaultValueCode == null ? '' : 'defaultValueSource: ${jsonEncode(parameter.defaultValueCode)},'}
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
  bool exportValues = false,
  String? argumentSource,
  String? primitiveSource,
  BindgenParamConfig? paramConfig,
  bool includeNamedLabel = true,
  bool useDefaultValue = true,
}) {
  final paramBuffer = StringBuffer();
  // Optional params may be absent when the call site sends only provided
  // arguments, so access must be bounds-safe.
  final source = argumentSource!;
  if (param.isNamed && includeNamedLabel) {
    paramBuffer.write(
      '${paramMapping[param.name] ?? param.name?.replaceFirst(RegExp('^_'), '')}: ',
    );
  }
  final type = param.type;
  final enclosing = param.enclosingElement;
  final owner = enclosing is ConstructorElement
      ? 'constructor'
      : enclosing is ExecutableElement && !enclosing.isStatic
      ? exportValues
            ? 'bridge'
            : 'self'
      : 'static';
  final defaultExpr = useDefaultValue
      ? paramConfig?.defaultValue ?? param.defaultValueCode
      : null;
  if (defaultExpr != null) {
    paramBuffer.write('$source == null ? $defaultExpr : ');
  }
  if (type.isDartCoreFunction || type is FunctionType) {
    if (type.nullabilitySuffix == NullabilitySuffix.question) {
      ctx.imports.add('package:dart_eval/stdlib/core.dart');
      paramBuffer.write('$source == null || $source is \$null ? null : ');
    }
    final signature = type is FunctionType
        ? type.getDisplayString().replaceFirst(RegExp(r'\?$'), '')
        : 'Function';
    // Capture witnesses while the caller's constructor/method context is live.
    // Native callbacks can run after that context has been restored.
    final callbackTypes = type is FunctionType
        ? [
            for (final p in type.formalParameters)
              p.type is VoidType
                  ? null
                  : runtimeTypeIdFor(
                      ctx,
                      p.type,
                      owner,
                      methodTypeArguments: 'runtime.bridgeCallTypeArguments',
                    ),
          ]
        : <String?>[];
    final callbackReturnType =
        type is FunctionType && _isDartCoreSink(type.returnType)
        ? runtimeTypeIdFor(
            ctx,
            type.returnType,
            owner,
            methodTypeArguments: 'runtime.bridgeCallTypeArguments',
          )
        : null;
    final captureCallbackTypes =
        callbackTypes.any((type) => type != null) || callbackReturnType != null;
    if (captureCallbackTypes) {
      ctx.imports.add(
        'package:dart_eval/src/eval/runtime/typed/typed_interop.dart',
      );
      paramBuffer.write('(() { ');
      for (final (i, typeId) in callbackTypes.indexed) {
        if (typeId != null) {
          paramBuffer.write('final _callbackType$i = $typeId; ');
        }
      }
      if (callbackReturnType != null) {
        paramBuffer.write('final _callbackReturnType = $callbackReturnType; ');
      }
      paramBuffer.write('return ');
    }
    final witnessKey = [
      for (final (i, typeId) in callbackTypes.indexed)
        if (typeId != null) '\$_callbackType$i',
      if (callbackReturnType != null) '\$_callbackReturnType',
    ].join(',');
    paramBuffer.write(
      'runtime.cachedCallback($source! as EvalCallable, '
      '${jsonEncode('$signature;export=$exportValues')}${witnessKey.isEmpty ? '' : ' + ";types=$witnessKey"'}, (_callable) => ',
    );
    if (type is FunctionType) {
      if (type.typeParameters.isNotEmpty) {
        paramBuffer.write(
          '<${type.typeParameters.map((p) {
            final bound = p.bound;
            return bound == null || bound is DynamicType || (bound.isDartCoreObject && bound.nullabilitySuffix != NullabilitySuffix.none) ? p.name : '${p.name} extends ${bound.getDisplayString()}';
          }).join(', ')}>',
        );
      }
      paramBuffer.write('(');
      paramBuffer.write(
        parameterHeader(
          type.formalParameters,
          preserveTypes: type.typeParameters.isNotEmpty,
        ),
      );
      paramBuffer.write(') {\n');
      if (type.returnType is! VoidType) {
        paramBuffer.write('return ');
      }
      final wrapped = type.formalParameters.indexed.map((entry) {
        final (index, parameter) = entry;
        final name = parameter.name ?? '';
        final value = name.isEmpty ? 'arg$index' : name;
        if (parameter.type is VoidType) {
          ctx.imports.add('package:dart_eval/stdlib/core.dart');
          return 'const \$null()';
        }
        if (callbackTypes[index] != null) {
          final payload = parameter.type;
          if (payload.isDartCoreList ||
              payload.isDartCoreMap ||
              payload.isDartCoreSet ||
              payload is TypeParameterType ||
              payload is DynamicType) {
            return 'TypedInterop.boxExternal($value, runtime: runtime, '
                'runtimeTypeId: _callbackType$index)';
          }
          final wrapped = wrapVar(ctx, payload, value, forCollection: true)!;
          if (_isDartCoreScalar(payload)) return wrapped;
          return 'TypedInterop.annotateBridgeType('
              '${_asExpression(wrapped)}, runtime, _callbackType$index)';
        }
        return exportValues
            ? wrapBridgeArgument(
                ctx,
                parameter.type,
                value,
                forCollection: true,
              )
            : wrapVar(ctx, parameter.type, value, forCollection: true);
      });
      final exprs = wrapped.map((e) => _asExpression(e!)).toList();
      final callableArgs = switch (exprs.length) {
        0 => 'null, null, 0',
        1 => '${exprs[0]}, null, 1',
        2 => '${exprs[0]}, ${exprs[1]}, 2',
        _ => '${exprs[0]}, ${exprs[1]}, [${exprs.skip(2).join(', ')}]',
      };
      final invocation = '_callable.call(runtime, null, $callableArgs)';
      if (type.returnType is VoidType) {
        paramBuffer.write(invocation);
      } else {
        final nativeReturnType = _nativeCallbackReturnType(
          ctx,
          type.returnType,
          owner,
          type.typeParameters,
        );
        paramBuffer.write(
          exportValues ||
                  _isDartCoreSink(type.returnType) ||
                  type.returnType is TypeParameterType ||
                  type.returnType.isDartCoreObject ||
                  type.returnType is DynamicType
              ? _exportValue(
                  ctx,
                  type.returnType,
                  invocation,
                  owner: owner,
                  nativeTypeParameters: owner == 'bridge',
                  localTypeParameters: type.typeParameters,
                  runtimeTypeId: callbackReturnType == null
                      ? null
                      : '_callbackReturnType',
                )
              : '$invocation?.\$value as $nativeReturnType',
        );
      }
      paramBuffer.write(';\n}');
    } else {
      // Untyped `Function` parameter (e.g. `StreamSubscription.onError`):
      // the host may call it with 1-3 positional arguments. Accept up to
      // three and forward the ones that were actually passed.
      paramBuffer.write(
        '(a0, [a1, a2]) {\n'
        'final _a0 = runtime.wrapAlways(a0);\n'
        '_callable.call(runtime, null, _a0,\n'
        'a1 != null ? runtime.wrapAlways(a1) : null,\n'
        'a2 != null ? [runtime.wrapAlways(a2)] : a1 != null ? 2 : 1);\n}',
      );
    }
    paramBuffer.write(')');
    if (captureCallbackTypes) {
      paramBuffer.write('; })()');
    }
  } else {
    final primitiveName = type.element?.name;
    if (primitiveSource != null &&
        type.nullabilitySuffix == NullabilitySuffix.none &&
        _isDartCoreScalar(type)) {
      paramBuffer.write('($primitiveSource as \$$primitiveName).\$value');
      return paramBuffer.toString();
    }
    // Erased generic arguments can contain guest objects without a host value.
    // Iterable arguments need a typed element view at the SDK boundary.
    if (type is TypeParameterType ||
        type.isDartCoreIterable ||
        type.isDartCoreObject ||
        type is DynamicType ||
        exportValues && _isDartCoreIterator(type) ||
        _isDartCoreSink(type)) {
      paramBuffer.write(
        _exportValue(
          ctx,
          type,
          source,
          owner: owner,
          nativeTypeParameters: owner == 'bridge',
        ),
      );
      return paramBuffer.toString();
    }
    final needsCast =
        type.isDartCoreList || type.isDartCoreMap || type.isDartCoreSet;
    final reify = needsCast || type.isDartCoreObject || type is DynamicType;
    if (needsCast) {
      paramBuffer.write('(');
    }
    if (type.isDartCoreList) {
      ctx.imports.add(
        'package:dart_eval/src/eval/runtime/typed/typed_interop.dart',
      );
      paramBuffer.write(
        'TypedInterop.exportExternal($source, runtime: runtime)',
      );
    } else {
      paramBuffer.write(source);
      final accessor = reify ? 'reified' : 'value';
      if (param.isRequired || defaultExpr != null) {
        paramBuffer.write('!.\$$accessor');
      } else {
        paramBuffer.write('?.\$$accessor');
      }
    }
    if (needsCast) {
      // Optional arguments can still have non-nullable types when the host
      // declaration supplies a default value. The fallback above handles an
      // absent argument; the cast must reflect the declared type.
      final q = type.nullabilitySuffix == NullabilitySuffix.question ? '?' : '';
      paramBuffer.write(' as ${type.element!.name}$q');
      // Native bridge calls have their SDK type parameters in scope. Let
      // the receiving method infer them instead of forcing erased arguments.
      final typeArgs = !exportValues && type is ParameterizedType
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
  bool exportValues = false,
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
          exportValues: exportValues,
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

bool _isDartCoreIterator(DartType type) =>
    type is InterfaceType &&
    type.element.name == 'Iterator' &&
    type.element.library.uri.toString() == 'dart:core';

bool _isDartCoreSink(DartType type) =>
    type is InterfaceType &&
    type.element.name == 'Sink' &&
    type.element.library.uri.toString() == 'dart:core';

bool _isDartCoreScalar(DartType type) =>
    type.element?.library?.uri.toString() == 'dart:core' &&
    const {
      'int',
      'double',
      'num',
      'bool',
      'String',
    }.contains(type.element?.name);

String _exportValue(
  BindgenContext ctx,
  DartType type,
  String source, {
  String? owner,
  bool nativeTypeParameters = false,
  String? runtimeTypeId,
  Iterable<TypeParameterElement> localTypeParameters = const [],
}) {
  if (_isDartCoreScalar(type)) {
    return '$source?.\$value as ${dartTypeErased(type)}';
  }
  ctx.imports.add(
    'package:dart_eval/src/eval/runtime/typed/typed_interop.dart',
  );
  if (_isDartCoreSink(type)) {
    if (type.nullabilitySuffix == NullabilitySuffix.question) {
      ctx.imports.add('package:dart_eval/stdlib/core.dart');
    }
    final sink = type as InterfaceType;
    final payload = sink.typeArguments.single;
    final nativeType = dartTypeErased(
      payload,
      nativeOwner: nativeTypeParameters ? ctx.classElement : null,
      localTypeParameters: localTypeParameters,
    );
    final typeId =
        runtimeTypeId ??
        runtimeTypeIdFor(
          ctx,
          sink,
          owner,
          methodTypeArguments: 'runtime.bridgeCallTypeArguments',
        )!;
    final exported =
        'TypedInterop.exportSink<$nativeType>($source, runtime, $typeId)';
    return type.nullabilitySuffix == NullabilitySuffix.question
        ? '$source == null || $source is \$null ? null : $exported'
        : exported;
  }
  if (_isDartCoreIterator(type)) {
    return 'TypedInterop.exportIterator($source, runtime)';
  }
  if (type.isDartCoreIterable) {
    if (type.nullabilitySuffix == NullabilitySuffix.question) {
      ctx.imports.add('package:dart_eval/stdlib/core.dart');
    }
    final exported = 'TypedInterop.exportIterable($source, runtime)';
    return type.nullabilitySuffix == NullabilitySuffix.question
        ? '$source == null || $source is \$null ? null : $exported'
        : exported;
  }
  return 'TypedInterop.exportExternal($source, runtime: runtime) '
      'as ${dartTypeErased(type, nativeOwner: nativeTypeParameters ? ctx.classElement : null, localTypeParameters: localTypeParameters)}';
}

String _nativeCallbackReturnType(
  BindgenContext ctx,
  DartType type,
  String owner,
  Iterable<TypeParameterElement> localTypeParameters,
) {
  void importAsync(DartType type) {
    if (type.isDartAsyncFutureOr || type.isDartAsyncFuture) {
      ctx.imports.add('dart:async');
    }
    if (type is ParameterizedType) {
      for (final argument in type.typeArguments) {
        importAsync(argument);
      }
    }
    if (type is FunctionType) {
      importAsync(type.returnType);
      for (final parameter in type.formalParameters) {
        importAsync(parameter.type);
      }
    }
  }

  importAsync(type);
  return dartTypeErased(
    type,
    nativeOwner: owner == 'bridge' ? ctx.classElement : null,
    localTypeParameters: localTypeParameters,
  );
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
