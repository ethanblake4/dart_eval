import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';

/// dart_eval wrapper for [num]
class $num<T extends num> implements $Instance {
  /// Wrap a [num] in a [$num].
  $num(this.$value) : _superclass = $Object($value);

  static const $declaration = BridgeClassDef(
    BridgeClassType(BridgeTypeRef(CoreTypes.num), isAbstract: true),
    constructors: {},
    methods: {
      // Other num methods are defined in builtins.dart
      // since they have special requirements (return types dependent on
      // argument types, etc.)
      'parse': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.num)),
          params: [
            BridgeParameter(
              'source',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
              false,
            ),
            BridgeParameter(
              'onError',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.function),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
        isStatic: true,
      ),
      'tryParse': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.num),
            nullable: true,
          ),
          params: [
            BridgeParameter(
              'source',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
              false,
            ),
          ],
        ),
        isStatic: true,
      ),

      'toInt': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
          params: [],
        ),
        isStatic: false,
      ),
      'toDouble': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.double)),
          params: [],
        ),
        isStatic: false,
      ),
      'ceil': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
          params: [],
        ),
        isStatic: false,
      ),
      'abs': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.num)),
          params: [],
        ),
        isStatic: false,
      ),
      'floor': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
          params: [],
        ),
        isStatic: false,
      ),
      'round': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
          params: [],
        ),
        isStatic: false,
      ),
      'truncate': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
          params: [],
        ),
        isStatic: false,
      ),
      'clamp': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.num)),
          params: [
            BridgeParameter(
              'lower',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.num)),
              false,
            ),
            BridgeParameter(
              'upper',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.num)),
              false,
            ),
          ],
        ),
        isStatic: false,
      ),
      'remainder': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.num)),
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.num)),
              false,
            ),
          ],
        ),
        isStatic: false,
      ),
      'toStringAsFixed': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
          params: [
            BridgeParameter(
              'fractionDigits',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
              false,
            ),
          ],
        ),
        isStatic: false,
      ),
      'toStringAsExponential': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
          params: [
            BridgeParameter(
              'fractionDigits',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
        isStatic: false,
      ),
      'toStringAsPrecision': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
          params: [
            BridgeParameter(
              'precision',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
              false,
            ),
          ],
        ),
        isStatic: false,
      ),
      'ceilToDouble': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.double)),
          params: [],
        ),
        isStatic: false,
      ),
      'floorToDouble': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.double)),
          params: [],
        ),
        isStatic: false,
      ),
      'roundToDouble': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.double)),
          params: [],
        ),
        isStatic: false,
      ),
      'truncateToDouble': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.double)),
          params: [],
        ),
        isStatic: false,
      ),
    },
    getters: {},
    setters: {},
    fields: {},
    wrap: true,
  );

  /// Wrapper of [num.parse]
  static $num? $parse(Runtime runtime, $Value? target, List<$Value?> args) {
    final source = args[0]!.$value as String;
    final onError = args[1]?.$value as EvalCallable?;
    final num result;
    try {
      result = num.parse(
        source,
        // ignore: deprecated_member_use
        onError == null
            ? null
            : (source) =>
                  onError.call(runtime, null, [$String(source)])?.$value,
      );
    } on FormatException catch (e) {
      runtime.$throw($FormatException.wrap(e));
    }
    if (result is int) {
      return $int(result);
    }
    if (result is double) {
      return $double(result);
    }
    throw UnimplementedError();
  }

  /// Wrapper of [num.tryParse]
  static $Value $tryParse(Runtime runtime, $Value? target, List<$Value?> args) {
    final source = args[0]!.$value as String;
    final result = num.tryParse(source);
    if (result == null) {
      return $null();
    }
    if (result is int) {
      return $int(result);
    }
    if (result is double) {
      return $double(result);
    }
    throw UnimplementedError();
  }

  @override
  T $value;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case '+':
        return __plus;
      case '-':
        return __minus;
      case '*':
        return __mul;
      case '/':
        return __div;

      case '%':
        return __mod;
      case '<':
        return __lt;
      case '>':
        return __gt;
      case '<=':
        return __lteq;
      case '>=':
        return __gteq;
      case 'compareTo':
        return __compareTo;
      case 'toInt':
        return __toInt;
      case 'toDouble':
        return __toDouble;
      case 'ceil':
        return __ceil;
      case 'abs':
        return __abs;
      case 'floor':
        return __floor;
      case 'round':
        return __round;
      case 'truncate':
        return __truncate;
      case 'clamp':
        return __clamp;
      case 'remainder':
        return __remainder;
      case 'toStringAsFixed':
        return __toStringAsFixed;
      case 'toStringAsExponential':
        return __toStringAsExponential;
      case 'toStringAsPrecision':
        return __toStringAsPrecision;
      case 'ceilToDouble':
        return __ceilToDouble;
      case 'floorToDouble':
        return __floorToDouble;
      case 'roundToDouble':
        return __roundToDouble;
      case 'truncateToDouble':
        return __truncateToDouble;
      case 'isNaN':
        return $bool($value.isNaN);
      case 'isInfinite':
        return $bool($value.isInfinite);
      case 'isNegative':
        return $bool($value.isNegative);
      case 'isFinite':
        return $bool($value.isFinite);
      case 'sign':
        return $num($value.sign);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }

  final $Instance _superclass;

  @override
  T get $reified => $value;

  static const $Function __plus = $Function(_plus);
  static $Value? _plus(Runtime runtime, $Value? target, List<$Value?> args) {
    final other = args[0];
    final evalResult = target!.$value + other!.$value;

    if (evalResult is int) {
      return $int(evalResult);
    }

    if (evalResult is double) {
      return $double(evalResult);
    }

    throw UnimplementedError();
  }

  static const $Function __minus = $Function(_minus);
  static $Value? _minus(Runtime runtime, $Value? target, List<$Value?> args) {
    if (args.isEmpty) {
      final value = -target!.$value;
      return value is int ? $int(value) : $double(value);
    }
    final other = args[0];
    final evalResult = target!.$value - other!.$value;

    if (evalResult is int) {
      return $int(evalResult);
    }

    if (evalResult is double) {
      return $double(evalResult);
    }

    throw UnimplementedError();
  }

  static const $Function __mul = $Function(_mul);
  static $Value? _mul(Runtime runtime, $Value? target, List<$Value?> args) {
    final other = args[0];
    final evalResult = target!.$value * other!.$value;

    if (evalResult is int) {
      return $int(evalResult);
    }

    if (evalResult is double) {
      return $double(evalResult);
    }

    throw UnimplementedError();
  }

  static const $Function __div = $Function(_div);
  static $Value? _div(Runtime runtime, $Value? target, List<$Value?> args) {
    final other = args[0];
    final evalResult = target!.$value / other!.$value;

    if (evalResult is double) {
      return $double(evalResult);
    }

    throw UnimplementedError();
  }

  static const $Function __mod = $Function(_mod);

  static $Value? _mod(Runtime runtime, $Value? target, List<$Value?> args) {
    final other = args[0];
    final evalResult = target!.$value % other!.$value;

    if (evalResult is int) {
      return $int(evalResult);
    }

    if (evalResult is double) {
      return $double(evalResult);
    }

    throw UnimplementedError();
  }

  static const $Function __lt = $Function(_lt);
  static $Value? _lt(Runtime runtime, $Value? target, List<$Value?> args) {
    final other = args[0];
    final evalResult = target!.$value < other!.$value;

    if (evalResult is bool) {
      return $bool(evalResult);
    }

    throw UnimplementedError();
  }

  static const $Function __gt = $Function(_gt);
  static $Value? _gt(Runtime runtime, $Value? target, List<$Value?> args) {
    final other = args[0];
    final evalResult = target!.$value > other!.$value;

    if (evalResult is bool) {
      return $bool(evalResult);
    }

    throw UnimplementedError();
  }

  static const $Function __lteq = $Function(_lteq);
  static $Value? _lteq(Runtime runtime, $Value? target, List<$Value?> args) {
    final other = args[0];
    final evalResult = target!.$value <= other!.$value;

    if (evalResult is bool) {
      return $bool(evalResult);
    }

    throw UnimplementedError();
  }

  static const $Function __gteq = $Function(_gteq);
  static $Value? _gteq(Runtime runtime, $Value? target, List<$Value?> args) {
    final other = args[0];
    final evalResult = target!.$value >= other!.$value;

    if (evalResult is bool) {
      return $bool(evalResult);
    }

    throw UnimplementedError();
  }

  static const $Function __toInt = $Function(_toInt);
  static $Value? _toInt(Runtime runtime, $Value? target, List<$Value?> args) {
    final evalResult = (target!.$value as num).toInt();
    return $int(evalResult);
  }

  static const $Function __toDouble = $Function(_toDouble);
  static $Value? _toDouble(
    Runtime runtime,
    $Value? target,
    List<$Value?> args,
  ) {
    final evalResult = (target!.$value as num).toDouble();
    return $double(evalResult);
  }

  static const $Function __abs = $Function(_abs);
  static $Value? _abs(Runtime runtime, $Value? target, List<$Value?> args) {
    final evalResult = (target!.$value as num).abs();
    return $num(evalResult);
  }

  static const $Function __ceil = $Function(_ceil);
  static $Value? _ceil(Runtime runtime, $Value? target, List<$Value?> args) {
    final evalResult = (target!.$value as num).ceil();
    return $int(evalResult);
  }

  static const $Function __compareTo = $Function(_compareTo);
  static $Value? _compareTo(
    Runtime runtime,
    $Value? target,
    List<$Value?> args,
  ) {
    final other = args[0];
    final evalResult = target!.$value.compareTo(other!.$value);

    return $int(evalResult);
  }

  static const $Function __floor = $Function(_floor);
  static $Value? _floor(Runtime runtime, $Value? target, List<$Value?> args) {
    final evalResult = (target!.$value as num).floor();
    return $int(evalResult);
  }

  static const $Function __round = $Function(_round);
  static $Value? _round(Runtime runtime, $Value? target, List<$Value?> args) {
    final evalResult = (target!.$value as num).round();
    return $int(evalResult);
  }

  static const $Function __truncate = $Function(_truncate);
  static $Value? _truncate(
    Runtime runtime,
    $Value? target,
    List<$Value?> args,
  ) {
    final evalResult = (target!.$value as num).truncate();
    return $int(evalResult);
  }

  static const $Function __clamp = $Function(_clamp);
  static $Value? _clamp(Runtime runtime, $Value? target, List<$Value?> args) {
    final lower = args[0]!.$value as num;
    final upper = args[1]!.$value as num;
    final evalResult = (target!.$value as num).clamp(lower, upper);
    if (evalResult is int) {
      return $int(evalResult);
    }
    if (evalResult is double) {
      return $double(evalResult);
    }
    throw UnimplementedError();
  }

  static const $Function __remainder = $Function(_remainder);
  static $Value? _remainder(
    Runtime runtime,
    $Value? target,
    List<$Value?> args,
  ) {
    final other = args[0]!.$value as num;
    final evalResult = (target!.$value as num).remainder(other);
    if (evalResult is int) {
      return $int(evalResult);
    }
    if (evalResult is double) {
      return $double(evalResult);
    }
    throw UnimplementedError();
  }

  static const $Function __toStringAsFixed = $Function(_toStringAsFixed);
  static $Value? _toStringAsFixed(
    Runtime runtime,
    $Value? target,
    List<$Value?> args,
  ) {
    final fractionDigits = args[0]!.$value as int;
    final evalResult = (target!.$value as num).toStringAsFixed(fractionDigits);
    return $String(evalResult);
  }

  static const $Function __toStringAsExponential = $Function(
    _toStringAsExponential,
  );
  static $Value? _toStringAsExponential(
    Runtime runtime,
    $Value? target,
    List<$Value?> args,
  ) {
    final fractionDigits = args[0]?.$value as int?;
    final evalResult = (target!.$value as num).toStringAsExponential(
      fractionDigits,
    );
    return $String(evalResult);
  }

  static const $Function __toStringAsPrecision = $Function(
    _toStringAsPrecision,
  );
  static $Value? _toStringAsPrecision(
    Runtime runtime,
    $Value? target,
    List<$Value?> args,
  ) {
    final precision = args[0]!.$value as int;
    final evalResult = (target!.$value as num).toStringAsPrecision(precision);
    return $String(evalResult);
  }

  static const $Function __ceilToDouble = $Function(_ceilToDouble);
  static $Value? _ceilToDouble(
    Runtime runtime,
    $Value? target,
    List<$Value?> args,
  ) {
    final evalResult = (target!.$value as num).ceilToDouble();
    return $double(evalResult);
  }

  static const $Function __floorToDouble = $Function(_floorToDouble);
  static $Value? _floorToDouble(
    Runtime runtime,
    $Value? target,
    List<$Value?> args,
  ) {
    final evalResult = (target!.$value as num).floorToDouble();
    return $double(evalResult);
  }

  static const $Function __roundToDouble = $Function(_roundToDouble);
  static $Value? _roundToDouble(
    Runtime runtime,
    $Value? target,
    List<$Value?> args,
  ) {
    final evalResult = (target!.$value as num).roundToDouble();
    return $double(evalResult);
  }

  static const $Function __truncateToDouble = $Function(_truncateToDouble);
  static $Value? _truncateToDouble(
    Runtime runtime,
    $Value? target,
    List<$Value?> args,
  ) {
    final evalResult = (target!.$value as num).truncateToDouble();
    return $double(evalResult);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is $num &&
          runtimeType == other.runtimeType &&
          $value == other.$value;

  @override
  int get hashCode => $value.hashCode;

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType(CoreTypes.num);
}

