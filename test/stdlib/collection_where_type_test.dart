import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void main() {
  test('collection whereType preserves guest subtype filters', () {
    for (final (mode, result) in runDynamicFixture(r'''
      import 'dart:collection';

      class Node {}
      class Element extends Node {
        final String name;
        Element(this.name);
      }
      class DocumentType extends Node {}

      class NodeList extends ListBase<Node> {
        final List<Node> values;
        NodeList(this.values);
        int get length => values.length;
        set length(int value) => values.length = value;
        Node operator [](int index) => values[index];
        void operator []=(int index, Node value) => values[index] = value;
      }

      bool keepsOnlyElement(Iterable<Node> nodes) {
        final result = nodes.whereType<Element>().toList();
        return result.length == 1 && result.single.name == 'selected';
      }

      bool main() {
        final items = <Node>[DocumentType(), Element('selected')];
        return keepsOnlyElement(NodeList(items)) &&
            keepsOnlyElement(UnmodifiableListView<Node>(items)) &&
            keepsOnlyElement(HashSet<Node>()..addAll(items));
      }
    ''')) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });
}
