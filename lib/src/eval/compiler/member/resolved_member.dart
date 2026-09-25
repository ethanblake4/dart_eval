import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/bridge/declaration/class.dart';
import 'package:dart_eval/src/eval/compiler/member/call_signature.dart';
import 'package:dart_eval/src/eval/compiler/member/member.dart';
import 'package:dart_eval/src/eval/compiler/member/member_name.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/shared/types.dart';

/// A member viewed from a receiver's instantiated type — carries the
/// substitution from the owner's parameter space into the receiver's
/// arguments.
final class ResolvedMember {
  ResolvedMember(this.member, this.viewedAs, {CallSignature? signature})
    : substitution = Substitution.forInterface(viewedAs),
      signatureOverride = signature;

  final Member member;
  final TypeRef viewedAs;
  final Substitution substitution;

  /// A signature merged over multiple interface candidates — already
  /// substituted, so it replaces `member.signature.substitute(...)`.
  final CallSignature? signatureOverride;

  /// The member's signature instantiated at [viewedAs]'s arguments.
  CallSignature get signature =>
      signatureOverride ?? member.signature.substitute(substitution);

  /// For a field accessor, the field's type in the receiver's view; for
  /// callables, the instantiated [FunctionTypeRef].
  TypeRef get valueType {
    if (member.isField) return signature.returnType;
    return signature.toFunctionType(member.ownerDecl!.ctx);
  }

  /// The member owner's type parameters bound to the receiver's applied
  /// arguments — `classTypeArguments`'s seed map. Since [viewedAs] is already
  /// the owner decl instantiated from the receiver, this is a zip of
  /// parameter names to arguments.
  Map<String, TypeRef> get ownerTypeArguments =>
      ownerTypeArgumentsOf(member.declaringDecl ?? member.ownerDecl, viewedAs);

  /// The field's declared/inferred type through the receiver's view —
  /// null when the field has neither, matching `lookupFieldType`.
  /// Non-field members fall back to [signature.returnType].
  TypeRef? get fieldType {
    final member = this.member;
    final TypeRef? raw;
    if (member is SourceMember && member.isField) {
      raw = member.fieldType;
    } else if (member is SourceMember && member.node is MethodDeclaration) {
      final m = member.node as MethodDeclaration;
      // A method read is a bound tear-off — the signature's function
      // type, preserving genericity for tear-off instantiation. An
      // unannotated accessor's signature carries the inherited type.
      raw = !m.isGetter && !m.isSetter
          ? member.signature.toFunctionType(member.ownerDecl!.ctx)
          : m.returnType == null
          ? null
          : member.signature.returnType;
    } else if (member is BridgeMember &&
        member.def is BridgeMethodDef &&
        member.name.kind == MemberKind.method) {
      // A bridged method read is a bound tear-off like the source case.
      raw = member.signature.toFunctionType(member.ownerDecl!.ctx);
    } else {
      raw = member.signature.returnType;
    }
    return raw?.substituteTypeParameters(substitution);
  }
}

/// [owner]'s type parameters bound to [viewedAs]'s applied arguments — the
/// name-keyed map `classTypeArguments` produced by walking the supertype
/// graph. `asInstanceOf` performs that same walk, so callers that have a
/// [ResolvedMember] can use `ownerTypeArguments` directly.
Map<String, TypeRef> ownerTypeArgumentsOf(TypeDecl? owner, TypeRef viewedAs) {
  if (owner == null) return const {};
  final params = owner.typeParameters;
  final args = interfaceArgumentsOf(viewedAs);
  if (params.isEmpty) return const {};
  return {
    for (var i = 0; i < params.length; i++)
      params[i].name: i < args.length
          ? args[i]
          : CoreTypes.dynamic.ref(owner.ctx),
  };
}
