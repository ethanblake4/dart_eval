import 'package:dart_eval/dart_eval_bridge.dart' show AsyncTypes, CoreTypes;
import 'package:dart_eval/src/eval/shared/runtime_type_descriptor.dart';

import '../context.dart';
import '../errors.dart';
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
    if (type.hasSchemaHoles) {
      throw CompileError(
        'Unresolved type schema $type reached runtime metadata',
      );
    }
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
      final ownerType = ownerIdOf(owner);
      return [
        idOf(CoreTypes.dynamic.ref(_ctx)),
        type.nullable ? 1 : 0,
        RuntimeTypeDescriptorTag.typeParameter,
        ownerType,
        parameter.index,
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
            : ownerIdOf(signature.typeParameters.first.owner),
        // A signature binds its own parameters. Keep dependent/F-bounds
        // symbolic for alpha-equivalent subtype checks and type display.
        for (final parameter in signature.typeParameters)
          idOf(parameter.bound ?? CoreTypes.dynamic.ref(_ctx)),
        for (final parameter in signature.positional) idOf(parameter),
        for (final entry in named) ...[
          _ctx.constantPool.addOrGet(entry.key),
          entry.value.required ? 1 : 0,
          idOf(entry.value.type),
        ],
      ];
    }
    // `FutureOr<S>` has no runtime descriptor — it is a compile-time union.
    // Wherever a type check can't see the union (parameter descriptors,
    // type literals) degrade to `Object?`, matching the old `dynamic`
    // behavior. `is`/`as` desugar the union before reaching here.
    if (type is InterfaceTypeRef && type.decl.isSpec(AsyncTypes.futureOr)) {
      return [idOf(CoreTypes.object.ref(_ctx)), 1];
    }
    return [
      (type is InterfaceTypeRef ? indexMap[type.decl] : null) ?? idOf(type),
      type.nullable ? 1 : 0,
      for (final argument
          in type is InterfaceTypeRef && type.arguments.isEmpty
              ? type.decl.defaultTypeArguments
              : interfaceArgumentsOf(type))
        idOf(argument),
    ];
  }

  final _callableOwnerIds = <TypeParameterOwner, int>{};

  /// Encode a parameter owner's runtime descriptor identity.
  int ownerIdOf(TypeParameterOwner owner) => owner.isClassLike
      ? idOf(_ctx.visibleTypes[owner.library]![owner.name]!)
      : -(4 + _callableOwnerIdOf(owner));

  /// A stable negative id identifying a callable's type-parameter space in
  /// descriptors (`-(4 + seq)`). Signature-bound references compare by owner
  /// identity rather than a flat index, so nested signatures do not alias an
  /// enclosing callable's parameters.
  int _callableOwnerIdOf(TypeParameterOwner owner) =>
      _callableOwnerIds.putIfAbsent(owner, () => _callableOwnerIds.length);

  static final _callableOwnerKinds = TypeParameterOwnerKind.values
      .where((kind) => kind != TypeParameterOwnerKind.classLike)
      .toSet();

  /// The descriptor-ready form of [parameter]'s bound. F-bounds can be
  /// cyclic (`T extends Foo<T>`, or mutually cyclic `S extends Built<S, B>`)
  /// and descriptors can't be. Preserve class parameters, which resolve
  /// through the receiver's type environment, unless their bounds lead back
  /// to this parameter. Lower callable parameters and erase the survivors.
  TypeRef _boundDescriptorType(TypeParameterDef parameter) {
    final bound = (parameter.bound ?? CoreTypes.dynamic.ref(_ctx))
        .substituteTypeParameters(
          Substitution.of({parameter: CoreTypes.dynamic.ref(_ctx)}),
        )
        .lowerTypeParameters(_ctx, only: const {}, kinds: _callableOwnerKinds)
        .eraseTypeParameters(
          _ctx,
          preserveKinds: const {TypeParameterOwnerKind.classLike},
        );
    final cyclic = <TypeParameterDef>{};
    for (final candidate in _typeParametersIn(bound)) {
      if (candidate.owner.isClassLike &&
          _boundDependsOn(candidate, parameter, {})) {
        cyclic.add(candidate);
      }
    }
    return cyclic.isEmpty
        ? bound
        : bound.substituteTypeParameters(
            Substitution.of({
              for (final candidate in cyclic)
                candidate: CoreTypes.dynamic.ref(_ctx),
            }),
          );
  }

  bool _boundDependsOn(
    TypeParameterDef source,
    TypeParameterDef target,
    Set<TypeParameterDef> visited,
  ) {
    if (source == target) return true;
    if (!visited.add(source) || source.bound == null) return false;
    return _typeParametersIn(
      source.bound!,
    ).any((next) => _boundDependsOn(next, target, visited));
  }

  Iterable<TypeParameterDef> _typeParametersIn(TypeRef type) sync* {
    switch (type) {
      case UnknownTypeRef():
        return;
      case TypeParameterTypeRef(:final parameter):
        yield parameter;
      case InterfaceTypeRef(:final arguments):
        for (final argument in arguments) {
          yield* _typeParametersIn(argument);
        }
      case RecordTypeRef(:final positional, :final named):
        for (final field in positional) {
          yield* _typeParametersIn(field);
        }
        for (final field in named.values) {
          yield* _typeParametersIn(field);
        }
      case FunctionTypeRef(:final signature):
        for (final parameter in signature.typeParameters) {
          if (parameter.bound != null) {
            yield* _typeParametersIn(parameter.bound!);
          }
        }
        yield* _typeParametersIn(signature.returnType);
        for (final parameter in signature.positional) {
          yield* _typeParametersIn(parameter);
        }
        for (final parameter in signature.named.values) {
          yield* _typeParametersIn(parameter.type);
        }
    }
  }
}
