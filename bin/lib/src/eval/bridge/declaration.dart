import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/util.dart';

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
    if (declaration is NamedCompilationUnitMember) {
      return [declaration.name.lexeme];
    } else if (declaration is TopLevelVariableDeclaration) {
      /// Top-level variable declaration
      return declaration.variables.variables.map((v) => v.name.lexeme).toList();
    }
    return [];
  }

  /// Flatten static nested declarations into an iterable of pairs of compound
  /// name to declaration
  /// For example, for a class `A` with a static method `foo`, this will return
  /// `['A', A]` and `['A.foo', foo]`
  static Iterable<Pair<String, DeclarationOrBridge>> expand(
      List<DeclarationOrBridge> declarations) sync* {
    /// Traverse declarations
    for (final d in declarations) {
      if (d.isBridge) {
        yield Pair(nameOf(d)[0], d);
      } else {
        // If it is a source code declaration
        final declaration = d.declaration!;
        if (declaration is NamedCompilationUnitMember) {
          final dName = declaration.name.lexeme;

          /// First yield the declaration itself
          yield Pair(dName, d);

          /// If it is a class declaration
          if (declaration is ClassDeclaration ||
              declaration is EnumDeclaration) {
            /// Then also yield the static class members
            for (final member in (declaration is ClassDeclaration
                ? declaration.members
                : (declaration as EnumDeclaration).members)) {
              if (member is ConstructorDeclaration) {
                yield Pair('$dName.${member.name?.lexeme ?? ""}',
                    DeclarationOrBridge(-1, declaration: member));
              } else if (member is MethodDeclaration && member.isStatic) {
                yield Pair('$dName.${member.name.lexeme}',
                    DeclarationOrBridge(-1, declaration: member));
              }
            }
          }
        } else if (declaration is TopLevelVariableDeclaration) {
          /// Top-level variable declaration
          for (final v in declaration.variables.variables) {
            yield Pair(v.name.lexeme, DeclarationOrBridge(-1, declaration: v));
          }
        }
      }
    }
  }
}
