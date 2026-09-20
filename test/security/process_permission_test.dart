import 'package:test/test.dart';
import 'package:dart_eval/dart_eval_security.dart';

void main() {
  group('ProcessRunPermission Tests', () {
    test('should match exact executable path', () {
      final permission = ProcessRunPermission(RegExp(r'^/usr/bin/dart$'));

      expect(permission.match('/usr/bin/dart'), isTrue);
      expect(permission.match('/usr/bin/dart2'), isFalse);
    });

    test('namedExecutable should match executable name in any directory', () {
      final permission = ProcessRunPermission.namedExecutable('dart');

      expect(permission.match('/usr/bin/dart'), isTrue);
      expect(permission.match('/opt/dart/dart'), isTrue);
      expect(permission.match('/usr/bin/dart2'), isFalse);
      expect(permission.match('/usr/bin/dartaotruntime'), isFalse);
    });

    test('any should match any executable path', () {
      final permission = ProcessRunPermission.any;

      expect(permission.match('/usr/bin/dart'), isTrue);
      expect(permission.match('anything'), isTrue);
      expect(permission.match(''), isTrue);
    });

    test('should return correct domains', () {
      final permission = ProcessRunPermission.namedExecutable('dart');

      expect(permission.domains, equals(['process:run']));
    });

    test('should not match non-string data', () {
      final permission = ProcessRunPermission.namedExecutable('dart');

      expect(permission.match(123), isFalse);
      expect(permission.match(null), isFalse);
      expect(permission.match(<String, dynamic>{}), isFalse);
    });

    test('same instance should be equal to itself', () {
      final perm = ProcessRunPermission(RegExp(r'dart$'));
      expect(perm == perm, isTrue);
    });

    test('any singleton should be equal to itself', () {
      expect(ProcessRunPermission.any == ProcessRunPermission.any, isTrue);
    });

    test('equivalent instances with same RegExp instance should be equal', () {
      final pattern = RegExp(r'dart$');
      final perm1 = ProcessRunPermission(pattern);
      final perm2 = ProcessRunPermission(pattern);

      expect(perm1 == perm2, isTrue);
      expect(perm1.hashCode, equals(perm2.hashCode));
    });

    test('instances with different patterns are not equal', () {
      final perm1 = ProcessRunPermission(RegExp(r'dart$'));
      final perm2 = ProcessRunPermission(RegExp(r'flutter$'));

      expect(perm1 == perm2, isFalse);
    });

    test('should not be equal to other permission types', () {
      final runPerm = ProcessRunPermission.namedExecutable('dart');
      final killPerm = ProcessKillPermisssion(1234);

      // ignore: unrelated_type_equality_checks
      expect(runPerm == killPerm, isFalse);
    });
  });

  group('ProcessKillPermisssion Tests', () {
    test('should match specific PID', () {
      final permission = ProcessKillPermisssion(1234);

      expect(permission.match(1234), isTrue);
      expect(permission.match(5678), isFalse);
    });

    test('without PID should match any PID', () {
      final permission = ProcessKillPermisssion();

      expect(permission.match(1234), isTrue);
      expect(permission.match(5678), isTrue);
      expect(permission.match(0), isTrue);
    });

    test('should return correct domains', () {
      final permission = ProcessKillPermisssion(1234);

      expect(permission.domains, equals(['process:kill']));
    });

    test('should not match non-int data', () {
      final permission = ProcessKillPermisssion(1234);

      expect(permission.match('/usr/bin/dart'), isFalse);
      expect(permission.match(null), isFalse);
      expect(permission.match(1234.0), isFalse);
    });

    test('permissions should be equal when PIDs are the same', () {
      final perm1 = ProcessKillPermisssion(1234);
      final perm2 = ProcessKillPermisssion(1234);

      expect(perm1 == perm2, isTrue);
      expect(perm1.hashCode, equals(perm2.hashCode));
    });

    test('permissions should not be equal when PIDs differ', () {
      final perm1 = ProcessKillPermisssion(1234);
      final perm2 = ProcessKillPermisssion(5678);

      expect(perm1 == perm2, isFalse);
    });

    test('wildcard permissions should be equal', () {
      final perm1 = ProcessKillPermisssion();
      final perm2 = ProcessKillPermisssion();

      expect(perm1 == perm2, isTrue);
      expect(perm1.hashCode, equals(perm2.hashCode));
    });

    test('should not be equal to other permission types', () {
      final killPerm = ProcessKillPermisssion(1234);
      final runPerm = ProcessRunPermission.any;

      // ignore: unrelated_type_equality_checks
      expect(killPerm == runPerm, isFalse);
    });
  });
}
