import 'package:dart_eval/src/eval/compiler/member/call_signature.dart';
import 'package:dart_eval/src/eval/compiler/member/member.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';

/// A member viewed from a receiver's instantiated type — carries the
/// substitution from the owner's parameter space into the receiver's
/// arguments.
final class ResolvedMember {
  ResolvedMember(this.member, this.viewedAs)
    : substitution = Substitution.forInterface(viewedAs);

  final Member member;
  final InterfaceTypeRef viewedAs;
  final Substitution substitution;

  /// The member's signature instantiated at [viewedAs]'s arguments.
  CallSignature get signature => member.signature.substitute(substitution);

  /// For a field accessor, the field's type in the receiver's view; for
  /// callables, the instantiated [FunctionTypeRef].
  TypeRef get valueType {
    if (member.isField) return signature.returnType;
    return signature.toFunctionType(member.ownerDecl!.ctx);
  }
}

