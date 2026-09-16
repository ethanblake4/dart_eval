import 'default_value.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/function.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/closures.dart';

extension TearOff on Variable {
  Variable tearOff(CompilerContext ctx) {
    if (type != CoreTypes.function.ref(ctx) || methodOffset == null) {
      throw CompileError('Cannot tear off non-function or unresolved function');
    }
    final offset = methodOffset!;
    final Declaration declaration;
    if (offset.className != null) {
      declaration =
          ctx.instanceDeclarationsMap[offset.file]![offset.className!]![offset
                  .name]!
              as MethodDeclaration;
    } else {
      final declared = ctx.topLevelDeclarationsMap[offset.file]![offset.name]!;
      if (declared.isBridge) {
        throw CompileError('Cannot tear off bridged function');
      }
      declaration = declared.declaration!;
    }
    final parameters = declaration is MethodDeclaration
        ? declaration.parameters
        : (declaration as FunctionDeclaration).functionExpression.parameters;
    final positional =
        parameters?.parameters.where((param) => param.isPositional).toList() ??
        <FormalParameter>[];
    final named =
        parameters?.parameters.where((param) => param.isNamed).toList() ??
        <FormalParameter>[];
    TypeRef parameterType(FormalParameter parameter) {
      final normal = parameter is DefaultFormalParameter
          ? parameter.parameter
          : parameter;
      final annotation = normal is SimpleFormalParameter ? normal.type : null;
      return annotation == null
          ? CoreTypes.dynamic.ref(ctx)
          : TypeRef.fromAnnotation(ctx, offset.file ?? ctx.library, annotation);
    }

    Object? parameterDefault(FormalParameter parameter) {
      final value = evaluateDefaultValue(
        ctx,
        offset.file ?? ctx.library,
        parameter is DefaultFormalParameter ? parameter.defaultValue : null,
      );
      return value is int &&
              parameterType(parameter) == CoreTypes.double.ref(ctx)
          ? value.toDouble()
          : value;
    }

    final captures = <SSA>[];
    if (declaration is MethodDeclaration && !declaration.isStatic) {
      final receiver = offset.targetName == null
          ? ctx.lookupLocal('#this')?.readBinding(ctx).ssa
          : SSA(offset.targetName!);
      if (receiver == null) {
        throw CompileError('Missing receiver for method tearoff');
      }
      captures.add(receiver);
    }
    return Variable.ssa(
      ctx,
      CreateClosure(
        ctx.svar('tearoff'),
        offset,
        captures,
        requiredPositional: positional
            .where((param) => param.isRequired)
            .length,
        positionalTypes: positional
            .map((param) => parameterType(param).toRuntimeType(ctx).toJson())
            .toList(),
        namedNames: named.map((param) => param.name!.lexeme).toList(),
        namedTypes: named
            .map((param) => parameterType(param).toRuntimeType(ctx).toJson())
            .toList(),
        hasEnvironment: false,
        positionalDefaults: positional.map(parameterDefault).toList(),
        namedDefaults: named.map(parameterDefault).toList(),
        requiredNamed: [
          for (final parameter in named)
            if (parameter.isRequired) parameter.name!.lexeme,
        ],
        boundReceiver:
            declaration is MethodDeclaration && !declaration.isStatic,
        positionalUnboxed: positional
            .map(
              (param) =>
                  declaration is FunctionDeclaration &&
                  parameterType(param).isUnboxedAcrossFunctionBoundaries,
            )
            .toList(),
        namedUnboxed: named
            .map(
              (param) =>
                  declaration is FunctionDeclaration &&
                  parameterType(param).isUnboxedAcrossFunctionBoundaries,
            )
            .toList(),
      ),
      CoreTypes.function.ref(ctx),
      methodReturnType:
          methodReturnType ??
          AlwaysReturnType(CoreTypes.dynamic.ref(ctx), false),
      methodOffset: offset,
      callingConvention: CallingConvention.dynamic,
    );
  }
}
