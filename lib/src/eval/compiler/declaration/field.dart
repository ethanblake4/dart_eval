import '../helpers/conversion.dart';
import '../helpers/global.dart';
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

void compileFieldDeclaration(
  int fieldIndex,
  FieldDeclaration d,
  CompilerContext ctx,
  Declaration parent,
) {
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
          type = widenedInferredType(ctx, V.type);
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
      final fieldType = d.fields.type == null
          ? (ctx.inferredFieldTypes[ctx.library]?[parentName]?[fieldName] ??
                CoreTypes.dynamic.ref(ctx))
          : TypeRef.fromAnnotation(ctx, ctx.library, d.fields.type!);
      final pos = ctx.beginFunction('$parentName.$fieldName (get)');
      ctx.functionSignatures[pos] = MachineFunctionSignature([
        MachineRepresentation.object,
      ], MachineRepresentation.object);
      final receiver = SSA('arg_0');
      ctx.pushOp(Parameter(receiver, 0));
      final value = ctx.svar('field');
      ctx.pushOp(
        LoadPropertyStatic(
          value,
          receiver,
          fieldIndex0,
          isLate: d.fields.isLate,
        ),
      );
      ctx.pushOp(Return(value));
      ctx.instanceDeclarationPositions[ctx.enclosingLibrary ??
              ctx.library]![parentName]![0][ctx.memberNameKey(fieldName)] =
          pos;
      ctx.instanceGetterIndices[ctx.enclosingLibrary ??
              ctx.library]![parentName]![fieldName] =
          fieldIndex0;

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
          ),
        );
        ctx.pushOp(Return(value));
        ctx.instanceDeclarationPositions[ctx.enclosingLibrary ??
                ctx.library]![parentName]![1][ctx.memberNameKey(fieldName)] =
            setterPos;
      }

      fieldIndex0++;
    }
  }
}
