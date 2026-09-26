import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/backend/representation.dart'
    show representationForType;
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/member/call_signature.dart';
import 'package:dart_eval/src/eval/compiler/member/member.dart';
import 'package:dart_eval/src/eval/compiler/member/member_name.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/values/value_rep.dart';
import 'package:dart_eval/src/eval/ir/representation.dart';

export 'package:dart_eval/src/eval/compiler/values/value_rep.dart';

/// What kind of callable an ABI belongs to. Drives the boxing convention
/// for its parameters and result.
enum CallableKind {
  /// Top-level/static functions: scalars cross the boundary unboxed.
  function,

  /// Instance members (methods, getters, setters): the dynamic-dispatch
  /// ABI is always boxed so bridge interop sees a consistent interface.
  method,

  /// Constructors: scalars cross the boundary unboxed.
  constructor,

  /// Closures: always boxed (closure values are `$Instance`s).
  closure,

  /// Constructor initializer conventions (`this.x` / `super.y` formals):
  /// same as the constructor boundary.
  initializer,
}

/// Boxing conventions for values that cross a boundary — call arguments,
/// results, field storage, collection elements. The convention is a
/// property of the boundary, not of the type.
abstract final class Abi {
  /// Native representations for non-nullable scalar and String values at
  /// direct call boundaries. Type parameters keep the erased boxed convention.
  static ValueRep unboxedAcrossCalls(TypeRef type) {
    if (type.nullable || type.isTypeParameter) return ValueRep.boxed;
    if (!type.isDartCore) return ValueRep.boxed;
    return switch (type.name) {
      'int' => ValueRep.int,
      'double' => ValueRep.double,
      'bool' => ValueRep.bool,
      'String' => ValueRep.string,
      _ => ValueRep.boxed,
    };
  }

  /// The rep an argument must have when passed for a parameter of [type]
  /// declared on a [kind] callable. [erased] marks parameters whose
  /// annotation names a type parameter of the enclosing declaration —
  /// those take the erased-object (boxed) ABI even on scalars.
  static ValueRep parameter(
    TypeRef type,
    CallableKind kind, {
    bool erased = false,
  }) {
    if (erased) return ValueRep.boxed;
    switch (kind) {
      case CallableKind.function:
      case CallableKind.constructor:
      case CallableKind.initializer:
        return unboxedAcrossCalls(type);
      case CallableKind.method:
      case CallableKind.closure:
        return ValueRep.boxed;
    }
  }

  /// The rep a callable of [kind] returns a value of [type] in.
  /// [isAsync] forces boxed (async results travel as `Future` objects).
  /// `==`/`!=` methods on evaluated classes return their bool unboxed;
  /// pass [unboxedBoolResult] to model that.
  static ValueRep result(
    TypeRef type,
    CallableKind kind, {
    bool isAsync = false,
    bool unboxedBoolResult = false,
  }) {
    if (isAsync) return ValueRep.boxed;
    switch (kind) {
      case CallableKind.function:
      case CallableKind.constructor:
      case CallableKind.initializer:
        return unboxedAcrossCalls(type);
      case CallableKind.method:
        if (unboxedBoolResult) return unboxedAcrossCalls(type);
        return ValueRep.boxed;
      case CallableKind.closure:
        return ValueRep.boxed;
    }
  }

  /// Local and global storage uses native scalars and strings; other values
  /// use boxed object storage. Instance fields follow [fieldStorage].
  static ValueRep storageSlot(TypeRef type) =>
      repForType(type, representationForType(type));

  /// Field storage is always boxed.
  static const fieldStorage = ValueRep.boxed;

  /// Collection elements are always boxed.
  static const collectionElement = ValueRep.boxed;
}

/// The machine layout of one callable. The parameter list includes any
/// receiver and hidden runtime-type slot, in the order the callee receives
/// them. A null result means a synchronous void function.
final class CallableAbi {
  CallableAbi(Iterable<ValueRep> parameters, this.result)
    : parameters = List<ValueRep>.unmodifiable(parameters);

  final List<ValueRep> parameters;
  final ValueRep? result;

  MachineFunctionSignature get machine => MachineFunctionSignature([
    for (final parameter in parameters) parameter.bank,
  ], result?.bank);

