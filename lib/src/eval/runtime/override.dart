import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/model/override_spec.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:pub_semver/pub_semver.dart';

Map<String, OverrideSpec>? runtimeOverrides;
Version? runtimeOverrideVersion;

Runtime? globalRuntime;

Object? runtimeOverride(String id, [Iterable<Object?> args = const []]) {
  final spec = runtimeOverrides?[id];

  if (spec == null) {
    return null;
  }

  if (runtimeOverrideVersion != null && spec.versionConstraint != null) {
    if (!VersionConstraint.parse(spec.versionConstraint!).allows(runtimeOverrideVersion!)) {
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
