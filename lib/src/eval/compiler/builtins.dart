import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/memory.dart';

var dartCoreFile = -1;

class BuiltinValue {
  BuiltinValue({
    this.intval,
    this.doubleval,
    this.stringval,
    this.boolval,
    this.name,
  }) {
    if (intval != null) {
      type = BuiltinValueType.intType;
    } else if (stringval != null) {
      type = BuiltinValueType.stringType;
    } else if (doubleval != null) {
      type = BuiltinValueType.doubleType;
    } else if (boolval != null) {
      type = BuiltinValueType.boolType;
    } else {
      type = BuiltinValueType.nullType;
    }
  }

  String? name;
  late BuiltinValueType type;
  final int? intval;
  final double? doubleval;
  final String? stringval;
  final bool? boolval;

  Variable _push(CompilerContext ctx, SSA target) {
    if (type == BuiltinValueType.intType) {
      final type = CoreTypes.int.ref(ctx).copyWith(boxed: false);
      return Variable.ssa(
        ctx,
        LoadInt(target, intval!),
        type,
        concreteTypes: [type],
        exactType: type,
        isConstInt: true,
        isConst: true,
      );
    } else if (type == BuiltinValueType.doubleType) {
      final type = CoreTypes.double.ref(ctx).copyWith(boxed: false);
      return Variable.ssa(
        ctx,
        LoadDouble(target, doubleval!),
        type,
        concreteTypes: [type],
        exactType: type,
        isConst: true,
      );
    } else if (type == BuiltinValueType.stringType) {
      final type = CoreTypes.string.ref(ctx).copyWith(boxed: false);
      return Variable.ssa(
        ctx,
        LoadString(target, stringval!),
        type,
        concreteTypes: [type],
        exactType: type,
        isConst: true,
      );
    } else if (type == BuiltinValueType.boolType) {
      final type = CoreTypes.bool.ref(ctx).copyWith(boxed: false);
      return Variable.ssa(
        ctx,
        LoadBool(target, boolval!),
        type,
        concreteTypes: [type],
        exactType: type,
        isConst: true,
      );
    } else if (type == BuiltinValueType.nullType) {
      final type = CoreTypes.nullType.ref(ctx).copyWith(boxed: false);
      return Variable.ssa(ctx, LoadNull(target), type, concreteTypes: [type], isConst: true);
    } else {
      throw CompileError('Cannot push unknown builtin value type $type');
    }
  }

  Variable push(CompilerContext ctx, [SSA? ssa]) =>
      _push(ctx, ssa ?? ctx.svar(name ?? 'var'));
}

enum BuiltinValueType { intType, stringType, doubleType, boolType, nullType }

late Set<TypeRef> unboxedAcrossFunctionBoundaries;
