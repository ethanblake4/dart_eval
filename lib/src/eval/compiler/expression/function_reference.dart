import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/shared/types.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/types.dart';
import '../variable/value_facts.dart';
import '../errors.dart';

/// Handles `List<num>`, `Map<String, int>` etc. as expressions.
Variable compileFunctionReference(FunctionReference e, CompilerContext ctx) {
  final typeArguments = e.typeArguments?.arguments;
  Variable? read;
  if (typeArguments != null &&
      (e.function is Identifier || e.function is PropertyAccess)) {
    final reference = compileExpressionAsReference(e.function, ctx);
    final type = reference.resolveType(ctx, source: e);
    if (type is FunctionTypeRef) {
      final signature = type.signature;
      if (signature.typeParameters.length != typeArguments.length) {
        throw CompileError('Wrong number of function type arguments', e);
      }
      final arguments = [
        for (final arg in typeArguments)
          TypeRef.fromAnnotation(ctx, ctx.library, arg),
      ];
      final substitution = Substitution.of({
        for (var i = 0; i < typeArguments.length; i++)
          signature.typeParameters[i]: arguments[i],
      });
      final instantiated = FunctionTypeRef(
        FunctionSignature(
          positional: [
            for (final parameter in signature.positional)
              parameter.substituteTypeParameters(substitution),
          ],
          requiredPositional: signature.requiredPositional,
          named: {
            for (final entry in signature.named.entries)
              entry.key: (
                type: entry.value.type.substituteTypeParameters(substitution),
                required: entry.value.required,
              ),
          },
          returnType: signature.returnType.substituteTypeParameters(
            substitution,
          ),
        ),
        decl: type.decl,
      );
      return reference.getValue(ctx, e, instantiated, arguments);
    }
    read = reference.getValue(ctx, e);
  }
  final inner = read ?? compileExpression(e.function, ctx);

  if (receiverOf(ctx, inner) case TypeLiteralReceiver(:final type)) {
    final baseType = type;
    final typeArgs = e.typeArguments;
    if (typeArgs != null && typeArgs.arguments.isNotEmpty) {
      final parameterized = (baseType as InterfaceTypeRef).copyWith(
        arguments: [
          for (final arg in typeArgs.arguments)
            TypeRef.fromAnnotation(ctx, ctx.library, arg),
        ],
      );
      final typeId = ctx.runtimeTypes.idOf(parameterized);
      final operation = parameterized.requiresTypeEnvironment
          ? LoadTypeParameter(ctx.svar('type'), typeId)
          : LoadConstantType(ctx.svar('type'), typeId);
      return Variable.ssa(
        ctx,
        operation,
        CoreTypes.type.ref(ctx),
        facts: ValueFacts(
          denotedType: parameterized,
          possibleClasses: [parameterized],
        ),
      );
    }
  }

  return inner;
}
