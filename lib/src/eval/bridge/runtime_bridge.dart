// ignore_for_file: non_constant_identifier_names

import 'package:dart_eval/dart_eval_bridge.dart';

/// A bridge class can be extended inside the dart_eval VM and used both in
/// and outside of it.
mixin $Bridge<T> on Object implements $Value, $Instance {
  $Value? $bridgeGet(
    Runtime runtime,
    String identifier,
  );

  void $bridgeSet(
    Runtime runtime,
    String identifier,
    $Value value,
  );

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    try {
      final BridgeData? bridgeData = Runtime.bridgeData[this];

      if (bridgeData == null) {
        return $bridgeGet(runtime, identifier);
      }

      if (bridgeData.subclass == null) {
        throw ("Subclass NOT FOUND: $bridgeData");
      }

      return bridgeData.subclass!.$getProperty(runtime, identifier);
    } on UnimplementedError catch (_) {
      return $bridgeGet(runtime, identifier);
    }
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    try {
      BridgeData? bridgeData = Runtime.bridgeData[this];

      if (bridgeData == null) {
        _autoRegisterBridge(runtime);
        bridgeData = Runtime.bridgeData[this];
      }

      if (bridgeData == null) {
        $bridgeSet(runtime, identifier, value);
        return;
      }

      if (bridgeData.subclass == null) {
        throw ("Subclass NOT FOUND: $bridgeData");
      }

      return bridgeData.subclass!.$setProperty(runtime, identifier, value);
    } on UnimplementedError catch (_) {
      $bridgeSet(runtime, identifier, value);
    }
  }

  /// Auto-registra objetos bridge externos no Runtime.bridgeData
  /// para garantir consistência nas modificações de propriedades
  void _autoRegisterBridge(Runtime runtime) {
    if (Runtime.bridgeData[this] == null) {
      Runtime.bridgeData[this] = BridgeData(
        runtime,
        1, // $runtimeType padrão para objetos bridge externos
        BridgeExternalShim(this),
      );
    }
  }

  dynamic $_get(String prop) {
    final runtime = Runtime.bridgeData[this]!.runtime;
    return ($getProperty(runtime, prop) as $Value).$reified;
  }

  void $_set(String prop, $Value value) {
    final runtime = Runtime.bridgeData[this]!.runtime;
    $setProperty(runtime, prop, value);
  }

  dynamic $_invoke(String method, List<$Value?> args) {
    Runtime? bridgeRuntime = Runtime.bridgeData[this]?.runtime;

    if (bridgeRuntime == null) {
      throw ("BridgeRuntime NOT FOUND: $this");
    }

    final $Value? value = $getProperty(bridgeRuntime, method);

    if (value is EvalFunction) {
      final EvalFunction evalFunction =
          ($getProperty(bridgeRuntime, method) as EvalFunction);

      dynamic result =
          evalFunction.call(bridgeRuntime, this, [this, ...args])?.$reified;

      return result;
    } else {
      return value?.$reified;
    }
  }

  @override
  $Bridge get $value => this;

  @override
  T get $reified => this as T;

  Runtime get $runtime => Runtime.bridgeData[this]!.runtime;

  @override
  int $getRuntimeType(Runtime runtime) {
    final data = Runtime.bridgeData[this];
    return data?.subclass?.$getRuntimeType(runtime) ?? data?.$runtimeType ?? 0;
  }
}

class BridgeSuperShim implements $Instance {
  BridgeSuperShim();

  late $Bridge bridge;

  @override
  $Value? $getProperty(Runtime runtime, String name) =>
      bridge.$bridgeGet(runtime, name);

  @override
  void $setProperty(Runtime runtime, String name, $Value value) =>
      bridge.$bridgeSet(runtime, name, value);

  @override
  $Bridge get $reified => bridge;

  @override
  $Bridge get $value => bridge;

  @override
  int $getRuntimeType(Runtime runtime) => bridge.$getRuntimeType(runtime);
}

class BridgeDelegatingShim implements $Instance {
  const BridgeDelegatingShim();

  @override
  $Value? $getProperty(Runtime runtime, String name) =>
      throw UnimplementedError();

  @override
  void $setProperty(Runtime runtime, String name, $Value value) =>
      throw UnimplementedError();

  @override
  $Bridge get $reified => throw UnimplementedError();

  @override
  $Bridge get $value => throw UnimplementedError();

  @override
  int $getRuntimeType(Runtime runtime) => throw UnimplementedError();
}

/// Shim para objetos bridge criados externamente que delega
/// de volta para os métodos $bridgeGet/$bridgeSet do objeto original
class BridgeExternalShim implements $Instance {
  final $Bridge _bridge;

  const BridgeExternalShim(this._bridge);

  @override
  $Value? $getProperty(Runtime runtime, String name) =>
      _bridge.$bridgeGet(runtime, name);

  @override
  void $setProperty(Runtime runtime, String name, $Value value) =>
      _bridge.$bridgeSet(runtime, name, value);

  @override
  $Bridge get $reified => _bridge;

  @override
  $Bridge get $value => _bridge;

  @override
  int $getRuntimeType(Runtime runtime) => _bridge.$getRuntimeType(runtime);
}

class BridgeData {
  final Runtime runtime;
  final $Instance? subclass;
  final int $runtimeType;

  const BridgeData(this.runtime, this.$runtimeType, this.subclass);
}
