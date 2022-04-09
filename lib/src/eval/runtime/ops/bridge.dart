part of '../runtime.dart';

class BridgeInstantiate implements DbcOp {
  BridgeInstantiate(Runtime exec) :
        _subclass = exec._readInt16(),
        _constructor = exec._readInt32();

  BridgeInstantiate.make(this._subclass, this._constructor);

  final int _subclass;
  final int _constructor;

  static int len(BridgeInstantiate s) {
    return Dbc.BASE_OPLEN + Dbc.I16_LEN + Dbc.I32_LEN;
  }

  @override
  void run(Runtime runtime) {
    final $subclass = runtime.frame[_subclass] as $Instance?;

    final _args = runtime.args;
    final _argsLen = _args.length;

    final _mappedArgs = List<$Value?>.filled(_argsLen, null);
    for (var i = 0; i < _argsLen; i++) {
      _mappedArgs[i] = (_args[i] as $Value?);
    }

    runtime.args = [];

    final $runtimeType = 1;
    final instance = runtime._bridgeFunctions[_constructor].func(runtime, null, _mappedArgs) as $Instance;
    Runtime.bridgeData[instance] = BridgeData(runtime, $runtimeType, $subclass ?? BridgeDelegatingShim());

    runtime.frame[runtime.frameOffset++] = instance;
  }

  @override
  String toString() => 'BridgeInstantiate (subclass L$_subclass, fn=$_constructor))';
}

class PushBridgeSuperShim extends DbcOp {
  PushBridgeSuperShim(Runtime runtime);

  PushBridgeSuperShim.make();

  static int LEN = Dbc.BASE_OPLEN;

  @override
  void run(Runtime runtime) {
    runtime.frame[runtime.frameOffset++] = BridgeSuperShim();
  }

  @override
  String toString() => 'PushBridgeSuperShim ()';
}

class ParentBridgeSuperShim extends DbcOp {
  ParentBridgeSuperShim(Runtime exec)
      : _shimOffset = exec._readInt16(),
        _bridgeOffset = exec._readInt16();

  ParentBridgeSuperShim.make(this._shimOffset, this._bridgeOffset);

  static const int LEN = Dbc.BASE_OPLEN + Dbc.I16_LEN * 2;

  final int _shimOffset;
  final int _bridgeOffset;

  @override
  void run(Runtime runtime) {
    final shim = runtime.frame[_shimOffset] as BridgeSuperShim;
    shim.bridge = runtime.frame[_bridgeOffset] as $Bridge;
  }

  @override
  String toString() => 'ParentBridgeSuperShim (shim L$_shimOffset, bridge L$_bridgeOffset)';
}
