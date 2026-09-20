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

import 'dart:math';
import 'package:dart_eval/stdlib/core.dart' hide $Point, $Random;

/// dart_eval function wrapper binding for [atan2]
class $atan2Fn {
  const $atan2Fn();

  static void configureForRuntime(Runtime runtime) {
    return runtime.registerBridgeFuncRegisters(
      'dart:math',
      'atan2',
      $atan2Fn.callRegisters,
    );
  }

  static const $declaration = BridgeFunctionDeclaration(
    'dart:math',
    'atan2',
    BridgeFunctionDef(
      returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.double, [])),
      namedParams: [],
      params: [
        BridgeParameter(
          'a',
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.num, [])),
          false,
        ),

        BridgeParameter(
          'b',
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.num, [])),
          false,
        ),
      ],
    ),
  );

  static $Value? callRegisters(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final result = atan2((r as $num).$value, (s as $num).$value);
    return $double(result);
  }
}

/// dart_eval function wrapper binding for [pow]
class $powFn {
  const $powFn();

  static void configureForRuntime(Runtime runtime) {
    return runtime.registerBridgeFuncRegisters(
      'dart:math',
      'pow',
      $powFn.callRegisters,
    );
  }

  static const $declaration = BridgeFunctionDeclaration(
    'dart:math',
    'pow',
    BridgeFunctionDef(
      returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.num, [])),
      namedParams: [],
      params: [
        BridgeParameter(
          'x',
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.num, [])),
          false,
        ),

        BridgeParameter(
          'exponent',
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.num, [])),
          false,
        ),
      ],
    ),
  );

  static $Value? callRegisters(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final result = pow((r as $num).$value, (s as $num).$value);
    return $num(result);
  }
}

/// dart_eval function wrapper binding for [sin]
class $sinFn {
  const $sinFn();

  static void configureForRuntime(Runtime runtime) {
    return runtime.registerBridgeFuncRegisters(
      'dart:math',
      'sin',
      $sinFn.callRegisters,
    );
  }

  static const $declaration = BridgeFunctionDeclaration(
    'dart:math',
    'sin',
    BridgeFunctionDef(
      returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.double, [])),
      namedParams: [],
      params: [
        BridgeParameter(
          'radians',
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.num, [])),
          false,
        ),
      ],
    ),
  );

  static $Value? callRegisters(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final result = sin((r as $num).$value);
    return $double(result);
  }
}

/// dart_eval function wrapper binding for [cos]
class $cosFn {
  const $cosFn();

  static void configureForRuntime(Runtime runtime) {
    return runtime.registerBridgeFuncRegisters(
      'dart:math',
      'cos',
      $cosFn.callRegisters,
    );
  }

  static const $declaration = BridgeFunctionDeclaration(
    'dart:math',
    'cos',
    BridgeFunctionDef(
      returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.double, [])),
      namedParams: [],
      params: [
        BridgeParameter(
          'radians',
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.num, [])),
          false,
        ),
      ],
    ),
  );

  static $Value? callRegisters(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final result = cos((r as $num).$value);
    return $double(result);
  }
}

/// dart_eval function wrapper binding for [tan]
class $tanFn {
  const $tanFn();

  static void configureForRuntime(Runtime runtime) {
    return runtime.registerBridgeFuncRegisters(
      'dart:math',
      'tan',
      $tanFn.callRegisters,
    );
  }

  static const $declaration = BridgeFunctionDeclaration(
    'dart:math',
    'tan',
    BridgeFunctionDef(
      returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.double, [])),
      namedParams: [],
      params: [
        BridgeParameter(
          'radians',
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.num, [])),
          false,
        ),
      ],
    ),
  );

  static $Value? callRegisters(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final result = tan((r as $num).$value);
    return $double(result);
  }
}

/// dart_eval function wrapper binding for [acos]
class $acosFn {
  const $acosFn();

