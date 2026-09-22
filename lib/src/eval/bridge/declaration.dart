import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';

import 'package:dart_eval/src/eval/compiler/errors.dart';

/// A Bridge declaration declares an element that is transferrable between the
/// Dart and dart_eval VM.
class BridgeDeclaration {
  const BridgeDeclaration();
}

/// Represents a declaration, which my be a standard Dart declaration or a
/// dart_eval bridge declaration.
class DeclarationOrBridge<T extends Declaration, R extends BridgeDeclaration> {
  DeclarationOrBridge(this.sourceLib, {this.declaration, this.bridge})
    : assert(declaration != null || bridge != null);

  int sourceLib;
  T? declaration;
  R? bridge;

  bool get isBridge => bridge != null;

  static List<String> nameOf(DeclarationOrBridge d) {
    if (d.isBridge) {
      /// Process bridge declaration
      final bridge = d.bridge as BridgeDeclaration;

      /// Find the declaration name according to its specific type
      if (bridge is BridgeClassDef) {
        /// Bridge class name
        return [bridge.type.type.spec!.name];
      } else if (bridge is BridgeEnumDef) {
        /// Bridge enumeration name
        return [bridge.type.spec!.name];
      } else if (bridge is BridgeFunctionDeclaration) {
        /// This is simple, directly yield the function name
        return [bridge.name];
      }
    }
    final declaration = d.declaration!;
    if (declaration is ClassDeclaration) {
      return [declaration.namePart.typeName.lexeme];
    } else if (declaration is EnumDeclaration) {
      return [declaration.namePart.typeName.lexeme];
    } else if (declaration is FunctionDeclaration) {
      // Accessors carry the `*g`/`*s` suffix (same keying as class members).
      final base = declaration.name.toString();
      if (declaration.isGetter) return ['$base*g'];
      if (declaration.isSetter) return ['$base*s'];
      return [base];
    } else if (declaration is TopLevelVariableDeclaration) {
      /// Top-level variable declaration
      return declaration.variables.variables.map((v) => v.name.lexeme).toList();
    } else if (declaration is TypeAlias) {
      return [declaration.name.lexeme];
    } else if (declaration is MixinDeclaration) {
      return [declaration.name.lexeme];
    } else if (declaration is ExtensionTypeDeclaration) {
      return [declaration.namePart.typeName.lexeme];
    } else if (declaration is ExtensionDeclaration) {
      /// `extension on T` may be unnamed.
      final name = declaration.name;
      return name == null ? const [] : [name.lexeme];
    } else {
      throw CompileError('Unsupported!');
    }
  }

  /// Flatten static nested declarations into an iterable of pairs of compound
  /// name to declaration
  /// For example, for a class `A` with a static method `foo`, this will return
  /// `['A', A]` and `['A.foo', foo]`
  static Iterable<(String, DeclarationOrBridge)> expand(
    List<DeclarationOrBridge> declarations,
  ) sync* {
    /// Traverse declarations
    for (final d in declarations) {
      if (d.isBridge) {
        yield (nameOf(d)[0], d);
      } else {
        // If it is a source code declaration
        final declaration = d.declaration!;

        if (declaration is ClassDeclaration) {
          final dName = declaration.namePart.typeName.lexeme;

          /// First yield the declaration itself
          yield (dName, d);

          /// Then also yield the static class members
          for (final member in declaration.body.members) {
            if (member is ConstructorDeclaration) {
              yield (
                '$dName.${member.name?.lexeme ?? ""}',
                DeclarationOrBridge(-1, declaration: member),
              );
            } else if (member is MethodDeclaration && member.isStatic) {
              yield (
                '$dName.${member.name.lexeme}',
                DeclarationOrBridge(-1, declaration: member),
              );
            }
          }
        } else if (declaration is EnumDeclaration) {
          final dName = declaration.namePart.typeName.lexeme;

          /// First yield the declaration itself
          yield (dName, d);

          /// Then also yield the static class members
          for (final member in declaration.body.members) {
            if (member is ConstructorDeclaration) {
              yield (
                '$dName.${member.name?.lexeme ?? ""}',
                DeclarationOrBridge(-1, declaration: member),
              );
            } else if (member is MethodDeclaration && member.isStatic) {
              yield (
                '$dName.${member.name.lexeme}',
                DeclarationOrBridge(-1, declaration: member),
              );
            }
          }
        } else if (declaration is TopLevelVariableDeclaration) {
          /// Top-level variable declaration
          for (final v in declaration.variables.variables) {
            yield (v.name.lexeme, DeclarationOrBridge(-1, declaration: v));
          }
        } else if (declaration is FunctionDeclaration) {
          final dName = declaration.name.toString();

          // Accessors key under `*g`/`*s` like class members so a getter and
          // setter of the same name (across imports or in one library) don't
          // collide.
          yield (
            declaration.isGetter
                ? '$dName*g'
                : declaration.isSetter
                ? '$dName*s'
                : dName,
            d,
          );
        } else {
          // Typedefs, mixins, extension types, etc. contribute no members.
          for (final name in nameOf(d)) {
            yield (name, d);
          }
        }
      }
    }
  }
}

/// Either a concrete declaration or a deferred import-prefix namespace
/// whose [children] are filled in once the library is compiled.
class DeclarationOrPrefix {
  DeclarationOrPrefix({this.declaration, this.children});

  DeclarationOrBridge? declaration;
  Map<String, DeclarationOrBridge>? children;
}
