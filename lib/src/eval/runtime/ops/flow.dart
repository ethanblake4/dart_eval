// ignore_for_file: constant_identifier_names

part of '../runtime.dart';

/// Static call opcode that jumps to another location in the program and adds the prior location to the call stack.
class Call implements EvcOp {
  Call(Runtime runtime) : _offset = runtime._readInt32();

  Call.make(this._offset);

  final int _offset;

  static final int length = Evc.BASE_OPLEN + Evc.I32_LEN;

  @override
  void run(Runtime runtime) {
    runtime.callStack.add(runtime._prOffset);
    runtime.catchStack.add([]);
    runtime._prOffset = _offset;
  }

  @override
  String toString() => 'Call (@$_offset)';
}

/// Push a new frame onto the stack, populated with any current args
class PushScope implements EvcOp {
  PushScope(Runtime runtime)
      : sourceFile = runtime._readInt32(),
        sourceOffset = runtime._readInt32(),
        frName = runtime._readString();

  PushScope.make(this.sourceFile, this.sourceOffset, this.frName);

  final int sourceFile;
  final int sourceOffset;
  final String frName;

  static int len(PushScope s) {
    return Evc.BASE_OPLEN + Evc.I32_LEN * 2 + Evc.istrLen(s.frName);
  }

  @override
  void run(Runtime runtime) {
    final frame = List<Object?>.filled(255, null);
    runtime.stack.add(frame);
    runtime.scopeNameStack.add(frName);
    runtime.frame = frame;
    runtime.frameOffsetStack.add(runtime.frameOffset);
    runtime.frameOffset = runtime.args.length;
    final args = runtime.args;
    for (var i = 0; i < args.length; i++) {
      frame[i] = args[i];
    }
    runtime.args = [];
  }

  @override
  String toString() => "PushScope (F$sourceFile:$sourceOffset, '$frName')";
}

/// Capture a reference to the previous stack frame (as a List) into the specified register of the current stack frame.
/// Typically used to implement closures
class PushCaptureScope implements EvcOp {
  PushCaptureScope(Runtime exec);

  PushCaptureScope.make();

  static int length = Evc.BASE_OPLEN;

  @override
  void run(Runtime exec) {
    exec.frame[exec.frameOffset++] = exec.stack[exec.stack.length - 2];
  }

  @override
  String toString() => 'PushCaptureScope ()';
}

/// Pop the current frame off the stack
class PopScope implements EvcOp {
  PopScope(Runtime runtime);

  PopScope.make();

  static const int LEN = Evc.BASE_OPLEN;

  @override
  void run(Runtime runtime) {
    runtime.stack.removeLast();
    runtime.scopeNameStack.removeLast();
    if (runtime.stack.isNotEmpty) {
      runtime.frame = runtime.stack.last;
      runtime.frameOffset = runtime.frameOffsetStack.removeLast();
    }
  }

  @override
  String toString() => 'PopScope()';
}

/// Jump to constant program offset if [_location] is not null
class JumpIfNonNull implements EvcOp {
  JumpIfNonNull(Runtime exec)
      : _location = exec._readInt16(),
        _offset = exec._readInt32();

  JumpIfNonNull.make(this._location, this._offset);

  final int _location;
  final int _offset;

  static const int LEN = Evc.I16_LEN + Evc.I32_LEN;

  // Conditional move
  @override
  void run(Runtime exec) {
    if (exec.frame[_location] != null) {
      exec._prOffset = _offset;
    }
  }

  @override
  String toString() => 'JumpIfNonNull (@$_offset if L$_location != null)';
}

/// Jump to constant program offset if [_location] is false
class JumpIfFalse implements EvcOp {
  JumpIfFalse(Runtime exec)
      : _location = exec._readInt16(),
        _offset = exec._readInt32();

  JumpIfFalse.make(this._location, this._offset);

  final int _location;
  final int _offset;

  static const int LEN = Evc.I16_LEN + Evc.I32_LEN;

  // Conditional move
  @override
  void run(Runtime exec) {
    if (exec.frame[_location] == false) {
      exec._prOffset = _offset;
    }
  }

  @override
  String toString() => 'JumpIfFalse (@$_offset if L$_location == false)';
}

