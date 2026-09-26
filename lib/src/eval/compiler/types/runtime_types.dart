import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart' show CoreTypes;
import 'package:dart_eval/src/eval/shared/runtime_type_descriptor.dart';

import '../context.dart';
import '../type.dart';

/// Owns the runtime-type tables the backend and Program read: the
/// declaration index map, descriptor ids, and the descriptor list itself.
/// Ids allocate in first-use order — the same order the old
/// `TypeRef.runtimeTypeId`/`_cacheTypeRef` pair produced.
final class RuntimeTypes {
  RuntimeTypes(this._ctx);

  final CompilerContext _ctx;

  /// Registered declarations → their index in the type table.
  final Map<TypeDecl, int> indexMap = {};

  /// Type → descriptor id, allocated on first use. The [TypeRef] value
  /// itself is the key: structural `==` decides identity, so structurally
  /// equal types share one id.
  final Map<TypeRef, int> descriptorIds = {};

  /// Types in descriptor-id order (a type's id is its position here).
  final List<TypeRef> list = [];

  /// Type names parallel to [list].
  final List<String> names = [];

  /// Per-type supertype id sets (parallel to [list]) — filled at emit.
  final List<Set<int>> typeSets = [];

  /// Descriptor lists (parallel to [list]) — filled at emit.
  final List<List<int>> descriptors = [];

  /// Allocates (or fetches) the descriptor id for [type]. Structural type
  /// equality decides identity, so structurally equal types share one id.
  int idOf(TypeRef type) {
    final existing = descriptorIds[type];
    if (existing != null) return existing;
    final id = list.length;
    descriptorIds[type] = id;
    list.add(type);
    names.add(type.name);
    return id;
  }

  /// The registered index for [decl]'s declaration ref — the nominal table
  /// key, distinct from [idOf] which also covers structural types.
  int? declarationIndex(TypeDecl decl) => indexMap[decl];

  /// The runtime descriptor list for [type]: `[parentId, isNullable,
  /// tag?, ...]` in the order the runtime decoder expects.
  List<int> descriptorOf(TypeRef type) {
    if (type.isTypeParameter) {
      final parameter = (type as TypeParameterTypeRef).parameter;
      final owner = parameter.owner;
      final ownerType = owner.isClassLike
          ? idOf(_ctx.visibleTypes[owner.library]![owner.name]!)
          : -(4 + _callableOwnerIdOf(owner));
      // An extension member's callable type parameters are the extension's
      // own parameters followed by the method's — a method-owned parameter's
      // environment index sits past the extension's `on` bindings.
      var index = parameter.index;
      if (owner.kind == TypeParameterOwnerKind.method) {
        index += _extensionParameterOffset(owner);
      }
      return [
        idOf(CoreTypes.dynamic.ref(_ctx)),
        type.nullable ? 1 : 0,
        RuntimeTypeDescriptorTag.typeParameter,
        ownerType,
        index,
        idOf(_boundDescriptorType(parameter)),
      ];
    }
    if (type is RecordTypeRef) {
      return [
        idOf(CoreTypes.record.ref(_ctx)),
        type.nullable ? 1 : 0,
        RuntimeTypeDescriptorTag.record,
        type.positional.length,
        type.named.length,
        for (final field in type.positional) idOf(field),
        for (final field in type.named.entries) ...[
          _ctx.constantPool.addOrGet(field.key),
          idOf(field.value),
        ],
      ];
    }
    final signature = type is FunctionTypeRef ? type.signature : null;
    if (signature != null) {
      final named = signature.named.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      return [
        idOf(CoreTypes.function.ref(_ctx)),
        type.nullable ? 1 : 0,
        RuntimeTypeDescriptorTag.function,
        idOf(signature.returnType),
        signature.requiredPositional,
        signature.positional.length,
        named.length,
        signature.typeParameters.length,
        signature.typeParameters.isEmpty
            ? 0
            : -(4 + _callableOwnerIdOf(signature.typeParameters.first.owner)),
        for (final parameter in signature.typeParameters)
          idOf(_boundDescriptorType(parameter)),
        for (final parameter in signature.positional) idOf(parameter),
        for (final entry in named) ...[
          _ctx.constantPool.addOrGet(entry.key),
          entry.value.required ? 1 : 0,
          idOf(entry.value.type),
        ],
      ];
    }
    return [
      (type is InterfaceTypeRef ? indexMap[type.decl] : null) ?? idOf(type),
      type.nullable ? 1 : 0,
      for (final argument in interfaceArgumentsOf(type)) idOf(argument),
    ];
  }

  final _callableOwnerIds = <TypeParameterOwner, int>{};

  /// A stable negative id identifying a callable's type-parameter space in
  /// descriptors (`-(4 + seq)`). Signature-bound references compare by owner
  /// identity rather than a flat index, so nested signatures do not alias an
  /// enclosing callable's parameters.
  int _callableOwnerIdOf(TypeParameterOwner owner) =>
      _callableOwnerIds.putIfAbsent(owner, () => _callableOwnerIds.length);

  /// The descriptor-ready form of [parameter]'s bound. F-bounds can be
  /// cyclic (`T extends Foo<T>`, or mutually cyclic `S extends Built<S, B>`)
  /// and descriptors can't be — self-erase, lower any chained parameter
  /// references to their bounds, then erase survivors to dynamic.
  TypeRef _boundDescriptorType(TypeParameterDef parameter) =>
      (parameter.bound ?? CoreTypes.dynamic.ref(_ctx))
          .substituteTypeParameters(
            Substitution.of({parameter: CoreTypes.dynamic.ref(_ctx)}),
          )
          .lowerTypeParameters(_ctx)
          .eraseTypeParameters(_ctx);

  /// The number of extension `on` bindings a method-owned [owner]'s callable
  /// environment places before its own type arguments — 0 when the method
  /// is not an extension member.
  int _extensionParameterOffset(TypeParameterOwner owner) {
    final dot = owner.name.indexOf('.');
    if (dot < 0) return 0;
    final extensionName = owner.name.substring(0, dot);
    final methodName = owner.name.substring(dot + 1);
    for (final ext in _ctx.extensions) {
      if (ext.library != owner.library || ext.name != extensionName) {
        continue;
      }
      for (final member in ext.members) {
        if (member is MethodDeclaration && member.name.lexeme == methodName) {
          return ext.declaration.typeParameters?.typeParameters.length ?? 0;
        }
      }
    }
    return 0;
  }
}
