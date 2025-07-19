import 'dart:io';
import 'package:path/path.dart' as p;

/// An [IOOverrides] implementation that safely overrides the current working directory
/// for file system operations at runtime.
///
/// This class is useful when you need to execute code with a different current directory,
/// especially on platforms like Android and iOS where directly setting [Directory.current]
/// is not recommended or may cause issues.
///
/// All file, directory, and link operations performed through this override will be
/// resolved relative to the specified [currentDir], ensuring isolation and safety.
///
/// Example usage:
/// ```dart
/// IOOverrides.runWithOverrides(
///   () {
///     // File operations here will use the overridden current directory.
///     // like: runtime.executeLib('package:example/main.dart', 'main');
///   },
///   CurrentDirIOOverrides('/my/custom/path'),
/// );
/// ```
class CurrentDirIOOverrides extends IOOverrides {
  final String currentDir;
  CurrentDirIOOverrides(this.currentDir);

  @override
  File createFile(String path) =>
      super.createFile(p.normalize(p.join(currentDir, path)));

  @override
  Directory createDirectory(String path) =>
      super.createDirectory(p.normalize(p.join(currentDir, path)));

  @override
  Directory getCurrentDirectory() => Directory(currentDir);

  @override
  Link createLink(String path) =>
      super.createLink(p.normalize(p.join(currentDir, path)));

  @override
  Future<FileStat> stat(String path) async =>
      await FileStat.stat(p.normalize(p.join(currentDir, path)));

  @override
  FileStat statSync(String path) =>
      FileStat.statSync(p.normalize(p.join(currentDir, path)));
}
