/// Hand-written shims for packages imported by the SDK language tests.
///
/// `package:expect` files that are self-contained (static_type_helper.dart,
/// variations.dart, minitest.dart) are vendored verbatim from the checked-out
/// `pkg/expect/lib` instead — see [SdkSuite._vendoredExpectLibs]. The files
/// below replace what can't run verbatim under dart_eval.
library;

/// Compact `package:expect/expect.dart`. Semantics match the SDK version
/// closely enough for the language suite: deep equality in [equals], typed
/// [throws]/[throwsWhen], and subtype assertions. Diff reporting is trimmed.
const expectShim = '''
class ExpectException implements Exception {
  ExpectException(this.message);
  final String message;
  @override
  String toString() => 'ExpectException(\$message)';
}

class Expect {
  static void _fail(String message) => throw ExpectException(message);

  static String _getMessage(String reason) =>
      reason.isEmpty ? "" : ", '\$reason'";

  static bool _deepEquals(dynamic expected, dynamic actual) {
    if (_identical(expected, actual)) return true;
    if (expected is List && actual is List) {
      if (expected.length != actual.length) return false;
      for (var i = 0; i < expected.length; i++) {
        if (!_deepEquals(expected[i], actual[i])) return false;
      }
      return true;
    }
    if (expected is Set && actual is Set) {
      if (expected.length != actual.length) return false;
      return expected.every(actual.contains);
    }
    if (expected is Map && actual is Map) {
      if (expected.length != actual.length) return false;
      for (final key in expected.keys) {
        if (!actual.containsKey(key)) return false;
        if (!_deepEquals(expected[key], actual[key])) return false;
      }
      return true;
    }
    return expected == actual;
  }

  static void equals(dynamic expected, dynamic actual, [String reason = ""]) {
    if (!_deepEquals(expected, actual)) {
      _fail('Expect.equals\$expected == \$actual fails\${_getMessage(reason)}');
    }
  }

  static void notEquals(dynamic unexpected, dynamic actual,
      [String reason = ""]) {
    if (unexpected != actual) return;
    _fail('Expect.notEquals\$unexpected != \$actual fails'
        '\${_getMessage(reason)}');
  }

  static void identical(dynamic expected, dynamic actual,
      [String reason = ""]) {
    if (!_identical(expected, actual)) {
      _fail('Expect.identical\$expected !== \$actual fails'
          '\${_getMessage(reason)}');
    }
  }

  static void notIdentical(dynamic unexpected, dynamic actual,
      [String reason = ""]) {
    if (_identical(unexpected, actual)) {
      _fail('Expect.notIdentical fails\${_getMessage(reason)}');
    }
  }

  static void allIdentical(List<dynamic> objects, [String reason = ""]) {
    for (var i = 1; i < objects.length; i++) {
      identical(objects[0], objects[i], reason);
    }
  }

  static void allDistinct(List<dynamic> objects, [String reason = ""]) {
    for (var i = 0; i < objects.length; i++) {
      for (var j = i + 1; j < objects.length; j++) {
        if (_identical(objects[i], objects[j])) {
          _fail('Expect.allDistinct fails\${_getMessage(reason)}');
        }
      }
    }
  }

  static void isTrue(dynamic actual, [String reason = ""]) {
    if (_identical(actual, true)) return;
    _fail('Expect.isTrue(\$actual) fails\${_getMessage(reason)}');
  }

  static void isFalse(dynamic actual, [String reason = ""]) {
    if (_identical(actual, false)) return;
    _fail('Expect.isFalse(\$actual) fails\${_getMessage(reason)}');
  }

  static void isNull(dynamic actual, [String reason = ""]) {
    if (actual != null) {
      _fail('Expect.isNull(\$actual) fails\${_getMessage(reason)}');
    }
  }

  static void isNotNull(dynamic actual, [String reason = ""]) {
    if (actual == null) {
      _fail('Expect.isNotNull(null) fails\${_getMessage(reason)}');
    }
  }

  static void isEmpty(dynamic actual, [String reason = ""]) {
    if (!(actual as dynamic).isEmpty) {
      _fail('Expect.isEmpty fails\${_getMessage(reason)}');
    }
  }

  static void isNotEmpty(dynamic actual, [String reason = ""]) {
    if (!(actual as dynamic).isNotEmpty) {
      _fail('Expect.isNotEmpty fails\${_getMessage(reason)}');
    }
  }

  static void fail(String msg) => _fail("Expect.fail('\$msg')");

  static void approxEquals(num expected, num actual,
      [dynamic tolerance = null, String reason = ""]) {
    var t = tolerance == null
        ? (expected.abs() / 1e4)
        : (tolerance as num).abs();
    if ((expected - actual).abs() <= t) return;
    _fail('Expect.approxEquals\$expected ~ \$actual fails'
        '\${_getMessage(reason)}');
  }

  static void listEquals(List expected, List actual, [String reason = ""]) {
    if (expected.length != actual.length) {
      _fail('Expect.listEquals length fails\${_getMessage(reason)}');
    }
    for (var i = 0; i < expected.length; i++) {
      if (!_deepEquals(expected[i], actual[i])) {
        _fail('Expect.listEquals[\$i] fails\${_getMessage(reason)}');
      }
    }
  }

  static void mapEquals(Map expected, Map actual, [String reason = ""]) {
    if (expected.length != actual.length) {
      _fail('Expect.mapEquals length fails\${_getMessage(reason)}');
    }
    for (final key in expected.keys) {
      if (!actual.containsKey(key) ||
          !_deepEquals(expected[key], actual[key])) {
        _fail('Expect.mapEquals[\$key] fails\${_getMessage(reason)}');
      }
    }
  }

  static void setEquals(Set expected, Set actual, [String reason = ""]) {
    if (expected.length != actual.length || !expected.every(actual.contains)) {
      _fail('Expect.setEquals fails\${_getMessage(reason)}');
    }
  }

  static void stringEquals(String expected, String actual,
      [String reason = ""]) {
    if (expected != actual) {
      _fail('Expect.stringEquals fails\${_getMessage(reason)}');
    }
  }

  static void contains(dynamic needle, Iterable haystack,
      [String reason = ""]) {
    if (haystack.contains(needle)) return;
    _fail('Expect.contains fails\${_getMessage(reason)}');
  }

  static void containsAny(Iterable needles, Iterable haystack,
      [String reason = ""]) {
    if (needles.any(haystack.contains)) return;
    _fail('Expect.containsAny fails\${_getMessage(reason)}');
  }

  static void containsInOrder(Iterable needles, Iterable haystack,
      [String reason = ""]) {
    final it = haystack.iterator;
    for (final needle in needles) {
      var found = false;
      while (it.moveNext()) {
        if (it.current == needle) {
          found = true;
          break;
        }
      }
      if (!found) {
        _fail('Expect.containsInOrder fails\${_getMessage(reason)}');
      }
    }
  }

  static void deepEquals(dynamic expected, dynamic actual) {
    if (!_deepEquals(expected, actual)) _fail('Expect.deepEquals fails');
  }

  static bool _defaultCheck(dynamic _) => true;

  // `check` takes dynamic rather than T: function-type annotations can't
  // resolve a method's type parameter under dart_eval.
  static T throws<T extends Object>(void Function() computation,
      [bool Function(dynamic error)? check, String reason = ""]) {
    try {
      computation();
    } catch (e) {
      if (e is ExpectException) rethrow;
      if (e is T && (check == null || check(e))) return e;
      _fail('Expect.throws: unexpected \$e\${_getMessage(reason)}');
    }
    _fail('Expect.throws fails: did not throw\${_getMessage(reason)}');
  }

  static E? throwsWhen<E extends Object>(bool condition,
      void Function() computation,
      [String reason = ""]) {
    if (condition) return throws<E>(computation, null, reason);
    computation();
    return null;
  }

  static ArgumentError throwsArgumentError(void Function() f,
          [String reason = ""]) =>
      throws<ArgumentError>(f, null, reason);

  static AssertionError throwsAssertionError(void Function() f,
          [String reason = ""]) =>
      throws<AssertionError>(f, null, reason);

  static FormatException throwsFormatException(void Function() f,
          [String reason = ""]) =>
      throws<FormatException>(f, null, reason);

  static NoSuchMethodError throwsNoSuchMethodError(void Function() f,
          [String reason = ""]) =>
      throws<NoSuchMethodError>(f, null, reason);

  static RangeError throwsRangeError(void Function() f,
          [String reason = ""]) =>
      throws<RangeError>(f, null, reason);

  static StateError throwsStateError(void Function() f,
          [String reason = ""]) =>
      throws<StateError>(f, null, reason);

  static TypeError throwsTypeError(void Function() f, [String reason = ""]) =>
      throws<TypeError>(f, null, reason);

  static TypeError? throwsTypeErrorWhen(bool condition, void Function() f,
          [String reason = ""]) =>
      throwsWhen<TypeError>(condition, f, reason);

  static UnsupportedError throwsUnsupportedError(void Function() f,
          [String reason = ""]) =>
      throws<UnsupportedError>(f, null, reason);

  static void testError(String message) => _fail('Test error: \$message');

  static void type<T>(dynamic object, [String reason = ""]) {
    if (object is T) return;
    _fail('Expect.type fails\${_getMessage(reason)}');
  }

  static void notType<T>(dynamic object, [String reason = ""]) {
    if (object is! T) return;
    _fail('Expect.type fails\${_getMessage(reason)}');
  }

  // Bound `Sub extends Super` is intentionally relaxed: dart_eval can't
  // resolve a bound that references a later parameter in the same list.
  static void subtype<Sub, Super>() {
    if ((<Sub>[] as dynamic) is List<Super>) return;
    _fail('Expect.subtype fails');
  }

  static void runtimeSubtype<Sub, Super>() {
    if (<Sub>[] is List<Super>) return;
    _fail('Expect.runtimeSubtype fails');
  }

  static void notSubtype<Sub, Super>() {
    if (<Sub>[] is List<Super>) {
      _fail('Expect.notSubtype fails');
    }
  }
}

bool _identical(dynamic a, dynamic b) => identical(a, b);

/// Mirrors the real `package:expect` null-safety detection: under sound
/// null safety `List<Null>` is not a `List<Object>`.
bool get hasUnsoundNullSafety => const <Null>[] is List<Object>;
bool get hasSoundNullSafety => !hasUnsoundNullSafety;
''';

