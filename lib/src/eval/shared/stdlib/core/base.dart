import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/runtime/exception.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/collection.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/object.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/pattern.dart';
import 'package:dart_eval/src/eval/utils/wrap_helper.dart';
import 'num.dart';

const $dynamicCls = BridgeClassDef(
  BridgeClassType(
    BridgeTypeRef(CoreTypes.dynamic),
    isAbstract: true,
    $extends: null,
  ),
  constructors: {},
  wrap: true,
  methods: {
    'toString': BridgeMethodDef(
      BridgeFunctionDef(
        returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
        params: [],
        namedParams: [],
      ),
    ),
  },
);

const $voidCls = BridgeClassDef(
  BridgeClassType(BridgeTypeRef(CoreTypes.voidType), isAbstract: true),
  constructors: {},
  wrap: true,
);

const $neverCls = BridgeClassDef(
  BridgeClassType(BridgeTypeRef(CoreTypes.never), isAbstract: true),
  constructors: {},
  wrap: true,
);

/// dart_eval [$Value] representation of [null]
class $null implements $Value {
  const $null();

  static const $declaration = BridgeClassDef(
    BridgeClassType(
      BridgeTypeRef(CoreTypes.nullType),
      $extends: BridgeTypeRef(CoreTypes.object),
      isAbstract: true,
    ),
    constructors: {},
    wrap: true,
  );

  @override
  Null get $value => null;

  @override
  Null get $reified => null;

  @override
  int $getRuntimeType(Runtime runtime) =>
      runtime.lookupType(CoreTypes.nullType);

  @override
  bool operator ==(Object other) => other is $null;

  @override
  int get hashCode => -12121212;
}

/// dart_eval [$Instance] representation of a [bool]
class $bool implements $Instance {
  /// Wrap a [bool] in a [$bool]. Only two instances exist.
  factory $bool(bool value) => value ? _true : _false;

  $bool._(this.$value) : _superclass = $Object($value);

  static final $bool _true = $bool._(true);
  static final $bool _false = $bool._(false);

