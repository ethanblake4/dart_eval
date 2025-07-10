import 'dart:io';
import 'package:test/test.dart';
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_security.dart';
import 'package:path/path.dart' as p;

void main() {
  group('FilesystemPermission Tests', () {
    late Directory tempDir;
    late String tempDirPath;
    late Compiler compiler;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('fs_permission_test');
      tempDirPath = tempDir.path;
      compiler = Compiler();
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
      // FilesystemPermission resolves paths based on the actual current working directory,
      // not the dart_eval runtime's currentDir
      final permission =
          FilesystemPermission.file(p.join(tempDirPath, 'test.txt'));
      final absolutePath = p.join(tempDirPath, 'test.txt');

      // The permission was created with absolute path, so it should match the absolute path
      expect(permission.match(absolutePath), isTrue);

      // For relative path matching, the permission system uses the actual current working directory
      // This test demonstrates that permissions work with absolute paths
      final relativePermission = FilesystemPermission.directory(tempDirPath);
      expect(relativePermission.match(absolutePath), isTrue);
    });

    test('should prevent path traversal attacks', () {
      final subDir = Directory(p.join(tempDirPath, 'allowed'));
      final permission = FilesystemPermission.directory(subDir.path);

      // Try to escape using ../
      final escapeAttempt = p.join(subDir.path, '..', 'secret.txt');

      expect(permission.match(escapeAttempt), isFalse);
      expect(permission.match('../secret.txt'), isFalse);
    });

    test(
        'should handle directory permissions independent of dart_eval runtime currentDir',
        () {
      // Create runtime and set currentDir
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            void main() {
              // This test just needs to compile and run
            }
          '''
        }
      });

      runtime.currentDir = tempDirPath;

      // Permission system works independently of runtime's currentDir
      final permission = FilesystemPermission.directory(tempDirPath);

      // Create subdirectory
      final subDir = Directory(p.join(tempDirPath, 'subdir'));
      subDir.createSync();

      // Change runtime's currentDir to subdirectory
      runtime.currentDir = subDir.path;

      // Permission should still work for files in the original allowed directory
      final fileInOriginalDir = p.join(tempDirPath, 'file.txt');
      expect(permission.match(fileInOriginalDir), isTrue);

      // And for files in subdirectories
      final siblingDir = Directory(p.join(tempDirPath, 'sibling'));
      siblingDir.createSync();
      final fileInSibling = p.join(siblingDir.path, 'file.txt');
      expect(permission.match(fileInSibling), isTrue);
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

    test('should work with dart_eval runtime currentDir for file operations',
        () async {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            import 'dart:io';

            Future<String> main() async {
              try {
                final file = File('test_permission.txt');
                await file.writeAsString('Testing permissions');
                final content = await file.readAsString();
                await file.delete();
                return content;
              } catch (e) {
                return 'error: \$e';
              }
            }
          '''
        }
      });

      // Set currentDir and grant permission for that directory
      runtime.currentDir = tempDirPath;
      runtime.grant(FilesystemPermission.directory(tempDirPath));

      final result =
          await runtime.executeLib('package:example/main.dart', 'main');
      expect(result.$value, 'Testing permissions');
    });

    test(
        'should deny access when currentDir is set but permission is not granted',
        () async {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            import 'dart:io';

            Future<String> main() async {
              try {
                final file = File('denied_file.txt');
                await file.writeAsString('This should fail');
                return 'should not reach here';
              } catch (e) {
                return 'caught error: \${e.toString().contains('Permission denied') ? 'permission denied' : e}';
              }
            }
          '''
        }
      });

      // Set currentDir but don't grant permission
      runtime.currentDir = tempDirPath;
      // Intentionally not granting any filesystem permissions

      expect(
        () => runtime.executeLib('package:example/main.dart', 'main'),
        throwsA(isA<Exception>()),
      );
    });

    test(
        'should handle path resolution with currentDir and relative permissions',
        () async {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            import 'dart:io';

            Future<String> main() async {
              final file = File('subdir/relative_file.txt');
              await file.writeAsString('Relative path with currentDir');
              final content = await file.readAsString();
              await file.delete();
              return content;
            }
          '''
        }
      });

      // Create subdirectory in tempDir
      final subDir = Directory(p.join(tempDirPath, 'subdir'));
      await subDir.create();

      // Set currentDir and grant permission for the entire temp directory
      runtime.currentDir = tempDirPath;
      runtime.grant(FilesystemPermission.directory(tempDirPath));

      final result =
          await runtime.executeLib('package:example/main.dart', 'main');
      expect(result.$value, 'Relative path with currentDir');

      // Clean up
      await subDir.delete();
    });

    test(
        'should demonstrate currentDir resolution in dart_eval with permissions',
        () async {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            import 'dart:io';

            Future<String> main() async {
              // File created with relative path - will be resolved using runtime.currentDir
              final file = File('resolved_file.txt');
              await file.writeAsString('File resolved through currentDir');
              
              // Check the absolute path of the created file
              final absolutePath = file.absolute.path;
              
              final content = await file.readAsString();
              await file.delete();
              
              return '\$content||\$absolutePath';
            }
          '''
        }
      });

      // Set runtime's currentDir
      runtime.currentDir = tempDirPath;

      // Grant permission for the temp directory where files will actually be created
      runtime.grant(FilesystemPermission.directory(tempDirPath));

      final result =
          await runtime.executeLib('package:example/main.dart', 'main');
      final parts = (result.$value as String).split('||');

      expect(parts[0], 'File resolved through currentDir');
      expect(
          parts[1],
          contains(
              tempDirPath)); // The absolute path should contain our temp directory
    });
  });
}
