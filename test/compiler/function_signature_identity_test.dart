import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:test/test.dart';

final _context = CompilerContext();
final _functionDecl = BridgeTypeDecl(_context, 0, 'dart:core', 'Function');
final _int = BridgeTypeDecl(_context, 0, 'dart:core', 'int').rawType;
final _num = BridgeTypeDecl(_context, 0, 'dart:core', 'num').rawType;
final _box = BridgeTypeDecl(_context, 1, 'package:test/box.dart', 'Box');

TypeParameterDef _parameter(int owner, String name) => TypeParameterDef(
  TypeParameterOwner(
    TypeParameterOwnerKind.functionTypeAnnotation,
    0,
    '',
    owner,
  ),
  0,
  name,
);

FunctionSignature _nestedSignature(
  TypeParameterDef outer,
  TypeParameterDef inner, {
  required bool usesOuter,
}) {
  final outerRef = TypeParameterTypeRef(outer);
  final innerRef = TypeParameterTypeRef(inner);
  final nested = FunctionTypeRef(
    FunctionSignature(
      typeParameters: [inner],
      positional: [usesOuter ? outerRef : innerRef],
      requiredPositional: 1,
      returnType: innerRef,
    ),
    decl: _functionDecl,
  );
  return FunctionSignature(
    typeParameters: [outer],
    positional: [outerRef],
    requiredPositional: 1,
    returnType: nested,
  );
}

void main() {
  test('renamed nested generic binders are alpha equivalent', () {
    final first = _nestedSignature(
      _parameter(1, 'T'),
      _parameter(2, 'U'),
      usesOuter: true,
    );
    final second = _nestedSignature(
      _parameter(3, 'A'),
      _parameter(4, 'B'),
      usesOuter: true,
    );

    expect(first, second);
    expect(first.hashCode, second.hashCode);
  });

  test('nested references distinguish outer and inner parameters', () {
    final outerReference = _nestedSignature(
      _parameter(5, 'T'),
      _parameter(6, 'U'),
      usesOuter: true,
    );
    final innerReference = _nestedSignature(
      _parameter(7, 'A'),
      _parameter(8, 'B'),
      usesOuter: false,
    );

    expect(outerReference, isNot(innerReference));
  });

  test('generic bounds contribute to signature identity', () {
    final t = _parameter(9, 'T')..bound = _int;
    final u = _parameter(10, 'U')..bound = _num;
    final first = FunctionSignature(
      typeParameters: [t],
      positional: [TypeParameterTypeRef(t)],
      requiredPositional: 1,
      returnType: TypeParameterTypeRef(t),
    );
    final second = FunctionSignature(
      typeParameters: [u],
      positional: [TypeParameterTypeRef(u)],
      requiredPositional: 1,
      returnType: TypeParameterTypeRef(u),
    );

    expect(first, isNot(second));
  });

  test('renamed F-bounds have equal signatures and hashes', () {
    final t = _parameter(11, 'T');
    final u = _parameter(12, 'U');
    t.bound = _box.instantiate([TypeParameterTypeRef(t)]);
    u.bound = _box.instantiate([TypeParameterTypeRef(u)]);
    final first = FunctionSignature(
      typeParameters: [t],
      positional: [TypeParameterTypeRef(t)],
      requiredPositional: 1,
      returnType: TypeParameterTypeRef(t),
    );
    final second = FunctionSignature(
      typeParameters: [u],
      positional: [TypeParameterTypeRef(u)],
      requiredPositional: 1,
      returnType: TypeParameterTypeRef(u),
    );

    expect(first, second);
    expect(first.hashCode, second.hashCode);
  });

  test('named parameter order does not affect equality or hash', () {
    final first = FunctionSignature(
      positional: const [],
      requiredPositional: 0,
      named: {
        'first': (type: _int, required: true),
        'second': (type: _num, required: false),
      },
      returnType: _num,
    );
    final second = FunctionSignature(
      positional: const [],
      requiredPositional: 0,
      named: {
        'second': (type: _num, required: false),
        'first': (type: _int, required: true),
      },
      returnType: _num,
    );

    expect(first, second);
    expect(first.hashCode, second.hashCode);
  });
}
