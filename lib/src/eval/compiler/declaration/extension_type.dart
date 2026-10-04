import 'package:analyzer/dart/ast/ast.dart';
import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/dart_eval_bridge.dart';

import '../context.dart';
import '../member/member_name.dart';
import '../statement/block.dart';
import '../type.dart';
import '../variable.dart';
import '../values/value_rep.dart';
import '../../ir/flow.dart';
import '../../ir/function.dart';
import '../../ir/representation.dart';

const extensionPrimaryBodyName = '#primaryBody';

/// A separate body keeps a constructor's bare return inside the constructor.
/// Representation-only constructors continue to compile as identity values.
void compileExtensionPrimaryBody(
  CompilerContext ctx,
  ExtensionTypeDeclaration declaration,
  PrimaryConstructorBody body,
) {
  final name = declarationName(declaration);
  final decl = ctx.types.find(ctx.library, name) as SourceTypeDecl;
  final id = ctx.beginFunction('$name.$extensionPrimaryBodyName()');
  ctx.instanceDeclarationPositions[ctx.library]![name]![MemberKind
          .method]![extensionPrimaryBodyName] =
      id;
  ctx.functionTypeParameters[id] = decl.typeParameters;
  ctx.functionSignatures[id] = const MachineFunctionSignature([
    MachineRepresentation.object,
  ], null);
  final oldScope = ctx.typeScopes[ctx.library];
  ctx.typeScopes[ctx.library] = TypeScope(oldScope)
    ..entries.addAll(decl.ownTypeParams);
  ctx.beginScope();
  try {
    ctx.pushOp(Parameter(SSA('arg_0'), 0));
    final receiver = Variable.of(
      ctx,
      SSA('arg_0'),
      decl.instantiate(decl.ownTypeParams.values.toList()),
      rep: ValueRep.boxed,
    );
    ctx.setLocal('#this', receiver, isFinal: true);
    ctx.setLocal(
      decl.extensionRepresentationParameter!.name!.lexeme,
      receiver.copyWith(type: decl.extensionRepresentation!),
      isFinal: true,
    );
    final result = compileBlock(
      (body.body as BlockFunctionBody).block,
      CoreTypes.voidType.ref(ctx),
      ctx,
      name: '$name.$extensionPrimaryBodyName()',
    );
    if (!result.willAlwaysReturn && !result.willAlwaysThrow) {
      ctx.pushOp(Return(null));
    }
  } finally {
    ctx.endScope();
    if (oldScope == null) {
      ctx.typeScopes.remove(ctx.library);
    } else {
      ctx.typeScopes[ctx.library] = oldScope;
    }
  }
}
