import 'package:dart_eval/dart_eval_security.dart';
import 'package:dart_eval/src/eval/utils/path_helper.dart';

/// A permission that allows access to read and write a file system resource.
class FilesystemPermission implements Permission {
  /// The allowed path pattern (absolute path to a file or directory).
  final String allowedPath;

  /// Create a new filesystem permission that matches a specific path.
  /// The path should be absolute. If relative, it will be resolved relative
  /// to the current working directory at permission creation time.
  FilesystemPermission(String path) : allowedPath = normalizePath(path);

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

  @override
  List<String> get domains => ['filesystem:read', 'filesystem:write'];

  @override
  bool match([Object? data]) {
    if (data is String) {
      return isPathAllowed(data, allowedPath);
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
  const FilesystemReadPermission._internal(super.path) : super._internal();

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
      return isPathAllowed(data, allowedPath);
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
  const FilesystemWritePermission._internal(super.path) : super._internal();

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
      return isPathAllowed(data, allowedPath);
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
