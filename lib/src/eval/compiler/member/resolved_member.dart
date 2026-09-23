import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/member/call_signature.dart';
import 'package:dart_eval/src/eval/compiler/member/member.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/shared/types.dart';

/// A member viewed from a receiver's instantiated type — carries the
/// substitution from the owner's parameter space into the receiver's
/// arguments.
final class ResolvedMember {
  ResolvedMember(this.member, this.viewedAs)
    : substitution = Substitution.forInterface(viewedAs);

  final Member member;
  final TypeRef viewedAs;
  final Substitution substitution;

  /// The member's signature instantiated at [viewedAs]'s arguments.
  CallSignature get signature => member.signature.substitute(substitution);

  /// For a field accessor, the field's type in the receiver's view; for
  /// callables, the instantiated [FunctionTypeRef].
  TypeRef get valueType {
    if (member.isField) return signature.returnType;
    return signature.toFunctionType(member.ownerDecl!.ctx);
  }

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
      // `lookupFieldType` on a non-accessor method returns `Function` —
      // its value is a tear-off, not the method's return type.
      raw = !m.isGetter && !m.isSetter
          ? CoreTypes.function.ref(member.ownerDecl!.ctx)
          : m.returnType == null
          ? null
          : member.signature.returnType;
    } else {
      raw = member.signature.returnType;
    }
    return raw?.substituteTypeParameters(substitution);
  }
}

