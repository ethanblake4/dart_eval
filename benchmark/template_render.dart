import 'support/comparison.dart';

// Render a batch of invoices through a heterogeneous template tree.
// dart compile exe benchmark/template_render.dart -o .dart_tool/template-baseline.exe
// .dart_tool/template-baseline.exe [documents] [samples]
const _source = r'''
abstract class Node {
  void render(Map<String, Object?> context, StringBuffer out);
}

void renderNodes(List<Node> nodes, Map<String, Object?> context, StringBuffer out) {
  for (final node in nodes) {
    node.render(context, out);
  }
}

class TextNode extends Node {
  TextNode(this.text);
  final String text;

  void render(Map<String, Object?> context, StringBuffer out) {
    out.write(text);
  }
}

class FieldNode extends Node {
  FieldNode(this.key, this.fallback);
  final String key;
  final String fallback;

  void render(Map<String, Object?> context, StringBuffer out) {
    final value = context[key];
    out.write(value == null ? fallback : value.toString());
  }
}

class ConditionalNode extends Node {
  ConditionalNode(this.key, this.whenTrue, this.whenFalse);
  final String key;
  final List<Node> whenTrue;
  final List<Node> whenFalse;

  void render(Map<String, Object?> context, StringBuffer out) {
    renderNodes(context[key] == true ? whenTrue : whenFalse, context, out);
  }
}

class SectionNode extends Node {
  SectionNode(this.key, this.children, this.whenEmpty);
  final String key;
  final List<Node> children;
  final List<Node> whenEmpty;

  void render(Map<String, Object?> context, StringBuffer out) {
    final rows = context[key] as List;
    if (rows.isEmpty) {
      renderNodes(whenEmpty, context, out);
      return;
    }
    for (final row in rows) {
      renderNodes(children, row as Map<String, Object?>, out);
    }
  }
}

int main(int documents) {
  final row = <Node>[
    TextNode('- '),
    FieldNode('title', '(untitled)'),
    TextNode(' x'),
    FieldNode('quantity', '0'),
    ConditionalNode('urgent', <Node>[TextNode(' !')], <Node>[]),
    TextNode('\n'),
  ];
  final template = <Node>[
    TextNode('Hello '),
    FieldNode('name', 'guest'),
    TextNode(',\n'),
    ConditionalNode(
      'premium',
      <Node>[TextNode('Priority order\n')],
      <Node>[TextNode('Standard order\n')],
    ),
    TextNode('Items:\n'),
    SectionNode('items', row, <Node>[TextNode('(none)\n')]),
    TextNode('Note: '),
    FieldNode('note', '-'),
    TextNode('\n'),
  ];
  final contexts = <Map<String, Object?>>[
    <String, Object?>{
      'name': 'Ada', 'premium': true, 'note': 'Call on arrival',
      'items': <Map<String, Object?>>[
        <String, Object?>{'title': 'laptop', 'quantity': 1, 'urgent': true},
        <String, Object?>{'title': 'case', 'quantity': 2, 'urgent': false},
      ],
    },
    <String, Object?>{
      'name': 'Ben', 'premium': false, 'note': null,
      'items': <Map<String, Object?>>[
        <String, Object?>{'title': 'cable', 'quantity': 4, 'urgent': false},
      ],
    },
    <String, Object?>{
      'name': null, 'premium': false, 'note': 'Backordered',
      'items': <Map<String, Object?>>[],
    },
    <String, Object?>{
      'name': 'Dia', 'premium': true, 'note': 'Gift wrap',
      'items': <Map<String, Object?>>[
        <String, Object?>{'title': 'book', 'quantity': 3, 'urgent': false},
        <String, Object?>{'title': null, 'quantity': 1, 'urgent': true},
        <String, Object?>{'title': 'pen', 'quantity': 5, 'urgent': false},
      ],
    },
  ];

  var checksum = 0;
  for (var i = 0; i < documents; i++) {
    final out = StringBuffer();
    renderNodes(template, contexts[i % contexts.length], out);
    final rendered = out.toString();
    checksum += rendered.length + rendered.codeUnitAt(0) * 31 +
        rendered.codeUnitAt(rendered.length ~/ 2) +
        rendered.codeUnitAt(rendered.length - 1) * 7;
  }
  return checksum;
}
''';

void main(List<String> args) => runComparison(
  args,
  name: 'template_render',
  source: _source,
  parameter: 'documents',
  unit: 'document',
  iterations: 20000,
  warmupIterations: 100,
);
