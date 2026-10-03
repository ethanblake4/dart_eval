import '../helpers/conversion.dart';
import '../helpers/global.dart';
import '../helpers/external.dart';
import '../member/member_name.dart';
import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/ir/objects.dart';
import 'package:dart_eval/src/eval/ir/function.dart';
import 'package:dart_eval/src/eval/ir/representation.dart';
import 'package:dart_eval/src/eval/shared/types.dart';
import '../values/abi.dart';
import '../variable.dart';
import '../macros/branch.dart';
import '../statement/statement.dart';
import 'constructor.dart' show compileFieldInitializer;

void compileFieldDeclaration(
  int fieldIndex,
  FieldDeclaration d,
  CompilerContext ctx,
  Declaration parent,
) {
  if (d.abstractKeyword != null) return;
  if (d.externalKeyword != null) {
    if (!d.isStatic) _compileExternalField(ctx, d, parent);
    return;
  }
  final parentName = declarationName(parent);
  var fieldIndex0 = fieldIndex;
  for (final field in d.fields.variables) {
    final fieldName = field.name.lexeme;
    if (d.isStatic) {
      final storageType = resolveGlobalType(
        ctx,
        ctx.library,
        '$parentName.$fieldName',
      );
      final initializer = field.initializer;
      TypeRef? type;
      final specifiedType = d.fields.type;
      if (specifiedType != null) {
        type = TypeRef.fromAnnotation(ctx, ctx.library, specifiedType);
      }
      if (initializer != null) {
        final pos = ctx.beginFunction('$fieldName*i');
        ctx.beginScope();
        ctx.functionSignatures[pos] = MachineFunctionSignature(
          [],
          Abi.storageSlot(storageType).bank,
        );
        var V = compileExpression(initializer, ctx, type);
        if (type != null) {
          V = convertInitializer(
            ctx,
            V,
            type,
            source: initializer,
            description:
                'Static field $parentName.$fieldName of inferred type '
                '${V.type} does not conform to type $type',
          );
        } else {
          type = ctx.typeFactory.widenedInferredType(V.type);
        }
        V = Abi.storageSlot(storageType).isBoxed
            ? V.boxIfNeeded(ctx)
            : V.unboxIfNeeded(ctx);
        type = storageType;
        final name = '$parentName.$fieldName';
        final index = ctx.topLevelGlobalIndices[ctx.library]![name]!;
        ctx.topLevelVariableInferredTypes[ctx.library]![name] = type;
        ctx.runtimeGlobalInitializerMap[index] = pos;
        ctx.pushOp(Return(V.ssa));
        ctx.endScope();
      } else {
        ctx.topLevelVariableInferredTypes[ctx
                .library]!['$parentName.$fieldName'] =
            storageType;
      }
    } else {
      var fieldType = d.fields.type == null
          ? (ctx.inferredFieldTypes[ctx.library]?[parentName]?[fieldName] ??
                CoreTypes.dynamic.ref(ctx))
          : TypeRef.fromAnnotation(ctx, ctx.library, d.fields.type!);
      final pos = ctx.beginFunction('$parentName.$fieldName (get)');
      ctx.functionSignatures[pos] = MachineFunctionSignature([
        MachineRepresentation.object,
      ], MachineRepresentation.object);
      final receiver = SSA('arg_0');
      ctx.pushOp(Parameter(receiver, 0));
      final hasLateInitializer = d.fields.isLate && field.initializer != null;
      if (hasLateInitializer) {
        _compileLateFieldInitializer(
          ctx,
          d,
          field,
          parentName,
          receiver,
          fieldIndex0,
        );
        if (d.fields.type == null) {
          fieldType =
              ctx.inferredFieldTypes[ctx.library]?[parentName]?[fieldName] ??
              fieldType;
        }
      }
      final value = ctx.svar('field');
      ctx.pushOp(
        LoadPropertyStatic(
          value,
          receiver,
          fieldIndex0,
          isLate: d.fields.isLate,
          fieldName: fieldName,
        ),
      );
      ctx.pushOp(Return(value));
      ctx.instanceDeclarationPositions[ctx.enclosingLibrary ??
              ctx.library]![parentName]![MemberKind.getter]![ctx.memberNameKey(
            fieldName,
          )] =
          pos;
      if (!hasLateInitializer) {
        ctx.instanceGetterIndices[ctx.enclosingLibrary ??
                ctx.library]![parentName]![fieldName] =
            fieldIndex0;
      }

      if (!(field.isFinal || field.isConst) ||
          (d.fields.isLate && field.initializer == null)) {
        final setterPos = ctx.beginFunction('$parentName.$fieldName (set)');
        final receiver = SSA('arg_0');
        ctx.functionSignatures[setterPos] = MachineFunctionSignature([
          MachineRepresentation.object,
          MachineRepresentation.object,
        ], MachineRepresentation.object);
        ctx.functionParameterTypes[setterPos] = [fieldType];
        final value = SSA('arg_1');
        ctx.pushOp(Parameter(receiver, 0));
        ctx.pushOp(Parameter(value, 1));
        ctx.pushOp(
          SetPropertyStatic(
            receiver,
            fieldIndex0,
            value,
            isLateFinal: d.fields.isLate && field.isFinal,
            fieldName: fieldName,
          ),
        );
        ctx.pushOp(Return(value));
        ctx.instanceDeclarationPositions[ctx.enclosingLibrary ??
                ctx.library]![parentName]![MemberKind.setter]![ctx
                .memberNameKey(fieldName)] =
            setterPos;
      }

      fieldIndex0++;
    }
  }
}

