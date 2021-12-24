part of '../runtime.dart';

class BridgeInstantiate implements DbcOp {
  BridgeInstantiate(Runtime exec)
      : _library = exec._readInt32(),
        _subclass = exec._readInt16(),
        _name = exec._readString(),
        _constructor = exec._readString();

  BridgeInstantiate.make(this._library, this._subclass, this._name, this._constructor);

  final int _library;
  final String _name;
  final String _constructor;
  final int _subclass;

  static int len(BridgeInstantiate s) {
    return Dbc.BASE_OPLEN + Dbc.I32_LEN + Dbc.I16_LEN + Dbc.istr_len(s._name) + Dbc.istr_len(s._constructor);
  }

  @override
  void run(Runtime runtime) {
    final $subclass = runtime._vStack[runtime.scopeStackOffset + _subclass] as EvalInstance?;
    final $cls = runtime._bridgeClasses[_library]![_name]!;
    final _args = runtime._args;
    final _argsLen = _args.length;
    final _mappedArgs = List<Object?>.filled(_argsLen, null);

    for (var i = 0; i < _argsLen; i++) {
      _mappedArgs[i] = (_args[i] as EvalValue?)?.$reified;
    }

    runtime._args = [];

    final instance = $cls.constructors[_constructor]!.instantiator(_mappedArgs);
    Runtime.bridgeData[instance] = BridgeData(runtime, $subclass ?? BridgeDelegatingShim());

    runtime._vStack[runtime._stackOffset++] = instance;
  }

  @override
  String toString() => 'BridgeInstantiate (F$_library:"$_name", subclass L$_subclass, constructor=$_constructor))';
}

class PushBridgeSuperShim extends DbcOp {
  PushBridgeSuperShim(Runtime exec);

  PushBridgeSuperShim.make();

  static int LEN = Dbc.BASE_OPLEN;

  @override
  void run(Runtime runtime) {
    runtime._vStack[runtime._stackOffset++] = BridgeSuperShim();
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
    final shim = runtime._vStack[runtime.scopeStackOffset + _shimOffset] as BridgeSuperShim;
    shim.bridge = runtime._vStack[runtime.scopeStackOffset + _bridgeOffset] as BridgeInstance;
  }

  @override
  String toString() => 'ParentBridgeSuperShim (shim L$_shimOffset, bridge L$_bridgeOffset)';
}