/// dart_eval wrapper for [int]
class $int extends $num<int> {
  /// Wrap an [int] in a [$int].
  $int(super.$value);

  static const $declaration = BridgeClassDef(
    BridgeClassType(
      BridgeTypeRef(CoreTypes.int),
      $extends: BridgeTypeRef(CoreTypes.num),
      isAbstract: true,
    ),
    constructors: {},
    methods: {
      'parse': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
          params: [
            BridgeParameter(
              'source',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
              false,
            ),
          ],
          namedParams: [
            BridgeParameter(
              'radix',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
              true,
            ),
          ],
        ),
        isStatic: true,
      ),
      'tryParse': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.int),
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
              'radix',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
              true,
            ),
          ],
        ),
        isStatic: true,
      ),
      'toRadixString': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
          params: [
            BridgeParameter(
              'radix',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
              false,
            ),
          ],
          namedParams: [],
        ),
      ),
      'abs': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
          params: [],
        ),
        isStatic: false,
      ),
      'gcd': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
              false,
            ),
          ],
        ),
        isStatic: false,
      ),
      'modPow': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
          params: [
            BridgeParameter(
              'exponent',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
              false,
            ),
            BridgeParameter(
              'modulus',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
              false,
            ),
          ],
        ),
        isStatic: false,
      ),
      'modInverse': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
          params: [
            BridgeParameter(
              'modulus',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
              false,
            ),
          ],
        ),
        isStatic: false,
      ),
      'toSigned': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
          params: [
            BridgeParameter(
              'width',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
              false,
            ),
          ],
        ),
        isStatic: false,
      ),
      'toUnsigned': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
          params: [
            BridgeParameter(
              'width',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
              false,
            ),
          ],
        ),
        isStatic: false,
      ),
    },
    getters: {},
    setters: {},
    fields: {},
    wrap: true,
  );

  static $int? $parse(Runtime runtime, $Value? target, List<$Value?> args) {
    final source = args[0]!.$value as String;
    final radix = args[1]?.$value as int?;
    final int result;

    try {
      result = int.parse(source, radix: radix);
    } on FormatException catch (e) {
      runtime.$throw($FormatException.wrap(e));
    }

    return $int(result);
  }

  static $Value $tryParse(Runtime runtime, $Value? target, List<$Value?> args) {
    final source = args[0]!.$value as String;
    final radix = args[1]?.$value as int?;

    final result = int.tryParse(source, radix: radix);

    if (result == null) {
      return $null();
    }

    return $int(result);
  }

  @override
  int get $reified => $value;

  @override
  String toString() {
    return $value.toString();
  }

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType(CoreTypes.int);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'toRadixString':
        return __toRadixString;
      case '|':
        return __bitwiseOr;
      case '&':
        return __bitwiseAnd;
      case '<<':
        return __shiftLeft;
      case '>>':
        return __shiftRight;
      case '^':
        return __bitwiseXor;
      case '~/':
        return __truncatediv;
      case 'abs':
        return __absInt;
      case 'gcd':
        return __gcd;
      case 'modPow':
        return __modPow;
      case 'modInverse':
        return __modInverse;
      case 'toSigned':
        return __toSigned;
      case 'toUnsigned':
        return __toUnsigned;
      case 'isEven':
        return $bool($value.isEven);
      case 'isOdd':
        return $bool($value.isOdd);
      case 'bitLength':
        return $int($value.bitLength);
      case 'sign':
        return $int($value.sign);
    }
    return super.$getProperty(runtime, identifier);
  }

  static const $Function __toRadixString = $Function(_toRadixString);

  static $Value? _toRadixString(
    Runtime runtime,
    $Value? target,
    List<$Value?> args,
  ) {
    final radix = args[0];
    final evalResult = (target!.$value as int).toRadixString(radix!.$value);

    return $String(evalResult);
  }

  static const $Function __bitwiseOr = $Function(_bitwiseOr);
  static $Value? _bitwiseOr(
    Runtime runtime,
    $Value? target,
    List<$Value?> args,
  ) {
    final other = args[0];
    final evalResult = target!.$value | other!.$value;

    if (evalResult is int) {
      return $int(evalResult);
    }

    throw UnimplementedError();
  }

  static const $Function __bitwiseAnd = $Function(_bitwiseAnd);
  static $Value? _bitwiseAnd(
    Runtime runtime,
    $Value? target,
    List<$Value?> args,
  ) {
    final other = args[0];
    final evalResult = target!.$value & other!.$value;

    if (evalResult is int) {
      return $int(evalResult);
    }

    throw UnimplementedError();
  }

  static const $Function __shiftLeft = $Function(_shiftLeft);
  static $Value? _shiftLeft(
    Runtime runtime,
    $Value? target,
    List<$Value?> args,
  ) {
    final other = args[0];
    final evalResult = target!.$value << other!.$value;

    if (evalResult is int) {
      return $int(evalResult);
    }

    throw UnimplementedError();
  }

  static const $Function __shiftRight = $Function(_shiftRight);
  static $Value? _shiftRight(
    Runtime runtime,
    $Value? target,
    List<$Value?> args,
  ) {
    final other = args[0];
    final evalResult = target!.$value >> other!.$value;

    if (evalResult is int) {
      return $int(evalResult);
    }

    throw UnimplementedError();
  }

  static const $Function __bitwiseXor = $Function(_bitwiseXor);

  static $Value? _bitwiseXor(
    Runtime runtime,
    $Value? target,
    List<$Value?> args,
  ) {
    final other = args[0];
    final evalResult = target!.$value ^ other!.$value;

    if (evalResult is int) {
      return $int(evalResult);
    }

    throw UnimplementedError();
  }

  static const __truncatediv = $Function(_truncatediv);
  static $Value? _truncatediv(
    Runtime runtime,
    $Value? target,
    List<$Value?> args,
  ) {
    final other = args[0];
    final evalResult = target!.$value ~/ other!.$value;

    return $int(evalResult);
  }

  static const $Function __absInt = $Function(_absInt);
  static $Value? _absInt(Runtime runtime, $Value? target, List<$Value?> args) {
    final evalResult = (target!.$value as int).abs();
    return $int(evalResult);
  }

  static const $Function __gcd = $Function(_gcd);
  static $Value? _gcd(Runtime runtime, $Value? target, List<$Value?> args) {
    final other = args[0]!.$value as int;
    final evalResult = (target!.$value as int).gcd(other);
    return $int(evalResult);
  }

  static const $Function __modPow = $Function(_modPow);
  static $Value? _modPow(Runtime runtime, $Value? target, List<$Value?> args) {
    final exponent = args[0]!.$value as int;
    final modulus = args[1]!.$value as int;
    final evalResult = (target!.$value as int).modPow(exponent, modulus);
    return $int(evalResult);
  }

  static const $Function __modInverse = $Function(_modInverse);
  static $Value? _modInverse(
    Runtime runtime,
    $Value? target,
    List<$Value?> args,
  ) {
    final modulus = args[0]!.$value as int;
    final evalResult = (target!.$value as int).modInverse(modulus);
    return $int(evalResult);
  }

  static const $Function __toSigned = $Function(_toSigned);
  static $Value? _toSigned(
    Runtime runtime,
    $Value? target,
    List<$Value?> args,
  ) {
    final width = args[0]!.$value as int;
    final evalResult = (target!.$value as int).toSigned(width);
    return $int(evalResult);
  }

  static const $Function __toUnsigned = $Function(_toUnsigned);
  static $Value? _toUnsigned(
    Runtime runtime,
    $Value? target,
    List<$Value?> args,
  ) {
    final width = args[0]!.$value as int;
    final evalResult = (target!.$value as int).toUnsigned(width);
    return $int(evalResult);
  }
}

