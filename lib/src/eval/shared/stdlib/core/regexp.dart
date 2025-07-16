import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';

/// dart_eval wrapper for [RegExp]
class $RegExp implements $Instance {
  /// Compile-time type reference to [RegExp]
  static const $type = BridgeTypeRef(BridgeTypeSpec('dart:core', 'RegExp'));

  /// Compile-time bridge declaration of [RegExp]
  static const $declaration = BridgeClassDef(
      BridgeClassType($type, isAbstract: true, $extends: $Pattern.$type),
      constructors: {
        '': BridgeConstructorDef(
            BridgeFunctionDef(returns: BridgeTypeAnnotation($type), params: [
          BridgeParameter('source',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)), false),
        ], namedParams: [
          BridgeParameter('multiLine',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)), false),
          BridgeParameter('caseSensitive',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)), false),
          BridgeParameter('unicode',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)), false),
          BridgeParameter('dotAll',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)), false),
        ]))
      },
      methods: {
        'hasMatch': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
            params: [
              BridgeParameter('input',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)), false),
            ])),
        'firstMatch': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation($RegExpMatch.$type, nullable: true),
            params: [
              BridgeParameter('input',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)), false),
            ])),
        'allMatches': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable,
                    [BridgeTypeAnnotation($RegExpMatch.$type)]),
                nullable: true),
            params: [
              BridgeParameter('input',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)), false),
              BridgeParameter('start',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)), true),
            ])),
        'stringMatch': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string),
                nullable: true),
            params: [
              BridgeParameter('input',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)), false),
            ]))
      },
      wrap: true);

  /// Wrap a [RegExp] in a [$RegExp]
  $RegExp.wrap(this.$value) : _superclass = $Pattern.wrap($value);

  static $Value? $new(Runtime runtime, $Value? target, List<$Value?> args) {
    return $RegExp.wrap(RegExp(args[0]!.$value,
        multiLine: args[1]?.$value ?? false,
        caseSensitive: args[2]?.$value ?? true,
        unicode: args[3]?.$value ?? false,
        dotAll: args[4]?.$value ?? false));
  }

  @override
  final RegExp $value;

  @override
  RegExp get $reified => $value;

  final $Instance _superclass;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'hasMatch':
        return __hasMatch;
      case 'firstMatch':
        return __firstMatch;
      case 'allMatches':
        return __allMatches;
      case 'stringMatch':
        return __stringMatch;

      default:
        return _superclass.$getProperty(runtime, identifier);
    }
  }

  static const $Function __hasMatch = $Function(_hasMatch);

  static $Value? _hasMatch(
      final Runtime runtime, final $Value? target, final List<$Value?> args) {
    target as $Value;
    final input = (args[0] as $String).$value;
    return $bool((target.$value as RegExp).hasMatch(input));
  }

  static const $Function __firstMatch = $Function(_firstMatch);

  static $Value? _firstMatch(
      final Runtime runtime, final $Value? target, final List<$Value?> args) {
    target as $Value;
    final input = (args[0] as $String).$value;
    final $result = (target.$value as RegExp).firstMatch(input);
    return $result == null ? $null() : $RegExpMatch.wrap($result);
  }

  static const $Function __allMatches = $Function(_allMatches);

  static $Value? _allMatches(
      final Runtime runtime, final $Value? target, final List<$Value?> args) {
    target as $Value;
    final string = (args[0] as $String).$value;
    final start = (args[1] as $int?)?.$value ?? 0;
    return $Iterable<$RegExpMatch>.wrap((target.$value as RegExp)
        .allMatches(string, start)
        .map((e) => $RegExpMatch.wrap(e)));
  }

  static const $Function __stringMatch = $Function(_stringMatch);

  static $Value? _stringMatch(
      final Runtime runtime, final $Value? target, final List<$Value?> args) {
    target as $Value;
    final input = (args[0] as $String).$value;

    final $result = (target.$value as RegExp).stringMatch(input);

    return $result == null ? $null() : $String($result);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);
}

class $RegExpMatch implements $Instance, RegExpMatch {
  /// Compile-time type reference to [RegExpMatch]
  static const $type =
      BridgeTypeRef(BridgeTypeSpec('dart:core', 'RegExpMatch'));

  /// Compile-time bridge declaration of [RegExp]
  static const $declaration = BridgeClassDef(
      BridgeClassType($type, isAbstract: true, $extends: $Match.$type),
      constructors: {},
      methods: {
        'namedGroup': BridgeMethodDef(BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string),
              nullable: true),
          params: [
            BridgeParameter('name',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)), false)
          ],
        )),
      },
      getters: {
        'pattern': BridgeMethodDef(
            BridgeFunctionDef(returns: BridgeTypeAnnotation($RegExp.$type))),
        'groupNames': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.iterable,
                [BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string))]))))
      },
      wrap: true);

  /// Wrap a [RegExpMatch] in a [$RegExpMatch]
  $RegExpMatch.wrap(this.$value) : _superclass = $Match.wrap($value);

  @override
  RegExpMatch get $reified => $value;

  @override
  final RegExpMatch $value;

  final $Instance _superclass;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'pattern':
        return $RegExp.wrap($value.pattern);

      case 'groupNames':
        return $Iterable.wrap($value.groupNames.map((e) => $String(e)));

      case 'namedGroup':
        return $Function(__namedGroup.call);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __namedGroup = $Function(_namedGroup);

  static $Value _namedGroup(
      final Runtime runtime, final $Value? target, final List<$Value?> args) {
    final group = (args[0] as $String).$value;

    final $result = (target!.$value as RegExpMatch).namedGroup(group);

    return $result == null ? $null() : $String($result);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    _superclass.$setProperty(runtime, identifier, value);
  }

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);

  @override
  String? operator [](int group) => $value[group];

  @override
  int get end => $value.end;

  @override
  String? group(int group) => $value.group(group);

  @override
  int get groupCount => $value.groupCount;

  @override
  Iterable<String> get groupNames => $value.groupNames;

  @override
  List<String?> groups(List<int> groupIndices) => $value.groups(groupIndices);

  @override
  String get input => $value.input;

  @override
  String? namedGroup(String name) => $value.namedGroup(name);

  @override
  RegExp get pattern => $value.pattern;

  @override
  int get start => $value.start;
}
