// ignore_for_file: depend_on_referenced_packages

import 'package:meta/meta.dart';

import '../../../dart_eval_bridge.dart';

class InstanceFunctionDefaultProps<T extends $Value>
    implements IInstanceDefaultProps {
  BridgeFunctionDeclaration? _declaration;

  BridgeFunctionDeclaration get declaration {
    _declaration ??= BridgeFunctionDeclaration(
      fileName,
      functionName,
      functionDef,
    );

    return _declaration!;
  }

  @mustBeOverridden
  BridgeFunctionDef get functionDef => throw UnimplementedError();

  @mustBeOverridden
  String get fileName => throw UnimplementedError();

  @mustBeOverridden
  String get functionName => throw UnimplementedError();

  @mustBeOverridden
  $Value? processFunction(
    Runtime runtime,
    $Value? target,
    List<$Value?> args,
  ) =>
      throw UnimplementedError();

  @override
  void defineCompiler(BridgeDeclarationRegistry registry) {
    registry.defineBridgeTopLevelFunction(
      BridgeFunctionDeclaration(
        fileName,
        functionName,
        functionDef,
      ),
    );
  }

  @override
  void registerRuntime(Runtime runtime) {
    runtime.registerBridgeFunc(
      fileName,
      functionName,
      processFunction,
    );
  }
}
