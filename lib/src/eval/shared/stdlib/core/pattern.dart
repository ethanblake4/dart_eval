import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';

class $Match implements $Instance {
  static const $type = BridgeTypeRef(BridgeTypeSpec('dart:core', 'Match'));

  static const $declaration = BridgeClassDef(BridgeClassType($type, isAbstract: true),
      constructors: {},
      methods: {
        'group': BridgeMethodDef(BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.stringType), nullable: true),
          params: [BridgeParameter('group', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.intType)), false)],
        )),
        '[]': BridgeMethodDef(BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.stringType), nullable: true),
          params: [BridgeParameter('group', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.intType)), false)],
        )),
      },
      getters: {
        'start':
            BridgeMethodDef(BridgeFunctionDef(returns: BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.intType)))),
        'end':
            BridgeMethodDef(BridgeFunctionDef(returns: BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.intType)))),
      },
      wrap: true);
  $Match.wrap(this.$value) : _superclass = $Object($value);

  @override
  final Match $value;

  @override
  Match get $reified => $value;

  late final $Instance _superclass;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'start':
        return $int($value.start);
      case 'end':
        return $int($value.end);
      case 'group':
        return $Function(__group);
      case '[]':
        return $Function(__group);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __group = $Function(_group);

  static $Value? _group(final Runtime runtime, final $Value? target, final List<$Value?> args) {
    final group = (args[0] as $int).$value;
    final $result = (target!.$value as Match).group(group);
    return $result == null ? $null() : $String($result);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }

  @override
  int get $runtimeType => throw UnimplementedError();
}

class $Pattern implements Pattern, $Instance {
  static const $type = BridgeTypeRef(BridgeTypeSpec('dart:core', 'Pattern'));

  static const $declaration = BridgeClassDef(BridgeClassType($type, isAbstract: true),
      constructors: {},
      methods: {
        'allMatches': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.iterable, [$Match.$type])),
            params: [
              BridgeParameter('string', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.stringType)), false),
              BridgeParameter('start', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.intType)), true),
            ])),
        'matchAsPrefix': BridgeMethodDef(BridgeFunctionDef(returns: BridgeTypeAnnotation($Match.$type), params: [
          BridgeParameter('string', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.stringType)), false),
          BridgeParameter('start', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.intType)), true),
        ])),
      },
      wrap: true);
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
        return $Function(__allMatches);
      case 'matchAsPrefix':
        return $Function(__matchAsPrefix);
      default:
        return _superclass.$getProperty(runtime, identifier);
    }
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }

  static const $Function __allMatches = $Function(_allMatches);

  static $Value? _allMatches(final Runtime runtime, final $Value? target, final List<$Value?> args) {
    target as $Value;
    final string = (args[0] as $String).$value;
    final start = (args[1] as $int?)?.$value ?? 0;
    return $Iterable<$Match>.wrap((target.$value as Pattern).allMatches(string, start).map((e) => $Match.wrap(e)));
  }

  static const $Function __matchAsPrefix = $Function(_matchAsPrefix);

  static $Value? _matchAsPrefix(final Runtime runtime, final $Value? target, final List<$Value?> args) {
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
  Iterable<Match> allMatches(String string, [int start = 0]) => $value.allMatches(string, start);

  @override
  Match? matchAsPrefix(String string, [int start = 0]) => $value.matchAsPrefix(string, start);

  @override
  int get $runtimeType => throw UnimplementedError();
}

class $Pattern$bridge with $Bridge implements Pattern {
  const $Pattern$bridge(List<Object?> _);

  static const $type = BridgeTypeRef(BridgeTypeSpec('dart:core', 'Pattern'));

  @override
  $Value? $bridgeGet(String identifier) {
    switch (identifier) {
      
    }
    throw UnimplementedError();
  }

  @override
  void $bridgeSet(String identifier, $Value value) {
    throw UnimplementedError();
  }

  @override
  Iterable<Match> allMatches(String string, [int start = 0]) => $_invoke('allMatches', [$String(string), $int(start)]);

  @override
  Match? matchAsPrefix(String string, [int start = 0]) => $_invoke('matchAsPrefix', [$String(string), $int(start)]);

  @override
  // TODO: implement $runtimeType
  int get $runtimeType => throw UnimplementedError();
}
