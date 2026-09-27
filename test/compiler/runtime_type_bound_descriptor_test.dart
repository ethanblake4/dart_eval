import 'package:dart_eval/dart_eval_bridge.dart' show CoreTypes;
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:test/test.dart';

CompilerContext _context() {
  final ctx = CompilerContext()
    ..libraryMap['dart:core'] = 0
    ..libraryMap['package:test/main.dart'] = 1;
  final core = <String, TypeRef>{};
  for (final name in ['dynamic', 'Function', 'List']) {
    final decl = BridgeTypeDecl(ctx, 0, 'dart:core', name);
    ctx.types.register(decl);
    core[name] = decl.rawType;
  }
  ctx.visibleTypes[0] = core;
  final owner = BridgeTypeDecl(ctx, 1, 'package:test/main.dart', 'C');
  ctx.types.register(owner);
  ctx.visibleTypes[1] = {'C': owner.rawType};
  return ctx;
}

TypeParameterDef _classParameter() => TypeParameterDef(
  const TypeParameterOwner(TypeParameterOwnerKind.classLike, 1, 'C'),
  0,
  'T',
);

TypeParameterDef _methodParameter(int index, String name) => TypeParameterDef(
  const TypeParameterOwner(TypeParameterOwnerKind.method, 1, 'C.foo'),
  index,
  name,
);

TypeRef _boundInDescriptor(CompilerContext ctx, TypeParameterDef parameter) {
  final signature = FunctionSignature(
    typeParameters: [parameter],
    positional: const [],
    requiredPositional: 0,
    returnType: CoreTypes.dynamic.ref(ctx),
  );
  final function = FunctionTypeRef(
    signature,
    decl: ctx.types.bySpec(CoreTypes.function),
  );
  final descriptor = ctx.runtimeTypes.descriptorOf(function);
  // The first signature bound follows the function header's nine slots.
  return ctx.runtimeTypes.list[descriptor[9]];
}

void main() {
  test('method bound preserves a class parameter', () {
    final ctx = _context();
    final t = _classParameter();
    final s = _methodParameter(0, 'S')..bound = TypeParameterTypeRef(t);

    expect(_boundInDescriptor(ctx, s), TypeParameterTypeRef(t));
  });

  test('method bound preserves a class parameter inside a generic type', () {
    final ctx = _context();
    final t = _classParameter();
    final list = ctx.types.bySpec(CoreTypes.list);
    final s = _methodParameter(0, 'S')
      ..bound = list.instantiate([TypeParameterTypeRef(t)]);

    expect(
      _boundInDescriptor(ctx, s),
      list.instantiate([TypeParameterTypeRef(t)]),
    );
  });

  test('recursive signatures retain the binder with a finite fallback', () {
    final ctx = _context();
    final list = ctx.types.bySpec(CoreTypes.list);
    final s = _methodParameter(0, 'S');
    s.bound = list.instantiate([TypeParameterTypeRef(s)]);

    final bound = _boundInDescriptor(ctx, s) as InterfaceTypeRef;
    expect(bound.arguments.single, TypeParameterTypeRef(s));
    final parameter = ctx.runtimeTypes.descriptorOf(TypeParameterTypeRef(s));
    final fallback = ctx.runtimeTypes.list[parameter[5]] as InterfaceTypeRef;
    expect(fallback.arguments.single.isSpec(CoreTypes.dynamic), isTrue);
  });
}
