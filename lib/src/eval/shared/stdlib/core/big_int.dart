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
        $BigInt,
        $DateTime,
        $Iterator,
        $Comparable,
        $Sink,
        $StackTrace,
        $StringBuffer,
        $Runes,
        $RuneIterator,
        $Expando,
        $Symbol,
        $MapEntry,
        $Stopwatch,
        $pragma,
        $Error,
        $StackOverflowError,
        $OutOfMemoryError,
        $TypeError,
        $NoSuchMethodError,
        $RangeError,
        $AssertionError,
        $ArgumentError,
        $StateError,
        $UnsupportedError,
        $UnimplementedError,
        $ConcurrentModificationError,
        $Exception,
        $FormatException,
        $Uri,
        $Pattern,
        $Match,
        $RegExp,
        $RegExpMatch,
        $StringSink,
        $Enum;

/// dart_eval wrapper binding for [BigInt]
class $BigInt implements $Instance {
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'BigInt.from',
      $BigInt.$from,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'BigInt.parse',
      $BigInt.$parse,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'BigInt.tryParse',
      $BigInt.$tryParse,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'BigInt.zero*g',
      $BigInt.$zero,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'BigInt.one*g',
      $BigInt.$one,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'BigInt.two*g',
      $BigInt.$two,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$BigInt]
  static const $spec = BridgeTypeSpec('dart:core', 'BigInt');

  /// Compile-time type declaration of [$BigInt]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$BigInt]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,
      isAbstract: true,

      $implements: [
        BridgeTypeRef(CoreTypes.comparable, [
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bigInt, [])),
        ]),
      ],
    ),
    constructors: {
      'from': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'value',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.num, [])),
              false,
            ),
          ],
        ),
        isFactory: true,
      ),
    },

    methods: {
      'compareTo': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bigInt, [])),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'parse': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bigInt, [])),
          namedParams: [
            BridgeParameter(
              'radix',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: true,
              ),
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

        isStatic: true,
      ),

      'tryParse': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.bigInt, []),
            nullable: true,
          ),
          namedParams: [
            BridgeParameter(
              'radix',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: true,
              ),
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

        isStatic: true,
      ),

      'abs': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bigInt, [])),
          namedParams: [],
          params: [],
        ),

        isAbstract: true,
      ),

      'unary-': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bigInt, [])),
          namedParams: [],
          params: [],
        ),

        isAbstract: true,
      ),

      '+': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bigInt, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bigInt, [])),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      '-': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bigInt, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bigInt, [])),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      '*': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bigInt, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bigInt, [])),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      '/': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.double, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bigInt, [])),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      '~/': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bigInt, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bigInt, [])),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      '%': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bigInt, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bigInt, [])),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'remainder': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bigInt, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bigInt, [])),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      '<<': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bigInt, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'shiftAmount',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      '>>': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bigInt, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'shiftAmount',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      '&': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bigInt, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bigInt, [])),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      '|': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bigInt, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bigInt, [])),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      '^': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bigInt, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bigInt, [])),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      '~': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bigInt, [])),
          namedParams: [],
          params: [],
        ),

        isAbstract: true,
      ),

      '<': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bigInt, [])),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      '<=': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bigInt, [])),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      '>': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bigInt, [])),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      '>=': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bigInt, [])),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'pow': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bigInt, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'exponent',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'modPow': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bigInt, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'exponent',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bigInt, [])),
              false,
            ),

            BridgeParameter(
              'modulus',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bigInt, [])),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'modInverse': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bigInt, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'modulus',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bigInt, [])),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'gcd': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bigInt, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bigInt, [])),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'toUnsigned': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bigInt, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'width',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'toSigned': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bigInt, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'width',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'toInt': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),

        isAbstract: true,
      ),

      'toDouble': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.double, [])),
          namedParams: [],
          params: [],
        ),

        isAbstract: true,
      ),

      'toRadixString': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'radix',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),
    },
    getters: {
      'zero': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bigInt, [])),
          namedParams: [],
          params: [],
        ),

        isStatic: true,
      ),

      'one': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bigInt, [])),
          namedParams: [],
          params: [],
        ),

        isStatic: true,
      ),

      'two': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bigInt, [])),
          namedParams: [],
          params: [],
        ),

        isStatic: true,
      ),

      'bitLength': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),

        isAbstract: true,
      ),

      'sign': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),

        isAbstract: true,
      ),

      'isEven': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [],
        ),

        isAbstract: true,
      ),

      'isOdd': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [],
        ),

        isAbstract: true,
      ),

      'isNegative': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [],
        ),

        isAbstract: true,
      ),

      'isValidInt': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [],
        ),

        isAbstract: true,
      ),
    },
    setters: {},
    fields: {},
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [BigInt.from] constructor
  static $Value? $from(Runtime runtime, Object? r, Object? s, Object? c) {
    return $BigInt.wrap(BigInt.from((r as $num).$value));
  }

  /// Wrapper for the [BigInt.parse] method
  static $Value? $parse(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = BigInt.parse(
      (r as $String).$value,
      radix: (s is $Value ? s : null)?.$value,
    );
    return $BigInt.wrap(value);
  }

  /// Wrapper for the [BigInt.tryParse] method
  static $Value? $tryParse(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = BigInt.tryParse(
      (r as $String).$value,
      radix: (s is $Value ? s : null)?.$value,
    );
    return value == null ? const $null() : $BigInt.wrap(value);
  }

  /// Wrapper for the [BigInt.zero] getter
  static $Value? $zero(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = BigInt.zero;
    return $BigInt.wrap(value);
  }

  /// Wrapper for the [BigInt.one] getter
  static $Value? $one(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = BigInt.one;
    return $BigInt.wrap(value);
  }

  /// Wrapper for the [BigInt.two] getter
  static $Value? $two(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = BigInt.two;
    return $BigInt.wrap(value);
  }

  final $Instance _superclass;

  @override
  final BigInt $value;

  @override
  BigInt get $reified => $value;

  /// Wrap a [BigInt] in a [$BigInt]
  $BigInt.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'bitLength':
        final _bitLength = $value.bitLength;
        return $int(_bitLength);
      case 'sign':
        final _sign = $value.sign;
        return $int(_sign);
      case 'isEven':
        final _isEven = $value.isEven;
        return $bool(_isEven);
      case 'isOdd':
        final _isOdd = $value.isOdd;
        return $bool(_isOdd);
      case 'isNegative':
        final _isNegative = $value.isNegative;
        return $bool(_isNegative);
      case 'isValidInt':
        final _isValidInt = $value.isValidInt;
        return $bool(_isValidInt);
      case 'compareTo':
        return $Closure(__compareTo.func, this);

      case 'abs':
        return $Closure(__abs.func, this);

      case 'unary-':
        return $Closure(__operatorMinusUnary.func, this);

      case '+':
        return $Closure(__operatorPlus.func, this);

      case '-':
        return $Closure(__operatorMinus.func, this);

      case '*':
        return $Closure(__operatorMul.func, this);

      case '/':
        return $Closure(__operatorDiv.func, this);

      case '~/':
        return $Closure(__operatorIntDiv.func, this);

      case '%':
        return $Closure(__operatorMod.func, this);

      case 'remainder':
        return $Closure(__remainder.func, this);

      case '<<':
        return $Closure(__operatorShl.func, this);

      case '>>':
        return $Closure(__operatorShr.func, this);

      case '&':
        return $Closure(__operatorBitAnd.func, this);

      case '|':
        return $Closure(__operatorBitOr.func, this);

      case '^':
        return $Closure(__operatorBitXor.func, this);

      case '~':
        return $Closure(__operatorBitNot.func, this);

      case '<':
        return $Closure(__operatorLt.func, this);

      case '<=':
        return $Closure(__operatorLte.func, this);

      case '>':
        return $Closure(__operatorGt.func, this);

      case '>=':
        return $Closure(__operatorGte.func, this);

      case 'pow':
        return $Closure(__pow.func, this);

      case 'modPow':
        return $Closure(__modPow.func, this);

      case 'modInverse':
        return $Closure(__modInverse.func, this);

      case 'gcd':
        return $Closure(__gcd.func, this);

      case 'toUnsigned':
        return $Closure(__toUnsigned.func, this);

      case 'toSigned':
        return $Closure(__toSigned.func, this);

      case 'toInt':
        return $Closure(__toInt.func, this);

      case 'toDouble':
        return $Closure(__toDouble.func, this);

      case 'toRadixString':
        return $Closure(__toRadixString.func, this);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __compareTo = $Function(_compareTo);
  static $Value? _compareTo(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $BigInt;
    final result = self.$value.compareTo((r as $Value?)!.$value);
    return $int(result);
  }

  static const $Function __abs = $Function(_abs);
  static $Value? _abs(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $BigInt;
    final result = self.$value.abs();
    return $BigInt.wrap(result);
  }

  static const $Function __operatorMinusUnary = $Function(_operatorMinusUnary);
  static $Value? _operatorMinusUnary(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $BigInt;
    final result = -self.$value;
    return $BigInt.wrap(result);
  }

  static const $Function __operatorPlus = $Function(_operatorPlus);
  static $Value? _operatorPlus(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $BigInt;
    final result = (self.$value + (r as $Value?)!.$value);
    return $BigInt.wrap(result);
  }

  static const $Function __operatorMinus = $Function(_operatorMinus);
  static $Value? _operatorMinus(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $BigInt;
    final result = (self.$value - (r as $Value?)!.$value);
    return $BigInt.wrap(result);
  }

  static const $Function __operatorMul = $Function(_operatorMul);
  static $Value? _operatorMul(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $BigInt;
    final result = (self.$value * (r as $Value?)!.$value);
    return $BigInt.wrap(result);
  }

  static const $Function __operatorDiv = $Function(_operatorDiv);
  static $Value? _operatorDiv(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $BigInt;
    final result = (self.$value / (r as $Value?)!.$value);
    return $double(result);
  }

  static const $Function __operatorIntDiv = $Function(_operatorIntDiv);
  static $Value? _operatorIntDiv(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $BigInt;
    final result = (self.$value ~/ (r as $Value?)!.$value);
    return $BigInt.wrap(result);
  }

  static const $Function __operatorMod = $Function(_operatorMod);
  static $Value? _operatorMod(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $BigInt;
    final result = (self.$value % (r as $Value?)!.$value);
    return $BigInt.wrap(result);
  }

  static const $Function __remainder = $Function(_remainder);
  static $Value? _remainder(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $BigInt;
    final result = self.$value.remainder((r as $Value?)!.$value);
    return $BigInt.wrap(result);
  }

  static const $Function __operatorShl = $Function(_operatorShl);
  static $Value? _operatorShl(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $BigInt;
    final result = (self.$value << (r as $int).$value);
    return $BigInt.wrap(result);
  }

  static const $Function __operatorShr = $Function(_operatorShr);
  static $Value? _operatorShr(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $BigInt;
    final result = (self.$value >> (r as $int).$value);
    return $BigInt.wrap(result);
  }

  static const $Function __operatorBitAnd = $Function(_operatorBitAnd);
  static $Value? _operatorBitAnd(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $BigInt;
    final result = (self.$value & (r as $Value?)!.$value);
    return $BigInt.wrap(result);
  }

  static const $Function __operatorBitOr = $Function(_operatorBitOr);
  static $Value? _operatorBitOr(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $BigInt;
    final result = (self.$value | (r as $Value?)!.$value);
    return $BigInt.wrap(result);
  }

  static const $Function __operatorBitXor = $Function(_operatorBitXor);
  static $Value? _operatorBitXor(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $BigInt;
    final result = (self.$value ^ (r as $Value?)!.$value);
    return $BigInt.wrap(result);
  }

  static const $Function __operatorBitNot = $Function(_operatorBitNot);
  static $Value? _operatorBitNot(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $BigInt;
    final result = ~self.$value;
    return $BigInt.wrap(result);
  }

  static const $Function __operatorLt = $Function(_operatorLt);
  static $Value? _operatorLt(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $BigInt;
    final result = (self.$value < (r as $Value?)!.$value);
    return $bool(result);
  }

  static const $Function __operatorLte = $Function(_operatorLte);
  static $Value? _operatorLte(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $BigInt;
    final result = (self.$value <= (r as $Value?)!.$value);
    return $bool(result);
  }

  static const $Function __operatorGt = $Function(_operatorGt);
  static $Value? _operatorGt(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $BigInt;
    final result = (self.$value > (r as $Value?)!.$value);
    return $bool(result);
  }

  static const $Function __operatorGte = $Function(_operatorGte);
  static $Value? _operatorGte(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $BigInt;
    final result = (self.$value >= (r as $Value?)!.$value);
    return $bool(result);
  }

  static const $Function __pow = $Function(_pow);
  static $Value? _pow(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $BigInt;
    final result = self.$value.pow((r as $int).$value);
    return $BigInt.wrap(result);
  }

  static const $Function __modPow = $Function(_modPow);
  static $Value? _modPow(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $BigInt;
    final result = self.$value.modPow(
      (r as $Value?)!.$value,
      (s as $Value?)!.$value,
    );
    return $BigInt.wrap(result);
  }

  static const $Function __modInverse = $Function(_modInverse);
  static $Value? _modInverse(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $BigInt;
    final result = self.$value.modInverse((r as $Value?)!.$value);
    return $BigInt.wrap(result);
  }

  static const $Function __gcd = $Function(_gcd);
  static $Value? _gcd(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $BigInt;
    final result = self.$value.gcd((r as $Value?)!.$value);
    return $BigInt.wrap(result);
  }

  static const $Function __toUnsigned = $Function(_toUnsigned);
  static $Value? _toUnsigned(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $BigInt;
    final result = self.$value.toUnsigned((r as $int).$value);
    return $BigInt.wrap(result);
  }

  static const $Function __toSigned = $Function(_toSigned);
  static $Value? _toSigned(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $BigInt;
    final result = self.$value.toSigned((r as $int).$value);
    return $BigInt.wrap(result);
  }

  static const $Function __toInt = $Function(_toInt);
  static $Value? _toInt(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $BigInt;
    final result = self.$value.toInt();
    return $int(result);
  }

  static const $Function __toDouble = $Function(_toDouble);
  static $Value? _toDouble(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $BigInt;
    final result = self.$value.toDouble();
    return $double(result);
  }

  static const $Function __toRadixString = $Function(_toRadixString);
  static $Value? _toRadixString(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $BigInt;
    final result = self.$value.toRadixString((r as $int).$value);
    return $String(result);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
