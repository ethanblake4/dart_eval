// ignore_for_file: unused_import, unnecessary_import
// ignore_for_file: always_specify_types, avoid_redundant_argument_values
// ignore_for_file: sort_constructors_first
// ignore_for_file: no_leading_underscores_for_local_identifiers
// ignore_for_file: prefer_is_empty
// ignore_for_file: undefined_hidden_name
// ignore_for_file: dead_code, unused_local_variable
// ignore_for_file: unnecessary_type_check, unnecessary_non_null_assertion
// ignore_for_file: unnecessary_cast
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

import 'pattern.dart';

/// dart_eval wrapper binding for [RegExp]
class $RegExp implements $Instance {
  /// Configure this class for use in a [Runtime]
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters('dart:core', 'RegExp.', $RegExp.$new);

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'RegExp.escape',
      $RegExp.$escape,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$RegExp]
  static const $spec = BridgeTypeSpec('dart:core', 'RegExp');

  /// Compile-time type declaration of [$RegExp]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$RegExp]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,
      isAbstract: true,

      $implements: [BridgeTypeRef(CoreTypes.pattern, [])],
    ),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [
            BridgeParameter(
              'multiLine',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
              true,
            ),

            BridgeParameter(
              'caseSensitive',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
              true,
            ),

            BridgeParameter(
              'unicode',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
              true,
            ),

            BridgeParameter(
              'dotAll',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
              true,
            ),
          ],
          params: [
            BridgeParameter(
              'source',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),
          ],
        ),
        isFactory: true,
      ),
    },

    methods: {
      'allMatches': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.iterable, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.regExpMatch, [])),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'input',
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

      'escape': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'text',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),
          ],
        ),

        isStatic: true,
      ),

      'firstMatch': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.regExpMatch, []),
            nullable: true,
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'input',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),
          ],
        ),
      ),

      'hasMatch': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'input',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),
          ],
        ),
      ),

      'stringMatch': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.string, []),
            nullable: true,
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'input',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),
          ],
        ),
      ),
    },
    getters: {
      'pattern': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'isMultiLine': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'isCaseSensitive': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'isUnicode': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'isDotAll': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
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

  /// Wrapper for the [RegExp.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    final _arg2OrNull = c is List && c.length > 0 ? c[0] as $Value? : null;
    final _arg3OrNull = c is List && c.length > 1 ? c[1] as $Value? : null;
    final _arg4OrNull = c is List && c.length > 2 ? c[2] as $Value? : null;

    return $RegExp.wrap(
      RegExp(
        (r as $String).$value,
        multiLine: (s is $Value ? s : null) == null
            ? false
            : (s as $bool).$value,
        caseSensitive: _arg2OrNull == null
            ? true
            : (_arg2OrNull as $bool).$value,
        unicode: _arg3OrNull == null ? false : (_arg3OrNull as $bool).$value,
        dotAll: _arg4OrNull == null ? false : (_arg4OrNull as $bool).$value,
      ),
    );
  }

  /// Wrapper for the [RegExp.escape] method
  static $Value? $escape(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = RegExp.escape((r as $String).$value);
    return $String(value);
  }

  final $Instance _superclass;

  @override
  final RegExp $value;

  @override
  RegExp get $reified => $value;

  /// Wrap a [RegExp] in a [$RegExp]
  $RegExp.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'pattern':
        final _pattern = $value.pattern;
        return $String(_pattern);
      case 'isMultiLine':
        final _isMultiLine = $value.isMultiLine;
        return $bool(_isMultiLine);
      case 'isCaseSensitive':
        final _isCaseSensitive = $value.isCaseSensitive;
        return $bool(_isCaseSensitive);
      case 'isUnicode':
        final _isUnicode = $value.isUnicode;
        return $bool(_isUnicode);
      case 'isDotAll':
        final _isDotAll = $value.isDotAll;
        return $bool(_isDotAll);
      case 'allMatches':
        return $Closure(__allMatches.func, this);

      case 'matchAsPrefix':
        return $Closure(__matchAsPrefix.func, this);

      case 'firstMatch':
        return $Closure(__firstMatch.func, this);

      case 'hasMatch':
        return $Closure(__hasMatch.func, this);

      case 'stringMatch':
        return $Closure(__stringMatch.func, this);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __allMatches = $Function(_allMatches);
  static $Value? _allMatches(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $RegExp;
    final result = self.$value.allMatches(
      (r as $String).$value,
      (s is $Value ? s : null) == null ? 0 : (s as $int).$value,
    );
    return $Iterable.wrap((result).map((e) => $RegExpMatch.wrap(e)));
  }

  static const $Function __matchAsPrefix = $Function(_matchAsPrefix);
  static $Value? _matchAsPrefix(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $RegExp;
    final result = self.$value.matchAsPrefix(
      (r as $String).$value,
      (s is $Value ? s : null) == null ? 0 : (s as $int).$value,
    );
    return result == null ? const $null() : $Match.wrap(result);
  }

  static const $Function __firstMatch = $Function(_firstMatch);
  static $Value? _firstMatch(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $RegExp;
    final result = self.$value.firstMatch((r as $String).$value);
    return result == null ? const $null() : $RegExpMatch.wrap(result);
  }

  static const $Function __hasMatch = $Function(_hasMatch);
  static $Value? _hasMatch(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $RegExp;
    final result = self.$value.hasMatch((r as $String).$value);
    return $bool(result);
  }

  static const $Function __stringMatch = $Function(_stringMatch);
  static $Value? _stringMatch(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $RegExp;
    final result = self.$value.stringMatch((r as $String).$value);
    return result == null ? const $null() : $String(result);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}

