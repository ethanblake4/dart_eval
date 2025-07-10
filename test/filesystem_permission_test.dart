import 'dart:io';
import 'package:test/test.dart';
import 'package:dart_eval/dart_eval_security.dart';
import 'package:path/path.dart' as p;

void main() {
  group('FilesystemPermission Tests', () {
    late Directory tempDir;
    late String tempDirPath;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('fs_permission_test');
      tempDirPath = tempDir.path;
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('should allow access to exact file', () {
      final testFile = File(p.join(tempDirPath, 'test.txt'));
      final permission = FilesystemPermission.file(testFile.path);

      expect(permission.match(testFile.path), isTrue);
    });

    test('should allow access to files within directory', () {
      final permission = FilesystemPermission.directory(tempDirPath);
      final testFile = p.join(tempDirPath, 'subdir', 'test.txt');

      expect(permission.match(testFile), isTrue);
    });

    test('should deny access to files outside allowed directory', () {
      final subDir = Directory(p.join(tempDirPath, 'allowed'));
      final permission = FilesystemPermission.directory(subDir.path);
      final deniedFile = p.join(tempDirPath, 'denied.txt');

      expect(permission.match(deniedFile), isFalse);
    });

    test('should handle relative paths by converting to absolute', () {
      final originalDir = Directory.current;
      try {
        Directory.current = tempDirPath;
        final permission = FilesystemPermission.file('test.txt');
        final absolutePath = p.join(tempDirPath, 'test.txt');

        expect(permission.match('test.txt'), isTrue);
        expect(permission.match('./test.txt'), isTrue);
        expect(permission.match(absolutePath), isTrue);
      } finally {
        Directory.current = originalDir;
      }
    });

    test('should prevent path traversal attacks', () {
      final subDir = Directory(p.join(tempDirPath, 'allowed'));
      final permission = FilesystemPermission.directory(subDir.path);

      // Try to escape using ../
      final escapeAttempt = p.join(subDir.path, '..', 'secret.txt');

      expect(permission.match(escapeAttempt), isFalse);
      expect(permission.match('../secret.txt'), isFalse);
    });

    test('should handle current directory changes', () {
      final originalDir = Directory.current;
      try {
        // Create permission for current directory
        Directory.current = tempDirPath;
        final permission = FilesystemPermission.directory('.');

        // Change directory
        final subDir = Directory(p.join(tempDirPath, 'subdir'));
        subDir.createSync();
        Directory.current = subDir.path;

        // Permission should still work for original allowed directory
        final fileInOriginalDir = p.join(tempDirPath, 'file.txt');
        expect(permission.match(fileInOriginalDir), isTrue);

        // But not allow access to new current directory's siblings
        final siblingDir = Directory(p.join(tempDirPath, 'sibling'));
        siblingDir.createSync();
        final fileInSibling = p.join(siblingDir.path, 'file.txt');
        expect(permission.match(fileInSibling),
            isTrue); // This should be true since sibling is under original allowed dir
      } finally {
        Directory.current = originalDir;
      }
    });

    test('FilesystemReadPermission should only allow read operations', () {
      final permission = FilesystemReadPermission.directory(tempDirPath);
      final testFile = p.join(tempDirPath, 'test.txt');

      expect(permission.domains, equals(['filesystem:read']));
      expect(permission.match(testFile), isTrue);
    });

    test('FilesystemWritePermission should only allow write operations', () {
      final permission = FilesystemWritePermission.directory(tempDirPath);
      final testFile = p.join(tempDirPath, 'test.txt');

      expect(permission.domains, equals(['filesystem:write']));
      expect(permission.match(testFile), isTrue);
    });

    test('FilesystemPermission.any should allow access to everything', () {
      final permission = FilesystemPermission.any;

      expect(permission.match('/any/path/anywhere'), isTrue);
      expect(permission.match('/etc/passwd'), isTrue);
      expect(permission.match('relative/path'), isTrue);
    });

    test('should handle non-existent paths', () {
      final nonExistentDir = p.join(tempDirPath, 'nonexistent');
      final permission = FilesystemPermission.directory(nonExistentDir);
      final testFile = p.join(nonExistentDir, 'test.txt');

      expect(permission.match(testFile), isTrue);
    });

    test('permissions should be equal when paths are the same', () {
      final perm1 = FilesystemPermission.directory(tempDirPath);
      final perm2 = FilesystemPermission.directory(tempDirPath);

      expect(perm1, equals(perm2));
      expect(perm1.hashCode, equals(perm2.hashCode));
    });

    test('permissions should not be equal when paths differ', () {
      final perm1 = FilesystemPermission.directory(tempDirPath);
      final perm2 = FilesystemPermission.directory('/different/path');

      expect(perm1, isNot(equals(perm2)));
    });
  });
}