  /// Builds the ABI from the declared parameter types, before any call-site
  /// substitution. Substituting a type parameter with `int` must not change
  /// the callee's erased object slot into an integer slot.
  factory CallableAbi.fromParameterTypes(
    Iterable<TypeRef> parameterTypes,
    TypeRef returnType,
    CallableKind kind, {
    int leadingBoxed = 0,
    bool hiddenTypeId = false,
    bool isAsync = false,
    bool returnsVoid = false,
    bool unboxedBoolResult = false,
  }) => CallableAbi(
    [
      for (var i = 0; i < leadingBoxed; i++) ValueRep.boxed,
      for (final type in parameterTypes) Abi.parameter(type, kind),
      if (hiddenTypeId) ValueRep.int,
    ],
    returnsVoid && !isAsync
        ? null
        : kind == CallableKind.constructor
        ? ValueRep.boxed
        : Abi.result(
            returnType,
            kind,
            isAsync: isAsync,
            unboxedBoolResult: unboxedBoolResult,
          ),
  );

  /// A member's declaration ABI, including its implicit receiver and the
  /// trailing runtime type id of a generative constructor.
  factory CallableAbi.of(Member member) {
    final signature = member.signature;
    final node = member is SourceMember ? member.node : null;
    final isConstructor = member.name.kind == MemberKind.constructor;
    if (member is BridgeMember) {
      return CallableAbi([
        if (!member.isStatic && !isConstructor) ValueRep.boxed,
        for (final _ in signature.positional) ValueRep.boxed,
        for (final _ in signature.named) ValueRep.boxed,
      ], ValueRep.boxed);
    }
    if (member.isField && !member.isStatic) {
      return CallableAbi([
        ValueRep.boxed,
        if (member.name.kind == MemberKind.setter) ValueRep.boxed,
      ], ValueRep.boxed);
    }
    final parameterTypes = [
      for (final parameter in signature.positional) parameter.type,
      for (final parameter in signature.named) parameter.type,
    ];
    if (node is MethodDeclaration) {
      return CallableAbi.ofMethod(node, parameterTypes, signature.returnType);
    }
    return CallableAbi.fromParameterTypes(
      parameterTypes,
      signature.returnType,
      isConstructor ? CallableKind.constructor : CallableKind.function,
      leadingBoxed: isConstructor && node?.parent?.parent is EnumDeclaration
          ? 2
          : 0,
      hiddenTypeId:
          isConstructor &&
          (node is ClassDeclaration ||
              node is ConstructorDeclaration && node.factoryKeyword == null),
      returnsVoid: signature.returnType.isSpec(CoreTypes.voidType),
    );
  }

  /// A source method's ABI, shared by its declaration and resolved callers.
  factory CallableAbi.ofMethod(
    MethodDeclaration declaration,
    Iterable<TypeRef> parameterTypes,
    TypeRef returnType,
  ) => CallableAbi.fromParameterTypes(
    parameterTypes,
    returnType,
    CallableKind.method,
    leadingBoxed: declaration.isStatic ? 0 : 1,
    isAsync: declaration.body.isAsynchronous,
    returnsVoid: returnType.isSpec(CoreTypes.voidType),
    unboxedBoolResult:
        declaration.body is ExpressionFunctionBody &&
        !declaration.body.isAsynchronous &&
        (declaration.name.lexeme == '==' || declaration.name.lexeme == '!=') &&
        !Abi.unboxedAcrossCalls(returnType).isBoxed,
  );

  /// A top-level function's ABI, available before it has a function id.
  factory CallableAbi.ofFunction(
    CompilerContext ctx,
    int library,
    FunctionDeclaration declaration,
  ) {
    final signature = CallSignature.forDeclaration(ctx, library, declaration);
    return CallableAbi.fromParameterTypes(
      [
        for (final parameter in signature.positional) parameter.type,
        for (final parameter in signature.named) parameter.type,
      ],
      signature.returnType,
      CallableKind.function,
      isAsync: declaration.functionExpression.body.isAsynchronous,
      returnsVoid: signature.returnType.isSpec(CoreTypes.voidType),
    );
  }

  factory CallableAbi.closure(int parameterCount) => CallableAbi(
    List<ValueRep>.filled(parameterCount + 1, ValueRep.boxed),
    ValueRep.boxed,
  );
}
