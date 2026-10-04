import 'package:test/test.dart';
import '../support/dynamic_fixtures.dart';

void main() {
  test('multi-mixin parent references retain inherited field storage', () {
    const source = '''
class Node {
  Node? parentNode;
  Element? get parent {
    final parentNode = this.parentNode;
    return parentNode is Element ? parentNode : null;
  }
  Map<String, String> attributes = {};
  late final nodes = NodeList(this);
  String describe() => 'node';
  String dispatch() => describe();
  Node._();
}
mixin ParentNode implements Node { void append(Node node) { nodes.add(node); } }
abstract mixin class ElementAndDocument implements ParentNode {}
class Element extends Node with ParentNode, ElementAndDocument {
  final String tag;
  Element(this.tag) : super._();
  String get id { final result = attributes['id']; return result ?? ''; }
  String describe() => 'element';
  String get baseDescription => super.describe();
}
class NodeList {
  final Node owner;
  NodeList(this.owner);
  void add(Node node) { node.parentNode = owner; }
}
bool main() {
  final parent = Element('ul');
  parent.attributes['id'] = 'list';
  final child = Element('li');
  parent.append(child);
  return identical(child.parent, parent) &&
      child.parent!.id == 'list' && child.id == '' &&
      child.parent!.dispatch() == 'element' &&
      child.parent!.baseDescription == 'node' && Element('orphan').parent == null;
}
''';
    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });

  test('a parent reference still rejects an unrelated subtype cast', () {
    const source = '''
class Node {
  late final nodes = NodeList(this);
}
mixin ParentNode implements Node {}
mixin ElementAndDocument implements ParentNode {}
class Element extends Node with ParentNode, ElementAndDocument {}
class Other extends Node {}
class NodeList {
  final Node owner;
  NodeList(this.owner);
}
Other main() {
  final element = Element();
  return element.nodes.owner as Other;
}
''';
    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.error(TypeError), reason: mode);
    }
  });
}