  static const $declaration = BridgeClassDef(
    BridgeClassType(
      BridgeTypeRef(CoreTypes.bool),
      $extends: BridgeTypeRef(CoreTypes.object),
      isAbstract: true,
    ),
    constructors: {
      'fromEnvironment': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
          params: [
            BridgeParameter(
              'name',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
              false,
            ),
          ],
          namedParams: [
            BridgeParameter(
              'defaultValue',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
              true,
            ),
          ],
        ),
        isFactory: true,
      ),
    },
    methods: {
      'hasEnvironment': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
          params: [
            BridgeParameter(
              'name',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
              false,
            ),
          ],
        ),
        isStatic: true,
      ),
      'parse': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
          params: [
            BridgeParameter(
              'source',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
              false,
            ),
          ],
          namedParams: [
            BridgeParameter(
              'caseSensitive',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
              true,
            ),
          ],
        ),
        isStatic: true,
      ),
      'tryParse': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.bool),
            nullable: true,
          ),
          params: [
            BridgeParameter(
              'source',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
              false,
            ),
          ],
          namedParams: [
            BridgeParameter(
              'caseSensitive',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
              true,
            ),
          ],
        ),
        isStatic: true,
      ),
      '&&': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
              false,
            ),
          ],
        ),
      ),
      '||': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
              false,
            ),
          ],
        ),
      ),
      '&': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
              false,
            ),
          ],
        ),
      ),
      '|': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
              false,
            ),
          ],
        ),
      ),
      '^': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
              false,
            ),
          ],
        ),
      ),
      '!': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
          params: [],
        ),
      ),
    },
    wrap: true,
  );

  final $Instance _superclass;

  @override
  bool $value;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case '&&':
        return $Closure(__and.func, this);
      case '||':
        return $Closure(__or.func, this);
      case '&':
        return $Closure(__bitAnd.func, this);
      case '|':
        return $Closure(__bitOr.func, this);
      case '^':
        return $Closure(__bitXor.func, this);
      case '!':
        return $Closure(__not.func, this);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {}

  /// Wrapper for the [bool.fromEnvironment] constructor
  static $Value? $fromEnvironment(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    return $bool(
      bool.fromEnvironment(
        (r as $Value?)!.$value,
        defaultValue: (s as $Value?)?.$value ?? false,
      ),
    );
  }

  /// Wrapper for the [bool.hasEnvironment] static method
  static $Value? $hasEnvironment(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    return $bool(bool.hasEnvironment((r as $Value?)!.$value));
  }

  /// Wrapper for the [bool.parse] static method
  static $Value? $parse(Runtime runtime, Object? r, Object? s, Object? c) {
    return $bool(
      bool.parse(
        (r as $Value?)!.$value,
        caseSensitive: (s as $Value?)?.$value ?? true,
      ),
    );
  }

  /// Wrapper for the [bool.tryParse] static method
  static $Value? $tryParse(Runtime runtime, Object? r, Object? s, Object? c) {
    final result = bool.tryParse(
      (r as $Value?)!.$value,
      caseSensitive: (s as $Value?)?.$value ?? true,
    );
    return result == null ? const $null() : $bool(result);
  }

  static const $Function __and = $Function(_and);

  static $Value? _and(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final other = (r as $Value?);
    return $bool(target!.$value && other!.$value);
  }

  static const $Function __or = $Function(_or);

  static $Value? _or(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final other = (r as $Value?);
    return $bool(target!.$value || other!.$value);
  }

  static const $Function __bitAnd = $Function(_bitAnd);

  static $Value? _bitAnd(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final other = (r as $Value?);
    return $bool(target!.$value & other!.$value);
  }

  static const $Function __bitOr = $Function(_bitOr);

  static $Value? _bitOr(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final other = (r as $Value?);
    return $bool(target!.$value | other!.$value);
  }

  static const $Function __bitXor = $Function(_bitXor);

  static $Value? _bitXor(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final other = (r as $Value?);
    return $bool(target!.$value ^ other!.$value);
  }

  static const $Function __not = $Function(_not);

  static $Value? _not(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    return $bool(!target!.$value);
  }

  @override
  bool get $reified => $value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is $bool &&
          runtimeType == other.runtimeType &&
          $value == other.$value;

  @override
  int get hashCode => $value.hashCode;

  @override
  String toString() {
    return '\${${$value}}';
  }

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType(CoreTypes.bool);
}

/// dart_eval [$Instance] representation of a [String]
class $String implements $Instance {
  $String(this.$value) : _superclass = $Pattern.wrap($value);