/// dart_eval wrapper binding for [RegExpMatch]
class $RegExpMatch implements $Instance {
  /// Configure this class for use in a [Runtime]
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {}

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$RegExpMatch]
  static const $spec = BridgeTypeSpec('dart:core', 'RegExpMatch');

  /// Compile-time type declaration of [$RegExpMatch]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$RegExpMatch]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,
      isAbstract: true,

      $implements: [BridgeTypeRef(CoreTypes.match, [])],
    ),
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

      'namedGroup': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.string, []),
            nullable: true,
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'name',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
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
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.regExp, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'groupNames': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.iterable, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
            ]),
          ),
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
  final RegExpMatch $value;

  @override
  RegExpMatch get $reified => $value;

  /// Wrap a [RegExpMatch] in a [$RegExpMatch]
  $RegExpMatch.wrap(this.$value) : _superclass = $Object($value);

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
        return $RegExp.wrap(_pattern);
      case 'groupNames':
        final _groupNames = $value.groupNames;
        return $Iterable.wrap((_groupNames).map((e) => $String(e)));
      case 'group':
        return $Closure(__group.func, this);

      case '[]':
        return $Closure(__operatorIndexGet.func, this);

      case 'groups':
        return $Closure(__groups.func, this);

      case 'namedGroup':
        return $Closure(__namedGroup.func, this);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __group = $Function(_group);
  static $Value? _group(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $RegExpMatch;
    final result = self.$value.group((r as $int).$value);
    return result == null ? const $null() : $String(result);
  }

  static const $Function __operatorIndexGet = $Function(_operatorIndexGet);
  static $Value? _operatorIndexGet(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $RegExpMatch;
    final result = self.$value[(r as $int).$value];
    return result == null ? const $null() : $String(result);
  }

  static const $Function __groups = $Function(_groups);
  static $Value? _groups(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $RegExpMatch;
    final result = self.$value.groups(
      ((r as $Value?)!.$reified as List).cast<int>(),
    );
    return $List.view(result, (e) => e == null ? const $null() : $String(e));
  }

  static const $Function __namedGroup = $Function(_namedGroup);
  static $Value? _namedGroup(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $RegExpMatch;
    final result = self.$value.namedGroup((r as $String).$value);
    return result == null ? const $null() : $String(result);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
