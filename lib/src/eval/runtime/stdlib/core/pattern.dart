import 'package:dart_eval/src/eval/bridge/declaration/type.dart';

import '../../../../../dart_eval.dart';
import '../../../../../dart_eval_bridge.dart';

extension $PatternExtension on Pattern {
  $Pattern get $wrapped => $Pattern.wrap(this);
}

class $Pattern implements Pattern, $Instance {
  $Pattern.wrap(this.$value);

  @override
  final Pattern $value;

  @override
  Pattern get $reified => $value;

  final $Instance evalSuperclass = const $Object();

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch(identifier) {
      case 'allMatches':
        return $Function(__allMatches);
    }
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    // TODO: implement $setProperty
  }

  static const $Function __allMatches = $Function(_allMatches);

  static $Value? _allMatches(final Runtime runtime, final $Value? target, final List<$Value?> args) {
    target as $Value;
    final string = (args[0] as $String).$value;
    return $Iterable<Match>.wrap((target.$value as Pattern).allMatches(string));
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

  static const $type = BridgeClassTypeDeclaration('dart:core', 'Pattern', isAbstract: true);

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
  Iterable<Match> allMatches(String string, [int start = 0]) =>
      $_invoke('allMatches', [$String(string), $int(start)]);

  @override
  Match? matchAsPrefix(String string, [int start = 0]) =>
      $_invoke('matchAsPrefix', [$String(string), $int(start)]);

  @override
  // TODO: implement $runtimeType
  int get $runtimeType => throw UnimplementedError();
}