void _compileExternalField(
  CompilerContext ctx,
  FieldDeclaration declaration,
  Declaration parent,
) {
  final library = ctx.enclosingLibrary ?? ctx.library;
  final parentName = declarationName(parent);
  for (final field in declaration.fields.variables) {
    final type = declaration.fields.type == null
        ? CoreTypes.dynamic.ref(ctx)
        : TypeRef.fromAnnotation(ctx, ctx.library, declaration.fields.type!);
    for (final setter in [false, if (!field.isFinal) true]) {
      final position = ctx.beginFunction(
        '$parentName.${field.name.lexeme} (external)',
      );
      ctx.functionSignatures[position] = MachineFunctionSignature(
        List.filled(setter ? 2 : 1, MachineRepresentation.object),
        MachineRepresentation.object,
      );
      final receiver = SSA('arg_0');
      ctx.pushOp(Parameter(receiver, 0));
      Variable? value;
      if (setter) {
        final argument = SSA('arg_1');
        ctx.pushOp(Parameter(argument, 1));
        ctx.functionParameterTypes[position] = [type];
        value = Variable.of(ctx, argument, type, rep: ValueRep.boxed);
      }
      emitMissingExternal(
        ctx,
        field.name.lexeme,
        kind: setter ? InvocationKind.setter : InvocationKind.getter,
        receiver: Variable.of(
          ctx,
          receiver,
          TypeRef.$this(ctx)!,
          rep: ValueRep.boxed,
        ),
        positional: [if (value != null) value],
      );
      ctx.instanceDeclarationPositions[library]![parentName]![setter
              ? MemberKind.setter
              : MemberKind.getter]![ctx.memberNameKey(field.name.lexeme)] =
          position;
    }
  }
}

void _compileLateFieldInitializer(
  CompilerContext ctx,
  FieldDeclaration declaration,
  VariableDeclaration field,
  String parentName,
  SSA receiver,
  int fieldIndex,
) {
  ctx.beginScope();
  ctx.setLocal(
    '#this',
    Variable.of(ctx, receiver, TypeRef.$this(ctx)!, rep: ValueRep.boxed),
  );
  macroBranch(
    ctx,
    null,
    condition: (ctx) => Variable.ssa(
      ctx,
      IsUninitializedField(ctx.svar('uninitialized'), receiver, fieldIndex),
      CoreTypes.bool.ref(ctx),
      rep: ValueRep.bool,
    ),
    thenBranch: (ctx, _) {
      final value = compileFieldInitializer(ctx, declaration, field);
      ctx.inferredFieldTypes
          .putIfAbsent(ctx.library, () => {})
          .putIfAbsent(parentName, () => {})[field.name.lexeme] = ctx
          .typeFactory
          .widenedInferredType(value.type);
      ctx.pushOp(
        SetPropertyStatic(
          receiver,
          fieldIndex,
          value.ssa,
          isLateFinal: field.isFinal,
          fieldName: field.name.lexeme,
          isLateInitialization: true,
        ),
      );
      return StatementInfo();
    },
  );
  ctx.endScope();
}
