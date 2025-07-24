// ignore_for_file: constant_identifier_names

part of '../runtime.dart';

class BridgeInstantiate implements EvcOp {
  BridgeInstantiate(Runtime exec)
      : _subclass = exec._readInt16(),
        _constructor = exec._readInt32();

  BridgeInstantiate.make(this._subclass, this._constructor);

  final int _subclass;
  final int _constructor;

  static int len(BridgeInstantiate s) {
    return Evc.BASE_OPLEN + Evc.I16_LEN + Evc.I32_LEN;
  }

  @override
  void run(Runtime runtime) {
    final $subclass = runtime.frame[_subclass] as $Instance?;

    final args = runtime.args;
    final argsLen = args.length;

    final mappedArgs = List<$Value?>.filled(argsLen, null);
    for (var i = 0; i < argsLen; i++) {
      mappedArgs[i] = (args[i] as $Value?);
    }

    runtime.args = [];

    final $runtimeType = 1;
    final instance =
        runtime._bridgeFunctions[_constructor](runtime, null, mappedArgs)
            as $Instance;
    Runtime.bridgeData[instance] =
        BridgeData(runtime, $runtimeType, $subclass ?? BridgeDelegatingShim());

    runtime.frame[runtime.frameOffset++] = instance;
  }

  @override
  String toString() =>
      'BridgeInstantiate (subclass L$_subclass, Ex#$_constructor))';
}

class PushBridgeSuperShim extends EvcOp {
  PushBridgeSuperShim(Runtime runtime);

  PushBridgeSuperShim.make();

  static int length = Evc.BASE_OPLEN;

  @override
  void run(Runtime runtime) {
    runtime.frame[runtime.frameOffset++] = BridgeSuperShim();
  }

  @override
  String toString() => 'PushBridgeSuperShim ()';
}

class ParentBridgeSuperShim extends EvcOp {
  ParentBridgeSuperShim(Runtime exec)
      : _shimOffset = exec._readInt16(),
        _bridgeOffset = exec._readInt16();

  ParentBridgeSuperShim.make(this._shimOffset, this._bridgeOffset);

  static const int LEN = Evc.BASE_OPLEN + Evc.I16_LEN * 2;

  final int _shimOffset;
  final int _bridgeOffset;

  @override
  void run(Runtime runtime) {
    final shim = runtime.frame[_shimOffset] as BridgeSuperShim;
    shim.bridge = runtime.frame[_bridgeOffset] as $Bridge;
  }

  @override
  String toString() =>
      'ParentBridgeSuperShim (shim L$_shimOffset, bridge L$_bridgeOffset)';
}

class InvokeExternal implements EvcOp {
  InvokeExternal(Runtime runtime) : _function = runtime._readInt32();

  InvokeExternal.make(this._function);

  static const int LEN = Evc.BASE_OPLEN + Evc.I32_LEN;

  final int _function;

  @override
  void run(Runtime runtime) {
    final args = runtime.args;
    final argsLen = args.length;

    final mappedArgs = List<$Value?>.filled(argsLen, null);
    for (var i = 0; i < argsLen; i++) {
      mappedArgs[i] = (args[i] as $Value?);
    }

    runtime.args = [];
    runtime.returnValue = null;
    final result =
        runtime._bridgeFunctions[_function](runtime, null, mappedArgs);
    if (result != null) {
      runtime.returnValue = result;
    }
  }

  @override
  String toString() => 'InvokeExternal (Ex#$_function)';
}

class Await implements EvcOp {
  Await(Runtime runtime)
      : _completerOffset = runtime._readInt16(),
        _futureOffset = runtime._readInt16();

  Await.make(this._completerOffset, this._futureOffset);

  final int _completerOffset;
  final int _futureOffset;

  static const int LEN = Evc.BASE_OPLEN + Evc.I16_LEN * 2;

  @override
  void run(Runtime runtime) {
    final completer = runtime.frame[_completerOffset] as Completer;

    // Create a continuation that holds the current program state, allowing us to resume this function after we've
    // finished awaiting the future
    final continuation = Continuation(
        programOffset: runtime._prOffset,
        frame: runtime.frame,
        frameOffset: runtime.frameOffset,
        args: []);

    var future = runtime.frame[_futureOffset] as $Future;
    _suspend(runtime, continuation, future, completer);

    // Return with the completer as the result (the following lines are a copy of the Return op code)
    runtime.returnValue = $Future.wrap(completer.future);
    runtime.stack.removeLast();
    runtime.scopeNameStack.removeLast();
    if (runtime.stack.isNotEmpty) {
      runtime.frame = runtime.stack.last;
      runtime.frameOffset = runtime.frameOffsetStack.removeLast();
    }

    final prOffset = runtime.callStack.removeLast();
    runtime.catchStack.removeLast();
    if (prOffset == -1) {
      throw ProgramExit(0);
    }
    runtime._prOffset = prOffset;
  }

  void _suspend(Runtime runtime, Continuation continuation, $Future future,
      Completer completer) async {
    try {
      final result = await future.$value;
      runtime.returnValue = result;
      runtime.frameOffset = continuation.frameOffset;
      runtime.frame = continuation.frame;
      runtime.stack.add(continuation.frame);
      runtime.scopeNameStack.add('<asynchronous gap>');

      runtime.bridgeCall(continuation.programOffset);
    } catch (e) {
      // temporary fix: this isn't correct, we need to reenter the eval loop
      completer.completeError(e);
    }
  }

  @override
  String toString() => 'Await (comp L$_completerOffset, L$_futureOffset)';
}

class Complete implements EvcOp {
  Complete(this._offset);

  final int _offset;

  @override
  void run(Runtime runtime) {
    (runtime.frame[runtime.frameOffset + _offset] as Completer).complete();
  }

  @override
  String toString() => 'Complete (L$_offset)';
}
