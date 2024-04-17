import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/runtime/ops/xval_ops.dart';

enum Size {
  u8,
  u16,
  u32,
  u64,
  i8,
  i16,
  i32,
  i64,
}

enum Register { r0, r1, r2 }

const _instructionsModifyingR0 = {
  Xops.lc0,
  Xops.lii0,
  Xops.lii0p,
  Xops.ls0,
  Xops.lprop0,
  Xops.iadd,
  Xops.ilt,
  Xops.ilteq,
};

const _instructionsUsingR0 = {
  Xops.push0,
  Xops.iadd,
  Xops.ilt,
  Xops.ilteq,
};

class Assembler {
  Assembler({this.optimizationLevel = 2});
  final List<List<int>> program = [];
  final int optimizationLevel;
  int prLen = 0;

  int? _findLastNot(
      {bool using = false,
      bool r0 = false,
      bool r1 = false,
      bool stackPtr = false,
      List<int> stack = const [],
      int limit = 10}) {
    var i = program.length - 1;
    var count = 0;
    var stackOffset = 0;
    while (i >= 0 && count < limit) {
      final instr = program[i][0];

      if ({Xops.jump, Xops.jumpf}.contains(instr)) {
        return i;
      }

      if (r0 &&
          {..._instructionsModifyingR0, if (using) ..._instructionsUsingR0}
              .contains(instr)) {
        return i;
      }

      if (r1 &&
          {
            Xops.lc1,
            Xops.lii1,
            Xops.lii1p,
            Xops.ls1,
            if (using) ...{
              Xops.push1,
              Xops.iadd,
              Xops.ilt,
              Xops.ilteq,
            }
          }.contains(instr)) {
        return i;
      }

      if ({
        Xops.isp,
        Xops.push0,
        Xops.push1,
        Xops.lii0p,
        Xops.lii1p,
        if (using) ...{
          Xops.ls0,
          Xops.ls1,
          Xops.sets0,
          Xops.sets1,
        }
      }.contains(instr)) {
        if (stackPtr) {
          return i;
        }
        stackOffset++;
      }

      if (instr == Xops.sets0 ||
          instr == Xops.sets1 ||
          (using && (instr == Xops.ls0 || instr == Xops.ls1))) {
        if (stack.contains(program[i][1] - stackOffset)) {
          return i;
        }
      }

      i--;
      count++;
    }
    return null;
  }

  int? _findLastOfTypeNot(int type,
      {bool using = false,
      bool r0 = false,
      bool r1 = false,
      bool stackPtr = false,
      List<int> stack = const [],
      int limit = 10}) {
    final instrs = _findLastNot(
        using: using,
        r0: r0,
        r1: r1,
        stackPtr: stackPtr,
        stack: stack,
        limit: limit);
    if (instrs == null) {
      return null;
    }

    var i = program.length;
    var count = 0;
    while (i >= 0 && count < instrs) {
      final instr = program[i][0];
      if (instr == type) {
        return i;
      }
      i--;
      count++;
    }
    return null;
  }

  void scope(int len, int name) {
    program.add([Xops.scope, len, name >> 8, name & 0xff]);
    prLen += 4;
  }

  void loadConstant0(int i) {
    program.add([Xops.lc0, i >> 8, i & 0xff]);
    prLen += 3;
  }

  void lc1(int i) {
    program.add([Xops.lc1, i >> 8, i & 0xff]);
    prLen += 3;
  }

  void lg0(int i) {
    program.add([Xops.lg0, i >> 8, i & 0xff]);
    prLen += 3;
  }

  void ls0(int ptr) {
    final last0 = _findLastNot(using: true, r0: true, stack: [ptr]);

    program.add([Xops.ls0, ptr]);
    prLen += 2;
  }

  void loadStack1(int ptr) {
    program.add([Xops.ls1, ptr]);
    prLen += 2;
  }

  void setStack0(int ptr) {
    program.add([Xops.sets0, ptr]);
    prLen += 2;
  }

  void setStack1(int ptr) {
    program.add([Xops.sets1, ptr]);
    prLen += 2;
  }

  void loadProperty0(int ptr) {
    program.add([Xops.lprop0, ptr]);
    prLen += 2;
  }

  void loadProperty1(int ptr) {
    program.add([Xops.lprop1, ptr]);
    prLen += 2;
  }

  Jump jump([int offset = 0]) {
    program.add([Xops.jump, offset >> 8, offset & 0xff]);
    prLen += 3;
    return Jump(program.length - 1, prLen - 3, 1, Size.i16);
  }

