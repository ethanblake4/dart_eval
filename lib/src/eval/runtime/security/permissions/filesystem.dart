import 'package:dart_eval/dart_eval_security.dart';

/// A permission that allows access to read and write a file system resource.
class FilesystemPermission implements Permission {
  /// The pattern that will be matched against the path.
  final Pattern matchPattern;

  /// Create a new filesystem permission that matches a [Pattern].
  const FilesystemPermission(this.matchPattern);

  /// A permission that allows access to any file system resource.
  static final FilesystemPermission any = FilesystemPermission(RegExp('.*'));

  /// Create a new filesystem permission that matches any file in a directory
  /// or one of its subdirectories.
  factory FilesystemPermission.directory(String dir) {
    final escaped = dir.replaceAll(r'\', r'\\').replaceAll(r'/', r'\/');
    return FilesystemPermission(RegExp('^$escaped.*'));
  }

  /// Create a new filesystem permission that matches a specific file.
  factory FilesystemPermission.file(String file) {
    final escaped = file.replaceAll(r'\', r'\\').replaceAll(r'/', r'\/');
    return FilesystemPermission(RegExp('^$escaped\$'));
  }

  @override
  List<String> get domains => ['filesystem:read', 'filesystem:write'];

  @override
  bool match([Object? data]) {
    if (data is String) {
      return matchPattern.matchAsPrefix(data) != null;
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
    final escaped = dir.replaceAll(r'\', r'\\').replaceAll(r'/', r'\/');
    return FilesystemReadPermission(RegExp('^$escaped.*'));
  }

  /// Create a new filesystem permission that matches a specific file.
  factory FilesystemReadPermission.file(String file) {
    final escaped = file.replaceAll(r'\', r'\\').replaceAll(r'/', r'\/');
    return FilesystemReadPermission(RegExp('^$escaped\$'));
  }

  @override
  List<String> get domains => ['filesystem:read'];

  @override
  bool match([Object? data]) {
    if (data is String) {
      return matchPattern.matchAsPrefix(data) != null;
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
    final escaped = dir.replaceAll(r'\', r'\\').replaceAll(r'/', r'\/');
    return FilesystemWritePermission(RegExp('^$escaped.*'));
  }

  /// Create a new filesystem permission that matches a specific file.
  factory FilesystemWritePermission.file(String file) {
    final escaped = file.replaceAll(r'\', r'\\').replaceAll(r'/', r'\/');
    return FilesystemWritePermission(RegExp('^$escaped\$'));
  }

  @override
  List<String> get domains => ['filesystem:write'];

  @override
  bool match([Object? data]) {
    if (data is String) {
      return matchPattern.matchAsPrefix(data) != null;
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
