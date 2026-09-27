import 'support/comparison.dart';

// Lazy depth-first traversal, as used by tree visitors and directory walkers.
const _source = r'''
Iterable<int> leaves(int node, int depth) sync* {
  if (depth == 0) {
    yield node;
    return;
  }
  yield* leaves(node * 2, depth - 1);
  yield* leaves(node * 2 + 1, depth - 1);
}

int main(int trees) {
  var checksum = 0;
  for (var tree = 0; tree < trees; tree++) {
    for (final leaf in leaves(tree + 1, 7)) {
      checksum += leaf;
    }
  }
  return checksum;
}
''';

void main(List<String> args) => runComparison(
  args,
  name: 'generator_tree',
  source: _source,
  parameter: 'trees',
  unit: 'tree',
  iterations: 100,
  warmupIterations: 2,
);
