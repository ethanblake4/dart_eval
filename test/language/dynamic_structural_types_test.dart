import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void main() {
  test('static nominal identity cannot eliminate structural checks', () {
    const source = '''
      int main() {
        int Function(int) f = (int x) => x;
        var result = 0;
        if (f is String Function(String)) return -1;
        try {
          final wrong = f as String Function(String);
          return -2;
        } on TypeError { result += 1; }
        List<int> values = <int>[];
        try {
          final wrong = values as List<String>;
          return -3;
        } on TypeError { result += 2; }
        return result;
      }
    ''';
    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(3), reason: mode);
    }
  });

  test('dynamic record checks compare shape and field types', () {
    const source = r'''
      int main() {
        dynamic value = (1, name: 'Ada');
        var result = 0;
        if (value is (int, {String name})) result += 1;
        if (value is (num, {Object name})) result += 2;
        if (value is (String, {String name})) result += 4;
        if (value is (int, {String label})) result += 8;
        if (value is (int, String)) result += 16;
        return result;
      }
    ''';

    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(3), reason: mode);
    }
  });

  test('dynamic function checks use Dart parameter and return variance', () {
    const source = r'''
      int main() {
        int Function(num, [String?]) typed =
            (num value, [String? label]) => value.toInt();
        dynamic value = typed;
        var result = 0;
        if (value is int Function(num, [String?])) result += 1;
        if (value is num Function(int)) result += 2;
        if (value is int Function(String)) result += 4;
        if (value is int Function(num, String?, Object?)) result += 8;
        if (value is String Function(num)) result += 16;
        return result;
      }
    ''';

    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(3), reason: mode);
    }
  });

  test('dynamic function checks account for named requirements', () {
    const source = r'''
      int main() {
        int Function(num, {required Object label, bool flag}) typed =
            (num value, {required Object label, bool flag = false}) =>
                value.toInt();
        dynamic value = typed;
        var result = 0;
        if (value is int Function(int, {required String label})) result += 1;
        if (value is int Function(int, {String label})) result += 2;
        if (value is num Function(int,
            {required String label, required bool flag})) result += 4;
        if (value is int Function(int, {required String missing})) result += 8;
        return result;
      }
    ''';

    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(5), reason: mode);
    }
  });

  test('dynamic casts enforce record and function structure', () {
    const source = r'''
      int main() {
        dynamic record = (1, name: 'Ada');
        int Function(num) typed = (num value) => value.toInt();
        dynamic function = typed;
        var result = 0;
        try {
          (num, {Object name}) value = record as (num, {Object name});
          if (value.$1 == 1) result += 1;
        } catch (_) {}
        try {
          (String, {String name}) value =
              record as (String, {String name});
          if (value.$1 == '1') result += 2;
        } on TypeError {
          result += 4;
        }
        try {
          num Function(int) value = function as num Function(int);
          if (value(2) == 2) result += 8;
        } catch (_) {}
        try {
          int Function(String) value = function as int Function(String);
          if (value('2') == 2) result += 2;
        } on TypeError {
          result += 16;
        }
        return result;
      }
    ''';

    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(29), reason: mode);
    }
  });

  test('top-level tear-offs retain their declared signature', () {
    const source = r'''
      int convert(int value, {Object? label}) => value;

      int main() {
        dynamic value = convert;
        var result = 0;
        if (value is num Function(int, {String? label})) result += 1;
        if (value is int Function(num, {Object? label})) result += 2;
        try {
          int Function(int, {String? label}) converted =
              value as int Function(int, {String? label});
          if (converted(3) == 3) result += 4;
        } catch (_) {}
        return result;
      }
    ''';

    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(5), reason: mode);
    }
  });

  test('function results are discarded for a void return target', () {
    const source = r'''
      int main() {
        int Function() typed = () => 1;
        dynamic value = typed;
        var result = 0;
        if (value is void Function()) result += 1;
        try {
          void Function() converted = value as void Function();
          converted();
          result += 2;
        } catch (_) {}
        return result;
      }
    ''';

    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(3), reason: mode);
    }
  });

  test('dynamic parameters use Object? function variance', () {
    const source = r'''
      int main() {
        int Function(Object?) typed = (Object? value) => 1;
        dynamic value = typed;
        var result = 0;
        if (value is int Function(dynamic)) result += 1;
        try {
          int Function(dynamic) converted = value as int Function(dynamic);
          if (converted(null) == 1) result += 2;
        } catch (_) {}
        return result;
      }
    ''';

    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(3), reason: mode);
    }
  });

  test('dynamic guest method tear-offs retain their declared signature', () {
    const source = r'''
      class A {
        int f(int value) => value;
      }

      int main() {
        dynamic instance = A();
        dynamic value = instance.f;
        var result = 0;
        if (value is int Function(int)) result += 1;
        if (value is int Function(String)) result += 2;
        try {
          int Function(int) converted = value as int Function(int);
          if (converted(4) == 4) result += 4;
        } catch (_) {}
        return result;
      }
    ''';

    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(5), reason: mode);
    }
  });
}
