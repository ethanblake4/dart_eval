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
