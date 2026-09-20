// ignore_for_file: unused_import, unnecessary_import
// ignore_for_file: always_specify_types, avoid_redundant_argument_values
// ignore_for_file: sort_constructors_first
// ignore_for_file: no_leading_underscores_for_local_identifiers
// ignore_for_file: prefer_is_empty
// ignore_for_file: undefined_hidden_name
// ignore_for_file: dead_code, unused_local_variable
// ignore_for_file: unnecessary_type_check, unnecessary_non_null_assertion
// ignore_for_file: sdk_version_since
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: argument_type_not_assignable_to_error_handler
// ignore_for_file: avoid_function_literals_in_foreach_calls

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';

import 'package:dart_eval/stdlib/core.dart'
    hide
        $Duration,
        $DateTime,
        $Iterator,
        $Comparable,
        $Sink,
        $StackTrace,
        $StringBuffer,
        $Symbol,
        $MapEntry,
        $Stopwatch,
        $Error,
        $TypeError,
        $NoSuchMethodError,
        $RangeError,
        $AssertionError,
        $ArgumentError,
        $StateError,
        $UnsupportedError,
        $UnimplementedError,
        $Invocation,
        $Exception,
        $FormatException,
        $Uri,
        $Pattern,
        $Match,
        $RegExp,
        $RegExpMatch,
        $StringSink;

/// dart_eval wrapper binding for [Pattern]
class $Pattern implements $Instance {
  /// Configure this class for use in a [Runtime]
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {}

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$Pattern]
  static const $spec = BridgeTypeSpec('dart:core', 'Pattern');

  /// Compile-time type declaration of [$Pattern]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$Pattern]
  static const $declaration = BridgeClassDef(
    BridgeClassType($type, isAbstract: true),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [],
        ),
        isFactory: false,
      ),
    },

    methods: {
      'allMatches': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.iterable, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.match, [])),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'string',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),

            BridgeParameter(
              'start',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
            ),
          ],
        ),
      ),

      'matchAsPrefix': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.match, []),
            nullable: true,
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'string',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),

            BridgeParameter(
              'start',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
            ),
          ],
        ),
      ),
    },
    getters: {},
    setters: {},
    fields: {},
    wrap: true,
    bridge: false,
  );

  final $Instance _superclass;

  @override
  final Pattern $value;

  @override
  Pattern get $reified => $value;

  /// Wrap a [Pattern] in a [$Pattern]
  $Pattern.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'allMatches':
        return __allMatches;

      case 'matchAsPrefix':
        return __matchAsPrefix;
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __allMatches = $Function(_allMatches);
  static $Value? _allMatches(
    Runtime runtime,
    $Value? target,
    List<$Value?> args,
  ) {
    final self = target! as $Pattern;
    final result = self.$value.allMatches(
      args[0]!.$value,
      (args.length > 1 ? args[1] : null) == null
          ? 0
          : (args.length > 1 ? args[1] : null)?.$value,
    );
    return $Iterable.wrap((result).map((e) => $Match.wrap(e)));
  }

  static const $Function __matchAsPrefix = $Function(_matchAsPrefix);
  static $Value? _matchAsPrefix(
    Runtime runtime,
    $Value? target,
    List<$Value?> args,
  ) {
    final self = target! as $Pattern;
    final result = self.$value.matchAsPrefix(
      args[0]!.$value,
      (args.length > 1 ? args[1] : null) == null
          ? 0
          : (args.length > 1 ? args[1] : null)?.$value,
    );
    return result == null ? const $null() : $Match.wrap(result);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}

/// dart_eval wrapper binding for [Match]
class $Match implements $Instance {
  /// Configure this class for use in a [Runtime]
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {}

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$Match]
  static const $spec = BridgeTypeSpec('dart:core', 'Match');

  /// Compile-time type declaration of [$Match]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$Match]
  static const $declaration = BridgeClassDef(
    BridgeClassType($type, isAbstract: true),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [],
        ),
        isFactory: false,
      ),
    },

    methods: {
      'group': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.string, []),
            nullable: true,
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'group',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),
          ],
        ),
      ),

      '[]': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.string, []),
            nullable: true,
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'group',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),
          ],
        ),
      ),

      'groups': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.list, [
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.string, []),
                nullable: true,
              ),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'groupIndices',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.list, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
                ]),
              ),
              false,
            ),
          ],
        ),
      ),
    },
    getters: {
      'start': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'end': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'groupCount': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'input': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'pattern': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.pattern, [])),
          namedParams: [],
          params: [],
        ),
      ),
    },
    setters: {},
    fields: {},
    wrap: true,
    bridge: false,
  );

  final $Instance _superclass;

  @override
  final Match $value;

  @override
  Match get $reified => $value;

  /// Wrap a [Match] in a [$Match]
  $Match.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'start':
        final _start = $value.start;
        return $int(_start);
      case 'end':
        final _end = $value.end;
        return $int(_end);
      case 'groupCount':
        final _groupCount = $value.groupCount;
        return $int(_groupCount);
      case 'input':
        final _input = $value.input;
        return $String(_input);
      case 'pattern':
        final _pattern = $value.pattern;
        return $Pattern.wrap(_pattern);
      case 'group':
        return __group;

      case '[]':
        return __operatorIndexGet;

      case 'groups':
        return __groups;
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __group = $Function(_group);
  static $Value? _group(Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target! as $Match;
    final result = self.$value.group(args[0]!.$value);
    return result == null ? const $null() : $String(result);
  }

  static const $Function __operatorIndexGet = $Function(_operatorIndexGet);
  static $Value? _operatorIndexGet(
    Runtime runtime,
    $Value? target,
    List<$Value?> args,
  ) {
    final self = target! as $Match;
    final result = self.$value[args[0]!.$value];
    return result == null ? const $null() : $String(result);
  }

  static const $Function __groups = $Function(_groups);
  static $Value? _groups(Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target! as $Match;
    final result = self.$value.groups((args[0]!.$reified as List).cast<int>());
    return $List.view(result, (e) => e == null ? const $null() : $String(e));
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