/// `package:expect/async_helper.dart` — the real file manages a zone-based
/// async test registry dart_eval doesn't need; tests run synchronously here.
const asyncHelperShim = '''
import 'dart:async';

void asyncStart() {}
void asyncEnd() {}

void asyncTest(FutureOr<void> Function() computation) {
  computation();
}

void asyncMultiTests(List<void Function()> computations) {
  for (final c in computations) {
    c();
  }
}

FutureOr<void> asyncExpectThrows<T extends Object>(
    Object? computation) async {
  var threw = false;
  try {
    await (computation is Function ? computation() : computation as FutureOr);
  } catch (e) {
    if (e is T) threw = true;
  }
  if (!threw) throw 'asyncExpectThrows: did not throw';
}

FutureOr<void> asyncExpectThrowsWhen<T extends Object>(
    bool condition, Object? computation) async {
  if (!condition) {
    await (computation is Function ? computation() : computation as FutureOr);
    return;
  }
  return asyncExpectThrows<T>(computation);
}

FutureOr<void> asyncExpectThrowsTypeErrorOrNSM(
    Object? computation) async {
  var threw = false;
  try {
    await (computation is Function ? computation() : computation as FutureOr);
  } catch (e) {
    if (e is TypeError || e is NoSuchMethodError) threw = true;
  }
  if (!threw) throw 'asyncExpectThrowsTypeErrorOrNSM: did not throw';
}
''';

/// `package:expect/config.dart` — queried by `variations.dart`. dart_eval
/// reports itself as neither VM nor web configuration.
const expectConfigShim = '''
final String configAsString = 'dart_eval';
const bool isVmConfiguration = false;
const bool isDart2jsConfiguration = false;
const bool isDdcConfiguration = false;
const bool isDart2WasmConfiguration = false;
const bool isVmJitConfiguration = false;
const bool isVmAotConfiguration = false;
const bool isDart2jsOss = false;
const bool isDart2jsOssConfiguration = false;
const bool isVm = false;
const bool isWasm = false;
''';

/// `package:meta/meta.dart` — only the annotation constants used by the
/// language tests; a handful of extras kept for future imports.
const metaShim = '''
class _Redeclare {
  const _Redeclare();
}

const redeclare = _Redeclare();
const experimental = Object();
const internal = Object();
const nonVirtual = Object();
const protected = Object();
const reopen = Object();
const sealed = Object();
const virtual = Object();
const visibleForTesting = Object();
const visibleForOverriding = Object();
const mustBeOverridden = Object();
const doNotStore = Object();
const doNotSubmit = Object();
const factory = Object();
const literal = Object();
const optionalTypeArgs = Object();
const useResult = Object();
''';
