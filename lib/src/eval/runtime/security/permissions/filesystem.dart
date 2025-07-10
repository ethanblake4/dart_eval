import 'dart:io';
import 'package:dart_eval/dart_eval_security.dart';
import 'package:dart_eval/src/eval/utils/path_helper.dart';
import 'package:path/path.dart' as p;

/// A permission that allows access to read and write a file system resource.
class FilesystemPermission implements Permission {
  /// The allowed path pattern (absolute path to a file or directory).
  final String allowedPath;

  /// Create a new filesystem permission that matches a specific path.
  /// The path should be absolute. If relative, it will be resolved relative
  /// to the current working directory at permission creation time.
  FilesystemPermission(String path) : allowedPath = _normalizePath(path);

  /// A permission that allows access to any file system resource.
  static final FilesystemPermission any = FilesystemPermission._internal('');

  /// Internal constructor for special cases like 'any' permission
  const FilesystemPermission._internal(this.allowedPath);

  /// Create a new filesystem permission that matches any file in a directory
  /// or one of its subdirectories.
  factory FilesystemPermission.directory(String dir) {
    return FilesystemPermission(dir);
  }

  /// Create a new filesystem permission that matches a specific file.
  factory FilesystemPermission.file(String file) {
    return FilesystemPermission(file);
  }

  /// Normalize and resolve the path to an absolute path
  static String _normalizePath(String path) {
    if (path.isEmpty) return '';

    // Convert to absolute path and normalize
    String absolutePath = p.isAbsolute(path) ? path : p.absolute(path);

    // Normalize to resolve .. and . components and remove redundant separators
    String normalized = p.normalize(absolutePath);

    // Try to resolve symlinks by walking up the directory tree
    String resolved = resolvePathRecursively(normalized);

    return resolved;
  }

  /// Check if a given path is allowed by this permission
  bool _isPathAllowed(String targetPath) {
    // Empty allowedPath means allow everything (any permission)
    if (allowedPath.isEmpty) return true;

    // Normalize both paths using the same resolution method
    String normalizedTarget = _normalizePath(targetPath);
    String normalizedAllowed = allowedPath;

    // Both paths should now be consistently resolved (with symlinks resolved when possible)

    // Ensure both paths end consistently for directory checks
    // If allowed path is a directory, ensure it ends with separator for proper containment check
    if (normalizedAllowed.isNotEmpty &&
        !normalizedAllowed.endsWith(p.separator)) {
      // Check if it's a directory or if we should treat it as one
      bool isDirectory = false;
      try {
        isDirectory = Directory(normalizedAllowed).existsSync();
      } catch (e) {
        // Ignore exceptions and fall through to heuristic check
      }

      // If directory doesn't exist, use heuristic: assume it's a directory if basename has no extension
      if (!isDirectory && !p.basename(normalizedAllowed).contains('.')) {
        isDirectory = true;
      }

      if (isDirectory) {
        normalizedAllowed = normalizedAllowed + p.separator;
      }
    }

    // Check if target is the same as or within allowed path
    if (normalizedTarget ==
        normalizedAllowed.replaceAll(RegExp(r'[/\\]+$'), '')) {
      return true; // Exact match
    }

    // Check if target is within allowed directory
    if (normalizedAllowed.endsWith(p.separator)) {
      return normalizedTarget.startsWith(normalizedAllowed);
    }

    // For file permissions, check exact match
    return normalizedTarget == normalizedAllowed;
  }

  @override
  List<String> get domains => ['filesystem:read', 'filesystem:write'];

  @override
  bool match([Object? data]) {
    if (data is String) {
      return _isPathAllowed(data);
    }
    return false;
  }

  @override
  bool operator ==(Object other) {
    if (other is FilesystemPermission) {
      return other.allowedPath == allowedPath &&
          other.runtimeType == runtimeType;
    }
    return false;
  }

  @override
  int get hashCode => allowedPath.hashCode ^ runtimeType.hashCode;
}

/// A permission that allows access to read a file system resource.
class FilesystemReadPermission extends FilesystemPermission {
  /// Create a new filesystem read permission that matches a specific path.
  FilesystemReadPermission(super.path);

  /// A permission that allows read access to any file system resource.
  static final FilesystemReadPermission any =
      FilesystemReadPermission._internal('');

  /// Internal constructor for special cases
  const FilesystemReadPermission._internal(String path) : super._internal(path);

  /// Create a new filesystem permission that matches any file in a directory
  /// or one of its subdirectories.
  factory FilesystemReadPermission.directory(String dir) {
    return FilesystemReadPermission(dir);
  }

  /// Create a new filesystem permission that matches a specific file.
  factory FilesystemReadPermission.file(String file) {
    return FilesystemReadPermission(file);
  }

  @override
  List<String> get domains => ['filesystem:read'];

  @override
  bool match([Object? data]) {
    if (data is String) {
      return _isPathAllowed(data);
    }
    return false;
  }

  @override
  bool operator ==(Object other) {
    if (other is FilesystemReadPermission) {
      return other.allowedPath == allowedPath;
    }
    return false;
  }

  @override
  int get hashCode => allowedPath.hashCode ^ runtimeType.hashCode;
}

/// A permission that allows access to write a file system resource.
class FilesystemWritePermission extends FilesystemPermission {
  /// Create a new filesystem write permission that matches a specific path.
  FilesystemWritePermission(super.path);

  /// A permission that allows write access to any file system resource.
  static final FilesystemWritePermission any =
      FilesystemWritePermission._internal('');

  /// Internal constructor for special cases
  const FilesystemWritePermission._internal(String path)
      : super._internal(path);

  /// Create a new filesystem permission that matches any file in a directory
  /// or one of its subdirectories.
  factory FilesystemWritePermission.directory(String dir) {
    return FilesystemWritePermission(dir);
  }

  /// Create a new filesystem permission that matches a specific file.
  factory FilesystemWritePermission.file(String file) {
    return FilesystemWritePermission(file);
  }

  @override
  List<String> get domains => ['filesystem:write'];

  @override
  bool match([Object? data]) {
    if (data is String) {
      return _isPathAllowed(data);
    }
    return false;
  }

  @override
  bool operator ==(Object other) {
    if (other is FilesystemWritePermission) {
      return other.allowedPath == allowedPath;
    }
    return false;
  }

  @override
  int get hashCode => allowedPath.hashCode ^ runtimeType.hashCode;
}
