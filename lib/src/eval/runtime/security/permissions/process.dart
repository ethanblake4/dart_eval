import 'package:dart_eval/dart_eval_security.dart';

/// A permission that allows access to execute a process on the host system.
class ProcessRunPermission implements Permission {
  /// The pattern that will be matched against the path.
  final Pattern matchPattern;

  /// Create a new process run permission that matches a [Pattern].
  const ProcessRunPermission(this.matchPattern);

  /// A permission that allows access to run any process.
  static final ProcessRunPermission any = ProcessRunPermission(RegExp('.*'));

  /// Create a new process run permission that matches a specific executable name
  /// in any directory.
  factory ProcessRunPermission.namedExecutable(String executable) {
    return ProcessRunPermission(RegExp('$executable\$'));
  }

  @override
  List<String> get domains => ['process:run'];

  @override
  bool match([Object? data]) {
    if (data is String) {
      return matchPattern.allMatches(data).isNotEmpty;
    }
    return false;
  }

  @override
  bool operator ==(Object other) {
    if (other is ProcessRunPermission) {
      return other.matchPattern == matchPattern && other.domains == domains;
    }
    return false;
  }

  @override
  int get hashCode => matchPattern.hashCode ^ domains.hashCode;
}

/// A permission that allows access to kill a process by its PID.
class ProcessKillPermisssion implements Permission {
  /// The PID of the process to kill, or null to allow killing any process.
  final int? pid;

  const ProcessKillPermisssion([this.pid]);

  @override
  List<String> get domains => ['process:kill'];

  @override
  bool match([Object? data]) {
    if (data is int) {
      return pid == null || data == pid;
    }
    return false;
  }

  @override
  bool operator ==(Object other) {
    return other is ProcessKillPermisssion && other.pid == pid;
  }

  @override
  int get hashCode => pid.hashCode;
}
