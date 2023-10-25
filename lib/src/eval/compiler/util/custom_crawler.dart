import 'package:directed_graph/directed_graph.dart';

/// Custom graph crawler with vastly better performance than the original.
class FastCrawler<T extends Object> extends GraphCrawler<T> {
  FastCrawler(super.edges);

  @override
  List<Set<T>> tree(T start, [T? target]) {
    final result = <Set<T>>[
      for (final connected in edges(start)) {connected}
    ];

    if (result.isEmpty) return result;

    var startIndexOld = 0;
    var startIndexNew = 0;
    final visited = <T>{};
    do {
      startIndexNew = result.length;
      for (var i = startIndexOld; i < startIndexNew; ++i) {
        final path = result[i];
        if (visited.contains(path.last)) continue;
        visited.add(path.last);
        for (final vertex in edges(path.last)) {
          // Discard walks which reach the same (inner) vertex twice.
          // Each path starts with [start] even though it is not
          // listed!
          if (path.contains(vertex) || path.contains(start)) {
            continue;
          } else {
            result.add({...path, vertex});
          }
          if (vertex == target) break;
        }
      }
      startIndexOld = startIndexNew;
    } while (startIndexNew < result.length);
    return result;
  }
}

/// Caching version of the above
class CachedFastCrawler<T extends Object> extends GraphCrawler<T> {
  CachedFastCrawler(super.edges);

  final _cache = <T, List<Set<T>>>{};

  @override
  List<Set<T>> tree(T start, [T? target]) {
    if (_cache.containsKey(start)) return _cache[start]!;
    return _cache[start] = super.tree(start, target);
  }
}
