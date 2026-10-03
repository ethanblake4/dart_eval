import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:dart_eval/src/eval/shared/library_environment.dart';

/// Environment bindings for one SDK fixture's SharedOptions definitions.
/// Const environment constructors use bridge calls in dart_eval, so these
/// definitions remain scoped to the fixture runtime, including imported files.
class SdkEnvironmentPlugin extends EvalPlugin {
  SdkEnvironmentPlugin(String source)
    : values = {
        for (final options in RegExp(
          r'^//\s*SharedOptions=(.*)$',
          multiLine: true,
        ).allMatches(source))
          for (final define in RegExp(
            r'(?:^|\s)-D([^\s=]+)=([^\s]*)',
          ).allMatches(options[1]!))
            define[1]!: define[2]!,
      };

  final Map<String, String> values;

  @override
  String get identifier => 'sdk_language.environment';

  @override
  void configureForCompile(BridgeDeclarationRegistry registry) {}

  @override
  void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters('dart:core', 'bool.hasEnvironment', (
      runtime,
      r,
      s,
      c,
    ) {
      final name = (r as $Value).$value as String;
      return values.containsKey(name)
          ? $bool(true)
          : $bool.$hasEnvironment(runtime, r, s, c);
    });
    runtime.registerBridgeFuncRegisters('dart:core', 'bool.fromEnvironment', (
      runtime,
      r,
      s,
      c,
    ) {
      final name = (r as $Value).$value as String;
      final value = values[name];
      return value == null
          ? $bool.$fromEnvironment(runtime, r, s, c)
          : $bool(bool.tryParse(value) ?? (s as $Value?)?.$value ?? false);
    });
    runtime.registerBridgeFuncRegisters('dart:core', 'int.fromEnvironment', (
      runtime,
      r,
      s,
      c,
    ) {
      final name = (r as $Value).$value as String;
      final value = values[name];
      return value == null
          ? $int.$fromEnvironment(runtime, r, s, c)
          : $int(int.tryParse(value) ?? (s as $Value?)?.$value ?? 0);
    });
    runtime.registerBridgeFuncRegisters('dart:core', 'String.fromEnvironment', (
      runtime,
      r,
      s,
      c,
    ) {
      final name = (r as $Value).$value as String;
      return $String(
        values[name] ??
            sdkLibraryEnvironment[name] ??
            String.fromEnvironment(
              name,
              defaultValue: (s as $Value?)?.$value ?? '',
            ),
      );
    });
  }
}
