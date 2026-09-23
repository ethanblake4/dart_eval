import 'package:dart_eval/dart_eval_bridge.dart' show CoreTypes;
import 'package:dart_eval/src/eval/compiler/model/function_type.dart';
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

  /// Registered declaration refs → their index in the type table.
  final Map<TypeRef, int> indexMap = {};

  /// Semantic key → descriptor id, allocated on first use.
  final Map<String, int> descriptorIds = {};

  /// Types in descriptor-id order (a type's id is its position here).
  final List<TypeRef> list = [];

  /// Type names parallel to [list].
  final List<String> names = [];

  /// Per-type supertype id sets (parallel to [list]) — filled at emit.
  final List<Set<int>> typeSets = [];

  /// Descriptor lists (parallel to [list]) — filled at emit.
  final List<List<int>> descriptors = [];

  /// Allocates (or fetches) the descriptor id for [type]. The semantic key
  /// — declaration, arguments, records, signature, nullability — decides
  /// identity, so structurally equal types share one id.
  int idOf(TypeRef type) {
    final key = type.semanticKey;
    final existing = descriptorIds[key];
    if (existing != null) return existing;
    final id = list.length;
    descriptorIds[key] = id;
    list.add(type);
    names.add(type.name);
    return id;
  }

  /// The registered index for [decl]'s declaration ref — the nominal table
  /// key, distinct from [idOf] which also covers structural types.
  int? declarationIndex(TypeDecl decl) => indexMap[decl.rawType];

  /// Every runtime type index a value of [type] may report `is`/`as`
  /// success for: its own id plus every declared supertype's, walked with
  /// substitutions applied at each hop.
  Set<int> supertypeIds(TypeRef type) => _ctx.typeSystem.supertypeIds(type);

  /// The runtime descriptor list for [type]: `[parentId, isNullable,
  /// tag?, ...]` in the order the runtime decoder expects.
  List<int> descriptorOf(TypeRef type) {
    if (type.isTypeParameter) {
      final parameter = type.parameter!;
      final owner = parameter.owner;
      final ownerType = owner.isClassLike
          ? idOf(_ctx.visibleTypes[owner.library]![owner.name]!)
          : RuntimeTypeDescriptorTag.callableTypeParameterOwner;
      return [
        idOf(CoreTypes.dynamic.ref(_ctx)),
        type.nullable ? 1 : 0,
        RuntimeTypeDescriptorTag.typeParameter,
        ownerType,
        parameter.index,
        // F-bounds reference the parameter itself (`T extends Foo<T>`); erase
        // the self-reference to dynamic — descriptors can't be cyclic.
        idOf(
          (parameter.bound ?? CoreTypes.dynamic.ref(_ctx))
              .substituteTypeParameters(
                Substitution.of({parameter: CoreTypes.dynamic.ref(_ctx)}),
              ),
        ),
      ];
    }
    if (type.recordFields.isNotEmpty) {
      final positional = type.recordPositionalFields;
      final named = type.recordNamedFields;
      return [
        idOf(CoreTypes.record.ref(_ctx)),
        type.nullable ? 1 : 0,
        RuntimeTypeDescriptorTag.record,
        positional.length,
        named.length,
        for (final field in positional) idOf(field.type),
        for (final field in named) ...[
          _ctx.constantPool.addOrGet(field.name!),
          idOf(field.type),
        ],
      ];
    }
    final signature = type.functionType;
    if (signature != null && signature.generics.isEmpty) {
      TypeRef resolve(FunctionTypeAnnotation annotation) =>
          annotation.type ?? CoreTypes.dynamic.ref(_ctx);
      final positional = [
        ...signature.normalParameters,
        ...signature.optionalParameters,
      ];
      final named = signature.namedParameters.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      return [
        idOf(CoreTypes.function.ref(_ctx)),
        type.nullable ? 1 : 0,
        RuntimeTypeDescriptorTag.function,
        idOf(resolve(signature.returnType)),
        signature.normalParameters.length,
        positional.length,
        named.length,
        for (final parameter in positional) idOf(resolve(parameter.type)),
        for (final entry in named) ...[
          _ctx.constantPool.addOrGet(entry.key),
          entry.value.isRequired ? 1 : 0,
          idOf(resolve(entry.value.type)),
        ],
      ];
    }
    return [
      indexMap[type] ?? idOf(type),
      type.nullable ? 1 : 0,
      for (final argument in type.specifiedTypeArgs) idOf(argument),
    ];
  }
}
