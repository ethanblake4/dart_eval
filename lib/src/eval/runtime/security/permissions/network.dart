import 'package:dart_eval/dart_eval_security.dart';

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
    final schemePattern = uri.scheme == ''
        ? r'[-a-zA-Z0-9@:%._\+~#=]{0,256}'
        : uri.scheme;
    final hostPattern = uri.host == ''
        ? r'[-a-zA-Z0-9@:%._\+~#=]{1,256}'
        : uri.host;
    final pathPattern = uri.path == ''
        ? r'[-a-zA-Z0-9@:%_\+.~&//=]*'
        : uri.path;
    final queryPattern = uri.query == ''
        ? r'[-a-zA-Z0-9@:%_\+.~?&//=]*'
        : uri.query;
    final fragmentPattern = uri.fragment == ''
        ? r'[-a-zA-Z0-9@:%_\+.~#?&//=]*'
        : uri.fragment;
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
