import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/src/eval/shared/types.dart';

/// Handles `List<num>`, `Map<String, int>` etc. as expressions.
Variable compileFunctionReference(FunctionReference e, CompilerContext ctx) {
  final inner = compileExpression(e.function, ctx);

  if (inner.type == CoreTypes.type.ref(ctx) && inner.concreteTypes.isNotEmpty) {
    final baseType = inner.concreteTypes[0];
    final typeArgs = e.typeArguments;
    if (typeArgs != null && typeArgs.arguments.isNotEmpty) {
      final parameterized = baseType.copyWith(
        specifiedTypeArgs: [
          for (final arg in typeArgs.arguments)
            TypeRef.fromAnnotation(ctx, ctx.library, arg),
        ],
      );
      ctx.pushOp(
        PushConstantType.make(parameterized.toRuntimeType(ctx).type),
        PushConstantType.LEN,
      );
      return Variable.alloc(
        ctx,
        CoreTypes.type.ref(ctx),
        concreteTypes: [parameterized],
      );
    }
  }

  return inner;
}
