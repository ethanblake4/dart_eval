import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';

/// dart_eval wrapper for [Match]
class $Match implements $Instance {
  /// Compile-time type reference to [Match]
  static const $type = BridgeTypeRef(BridgeTypeSpec('dart:core', 'Match'));

  /// Compile-time bridge declaration of [Match]
  static const $declaration =
      BridgeClassDef(BridgeClassType($type, isAbstract: true),
          constructors: {},
          methods: {
            'group': BridgeMethodDef(BridgeFunctionDef(
              returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string),
                  nullable: true),
              params: [
                BridgeParameter('group',
                    BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)), false)
              ],
            )),
            'groups': BridgeMethodDef(BridgeFunctionDef(
              returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.list),
                  nullable: false),
              params: [
                BridgeParameter(
                    'groupIndices',
                    BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.list,
                        [BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int))])),
                    false)
              ],
            )),
            '[]': BridgeMethodDef(BridgeFunctionDef(
              returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string),
                  nullable: true),
              params: [
                BridgeParameter('group',
                    BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)), false)
              ],
            )),
          },
          getters: {
            'input': BridgeMethodDef(BridgeFunctionDef(
                returns:
                    BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)))),
            'start': BridgeMethodDef(BridgeFunctionDef(
                returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)))),
            'end': BridgeMethodDef(BridgeFunctionDef(
                returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)))),
            'groupCount': BridgeMethodDef(BridgeFunctionDef(
                returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)))),
          },
          wrap: true);

  /// Wrap a [Match] in a [$Match]
  $Match.wrap(this.$value) : _superclass = $Object($value);

  @override
  final Match $value;

  @override
  Match get $reified => $value;

  late final $Instance _superclass;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'input':
        return $String($value.input);

      case 'start':
        return $int($value.start);

      case 'end':
        return $int($value.end);

      case 'groupCount':
        return $int($value.groupCount);

      case 'group':
      case '[]':
        return __group;
      case 'groups':
        return __groups;
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __group = $Function(_group);

  static $Value? _group(
      final Runtime runtime, final $Value? target, final List<$Value?> args) {
    final group = (args[0] as $int).$value;
    final $result = (target!.$value as Match).group(group);
    return $result == null ? $null() : $String($result);
  }

  static const $Function __groups = $Function(_groups);

  static $Value _groups(
      final Runtime runtime, final $Value? target, final List<$Value?> args) {
    final list = (args[0] as $List).$value;
    final groups = [for ($int i in list) i.$value];
    final $result = (target!.$value as Match).groups(groups);
    return $List.wrap(
        [for (String? str in $result) str == null ? $null() : $String(str)]);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);
}

/// dart_eval wrapper for [Pattern]
class $Pattern implements Pattern, $Instance {
  /// Compile-time type reference to [Pattern]
  static const $type = BridgeTypeRef(BridgeTypeSpec('dart:core', 'Pattern'));

  /// Compile-time bridge declaration of [Pattern]
  static const $declaration =
      BridgeClassDef(BridgeClassType($type, isAbstract: true),
          constructors: {},
          methods: {
            'allMatches': BridgeMethodDef(BridgeFunctionDef(
                returns: BridgeTypeAnnotation(BridgeTypeRef(
                    CoreTypes.iterable, [BridgeTypeAnnotation($Match.$type)])),
                params: [
                  BridgeParameter(
                      'string',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
                      false),
                  BridgeParameter('start',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)), true),
                ])),
            'matchAsPrefix': BridgeMethodDef(BridgeFunctionDef(
                returns: BridgeTypeAnnotation($Match.$type),
                params: [
                  BridgeParameter(
                      'string',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
                      false),
                  BridgeParameter('start',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)), true),
                ])),
          },
          wrap: true);

  /// Wrap a [Pattern] in a [$Pattern]
  $Pattern.wrap(this.$value) : _superclass = $Object($value);

  @override
  final Pattern $value;

  @override
  Pattern get $reified => $value;

  final $Instance _superclass;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'allMatches':
        return $Function(__allMatches.call);
      case 'matchAsPrefix':
        return $Function(__matchAsPrefix.call);
      default:
        return _superclass.$getProperty(runtime, identifier);
    }
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }

  static const $Function __allMatches = $Function(_allMatches);

  static $Value? _allMatches(
      final Runtime runtime, final $Value? target, final List<$Value?> args) {
    target as $Value;
    final string = (args[0] as $String).$value;
    final start = (args[1] as $int?)?.$value ?? 0;
    return $Iterable<$Match>.wrap((target.$value as Pattern)
        .allMatches(string, start)
        .map((e) => $Match.wrap(e)));
  }

  static const $Function __matchAsPrefix = $Function(_matchAsPrefix);

  static $Value? _matchAsPrefix(
      final Runtime runtime, final $Value? target, final List<$Value?> args) {
    target as $Value;
    final string = (args[0] as $String).$value;
    final start = (args[1] as $int?)?.$value ?? 0;
    final result = (target.$value as Pattern).matchAsPrefix(string, start);
    if (result == null) {
      return $null();
    }
    return $Match.wrap(result);
  }

  @override
  Iterable<Match> allMatches(String string, [int start = 0]) =>
      $value.allMatches(string, start);

  @override
  Match? matchAsPrefix(String string, [int start = 0]) =>
      $value.matchAsPrefix(string, start);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);
}

class $Pattern$bridge with $Bridge implements Pattern {
  const $Pattern$bridge(List<Object?> _);

  static const $type = BridgeTypeRef(BridgeTypeSpec('dart:core', 'Pattern'));

  @override
  $Value? $bridgeGet(String identifier) {
    switch (identifier) {}
    throw UnimplementedError();
  }

  @override
  void $bridgeSet(String identifier, $Value value) {
    throw UnimplementedError();
  }

  @override
  Iterable<Match> allMatches(String string, [int start = 0]) =>
      $_invoke('allMatches', [$String(string), $int(start)]);

  @override
  Match? matchAsPrefix(String string, [int start = 0]) =>
      $_invoke('matchAsPrefix', [$String(string), $int(start)]);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);
}