// Exit program
class Exit implements EvcOp {
  Exit(Runtime exec) : _location = exec._readInt16();

  Exit.make(this._location);

  final int _location;

  static const int LEN = Evc.BASE_OPLEN + Evc.I16_LEN;

  @override
  void run(Runtime exec) {
    throw ProgramExit(exec.frame[_location] as int);
  }

  @override
  String toString() => 'Exit (L$_location)';
}

/// Return from a function. This does several things:
/// 1. Sets the program's return value to the value at [_location], or null if [_location] is -1
/// 2. Pops the current frame off the stack, just like [PopScope]
/// 3. Pops the last offset from the call stack and jumps to it, unless it is -1 in which case [Exit] is mimicked
class Return implements EvcOp {
  Return(Runtime exec) : _location = exec._readInt16();

  Return.make(this._location);

  final int _location;

  static const int LEN = Evc.BASE_OPLEN + Evc.I16_LEN;

  @override
  void run(Runtime runtime) {
    if (_location > -1) {
      runtime.returnValue = runtime.frame[_location];
    } else if (_location == -1 || _location == -3) {
      runtime.returnValue = null;
    } else {
      if (runtime.rethrowException != null) {
        runtime.$throw(runtime.rethrowException!);
        return;
      }
      if (runtime.catchControlFlowOutcome != 1) {
        return;
      }
      runtime.returnValue = runtime.returnFromCatch;
    }

    runtime.stack.removeLast();
    runtime.scopeNameStack.removeLast();
    if (runtime.stack.isNotEmpty) {
      runtime.frame = runtime.stack.last;
      runtime.frameOffset = runtime.frameOffsetStack.removeLast();
    }

    runtime.catchStack.removeLast();
    if (runtime.inCatch) {
      if (_location != -3) {
        runtime.catchControlFlowOutcome = 1;
      }
      runtime.inCatch = false;
    }

    final prOffset = runtime.callStack.removeLast();
    if (prOffset == -1) {
      throw ProgramExit(0);
    }
    runtime._prOffset = prOffset;
  }

  @override
  String toString() => 'Return (L$_location)';
}

class ReturnAsync implements EvcOp {
  ReturnAsync(Runtime exec)
      : _location = exec._readInt16(),
        _completerOffset = exec._readInt16();

  ReturnAsync.make(this._location, this._completerOffset);

  final int _location;
  final int _completerOffset;

  static const int LEN = Evc.BASE_OPLEN + Evc.I16_LEN * 2;

  @override
  void run(Runtime runtime) {
    final completer = runtime.frame[_completerOffset] as Completer;
    final rv = _location == -1 ? null : runtime.frame[_location];
    runtime.returnValue = $Future.wrap(completer.future);

    runtime.stack.removeLast();
    runtime.scopeNameStack.removeLast();
    if (runtime.stack.isNotEmpty) {
      runtime.frame = runtime.stack.last;
      runtime.frameOffset = runtime.frameOffsetStack.removeLast();
    }

    _suspend(completer, rv);

    final prOffset = runtime.callStack.removeLast();
    runtime.catchStack.removeLast();
    if (runtime.inCatch) {
      if (_location != -3) {
        runtime.catchControlFlowOutcome = 1;
      }
      runtime.inCatch = false;
    }
    if (prOffset == -1) {
      throw ProgramExit(0);
    }
    runtime._prOffset = prOffset;
  }

  void _suspend(Completer completer, dynamic value) async {
    // create an async gap
    await Future.value(null);

    if (!completer.isCompleted) {
      completer.complete(value);
    }
  }

  @override
  String toString() =>
      'ReturnAsync (L$_location, completer L$_completerOffset)';
}

// Jump to constant program offset
class JumpConstant implements EvcOp {
  JumpConstant(Runtime exec) : _offset = exec._readInt32();

  JumpConstant.make(this._offset);

  static const int LEN = Evc.BASE_OPLEN + Evc.I32_LEN;

  final int _offset;

  @override
  void run(Runtime exec) {
    exec._prOffset = _offset;
  }

  @override
  String toString() => 'JumpConstant (@$_offset)';
}

