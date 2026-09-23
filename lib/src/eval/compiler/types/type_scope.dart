import '../type.dart';

/// One frame in a library's type-parameter environment: the type
/// parameters the innermost enclosing declaration introduced (a class's
/// own parameters, a method's, a function's) mapped by name. Frames form
/// a chain — a nested declaration's frame shadows same-named outer
/// parameters without mutating them.
final class TypeScope {
  TypeScope(this.parent);

  final TypeScope? parent;

  /// The type parameters this frame introduces — mutable for the life of
  /// the frame so seeds (mixin application arguments, folded member
  /// bindings, bound resolution passes) can land after the frame opens.
  final Map<String, TypeRef> entries = {};

  /// The innermost binding for [name], or null when out of scope.
  TypeRef? operator [](Object? name) => entries[name] ?? parent?[name];
}
