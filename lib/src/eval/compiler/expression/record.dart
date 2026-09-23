import 'package:analyzer/dart/ast/ast.dart';
import 'package:collection/collection.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/helpers/const.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/collection.dart';
import 'package:dart_eval/src/eval/shared/types.dart';

Variable compileRecordLiteral(
  RecordLiteral l,
  CompilerContext ctx, [
  TypeRef? bound,
]) {
  // Field names in layout order (index i holds the name of field i). A
  // list is used rather than a name-to-index map because the constant
  // pool dedupes maps by unordered deep equality, which would collide
  // layouts that differ only in field order.
  final fieldNames = List<String>.filled(l.fields.length, '');

  if (bound != null && !bound.isRecord) bound = null;

  if (!(bound?.isAssignableTo(ctx, CoreTypes.record.ref(ctx)) ?? true)) {
    throw CompileError('Incompatible record type', l);
  }

  final fieldList = Variable.ssa(
    ctx,
    NewList(ctx.svar('record_fields')),
    CoreTypes.list.ref(ctx),
  );

  var positionalFields = 1;

  final boundRecord = bound is RecordTypeRef ? bound : null;
  final inferredPositional = <TypeRef>[];
  final inferredNamed = <String, TypeRef>{};

  if (boundRecord != null &&
      l.fields.length !=
          boundRecord.positional.length + boundRecord.named.length) {
    throw CompileError(
      'Record literal has ${l.fields.length} fields, expected ${boundRecord.positional.length + boundRecord.named.length} from type bound',
      l,
    );
  }
  // Bound record fields list positionals first, then named — while the
  // literal lists them in source order. Named fields match by name;
  // positional fields match by their ordinal among positionals.
  TypeRef? namedBound(String name) => boundRecord?.named[name];

  // The bound only provides each field's inference context — the literal's
  // static type is built from the field expressions' own types. When the
  // field isn't assignable to its context but has a `call` member, the spec
  // inserts an implicit `.call` tear-off coercion (e.g. `C() => int` under a
  // `_ Function()` context yields the `int Function()` tear-off).
  Variable compileField(Expression expression, TypeRef? fieldBound) {
    final value = compileExpression(
      expression,
      ctx,
      fieldBound,
    ).boxIfNeeded(ctx);
    if (fieldBound == null || value.type.isAssignableTo(ctx, fieldBound)) {
      return value;
    }
    final bound0 = fieldBound;
    if (bound0.functionType == null && !bound0.isSpec(CoreTypes.function)) {
      return value;
    }
    try {
      final call = value.getProperty(ctx, 'call');
      if (call.type.functionType == null) {
        return value;
      }
      return call.boxIfNeeded(ctx);
    } on CompileError {
      return value;
    }
  }

  for (var i = 0; i < l.fields.length; i++) {
    final field = l.fields[i];
    if (field is RecordLiteralNamedField) {
      final name = field.name.lexeme;
      final value = compileField(field.fieldExpression, namedBound(name));
      inferredNamed[name] = value.type;
      ctx.pushOp(ListAppend(fieldList.ssa, value.ssa));
      fieldNames[i] = name;
    } else {
      // Positional field
      final fieldBound = boundRecord?.positional.elementAtOrNull(
        positionalFields - 1,
      );
      final value = compileField(field.fieldExpression, fieldBound);
      final name = '\$${positionalFields++}';
      inferredPositional.add(value.type);
      ctx.pushOp(ListAppend(fieldList.ssa, value.ssa));
      fieldNames[i] = name;
    }
  }

  // The literal's static type is built from each field's inferred type —
  // the bound only provided the inference context (`(T,)` infers its own
  // field types and then unifies T with them).
  final type = RecordTypeRef(inferredPositional, inferredNamed);
  final constIndex = ctx.constantPool.addOrGet(fieldNames);
  final record = Variable.ssa(
    ctx,
    NewRecord(
      ctx.svar('record'),
      fieldList.ssa,
      constIndex,
      ctx.runtimeTypes.idOf(type),
      reify: [
        ...inferredPositional,
        ...inferredNamed.values,
      ].any((t) => !t.hasFixedRuntimeType(ctx)),
    ),
    type,
  );
  return l.isConst ? internConst(ctx, record, type) : record;
}
