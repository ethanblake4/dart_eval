import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/model/override_spec.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:pub_semver/pub_semver.dart';

/// Mapping of runtime overrides, which can be used to dynamically swap
/// implementations of functions at runtime by a unique ID
Map<String, OverrideSpec>? runtimeOverrides;

/// The current semver [Version] of your app. Overriden functions can specify
/// a version constraint in their @RuntimeOverride annotation which will be
/// checked against this version to determine if the override should apply.
Version? runtimeOverrideVersion;

/// The global runtime instance to be used for overrides
Runtime? globalRuntime;

/// Lookup and execute an overriden function on the [globalRuntime] by its ID
Object? runtimeOverride(String id, [Iterable<Object?> args = const []]) {
  final spec = runtimeOverrides?[id];

  if (spec == null) {
    return null;
  }

  if (runtimeOverrideVersion != null && spec.versionConstraint != null) {
    if (!VersionConstraint.parse(
      spec.versionConstraint!,
    ).allows(runtimeOverrideVersion!)) {
      return null;
    }
  }

  globalRuntime!.args.addAll(args);
  final result = globalRuntime!.execute(spec.offset);
  if (result == null) {
    return $null();
  }
  if (result is List && result is! $List) {
    return $List.wrap(result).$reified;
  }
  return result is $Value ? result.$reified : result;
}
