import 'package:dart_eval/dart_eval.dart';

/// A rule that allows or denies a dart_eval [Runtime] access to a potentially
/// sensitive resource, such as the network or file system.
abstract class Permission {
  /// The domain specifies the type of resource, such as 'network' or
  /// 'filesystem'.
  String get domain;

  /// Returns true if the permission allows access to the specified resource.
  /// If the permission is granular, the [data] parameter may be used to
  /// specify a specific resource (e.g. a URL for a network permission).
  bool match([Object? data]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Permission && runtimeType == other.runtimeType && domain == other.domain;

  @override
  int get hashCode => domain.hashCode;
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
    final schemePattern = uri.scheme == '' ? r'[-a-zA-Z0-9@:%._\+~#=]{0,256}' : uri.scheme;
    final hostPattern = uri.host == '' ? r'[-a-zA-Z0-9@:%._\+~#=]{1,256}' : uri.host;
    final pathPattern = uri.path == '' ? r'[-a-zA-Z0-9@:%_\+.~&//=]*' : uri.path;
    final queryPattern = uri.query == '' ? r'[-a-zA-Z0-9@:%_\+.~?&//=]*' : uri.query;
    final fragmentPattern = uri.fragment == '' ? r'[-a-zA-Z0-9@:%_\+.~#?&//=]*' : uri.fragment;
    final pattern = '^$schemePattern:?\\/*$hostPattern\\/?$pathPattern\\??$queryPattern\\#?$fragmentPattern\$';
    return NetworkPermission(RegExp(pattern));
  }

  /// A permission that allows access to any network resource.
  static final NetworkPermission any = NetworkPermission(RegExp('.*'));

  @override
  String get domain => 'network';

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
      return other.matchPattern == matchPattern && other.domain == domain;
    }
    return false;
  }

  @override
  int get hashCode => matchPattern.hashCode ^ domain.hashCode;
}

/// A permission that allows access to a file system resource.
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
  String get domain => 'filesystem';

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
      return other.matchPattern == matchPattern && other.domain == domain;
    }
    return false;
  }

  @override
  int get hashCode => matchPattern.hashCode ^ domain.hashCode;
}