  static const $declaration = BridgeClassDef(
    BridgeClassType(
      BridgeTypeRef(CoreTypes.string),
      $extends: BridgeTypeRef(CoreTypes.object),
      $implements: [BridgeTypeRef(CoreTypes.pattern)],
      isAbstract: true,
    ),
    constructors: {
      'fromCharCode': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
          params: [
            BridgeParameter(
              'charCode',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
              false,
            ),
          ],
        ),
        isFactory: true,
      ),
      'fromCharCodes': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
          params: [
            BridgeParameter(
              'charCodes',
              BridgeTypeAnnotation(
                BridgeTypeRef(BridgeTypeSpec('dart:core', 'Iterable')),
              ),
              false,
            ),
            BridgeParameter(
              'start',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
              true,
            ),
            BridgeParameter(
              'end',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
        isFactory: true,
      ),
      'fromEnvironment': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
          params: [
            BridgeParameter(
              'name',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
              false,
            ),
          ],
          namedParams: [
            BridgeParameter(
              'defaultValue',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
              true,
            ),
          ],
        ),
        isFactory: true,
      ),
    },
    methods: {
      '+': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
              false,
            ),
          ],
        ),
      ),
      'codeUnitAt': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
          params: [
            BridgeParameter(
              'index',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
              false,
            ),
          ],
        ),
      ),
      'compareTo': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
              false,
            ),
          ],
        ),
      ),
      'contains': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.pattern)),
              false,
            ),
            BridgeParameter(
              'startIndex',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
              true,
            ),
          ],
        ),
      ),
      'endsWith': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
              false,
            ),
          ],
        ),
      ),
      'indexOf': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
          params: [
            BridgeParameter(
              'pattern',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.pattern)),
              false,
            ),
            BridgeParameter(
              'start',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
              true,
            ),
          ],
        ),
      ),
      'lastIndexOf': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
          params: [
            BridgeParameter(
              'pattern',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.pattern)),
              false,
            ),
            BridgeParameter(
              'start',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
              true,
            ),
          ],
        ),
      ),
      'padLeft': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
          params: [
            BridgeParameter(
              'width',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
              false,
            ),
            BridgeParameter(
              'padding',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
              true,
            ),
          ],
        ),
      ),
      'padRight': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
          params: [
            BridgeParameter(
              'width',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
              false,
            ),
            BridgeParameter(
              'padding',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
              true,
            ),
          ],
        ),
      ),
      'replaceAll': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
          params: [
            BridgeParameter(
              'from',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.pattern)),
              false,
            ),
            BridgeParameter(
              'replace',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
              false,
            ),
          ],
        ),
      ),
      'replaceFirst': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
          params: [
            BridgeParameter(
              'from',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.pattern)),
              false,
            ),
            BridgeParameter(
              'to',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
              false,
            ),
            BridgeParameter(
              'startIndex',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
              true,
            ),
          ],
        ),
      ),
      'replaceRange': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
          params: [
            BridgeParameter(
              'start',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
              false,
            ),
            BridgeParameter(
              'end',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int),
                nullable: true,
              ),
              false,
            ),
            BridgeParameter(
              'replacement',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
              false,
            ),
          ],
        ),
      ),
      'startsWith': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
          params: [
            BridgeParameter(
              'pattern',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.pattern)),
              false,
            ),
            BridgeParameter(
              'index',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
              true,
            ),
          ],
        ),
      ),
      'substring': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
          params: [
            BridgeParameter(
              'start',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
              false,
            ),
            BridgeParameter(
              'end',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
      ),
      'toLowerCase': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
          params: [],
        ),
      ),
      'toUpperCase': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
          params: [],
        ),
      ),
      'trim': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
          params: [],
        ),
      ),
      'trimLeft': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
          params: [],
        ),
      ),
      'trimRight': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
          params: [],
        ),
      ),
      'split': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.list, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
            ]),
          ),
          params: [
            BridgeParameter(
              'pattern',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.pattern)),
              false,
            ),
          ],
          namedParams: [],
        ),
      ),
      '[]': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
          params: [
            BridgeParameter(
              'index',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
              false,
            ),
          ],
          namedParams: [],
        ),
      ),
    },
    getters: {
      'length': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
        ),
      ),
      'isEmpty': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
        ),
      ),
      'isNotEmpty': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
        ),
      ),
      'codeUnits': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.list, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
            ]),
          ),
        ),
      ),
      'runes': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.iterable, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
            ]),
          ),
        ),
      ),
    },
    wrap: true,
  );

  @override
  final String $value;

  final $Instance _superclass;

  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'String.fromCharCode',
      _fromCharCode,
    );
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'String.fromCharCodes',
      _fromCharCodes,
    );
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'String.fromEnvironment',
      _fromEnvironment,
    );
  }

  static $Value? _fromEnvironment(
    final Runtime runtime,
    final Object? r,
    final Object? s,
    final Object? c,
  ) {
    return $String(
      String.fromEnvironment(
        (r as $Value?)!.$value,
        defaultValue: (s as $Value?)?.$value ?? '',
      ),
    );
  }

  static $Value? _fromCharCode(
    final Runtime runtime,
    final Object? r,
    final Object? s,
    final Object? c,
  ) {
    return $String(String.fromCharCode((r as $Value?)?.$value));
  }

  static $Value? _fromCharCodes(
    final Runtime runtime,
    final Object? r,
    final Object? s,
    final Object? c,
  ) {
    final charCodes = ((r as $Value).$value as Iterable).map(
      (e) => (e is $Value ? e.$reified : e) as int,
    );
    int? end;
    try {
      end = (c as $Value?)?.$value as int?;
    } catch (_) {}
    return $String(
      String.fromCharCodes(charCodes, (s as $Value?)?.$value ?? 0, end),
    );
  }

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'length':
        return $int($value.length);
      case 'isEmpty':
        return $bool($value.isEmpty);
      case 'isNotEmpty':
        return $bool($value.isNotEmpty);
      case '+':
        return $Closure(__concat.func, this);
      case '[]':
        return $Closure(__index.func, this);
      case 'codeUnitAt':
        return $Closure(__codeUnitAt.func, this);
      case 'runes':
        return wrapList<int>($value.runes.toList(), (e) => $int(e));
      case 'codeUnits':
        return wrapList<int>($value.codeUnits, (e) => $int(e));
      case 'compareTo':
        return $Closure(__compareTo.func, this);
      case 'contains':
        return $Closure(__contains.func, this);
      case 'endsWith':
        return $Closure(__endsWith.func, this);
      case 'indexOf':
        return $Closure(__indexOf.func, this);
      case 'lastIndexOf':
        return $Closure(__lastIndexOf.func, this);
      case 'padLeft':
        return $Closure(__padLeft.func, this);
      case 'padRight':
        return $Closure(__padRight.func, this);
      case 'replaceAll':
        return $Closure(__replaceAll.func, this);
      case 'replaceFirst':
        return $Closure(__replaceFirst.func, this);
      case 'replaceRange':
        return $Closure(__replaceRange.func, this);
      case 'startsWith':
        return $Closure(__startsWith.func, this);
      case 'split':
        return $Closure(__split.func, this);
      case 'substring':
        return $Closure(__substring.func, this);
      case 'toLowerCase':
        return $Closure(__toLowerCase.func, this);
      case 'toUpperCase':
        return $Closure(__toUpperCase.func, this);
      case 'trim':
        return $Closure(__trim.func, this);
      case 'trimLeft':
        return $Closure(__trimLeft.func, this);
      case 'trimRight':
        return $Closure(__trimRight.func, this);
    }

    return _superclass.$getProperty(runtime, identifier);
  }

  @override
  String toString() {
    return '\$"${$value}"';
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    throw EvalUnknownPropertyException(identifier);
  }

  static const $Function __concat = $Function(_concat);

  static $Value? _concat(
    final Runtime runtime,
    final $Value? target,
    final Object? r,
    Object? s,
    Object? c,
  ) {
    target as $String;
    final other = (r as $Value?) as $String;
    return $String(target.$value + other.$value);
  }

  static const $Function __index = $Function(_index);

  static $Value? _index(
    final Runtime runtime,
    final $Value? target,
    final Object? r,
    Object? s,
    Object? c,
  ) {
    target as $String;
    final index = (r as $Value?) as $int;
    return $String(target.$value[index.$value]);
  }

  static const $Function __codeUnitAt = $Function(_codeUnitAt);

  static $Value? _codeUnitAt(
    final Runtime runtime,
    final $Value? target,
    final Object? r,
    Object? s,
    Object? c,
  ) {
    target as $String;
    final index = (r as $Value?) as $int;
    return $int(target.$value.codeUnitAt(index.$value));
  }

  static const $Function __compareTo = $Function(_compareTo);

  static $Value? _compareTo(
    final Runtime runtime,
    final $Value? target,
    final Object? r,
    Object? s,
    Object? c,
  ) {
    target as $String;
    final other = (r as $Value?) as $String;
    return $int(target.$value.compareTo(other.$value));
  }

  static const $Function __contains = $Function(_contains);

  static $Value? _contains(
    final Runtime runtime,
    final $Value? target,
    final Object? r,
    Object? s,
    Object? c,
  ) {
    target as $String;
    final other = (r as $Value?) as $String;
    return $bool(target.$value.contains(other.$value));
  }

  static const $Function __endsWith = $Function(_endsWith);

  static $Value? _endsWith(
    final Runtime runtime,
    final $Value? target,
    final Object? r,
    Object? s,
    Object? c,
  ) {
    target as $String;
    final other = (r as $Value?) as $String;
    return $bool(target.$value.endsWith(other.$value));
  }

  static const $Function __indexOf = $Function(_indexOf);

  static $Value? _indexOf(
    final Runtime runtime,
    final $Value? target,
    final Object? r,
    Object? s,
    Object? c,
  ) {
    target as $String;
    final other = (r as $Value?)!;
    final start =
        ((c is int ? c : 2 + (c as List).length) > 1) && (s as $Value?) is $int
        ? s as $int
        : null;
    if (start != null) {
      return $int(target.$value.indexOf(other.$value, start.$value));
    } else {
      return $int(target.$value.indexOf(other.$value));
    }
  }

  static const $Function __lastIndexOf = $Function(_lastIndexOf);

  static $Value? _lastIndexOf(
    final Runtime runtime,
    final $Value? target,
    final Object? r,
    Object? s,
    Object? c,
  ) {
    target as $String;
    final other = (r as $Value?)!;
    final start =
        ((c is int ? c : 2 + (c as List).length) > 1) && (s as $Value?) is $int
        ? s as $int
        : null;
    if (start != null) {
      return $int(target.$value.lastIndexOf(other.$value, start.$value));
    } else {
      return $int(target.$value.lastIndexOf(other.$value));
    }
  }

  static const $Function __padLeft = $Function(_padLeft);

  static $Value? _padLeft(
    final Runtime runtime,
    final $Value? target,
    final Object? r,
    Object? s,
    Object? c,
  ) {
    target as $String;
    final width = (r as $Value?) as $int;
    final padding =
        ((c is int ? c : 2 + (c as List).length) > 1) &&
            (s as $Value?) is $String
        ? s as $String
        : null;
    if (padding != null) {
      return $String(target.$value.padLeft(width.$value, padding.$value));
    } else {
      return $String(target.$value.padLeft(width.$value));
    }
  }

  static const $Function __padRight = $Function(_padRight);

  static $Value? _padRight(
    final Runtime runtime,
    final $Value? target,
    final Object? r,
    Object? s,
    Object? c,
  ) {
    target as $String;
    final width = (r as $Value?) as $int;
    final padding =
        ((c is int ? c : 2 + (c as List).length) > 1) &&
            (s as $Value?) is $String
        ? s as $String
        : null;
    if (padding != null) {
      return $String(target.$value.padRight(width.$value, padding.$value));
    } else {
      return $String(target.$value.padRight(width.$value));
    }
  }

  static const $Function __replaceAll = $Function(_replaceAll);

  static $Value? _replaceAll(
    final Runtime runtime,
    final $Value? target,
    final Object? r,
    Object? s,
    Object? c,
  ) {
    target as $String;
    final from = (r as $Value?)!.$value;
    final replace = (s as $Value?)!.$value;
    return $String(target.$value.replaceAll(from, replace));
  }

  static const $Function __replaceFirst = $Function(_replaceFirst);

  static $Value? _replaceFirst(
    final Runtime runtime,
    final $Value? target,
    final Object? r,
    Object? s,
    Object? c,
  ) {
    target as $String;
    final from = (r as $Value?)!.$value;
    final to = (s as $Value?)!.$value;
    final startIndex =
        ((c is int ? c : 2 + (c as List).length) > 2) &&
            ((c as List<Object?>)[0] as $Value?) is $int
        ? (c[0] as $Value?) as $int
        : null;
    if (startIndex != null) {
      return $String(target.$value.replaceFirst(from, to, startIndex.$value));
    } else {
      return $String(target.$value.replaceFirst(from, to));
    }
  }

  static const $Function __replaceRange = $Function(_replaceRange);

  static $Value? _replaceRange(
    final Runtime runtime,
    final $Value? target,
    final Object? r,
    Object? s,
    Object? c,
  ) {
    target as $String;
    final start = (r as $Value?) as $int;
    final end = (s as $Value?) is $int ? s as $int : $null();
    final replacement = ((c as List<Object?>)[0] as $Value?) as $String;
    return $String(
      target.$value.replaceRange(start.$value, end.$value, replacement.$value),
    );
  }

  static const $Function __startsWith = $Function(_startsWith);

  static $Value? _startsWith(
    final Runtime runtime,
    final $Value? target,
    final Object? r,
    Object? s,
    Object? c,
  ) {
    target as $String;
    final pattern = (r as $Value?) as $String;
    final index =
        ((c is int ? c : 2 + (c as List).length) > 1) && (s as $Value?) is $int
        ? s as $int
        : null;
    if (index != null) {
      return $bool(target.$value.startsWith(pattern.$value, index.$value));
    } else {
      return $bool(target.$value.startsWith(pattern.$value));
    }
  }

  static const $Function __split = $Function(_split);

  static $Value? _split(
    final Runtime runtime,
    final $Value? target,
    final Object? r,
    Object? s,
    Object? c,
  ) {
    target as $String;
    final pattern = (r as $Value?) as $String;
    return $List.wrap(
      target.$value.split(pattern.$value).map((e) => $String(e)).toList(),
    );
  }

  static const $Function __substring = $Function(_substring);

  static $Value? _substring(
    final Runtime runtime,
    final $Value? target,
    final Object? r,
    Object? s,
    Object? c,
  ) {
    target as $String;
    final start = (r as $Value?) as $int;
    final end =
        ((c is int ? c : 2 + (c as List).length) > 1) && (s as $Value?) is $int
        ? s as $int
        : null;
    return $String(target.$value.substring(start.$value, end?.$value));
  }

  static const $Function __toLowerCase = $Function(_toLowerCase);

  static $Value? _toLowerCase(
    final Runtime runtime,
    final $Value? target,
    final Object? r,
    Object? s,
    Object? c,
  ) {
    return $String((target!.$value as String).toLowerCase());
  }

  static const $Function __toUpperCase = $Function(_toUpperCase);

  static $Value? _toUpperCase(
    final Runtime runtime,
    final $Value? target,
    final Object? r,
    Object? s,
    Object? c,
  ) {
    return $String((target!.$value as String).toUpperCase());
  }

  static const $Function __trim = $Function(_trim);

  static $Value? _trim(
    final Runtime runtime,
    final $Value? target,
    final Object? r,
    Object? s,
    Object? c,
  ) {
    return $String((target!.$value as String).trim());
  }

  static const $Function __trimLeft = $Function(_trimLeft);

  static $Value? _trimLeft(
    final Runtime runtime,
    final $Value? target,
    final Object? r,
    Object? s,
    Object? c,
  ) {
    return $String((target!.$value as String).trimLeft());
  }

  static const $Function __trimRight = $Function(_trimRight);

  static $Value? _trimRight(
    final Runtime runtime,
    final $Value? target,
    final Object? r,
    Object? s,
    Object? c,
  ) {
    return $String((target!.$value as String).trimRight());
  }

  @override
  String get $reified => $value;

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType(CoreTypes.string);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is $String &&
          runtimeType == other.runtimeType &&
          $value == other.$value;

  @override
  int get hashCode => $value.hashCode;
}
