import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'context.dart';

Future<void> prepareNativeDefaults(
  BindgenContext ctx,
  AnalysisSession session,
  Element element,
) async {
  final parameters = <FormalParameterElement>[];
  void collect(Element element) {
    if (element is ExecutableElement) {
      parameters.addAll(
        element.formalParameters.where((p) => p.defaultValueCode != null),
      );
    } else if (element is InterfaceElement) {
      for (final member in [
        ...element.constructors,
        ...element.methods,
        ...element.setters,
      ]) {
        collect(member);
      }
    } else if (element is LibraryElement) {
      for (final member in [...element.classes, ...element.topLevelFunctions]) {
        collect(member);
      }
    }
  }

  collect(element);
  if (element is InterfaceElement) {
    for (final type in element.allSupertypes) {
      collect(type.element);
    }
  }
  final libraries = parameters.map((p) => p.library!).toSet();
  for (final library in libraries) {
    final result = await session.getResolvedLibraryByElement(library);
    if (result is! ResolvedLibraryResult) continue;
    for (final parameter in parameters.where((p) => p.library == library)) {
      final declaration = result
          .getFragmentDeclaration(parameter.firstFragment)
          ?.node;
      if (declaration is FormalParameter) {
        final value = declaration.defaultClause?.value;
        if (value != null) {
          ctx.nativeDefaults[parameter.firstFragment.element] = value;
        }
      }
    }
  }
}

/// Host source uses the declaration's resolved namespace. Bridge metadata keeps
/// the original source because it is compiled in the guest library instead.
String? nativeDefaultSource(BindgenContext ctx, FormalParameterElement param) {
  if (ctx.outputIsPart) return param.defaultValueCode;
  final expression = ctx.nativeDefaults[param.firstFragment.element];
  if (expression == null) return param.defaultValueCode;
  final visitor = _NativeSource(ctx);
  expression.accept(visitor);
  // Work against the original text to preserve offsets, comments and spacing.
  final original = param.firstFragment.libraryFragment!.source.contents.data;
  var source = original.substring(expression.offset, expression.end);
  for (final edit
      in visitor.edits..sort((a, b) => b.start.compareTo(a.start))) {
    source = source.replaceRange(
      edit.start - expression.offset,
      edit.end - expression.offset,
      edit.value,
    );
  }
  return source;
}

class _NativeSource extends RecursiveAstVisitor<void> {
  _NativeSource(this.ctx);
  final BindgenContext ctx;
  final edits = <({int start, int end, String value})>[];

  bool replace(int start, int end, Element? element) {
    if (element == null || element.name == null || element.isPrivate) {
      return false;
    }
    if (element is! InterfaceElement &&
        element is! TypeAliasElement &&
        element.enclosingElement is! LibraryElement) {
      return false;
    }
    edits.add((start: start, end: end, value: ctx.nativeName(element)));
    return true;
  }

  @override
  void visitNamedType(NamedType node) {
    replace(node.offset, node.name.end, node.element);
    node.typeArguments?.accept(this);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.prefix.element is PrefixElement &&
        replace(node.offset, node.end, node.element)) {
      return;
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    replace(node.offset, node.end, node.element);
  }
}
