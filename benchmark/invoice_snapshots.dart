import 'support/comparison.dart';

// Materialize immutable invoice rows in pages before calculating their totals.
const _source = r'''
class InvoiceRow {
  final int units;
  final int unitCents;
  final int shippingCents;
  InvoiceRow(this.units, this.unitCents, this.shippingCents);
}

int main(int pages) {
  var total = 0;
  for (var page = 0; page < pages; page++) {
    final rows = <InvoiceRow>[];
    for (var item = 0; item < 32; item++) {
      rows.add(InvoiceRow(item % 7 + 1, page % 97 + 100, item % 5));
    }
    for (final row in rows) {
      total += row.units * row.unitCents + row.shippingCents;
    }
  }
  return total;
}
''';

void main(List<String> args) => runComparison(
  args,
  name: 'invoice_snapshots',
  source: _source,
  parameter: 'pages',
  unit: 'page',
  iterations: 5000,
  warmupIterations: 50,
);
