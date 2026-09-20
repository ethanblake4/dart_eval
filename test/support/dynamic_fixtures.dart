import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart' show RuntimeException;

const dynamicFixtureLibrary = 'package:dynamic_fixtures/main.dart';

final class DynamicFixtureResult {
  const DynamicFixtureResult.value(this.value) : errorType = null;
  const DynamicFixtureResult.error(this.errorType) : value = null;

  final Object? value;
  final Type? errorType;

  @override
  bool operator ==(Object other) =>
      other is DynamicFixtureResult &&
      value == other.value &&
      errorType == other.errorType;

  @override
  int get hashCode => Object.hash(value, errorType);

  @override
  String toString() =>
      errorType == null ? 'value($value)' : 'error($errorType)';
}

/// Compiles once, then executes both the fresh and serialized program forms.
List<(String, DynamicFixtureResult)> runDynamicFixture(String source) {
  return runDynamicPackages({
    'dynamic_fixtures': {'main.dart': source},
  }, entrypoint: dynamicFixtureLibrary);
}

List<(String, DynamicFixtureResult)> runDynamicPackages(
  Map<String, Map<String, String>> packages, {
  required String entrypoint,
}) {
  final program = Compiler().compile(packages);
  return [
    for (final (label, runtime) in [
      ('fresh', Runtime.ofProgram(program)),
      ('serialized', Runtime(program.write().buffer)),
    ])
      (label, _execute(runtime, entrypoint)),
  ];
}

DynamicFixtureResult _execute(Runtime runtime, String entrypoint) {
  try {
    return DynamicFixtureResult.value(runtime.executeLib(entrypoint, 'main'));
  } on RuntimeException catch (error) {
    return DynamicFixtureResult.error(error.caughtException.runtimeType);
  } catch (error) {
    return DynamicFixtureResult.error(error.runtimeType);
  }
}
