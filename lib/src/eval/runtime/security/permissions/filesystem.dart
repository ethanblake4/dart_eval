import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:dart_eval/dart_eval_security.dart';

/// A permission that allows access to read and write a file system resource.
class FilesystemPermission implements Permission {
  /// The pattern that will be matched against the path.
  final Pattern matchPattern;

  /// Create a new filesystem permission that matches a [Pattern].
  const FilesystemPermission(this.matchPattern);

  /// A permission that allows access to any file system resource.
  static final FilesystemPermission any = FilesystemPermission(RegExp('.*'));

  /// Resolves a path to its canonical form, handling symlinks and different
  /// path representations (e.g., /data/data vs /data/user/0 on Android).
  static String _resolvePath(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) {
        return file.resolveSymbolicLinksSync();
      }

      final dir = Directory(p.dirname(path));
      if (dir.existsSync()) {
        final resolvedParent = dir.resolveSymbolicLinksSync();
        return p.join(resolvedParent, p.basename(path));
      }

      return p.normalize(p.absolute(path));
    } catch (e) {
      return p.normalize(p.absolute(path));
    }
  }

  /// Create a new filesystem permission that matches any file in a directory
  /// or one of its subdirectories.
  factory FilesystemPermission.directory(String dir) {
    final resolvedPath = _resolvePath(dir);
    final escaped =
        resolvedPath.replaceAll(r'\', r'\\').replaceAll(r'/', r'\/');
    return FilesystemPermission(RegExp('^$escaped.*'));
  }

  /// Create a new filesystem permission that matches a specific file.
  factory FilesystemPermission.file(String file) {
    final resolvedPath = _resolvePath(file);
    final escaped =
        resolvedPath.replaceAll(r'\', r'\\').replaceAll(r'/', r'\/');
    return FilesystemPermission(RegExp('^$escaped\$'));
  }

  @override
  List<String> get domains => ['filesystem:read', 'filesystem:write'];

  @override
  bool match([Object? data]) {
    if (data is String) {
      final resolvedPath = _resolvePath(data);
      return matchPattern.matchAsPrefix(resolvedPath) != null;
    }
    return false;
  }

  @override
  bool operator ==(Object other) {
    if (other is FilesystemPermission) {
      return other.matchPattern == matchPattern && other.domains == domains;
    }
    return false;
  }

  @override
  int get hashCode => matchPattern.hashCode ^ domains.hashCode;
}

/// A permission that allows access to read a file system resource.
class FilesystemReadPermission extends FilesystemPermission {
  /// Create a new filesystem permission that matches a [Pattern].
  const FilesystemReadPermission(super.matchPattern);

  /// A permission that allows access to any file system resource.
  static final FilesystemReadPermission any =
      FilesystemReadPermission(RegExp('.*'));

  /// Create a new filesystem permission that matches any file in a directory
  /// or one of its subdirectories.
  factory FilesystemReadPermission.directory(String dir) {
    final resolvedPath = FilesystemPermission._resolvePath(dir);
    final escaped =
        resolvedPath.replaceAll(r'\', r'\\').replaceAll(r'/', r'\/');
    return FilesystemReadPermission(RegExp('^$escaped.*'));
  }

  /// Create a new filesystem permission that matches a specific file.
  factory FilesystemReadPermission.file(String file) {
    final resolvedPath = FilesystemPermission._resolvePath(file);
    final escaped =
        resolvedPath.replaceAll(r'\', r'\\').replaceAll(r'/', r'\/');
    return FilesystemReadPermission(RegExp('^$escaped\$'));
  }

  @override
  List<String> get domains => ['filesystem:read'];

  @override
  bool match([Object? data]) {
    if (data is String) {
      final resolvedPath = FilesystemPermission._resolvePath(data);
      return matchPattern.matchAsPrefix(resolvedPath) != null;
    }
    return false;
  }

  @override
  bool operator ==(Object other) {
    if (other is FilesystemReadPermission) {
      return other.matchPattern == matchPattern && other.domains == domains;
    }
    return false;
  }

  @override
  int get hashCode => matchPattern.hashCode ^ domains.hashCode;
}

/// A permission that allows access to write a file system resource.
class FilesystemWritePermission extends FilesystemPermission {
  /// Create a new filesystem permission that matches a [Pattern].
  const FilesystemWritePermission(super.matchPattern);

  /// A permission that allows access to any file system resource.
  static final FilesystemWritePermission any =
      FilesystemWritePermission(RegExp('.*'));

  /// Create a new filesystem permission that matches any file in a directory
  /// or one of its subdirectories.
  factory FilesystemWritePermission.directory(String dir) {
    final resolvedPath = FilesystemPermission._resolvePath(dir);
    final escaped =
        resolvedPath.replaceAll(r'\', r'\\').replaceAll(r'/', r'\/');
    return FilesystemWritePermission(RegExp('^$escaped.*'));
  }

  /// Create a new filesystem permission that matches a specific file.
  factory FilesystemWritePermission.file(String file) {
    final resolvedPath = FilesystemPermission._resolvePath(file);
    final escaped =
        resolvedPath.replaceAll(r'\', r'\\').replaceAll(r'/', r'\/');
    return FilesystemWritePermission(RegExp('^$escaped\$'));
  }

  @override
  List<String> get domains => ['filesystem:write'];

  @override
  bool match([Object? data]) {
    if (data is String) {
      final resolvedPath = FilesystemPermission._resolvePath(data);
      return matchPattern.matchAsPrefix(resolvedPath) != null;
    }
    return false;
  }

  @override
  bool operator ==(Object other) {
    if (other is FilesystemWritePermission) {
      return other.matchPattern == matchPattern && other.domains == domains;
    }
    return false;
  }

  @override
  int get hashCode => matchPattern.hashCode ^ domains.hashCode;
}
