import '../builtins.dart';
import '../helpers/global.dart';
import '../helpers/conversion.dart';
import '../backend/representation.dart' show representationForType;
import '../../ir/representation.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';

void compileTopLevelVariableDeclaration(
  VariableDeclaration v,
  CompilerContext ctx,
) {
  final parent = v.parent!.parent! as TopLevelVariableDeclaration;
  final varName = v.name.lexeme;

  final storageType = resolveGlobalType(ctx, ctx.library, varName);
  final initializer = v.initializer;
  if (initializer != null) {
    final pos = ctx.beginFunction('$varName*i');
    ctx.beginScope();
    ctx.functionSignatures[pos] = MachineFunctionSignature(
      [],
      representationForType(storageType),
    );
    var V = compileExpression(initializer, ctx, storageType);
    TypeRef type;
    final specifiedType = parent.variables.type;
    if (specifiedType != null) {
      type = TypeRef.fromAnnotation(ctx, ctx.library, specifiedType);
    } else {
      type = V.type;
    }
    V = convertForAssignment(
      ctx,
      V,
      type,
      representation: representationForType(storageType),
      source: v,
      description:
          'Variable $varName of inferred type ${V.type} does not conform to '
          'type $type',
    );
    type = storageType;
    final index = ctx.topLevelGlobalIndices[ctx.library]![varName]!;
    ctx.topLevelVariableInferredTypes[ctx.library]![varName] = type;
    ctx.runtimeGlobalInitializerMap[index] = pos;
    // An initializer that never produces a value (`throw`, `Never`-typed)
    // still needs a Return operand for the initializer function frame.
    ctx.pushOp(
      Return(V.name == null ? BuiltinValue().push(ctx).ssa : V.ssa),
    );
    ctx.endScope();
  }
}