/// dart_eval wrapper for [double]
class $double extends $num<double> {
  /// Wrap a [double] in a [$double].
  $double(super.$value);

  static const $declaration = BridgeClassDef(
    BridgeClassType(
      BridgeTypeRef(CoreTypes.double),
      $extends: BridgeTypeRef(CoreTypes.num),
      isAbstract: true,
    ),
    constructors: {},
    methods: {
      'parse': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.double)),
          params: [
            BridgeParameter(
              'source',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
              false,
            ),
            BridgeParameter(
              'onError',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.function),
                nullable: true,
              ),
              true,
            ),
          ],
          namedParams: [],
        ),
        isStatic: true,
      ),
      'tryParse': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.double),
            nullable: true,
          ),
          params: [
            BridgeParameter(
              'source',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
              false,
            ),
          ],
          namedParams: [],
        ),
        isStatic: true,
      ),
    },
    getters: {
      'nan': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.double)),
          params: [],
        ),
        isStatic: true,
      ),
      'infinity': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.double)),
          params: [],
        ),
        isStatic: true,
      ),
      'negativeInfinity': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.double)),
          params: [],
        ),
        isStatic: true,
      ),
    },
    setters: {},
    fields: {},
    wrap: true,
  );

  static $Value? $nan(Runtime runtime, $Value? target, List<$Value?> args) {
    return $double(double.nan);
  }

  static $Value? $infinity(
    Runtime runtime,
    $Value? target,
    List<$Value?> args,
  ) {
    return $double(double.infinity);
  }

  static $Value? $negativeInfinity(
    Runtime runtime,
    $Value? target,
    List<$Value?> args,
  ) {
    return $double(double.negativeInfinity);
  }

  static $double? $parse(Runtime runtime, $Value? target, List<$Value?> args) {
    final source = args[0]!.$value as String;
    final onError = args[1] as EvalCallable?;
    final double result;
    try {
      result = double.parse(source);
    } on FormatException catch (e) {
      if (onError != null) {
        final errorResult = onError.call(runtime, null, [$String(source)]);
        if (errorResult != null) {
          return errorResult as $double?;
        }
      }
      runtime.$throw($FormatException.wrap(e));
    }
    return $double(result);
  }

  static $Value $tryParse(Runtime runtime, $Value? target, List<$Value?> args) {
    final source = args[0]!.$value as String;
    final result = double.tryParse(source);
    if (result == null) {
      return $null();
    }
    return $double(result);
  }

  @override
  double get $reified => $value;

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType(CoreTypes.double);
}
