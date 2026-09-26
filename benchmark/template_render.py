from support.comparison import run_comparison


class Node:
    def render(self, context: dict[str, object], out: list[str]) -> None:
        raise NotImplementedError


def render_nodes(nodes: list[Node], context: dict[str, object], out: list[str]) -> None:
    for node in nodes:
        node.render(context, out)


class TextNode(Node):
    def __init__(self, text: str) -> None:
        self.text = text

    def render(self, context: dict[str, object], out: list[str]) -> None:
        out.append(self.text)


class FieldNode(Node):
    def __init__(self, key: str, fallback: str) -> None:
        self.key = key
        self.fallback = fallback

    def render(self, context: dict[str, object], out: list[str]) -> None:
        value = context.get(self.key)
        out.append(self.fallback if value is None else str(value))


class ConditionalNode(Node):
    def __init__(self, key: str, when_true: list[Node], when_false: list[Node]) -> None:
        self.key = key
        self.when_true = when_true
        self.when_false = when_false

    def render(self, context: dict[str, object], out: list[str]) -> None:
        render_nodes(self.when_true if context.get(self.key) is True else self.when_false,
                     context, out)


class SectionNode(Node):
    def __init__(self, key: str, children: list[Node], when_empty: list[Node]) -> None:
        self.key = key
        self.children = children
        self.when_empty = when_empty

    def render(self, context: dict[str, object], out: list[str]) -> None:
        rows = context[self.key]
        if not rows:
            render_nodes(self.when_empty, context, out)
            return
        for row in rows:
            render_nodes(self.children, row, out)


def main(documents: int) -> int:
    row: list[Node] = [
        TextNode('- '),
        FieldNode('title', '(untitled)'),
        TextNode(' x'),
        FieldNode('quantity', '0'),
        ConditionalNode('urgent', [TextNode(' !')], []),
        TextNode('\n'),
    ]
    template: list[Node] = [
        TextNode('Hello '),
        FieldNode('name', 'guest'),
        TextNode(',\n'),
        ConditionalNode('premium', [TextNode('Priority order\n')],
                        [TextNode('Standard order\n')]),
        TextNode('Items:\n'),
        SectionNode('items', row, [TextNode('(none)\n')]),
        TextNode('Note: '),
        FieldNode('note', '-'),
        TextNode('\n'),
    ]
    contexts: list[dict[str, object]] = [
        {
            'name': 'Ada', 'premium': True, 'note': 'Call on arrival',
            'items': [
                {'title': 'laptop', 'quantity': 1, 'urgent': True},
                {'title': 'case', 'quantity': 2, 'urgent': False},
            ],
        },
        {
            'name': 'Ben', 'premium': False, 'note': None,
            'items': [
                {'title': 'cable', 'quantity': 4, 'urgent': False},
            ],
        },
        {
            'name': None, 'premium': False, 'note': 'Backordered',
            'items': [],
        },
        {
            'name': 'Dia', 'premium': True, 'note': 'Gift wrap',
            'items': [
                {'title': 'book', 'quantity': 3, 'urgent': False},
                {'title': None, 'quantity': 1, 'urgent': True},
                {'title': 'pen', 'quantity': 5, 'urgent': False},
            ],
        },
    ]

    checksum = 0
    for i in range(documents):
        out: list[str] = []
        render_nodes(template, contexts[i % len(contexts)], out)
        rendered = ''.join(out)
        checksum += (len(rendered) + ord(rendered[0]) * 31
                     + ord(rendered[len(rendered) // 2])
                     + ord(rendered[-1]) * 7)
    return checksum


if __name__ == '__main__':
    run_comparison(
        'template_render', main, unit='document',
        iterations=20000, warmup_iterations=100,
    )