class PushFunctionPtr implements EvcOp {
  PushFunctionPtr(Runtime exec) : _offset = exec._readInt32();

  PushFunctionPtr.make(this._offset);

  static const int LEN = Evc.BASE_OPLEN + Evc.I32_LEN;

  final int _offset;

  @override
  void run(Runtime runtime) {
    final args = runtime.args;
    final pAT = runtime.constantPool[args[1] as int] as List;
    final posArgTypes = [for (final json in pAT) RuntimeType.fromJson(json)];
    final snAT = runtime.constantPool[args[3] as int] as List;
    final sortedNamedArgTypes = [
      for (final json in snAT) RuntimeType.fromJson(json)
    ];

    runtime.frame[runtime.frameOffset++] = EvalFunctionPtr(
        runtime.frame,
        _offset,
        args[0] as int,
        posArgTypes,
        (runtime.constantPool[args[2] as int] as List).cast(),
        sortedNamedArgTypes);

    runtime.args = [];
  }

  @override
  String toString() => 'PushFunctionPtr (@$_offset)';
}

class Try implements EvcOp {
  Try(Runtime exec) : _catchOffset = exec._readInt32();

  Try.make(this._catchOffset);

  static const int LEN = Evc.BASE_OPLEN + Evc.I32_LEN;

  final int _catchOffset;

  @override
  void run(Runtime runtime) {
    runtime.catchControlFlowOutcome = -1;
    runtime.frameOffsetStack.add(runtime.frameOffset);
    if (_catchOffset > -1) {
      runtime.catchStack.last.add(_catchOffset);
    }
  }

  @override
  String toString() => 'Try (catch: @$_catchOffset)';
}

class Throw implements EvcOp {
  Throw(Runtime exec) : _location = exec._readInt16();

  Throw.make(this._location);

  static const int LEN = Evc.BASE_OPLEN + Evc.I16_LEN;

  final int _location;

  @override
  void run(Runtime runtime) => runtime.$throw(runtime.frame[_location]);

  @override
  String toString() => 'Throw (L$_location)';
}

class PopCatch implements EvcOp {
  PopCatch(Runtime exec);

  PopCatch.make();

  static const int LEN = Evc.BASE_OPLEN;

  @override
  void run(Runtime runtime) {
    runtime.catchStack.last.removeLast();
  }

  @override
  String toString() => 'PopCatch()';
}

class Assert implements EvcOp {
  Assert(Runtime exec)
      : _valueOffset = exec._readInt16(),
        _exceptionOffset = exec._readInt16();

  Assert.make(this._valueOffset, this._exceptionOffset);

  static const int LEN = Evc.BASE_OPLEN + Evc.I16_LEN * 2;

  final int _valueOffset;
  final int _exceptionOffset;

  @override
  void run(Runtime runtime) {
    if (!(runtime.frame[_valueOffset] as bool)) {
      runtime.$throw(runtime.frame[_exceptionOffset]);
    }
  }

  @override
  String toString() => 'Assert (!L$_valueOffset, L$_exceptionOffset)';
}

class PushFinally implements EvcOp {
  PushFinally(Runtime exec) : _tryOffset = exec._readInt32();

  PushFinally.make(this._tryOffset);

  static const int LEN = Evc.BASE_OPLEN + Evc.I32_LEN;

  final int _tryOffset;

  @override
  void run(Runtime runtime) {
    runtime.catchStack.last.add(-runtime._prOffset);
    runtime.callStack.add(runtime._prOffset);
    runtime.catchStack.add([]);
    runtime.stack.add(runtime.stack.last);
    runtime.scopeNameStack.add(runtime.scopeNameStack.last);
    runtime.frameOffsetStack.add(runtime.frameOffsetStack.last);
    runtime._prOffset = _tryOffset;
  }

  @override
  String toString() => 'PushFinally (try @$_tryOffset)';
}

class PushReturnFromCatch implements EvcOp {
  PushReturnFromCatch(Runtime exec);

  PushReturnFromCatch.make();

  static const int LEN = Evc.BASE_OPLEN;

  @override
  void run(Runtime runtime) {
    runtime.returnFromCatch = runtime.returnValue;
  }

  @override
  String toString() => 'PushReturnFromCatch ()';
}
