import '../helpers/global.dart';
import '../backend/representation.dart' show representationForType;
import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/scope.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/ir/objects.dart';
import 'package:dart_eval/src/eval/ir/function.dart';
import 'package:dart_eval/src/eval/ir/representation.dart';

void compileFieldDeclaration(
  int fieldIndex,
  FieldDeclaration d,
  CompilerContext ctx,
  NamedCompilationUnitMember parent,
) {
  final parentName = parent.name.lexeme;
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
        final pos = beginMethod(ctx, field, field.offset, '$fieldName*i');
        ctx.beginAllocScope();
        ctx.functionSignatures[pos] = MachineFunctionSignature(
          [],
          representationForType(storageType),
        );
        var V = compileExpression(initializer, ctx, type);
        if (type != null) {
          if (!V.type.isAssignableTo(ctx, type)) {
            throw CompileError(
              'Static field $parentName.$fieldName of inferred type ${V.type} '
              'does not conform to type $type',
            );
          }
        } else {
          type = V.type;
        }
        V = storageType.boxed ? V.boxIfNeeded(ctx) : V.unboxIfNeeded(ctx);
        type = storageType;
        final name = '$parentName.$fieldName';
        final index = ctx.topLevelGlobalIndices[ctx.library]![name]!;
        ctx.topLevelVariableInferredTypes[ctx.library]![name] = type;
        ctx.topLevelGlobalInitializers[ctx.library]![name] = pos;
        ctx.runtimeGlobalInitializerMap[index] = pos;
        ctx.pushOp(Return(V.ssa));
        ctx.endAllocScope(popValues: false);
      } else {
        ctx.topLevelVariableInferredTypes[ctx
                .library]!['$parentName.$fieldName'] =
            storageType;
      }
    } else {
      final pos = beginMethod(ctx, d, d.offset, '$parentName.$fieldName (get)');
      ctx.functionSignatures[pos] = MachineFunctionSignature([
        MachineRepresentation.object,
      ], MachineRepresentation.object);
      final receiver = SSA('arg_0');
      ctx.pushOp(Parameter(receiver, 0));
      final value = ctx.svar('field');
      ctx.pushOp(LoadPropertyStatic(value, receiver, fieldIndex0));
      ctx.pushOp(Return(value));
      ctx.instanceDeclarationPositions[ctx
              .library]![parentName]![0][fieldName] =
          pos;
      ctx.instanceGetterIndices[ctx.library]![parentName]![fieldName] =
          fieldIndex0;

      if (!(field.isFinal || field.isConst)) {
        final setterPos = beginMethod(
          ctx,
          d,
          d.offset,
          '$parentName.$fieldName (set)',
        );
        final receiver = SSA('arg_0');
        ctx.functionSignatures[setterPos] = MachineFunctionSignature([
          MachineRepresentation.object,
          MachineRepresentation.object,
        ], MachineRepresentation.object);
        final value = SSA('arg_1');
        ctx.pushOp(Parameter(receiver, 0));
        ctx.pushOp(Parameter(value, 1));
        ctx.pushOp(SetPropertyStatic(receiver, fieldIndex0, value));
        ctx.pushOp(Return(value));
        ctx.instanceDeclarationPositions[ctx
                .library]![parentName]![1][fieldName] =
            setterPos;
      }

      fieldIndex0++;
    }
  }
}
