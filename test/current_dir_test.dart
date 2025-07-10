@TestOn('vm')
library current_dir_test;

import 'dart:io' as io;
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_security.dart';
import 'package:test/test.dart';

void main() {
  group('currentDir tests', () {
    late Compiler compiler;
    late io.Directory tempDir;

    setUp(() async {
      compiler = Compiler();
      tempDir = await io.Directory.systemTemp.createTemp('dart_eval_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('File operations with relative paths when currentDir is set',
        () async {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            import 'dart:io';

            Future<String> main() async {
              // Create a file with relative path
              final file = File('test.txt');
              await file.writeAsString('Hello, World!');
              
              // Read the file back
              final content = await file.readAsString();
              
              // Clean up
              await file.delete();
              
              return content;
            }
          '''
        }
      });

      // Set the current directory
      runtime.currentDir = tempDir.path;
      runtime.grant(FilesystemPermission.any);

      final result = (await runtime.executeLib(
        'package:example/main.dart',
        'main',
      ))
          .$value;

      expect(result, 'Hello, World!');
    });

    test('File operations with nested relative paths', () async {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            import 'dart:io';

            Future<String> main() async {
              // Create nested directories and file
              final dir = Directory('subdir');
              await dir.create();
              
              final file = File('subdir/nested.txt');
              await file.writeAsString('Nested content');
              
              final content = await file.readAsString();
              
              // Clean up
              await file.delete();
              await dir.delete();
              
              return content;
            }
          '''
        }
      });

      runtime.currentDir = tempDir.path;
      runtime.grant(FilesystemPermission.any);

      final result = (await runtime.executeLib(
        'package:example/main.dart',
        'main',
      ))
          .$value;

      expect(result, 'Nested content');
    });

    test('Directory operations with relative paths', () async {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            import 'dart:io';

            Future<bool> main() async {
              final dir = Directory('test_dir');
              await dir.create();
              
              final exists = await dir.exists();
              
              await dir.delete();
              
              return exists;
            }
          '''
        }
      });

      runtime.currentDir = tempDir.path;
      runtime.grant(FilesystemPermission.any);

      final result = (await runtime.executeLib(
        'package:example/main.dart',
        'main',
      ))
          .$value;

      expect(result, true);
    });

    test('File rename with relative paths', () async {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            import 'dart:io';

            Future<String> main() async {
              final file = File('original.txt');
              await file.writeAsString('Content');
              
              final renamed = await file.rename('renamed.txt');
              final content = await renamed.readAsString();
              
              await renamed.delete();
              
              return content;
            }
          '''
        }
      });

      runtime.currentDir = tempDir.path;
      runtime.grant(FilesystemPermission.any);

      final result = (await runtime.executeLib(
        'package:example/main.dart',
        'main',
      ))
          .$value;

      expect(result, 'Content');
    });

    test('Directory rename with relative paths', () async {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            import 'dart:io';

            Future<bool> main() async {
              final dir = Directory('old_name');
              await dir.create();
              
              final renamed = await dir.rename('new_name');
              final exists = await renamed.exists();
              
              await renamed.delete();
              
              return exists;
            }
          '''
        }
      });

      runtime.currentDir = tempDir.path;
      runtime.grant(FilesystemPermission.any);

      final result = (await runtime.executeLib(
        'package:example/main.dart',
        'main',
      ))
          .$value;

      expect(result, true);
    });

    test('Path resolution with dot and double dot', () async {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            import 'dart:io';

            Future<String> main() async {
              // Create a subdirectory structure
              final subdir = Directory('subdir');
              await subdir.create();
              
              // Create a file using relative path with ..
              final file = File('subdir/../test.txt');
              await file.writeAsString('Dot dot navigation works');
              
              final content = await file.readAsString();
              
              // Clean up
              await file.delete();
              await subdir.delete();
              
              return content;
            }
          '''
        }
      });

      runtime.currentDir = tempDir.path;
      runtime.grant(FilesystemPermission.any);

      final result = (await runtime.executeLib(
        'package:example/main.dart',
        'main',
      ))
          .$value;

      expect(result, 'Dot dot navigation works');
    });

    test('currentDir setter with absolute path', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            void main() {
              // This test just needs to compile and run
            }
          '''
        }
      });

      runtime.currentDir = '/absolute/path';
      expect(runtime.currentDir, '/absolute/path');
    });

    test('currentDir setter with relative path from existing currentDir', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            void main() {
              // This test just needs to compile and run
            }
          '''
        }
      });

      runtime.currentDir = '/base/path';
      runtime.currentDir = 'relative/subdir';
      expect(runtime.currentDir, '/base/path/relative/subdir');
    });

    test('currentDir setter with null resets to null', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            void main() {
              // This test just needs to compile and run
            }
          '''
        }
      });

      runtime.currentDir = '/some/path';
      runtime.currentDir = null;
      expect(runtime.currentDir, null);
    });

    test('resolvePath function with various inputs', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            void main() {
              // This test just needs to compile and run
            }
          '''
        }
      });

      // Test absolute path - should return as is
      expect(runtime.resolvePath('/absolute/path'), '/absolute/path');

      // Test relative path with working directory
      expect(
          runtime.resolvePath('relative/path', '/base'), '/base/relative/path');

      // Test relative path without working directory
      expect(runtime.resolvePath('relative/path'), 'relative/path');
    });

    test('Path normalization with complex paths', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            void main() {
              // This test just needs to compile and run
            }
          '''
        }
      });

      // Test resolvePath function which does normalization
      expect(runtime.resolvePath('base/./path/../normalized', '/'),
          '/base/normalized');
      expect(runtime.resolvePath('path/to/deep/../../shallow', '/'),
          '/path/shallow');
      expect(
          runtime.resolvePath('root/./././directory', '/'), '/root/directory');

      // Test currentDir setter with relative paths that get normalized
      runtime.currentDir = '/base';
      runtime.currentDir = './path/../normalized';
      expect(runtime.currentDir, '/base/normalized');
    });

    test('File operations without currentDir set use absolute paths', () async {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            import 'dart:io';

            Future<String> main() async {
              final file = File('${tempDir.path}/absolute_test.txt');
              await file.writeAsString('Absolute path works');
              
              final content = await file.readAsString();
              
              await file.delete();
              
              return content;
            }
          '''
        }
      });

      // Don't set currentDir - it should remain null
      expect(runtime.currentDir, null);
      runtime.grant(FilesystemPermission.any);

      final result = (await runtime.executeLib(
        'package:example/main.dart',
        'main',
      ))
          .$value;

      expect(result, 'Absolute path works');
    });

    test('Directory listing with currentDir', () async {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            import 'dart:io';

            Future<int> main() async {
              // Create some test files
              final file1 = File('test1.txt');
              final file2 = File('test2.txt');
              final subDir = Directory('testdir');
              
              await file1.writeAsString('content1');
              await file2.writeAsString('content2');
              await subDir.create();
              
              // List current directory synchronously
              final dir = Directory('.');
              final entities = dir.listSync();
              
              // Clean up
              await file1.delete();
              await file2.delete();
              await subDir.delete();
              
              return entities.length;
            }
          '''
        }
      });

      runtime.currentDir = tempDir.path;
      runtime.grant(FilesystemPermission.any);

      final result = (await runtime.executeLib(
        'package:example/main.dart',
        'main',
      ))
          .$value as int;

      // Should have at least the files and directory we created
      expect(result, greaterThanOrEqualTo(3));
    });

    test('Verify file actually created in currentDir on real filesystem',
        () async {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            import 'dart:io';

            Future<String> main() async {
              final file = File('verify_test.txt');
              await file.writeAsString('File created successfully');
              return 'done';
            }
          '''
        }
      });

      // Set the current directory
      runtime.currentDir = tempDir.path;
      runtime.grant(FilesystemPermission.any);

      // Execute the dart_eval code
      await runtime.executeLib('package:example/main.dart', 'main');

      // Verify the file was actually created in the temp directory
      final realFile = io.File('${tempDir.path}/verify_test.txt');
      expect(await realFile.exists(), true);

      final content = await realFile.readAsString();
      expect(content, 'File created successfully');

      // Clean up
      await realFile.delete();
    });

    test('Verify nested directory structure created in currentDir', () async {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            import 'dart:io';

            Future<String> main() async {
              // Create nested directories step by step
              final dir1 = Directory('nested');
              await dir1.create();
              
              final dir2 = Directory('nested/deep');
              await dir2.create();
              
              final dir3 = Directory('nested/deep/structure');
              await dir3.create();
              
              final file = File('nested/deep/structure/test.txt');
              await file.writeAsString('Deep nested file');
              
              return 'created';
            }
          '''
        }
      });

      runtime.currentDir = tempDir.path;
      runtime.grant(FilesystemPermission.any);

      await runtime.executeLib('package:example/main.dart', 'main');

      // Verify the nested structure exists in the real filesystem
      final realDir = io.Directory('${tempDir.path}/nested/deep/structure');
      final realFile =
          io.File('${tempDir.path}/nested/deep/structure/test.txt');

      expect(await realDir.exists(), true);
      expect(await realFile.exists(), true);

      final content = await realFile.readAsString();
      expect(content, 'Deep nested file');

      // Clean up
      await realFile.delete();
      await io.Directory('${tempDir.path}/nested').delete(recursive: true);
    });

    test('Verify file created with relative path resolves correctly', () async {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            import 'dart:io';

            Future<String> main() async {
              // Create file with complex relative path
              final file = File('./subdir/../relative_test.txt');
              await file.writeAsString('Relative path resolved');
              return 'done';
            }
          '''
        }
      });

      runtime.currentDir = tempDir.path;
      runtime.grant(FilesystemPermission.any);

      await runtime.executeLib('package:example/main.dart', 'main');

      // The file should be created directly in tempDir due to path resolution
      final expectedFile = io.File('${tempDir.path}/relative_test.txt');
      expect(await expectedFile.exists(), true);

      final content = await expectedFile.readAsString();
      expect(content, 'Relative path resolved');

      // Verify it's NOT in a subdir/../ structure
      final wrongPath = io.File('${tempDir.path}/subdir/../relative_test.txt');
      expect(await wrongPath.exists(), false);

      // Clean up
      await expectedFile.delete();
    });

    test('Verify files created without currentDir use absolute paths',
        () async {
      // Create a specific test directory outside tempDir
      final testDir =
          await io.Directory.systemTemp.createTemp('absolute_test_');

      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            import 'dart:io';

            Future<String> main() async {
              final file = File('${testDir.path}/absolute_file.txt');
              await file.writeAsString('Absolute path file');
              return 'done';
            }
          '''
        }
      });

      // Don't set currentDir - should remain null
      expect(runtime.currentDir, null);
      runtime.grant(FilesystemPermission.any);

      await runtime.executeLib('package:example/main.dart', 'main');

      // Verify file was created in the absolute path location
      final absoluteFile = io.File('${testDir.path}/absolute_file.txt');
      expect(await absoluteFile.exists(), true);

      final content = await absoluteFile.readAsString();
      expect(content, 'Absolute path file');

      // Verify file was NOT created in tempDir
      final wrongFile = io.File('${tempDir.path}/absolute_file.txt');
      expect(await wrongFile.exists(), false);

      // Clean up
      await testDir.delete(recursive: true);
    });

    test('Verify directory rename creates new directory in correct location',
        () async {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            import 'dart:io';

            Future<String> main() async {
              final dir = Directory('original_dir');
              await dir.create();
              
              final renamed = await dir.rename('renamed_dir');
              return 'renamed';
            }
          '''
        }
      });

      runtime.currentDir = tempDir.path;
      runtime.grant(FilesystemPermission.any);

      await runtime.executeLib('package:example/main.dart', 'main');

      // Verify original directory no longer exists
      final originalDir = io.Directory('${tempDir.path}/original_dir');
      expect(await originalDir.exists(), false);

      // Verify renamed directory exists in correct location
      final renamedDir = io.Directory('${tempDir.path}/renamed_dir');
      expect(await renamedDir.exists(), true);

      // Clean up
      await renamedDir.delete();
    });

    test('Verify currentDir affects multiple file operations in sequence',
        () async {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            import 'dart:io';

            Future<List<String>> main() async {
              final results = <String>[];
              
              // Create first file
              final file1 = File('sequence_1.txt');
              await file1.writeAsString('First file');
              results.add('file1_created');
              
              // Create directory
              final dir = Directory('sequence_dir');
              await dir.create();
              results.add('dir_created');
              
              // Create file in directory
              final file2 = File('sequence_dir/sequence_2.txt');
              await file2.writeAsString('Second file');
              results.add('file2_created');
              
              return results;
            }
          '''
        }
      });

      runtime.currentDir = tempDir.path;
      runtime.grant(FilesystemPermission.any);

      await runtime.executeLib('package:example/main.dart', 'main');

      // Verify all files and directories were created in the correct location
      final file1 = io.File('${tempDir.path}/sequence_1.txt');
      final dir = io.Directory('${tempDir.path}/sequence_dir');
      final file2 = io.File('${tempDir.path}/sequence_dir/sequence_2.txt');

      expect(await file1.exists(), true);
      expect(await dir.exists(), true);
      expect(await file2.exists(), true);

      // Verify contents
      expect(await file1.readAsString(), 'First file');
      expect(await file2.readAsString(), 'Second file');

      // Clean up
      await file1.delete();
      await dir.delete(recursive: true);
    });

    test('Verify relative paths fail appropriately without currentDir',
        () async {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            import 'dart:io';

            Future<String> main() async {
              try {
                // Try to create a file with relative path when no currentDir is set
                final file = File('should_not_work.txt');
                await file.writeAsString('This should use current working directory');
                return 'created';
              } catch (e) {
                return 'error: \$e';
              }
            }
          '''
        }
      });

      // Don't set currentDir - should remain null
      expect(runtime.currentDir, null);
      runtime.grant(FilesystemPermission.any);

      final result =
          await runtime.executeLib('package:example/main.dart', 'main');

      // Should have executed successfully
      expect(result.$value, 'created');
      // The file should be created in the actual current working directory (not tempDir)
      // Let's check that it's NOT in our tempDir
      final fileInTempDir = io.File('${tempDir.path}/should_not_work.txt');
      expect(await fileInTempDir.exists(), false);

      // Clean up if file was created in current working directory
      final fileInCurrentDir = io.File('should_not_work.txt');
      if (await fileInCurrentDir.exists()) {
        await fileInCurrentDir.delete();
      }
    });
  });
}
