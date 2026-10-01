import 'package:dart_eval/dart_eval.dart';

// Price repeated purchase baskets against a host inventory feed, a guest
// contract-price view, or alternating feed/view rows. Build this host with AOT.
const common = r'''
import 'dart:collection';
class ContractPrices extends MapBase<String?, int?> {
  ContractPrices(this.prices)
      : bolts = (prices['bolts'] ?? 0) + 2,
        panels = (prices['panels'] ?? 0) + 2,
        sealant = (prices['sealant'] ?? 0) + 2,
        brackets = (prices['brackets'] ?? 0) + 2,
        freight = (prices[null] ?? 0) + 2;
  final Map<String?, int?> prices;
  final int bolts;
  final int panels;
  final int sealant;
  final int brackets;
  final int freight;
  Iterable<String?> get keys => prices.keys;
  int? operator [](Object? key) {
    switch (key) {
      case 'bolts': return bolts;
      case 'panels': return panels;
      case 'sealant': return sealant;
      case 'brackets': return brackets;
      case null: return freight;
      default: return null;
    }
  }
  void operator []=(String? key, int? value) => throw UnsupportedError('read only');
  int? remove(Object? key) => throw UnsupportedError('read only');
  void clear() => throw UnsupportedError('read only');
}
int basketPrice(Map<String?, int?> prices) {
  return (prices['bolts'] ?? 0) * 4
      + (prices['panels'] ?? 0) * 2
      + (prices['sealant'] ?? 0) * 3
      + (prices['brackets'] ?? 0) * 6
      + (prices[null] ?? 0)
      + (prices['discontinued'] ?? 0)
      + (prices['unlisted'] ?? 0);
}
''';

String sourceFor(String mode) =>
    '''$common
int main(Map<String?, int?> prices, int batches) {
  final contracts = ContractPrices(prices);
  var checksum = 0;
  for (var batch = 0; batch < batches; batch++) {
    final Map<String?, int?> selected = ${switch (mode) {
      'native' => 'prices',
      'guest' => 'contracts',
      'mixed' => 'batch.isEven ? prices : contracts',
      _ => throw ArgumentError.value(mode, 'mode'),
    }};
    checksum += (basketPrice(selected) * (batch % 5 + 1)) ^ (batch & 7);
  }
  return checksum;
}
''';

Map<String?, int?> inventory() => {
  'bolts': 7,
  'panels': 13,
  'sealant': 11,
  'brackets': 5,
  null: 3,
  'discontinued': null,
};

// Five priced basket lines total 120. The contract adjustment adds 2 * 16.
// Missing and discontinued lines contribute zero in every mode.
int expectedChecksum(String mode, int batches) {
  var checksum = 0;
  for (var batch = 0; batch < batches; batch++) {
    final adjusted = mode == 'guest' || (mode == 'mixed' && batch.isOdd);
    final price = adjusted ? 152 : 120;
    checksum += (price * (batch % 5 + 1)) ^ (batch & 7);
  }
  return checksum;
}

void main(List<String> args) {
  final batches = args.isEmpty ? 20000 : int.parse(args[0]);
  final samples = args.length < 2 ? 7 : int.parse(args[1]);
  final mode = args.length < 3 ? 'native' : args[2];
  if (batches < 1 || samples < 7) {
    throw ArgumentError('Positive batches and at least seven samples required');
  }
  final source = sourceFor(mode);
  if (expectedChecksum('native', 1) != 120 ||
      expectedChecksum('guest', 1) != 152 ||
      expectedChecksum('mixed', 2) != 425) {
    throw StateError('Native reference checksum mismatch');
  }
  const library = 'package:inventory_pricing/main.dart';
  final compiler = Compiler()..entrypoints.add(library);
  final program = compiler.compile({
    'inventory_pricing': {'main.dart': source},
  });
  final hostPrices = inventory();
  final expected = expectedChecksum(mode, batches);
  for (final (label, runtime) in [
    ('fresh', Runtime.ofProgram(program)),
    ('serialized', Runtime(program.write().buffer)),
  ]) {
    int run(int count) =>
        runtime.executeLib(
              library,
              'main',
              arguments: {'prices': hostPrices, 'batches': count},
            )
            as int;
    for (var warm = 0; warm < 2; warm++) {
      final result = run(100);
      if (result != expectedChecksum(mode, 100)) {
        throw StateError('$label warmup checksum mismatch: $result');
      }
    }
    final times = <double>[];
    for (var sample = 0; sample < samples; sample++) {
      final watch = Stopwatch()..start();
      final result = run(batches);
      watch.stop();
      if (result != expected) {
        throw StateError('$label checksum $result != $expected');
      }
      times.add(watch.elapsedMicroseconds / 1000);
    }
    final raw = List<double>.of(times);
    times.sort();
    final median = times[times.length ~/ 2];
    print(
      'inventory_pricing_$mode $label median_ms=${median.toStringAsFixed(3)} '
      'ns/basket=${(median * 1000000 / batches).toStringAsFixed(2)} '
      'raw_ms=${raw.map((value) => value.toStringAsFixed(3)).join(',')} '
      'checksum=$expected',
    );
  }
}
