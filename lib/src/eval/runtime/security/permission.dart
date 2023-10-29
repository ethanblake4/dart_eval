import 'package:dart_eval/dart_eval.dart';

/// A rule that allows or denies a dart_eval [Runtime] access to a potentially
/// sensitive resource, such as the network or file system.
abstract class Permission {
  /// The domain specifies the type of resource, such as 'network' or
  /// 'filesystem'.
  List<String> get domains;

  /// Returns true if the permission allows access to the specified resource.
  /// If the permission is granular, the [data] parameter may be used to
  /// specify a specific resource (e.g. a URL for a network permission).
  bool match([Object? data]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Permission &&
          runtimeType == other.runtimeType &&
          domains == other.domains;

  @override
  int get hashCode => domains.hashCode;
}

/// A permission that allows access to a network resource.
class NetworkPermission implements Permission {
  /// The pattern that will be matched against the URL.
  final Pattern matchPattern;

  /// Create a new network permission that matches a [Pattern].
  const NetworkPermission(this.matchPattern);

  /// Create a new network permission that matches a [String] URL. The URL
  /// can exclude the scheme, host, path, query, or fragment, in which case
  /// the permission will match any value for that part of the URL. If more
  /// customization is needed, use the default constructor to specify a
  /// RegExp [Pattern] directly.
  factory NetworkPermission.url(String url) {
    final uri = Uri.parse(url);
    final schemePattern =
        uri.scheme == '' ? r'[-a-zA-Z0-9@:%._\+~#=]{0,256}' : uri.scheme;
    final hostPattern =
        uri.host == '' ? r'[-a-zA-Z0-9@:%._\+~#=]{1,256}' : uri.host;
    final pathPattern =
        uri.path == '' ? r'[-a-zA-Z0-9@:%_\+.~&//=]*' : uri.path;
    final queryPattern =
        uri.query == '' ? r'[-a-zA-Z0-9@:%_\+.~?&//=]*' : uri.query;
    final fragmentPattern =
        uri.fragment == '' ? r'[-a-zA-Z0-9@:%_\+.~#?&//=]*' : uri.fragment;
    final pattern =
        '^$schemePattern:?\\/*$hostPattern\\/?$pathPattern\\??$queryPattern\\#?$fragmentPattern\$';
    return NetworkPermission(RegExp(pattern));
  }

  /// A permission that allows access to any network resource.
  static final NetworkPermission any = NetworkPermission(RegExp('.*'));

  @override
  List<String> get domains => ['network'];

  @override
  bool match([Object? data]) {
    if (data is String) {
      return matchPattern.matchAsPrefix(data) != null;
    }
    return false;
  }

  @override
  bool operator ==(Object other) {
    if (other is NetworkPermission) {
      return other.matchPattern == matchPattern && other.domains == domains;
    }
    return false;
  }

  @override
  int get hashCode => matchPattern.hashCode ^ domains.hashCode;
}

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