  Jump jumpLabel(Label label) {
    return jump()..linkLabel(this, label);
  }

  Jump jumpf([int offset = 0]) {
    program.add([Xops.jumpf, offset >> 8, offset & 0xff]);
    prLen += 3;
    return Jump(program.length - 1, prLen - 3, 1, Size.i16);
  }

  Jump jumpfLabel(Label label) {
    return jumpf()..linkLabel(this, label);
  }

  void push0() {
    if (optimizationLevel >= 2) {
      final pushMapping = {
        Xops.lii0: Xops.lii0p,
        Xops.lii0b: Xops.lii0bp,
        Xops.lc0: Xops.lc0p,
        Xops.ltrue0: Xops.ltrue0p,
        Xops.ltrue0b: Xops.ltrue0bp,
        Xops.lfalse0: Xops.lfalse0p,
        Xops.lfalse0b: Xops.lfalse0bp,
        Xops.lci0: Xops.lci0p,
        Xops.lcf0: Xops.lcf0p,
        Xops.lnull0: Xops.lnull0p,
        Xops.lnull0b: Xops.lnull0bp,
      };

      for (final instr in pushMapping.keys) {
        final lastInstr = _findLastOfTypeNot(instr, r0: true, stackPtr: true);
        if (lastInstr != null) {
          program[lastInstr][0] = pushMapping[instr]!;
          return;
        }
      }
    }
    program.add([Xops.push0]);
    prLen++;
  }

  void push1() {
    if (optimizationLevel >= 2) {
      final pushMapping = {
        Xops.lii1: Xops.lii1p,
        Xops.lii1b: Xops.lii1bp,
        Xops.lc1: Xops.lc1p,
        Xops.ltrue1: Xops.ltrue1p,
        Xops.ltrue1b: Xops.ltrue1bp,
        Xops.lfalse1: Xops.lfalse1p,
        Xops.lfalse1b: Xops.lfalse1bp,
        Xops.lci1: Xops.lci1p,
        Xops.lcf1: Xops.lcf1p,
        Xops.lnull1: Xops.lnull1p,
        Xops.lnull1b: Xops.lnull1bp,
      };

      for (final instr in pushMapping.keys) {
        final lastInstr = _findLastOfTypeNot(instr, r1: true, stackPtr: true);
        if (lastInstr != null) {
          program[lastInstr][0] = pushMapping[instr]!;
          return;
        }
      }
    }
    program.add([Xops.push1]);
    prLen++;
  }

  void lii0(int i) {
    program.add([Xops.lii0, i >> 8, i & 0xff]);
    prLen += 3;
  }

  void lii1(int i) {
    program.add([Xops.lii1, i >> 8, i & 0xff]);
    prLen += 3;
  }

  void lii0p(int i) {
    program.add([Xops.lii0p, i >> 8, i & 0xff]);
    prLen += 3;
  }

  void lii1p(int i) {
    program.add([Xops.lii1p, i >> 8, i & 0xff]);
    prLen += 3;
  }

  void iadd() {
    program.add([Xops.iadd]);
    prLen++;
  }

  void iadds(int ptr) {
    program.add([Xops.iadds, ptr]);
    prLen += 2;
  }

  void iaddsp(int ptr) {
    program.add([Xops.iaddsp, ptr]);
    prLen += 2;
  }

  void lt() {
    program.add([Xops.ilt]);
    prLen++;
  }

  void lteq() {
    program.add([Xops.ilteq]);
    prLen++;
  }

  void isp() {
    program.add([Xops.isp]);
    prLen++;
  }

  Label label() {
    return Label(program.length, prLen);
  }
}

class Label {
  final int instr;
  final int offset;

  Label(this.instr, this.offset);
}

class Jump {
  final int instr;
  final int rel;
  final int ptr;
  final Size size;

  Jump(this.instr, this.rel, this.ptr, this.size);

  void link(Assembler asm) {
    final offset = asm.prLen - rel;
    switch (size) {
      case Size.i16:
        asm.program[rel][ptr] = offset >> 8;
        asm.program[rel][ptr + 1] = offset & 0xff;
        break;
      default:
        throw Exception("Unknown label size $size");
    }
  }

  void linkLabel(Assembler asm, Label label) {
    final offset = label.offset - rel;
    switch (size) {
      case Size.i16:
        asm.program[rel][ptr] = offset >> 8;
        asm.program[rel][ptr + 1] = offset & 0xff;
        break;
      default:
        throw Exception("Unknown label size $size");
    }
  }
}
