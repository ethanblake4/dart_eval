import 'support/comparison.dart';

// Calculate merchandise, shipping and insured value for a batch of order lines.
const _source = r'''
class OrderLine {
  final int quantity;
  final int unitCents;
  final int shippingCents;
  final int insuranceCents;
  OrderLine(this.quantity, this.unitCents, this.shippingCents, this.insuranceCents);
}

int main(int batches) {
  final lines = <OrderLine>[];
  for (var i = 0; i < 128; i++) {
    lines.add(OrderLine(i % 7 + 1, i % 97 + 100, i % 5 + 1, i % 3));
  }
  var total = 0;
  for (var batch = 0; batch < batches; batch++) {
    for (final line in lines) {
      total += line.quantity * line.unitCents +
          line.quantity * line.shippingCents +
          line.quantity * line.insuranceCents;
    }
  }
  return total;
}
''';

void main(List<String> args) => runComparison(
  args,
  name: 'order_totals',
  source: _source,
  parameter: 'batches',
  unit: 'batch',
  iterations: 5000,
  warmupIterations: 50,
);