  static void configureForRuntime(Runtime runtime) {
    return runtime.registerBridgeFuncRegisters(
      'dart:math',
      'acos',
      $acosFn.callRegisters,
    );
  }

  static const $declaration = BridgeFunctionDeclaration(
    'dart:math',
    'acos',
    BridgeFunctionDef(
      returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.double, [])),
      namedParams: [],
      params: [
        BridgeParameter(
          'x',
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.num, [])),
          false,
        ),
      ],
    ),
  );

  static $Value? callRegisters(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final result = acos((r as $num).$value);
    return $double(result);
  }
}

/// dart_eval function wrapper binding for [asin]
class $asinFn {
  const $asinFn();

  static void configureForRuntime(Runtime runtime) {
    return runtime.registerBridgeFuncRegisters(
      'dart:math',
      'asin',
      $asinFn.callRegisters,
    );
  }

  static const $declaration = BridgeFunctionDeclaration(
    'dart:math',
    'asin',
    BridgeFunctionDef(
      returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.double, [])),
      namedParams: [],
      params: [
        BridgeParameter(
          'x',
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.num, [])),
          false,
        ),
      ],
    ),
  );

  static $Value? callRegisters(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final result = asin((r as $num).$value);
    return $double(result);
  }
}

/// dart_eval function wrapper binding for [atan]
class $atanFn {
  const $atanFn();

  static void configureForRuntime(Runtime runtime) {
    return runtime.registerBridgeFuncRegisters(
      'dart:math',
      'atan',
      $atanFn.callRegisters,
    );
  }

  static const $declaration = BridgeFunctionDeclaration(
    'dart:math',
    'atan',
    BridgeFunctionDef(
      returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.double, [])),
      namedParams: [],
      params: [
        BridgeParameter(
          'x',
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.num, [])),
          false,
        ),
      ],
    ),
  );

  static $Value? callRegisters(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final result = atan((r as $num).$value);
    return $double(result);
  }
}

/// dart_eval function wrapper binding for [sqrt]
class $sqrtFn {
  const $sqrtFn();

  static void configureForRuntime(Runtime runtime) {
    return runtime.registerBridgeFuncRegisters(
      'dart:math',
      'sqrt',
      $sqrtFn.callRegisters,
    );
  }

  static const $declaration = BridgeFunctionDeclaration(
    'dart:math',
    'sqrt',
    BridgeFunctionDef(
      returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.double, [])),
      namedParams: [],
      params: [
        BridgeParameter(
          'x',
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.num, [])),
          false,
        ),
      ],
    ),
  );

  static $Value? callRegisters(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final result = sqrt((r as $num).$value);
    return $double(result);
  }
}

/// dart_eval function wrapper binding for [exp]
class $expFn {
  const $expFn();

  static void configureForRuntime(Runtime runtime) {
    return runtime.registerBridgeFuncRegisters(
      'dart:math',
      'exp',
      $expFn.callRegisters,
    );
  }

  static const $declaration = BridgeFunctionDeclaration(
    'dart:math',
    'exp',
    BridgeFunctionDef(
      returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.double, [])),
      namedParams: [],
      params: [
        BridgeParameter(
          'x',
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.num, [])),
          false,
        ),
      ],
    ),
  );

  static $Value? callRegisters(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final result = exp((r as $num).$value);
    return $double(result);
  }
}

/// dart_eval function wrapper binding for [log]
class $logFn {
  const $logFn();

  static void configureForRuntime(Runtime runtime) {
    return runtime.registerBridgeFuncRegisters(
      'dart:math',
      'log',
      $logFn.callRegisters,
    );
  }

  static const $declaration = BridgeFunctionDeclaration(
    'dart:math',
    'log',
    BridgeFunctionDef(
      returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.double, [])),
      namedParams: [],
      params: [
        BridgeParameter(
          'x',
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.num, [])),
          false,
        ),
      ],
    ),
  );

  static $Value? callRegisters(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final result = log((r as $num).$value);
    return $double(result);
  }
}
