import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/stdlib/core.dart';

Map<String, int>? runtimeOverrides;

late final Runtime globalRuntime;

Object? runtimeOverride(String id, [Iterable<Object?> args = const []]) {
  final _fn = runtimeOverrides?[id];

  if (_fn == null) {
    return null;
  }
  globalRuntime.args.addAll(args);
  final result = globalRuntime.execute(_fn);
  if (result == null) {
    return $null();
  }
  return result;
}
