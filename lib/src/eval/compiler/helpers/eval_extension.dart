import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';

/// An `extension` declaration with the library it was declared in and the
/// name used to register its members (`E.foo`), synthesized when unnamed.
class EvalExtension {
  EvalExtension(this.library, this.declaration, this.name);

  final int library;
  final ExtensionDeclaration declaration;
  final String name;

  /// The members declared in the extension body.
  List<ClassMember> get members => switch (declaration.body) {
    BlockClassBody b => b.members,
    _ => const [],
  };

  /// Member registration key in `topLevelDeclarationPositions`.
  String memberKey(MethodDeclaration member) =>
      extensionMemberKey(name, member);

  /// The `on` type, or null when it can't be resolved. For generic
  /// extensions this is the *pattern* — type parameters appear as
  /// type-parameter TypeRefs keyed by `extension:library:name` — to be bound
  /// per call site by [matchExtensionOn].
  TypeRef? resolveOnType(CompilerContext ctx) {
    final tps = declaration.typeParameters?.typeParameters;
    if (tps == null || tps.isEmpty) {
      try {
        return TypeRef.fromAnnotation(
          ctx,
          library,
          declaration.onClause!.extendedType,
        );
      } catch (_) {
        return null;
      }
    }
    // Seed the extension's own parameters as visible type parameters so the
    // `on` annotation resolves into a pattern; restore the scope afterwards.
    return ctx.withTypeParameters(
      library,
      TypeParameterOwner(TypeParameterOwnerKind.extension, library, name),
      tps,
      () {
        try {
          return TypeRef.fromAnnotation(
            ctx,
            library,
            declaration.onClause!.extendedType,
          );
        } catch (_) {
          return null;
        }
      },
      resolveBounds: false,
    );
  }
}


/// Member registration key for [member] of the extension named [extName].
/// `operator -` is the only arity-overloadable operator — unary and binary
/// forms can coexist in one extension — so it is keyed by positional arity.
String extensionMemberKey(String extName, MethodDeclaration member) {
  final suffix = member.isGetter
      ? '*g'
      : member.isSetter
      ? '*s'
      : member.name.lexeme == '-'
      ? ':${positionalArityOf(member)}'
      : '';
  return '$extName.${member.name.lexeme}$suffix';
}

/// Total positional parameter count (required + optional) of [member].
int positionalArityOf(MethodDeclaration member) =>
    member.parameters?.parameters.where((p) => p.isPositional).length ?? 0;

