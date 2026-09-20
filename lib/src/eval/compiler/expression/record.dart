import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/collection.dart';
import 'package:dart_eval/src/eval/shared/types.dart';

Variable compileRecordLiteral(
  RecordLiteral l,
  CompilerContext ctx, [
  TypeRef? bound,
]) {
  final fields = <String, int>{};

  if (bound != null && !bound.name.startsWith('@record')) bound = null;

  if (!(bound?.isAssignableTo(ctx, CoreTypes.record.ref(ctx)) ?? true)) {
    throw CompileError('Incompatible record type', l);
  }

  final fieldList = Variable.ssa(
    ctx,
    NewList(ctx.svar('record_fields')),
    CoreTypes.list.ref(ctx),
  );

  var positionalFields = 1;

  final boundRecordFields = bound?.recordFields;
  final inferredRecordFields = <RecordParameterType>[];
  var inferredTypeName = StringBuffer('@record<');
  if (boundRecordFields != null &&
      l.fields.length != boundRecordFields.length) {
    throw CompileError(
      'Record literal has ${l.fields.length} fields, expected ${boundRecordFields.length} from type bound',
      l,
    );
  }
  var processingNamed = false;
  for (var i = 0; i < l.fields.length; i++) {
    final field = l.fields[i];
    if (field is RecordLiteralNamedField) {
      final name = field.name.lexeme;
      final fieldBound = boundRecordFields == null
          ? null
          : boundRecordFields[i];
      final value = compileExpression(
        field.fieldExpression,
        ctx,
        fieldBound?.type,
      ).boxIfNeeded(ctx);
      if (fieldBound != null &&
          (!fieldBound.isNamed ||
              fieldBound.name != name ||
              !value.type.isAssignableTo(ctx, fieldBound.type))) {
        throw CompileError(
          'A value of type $name: ${value.type} is not assignable to $fieldBound',
          field,
        );
      } else if (boundRecordFields == null) {
        inferredRecordFields.add(RecordParameterType(name, value.type, true));
        if (i > 0) {
          inferredTypeName.write(',');
        }
        if (!processingNamed) {
          inferredTypeName.write('{');
          processingNamed = true;
        }
        inferredTypeName.write('$name:${value.type}');
      }
      ctx.pushOp(ListAppend(fieldList.ssa, value.ssa));
      fields[name] = i;
    } else {
      // Positional field
      final fieldBound = boundRecordFields == null
          ? null
          : boundRecordFields[i];
      final value = compileExpression(
        field.fieldExpression,
        ctx,
        fieldBound?.type,
      ).boxIfNeeded(ctx);
      final name = '\$${positionalFields++}';
      if (fieldBound != null &&
          (fieldBound.isNamed ||
              !value.type.isAssignableTo(ctx, fieldBound.type))) {
        throw CompileError(
          'A value of type ${value.type} is not assignable to $fieldBound',
          field,
        );
      } else if (boundRecordFields == null) {
        inferredRecordFields.add(RecordParameterType(name, value.type, false));
        if (i > 0) {
          inferredTypeName.write(',');
        }
        inferredTypeName.write('${value.type}');
      }
      ctx.pushOp(ListAppend(fieldList.ssa, value.ssa));
      fields[name] = i;
    }
  }

  if (processingNamed) {
    inferredTypeName.write('}');
  }

  inferredTypeName.write('>');

  final type =
      bound?.copyWith(boxed: true) ??
      TypeRef(
        ctx.library,
        inferredTypeName.toString(),
        extendsType: CoreTypes.record.ref(ctx),
        recordFields: inferredRecordFields,
      );
  final constIndex = ctx.constantPool.addOrGet(fields);
  return Variable.ssa(
    ctx,
    NewRecord(
      ctx.svar('record'),
      fieldList.ssa,
      constIndex,
      type.runtimeTypeId(ctx),
    ),
    type,
  );
}
