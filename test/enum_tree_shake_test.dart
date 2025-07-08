import 'package:test/test.dart';
import 'package:dart_eval/dart_eval.dart';

void main() {
  group('Tree-shaking enum test', () {
    late Compiler compiler;

    setUp(() {
      compiler = Compiler();
    });

    test('Enum used in field should not be removed', () {
      const code = '''
enum AbcCategory {
  A,
  B,
  C,
}

class AbcItem {
  final String id;
  final String name;
  final double value;
  AbcCategory? category;
  double? cumulativePercentage;
  double? individualPercentage;

  AbcItem({
    required this.id,
    required this.name,
    required this.value,
    this.category,
    this.cumulativePercentage,
    this.individualPercentage,
  });

  AbcItem copyWith({
    String? id,
    String? name,
    double? value,
    AbcCategory? category,
    double? cumulativePercentage,
    double? individualPercentage,
  }) {
    return AbcItem(
      id: id ?? this.id,
      name: name ?? this.name,
      value: value ?? this.value,
      category: category ?? this.category,
      cumulativePercentage: cumulativePercentage ?? this.cumulativePercentage,
      individualPercentage: individualPercentage ?? this.individualPercentage,
    );
  }

  @override
  String toString() {
    return 'AbcItem(id: \$id, name: \$name, value: \$value, category: \$category, cumulativePercentage: \$cumulativePercentage%)';
  }
}

void main() {
  final item = AbcItem(
    id: '1',
    name: 'Test Item',
    value: 100.0,
    category: AbcCategory.A,
  );
  
  print(item.toString());
  
  final copiedItem = item.copyWith(category: AbcCategory.B);
  print(copiedItem.toString());
}
''';

      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': code,
        }
      });

      // Deve executar sem erros de "Unknown type"
      expect(() => runtime.executeLib('package:example/main.dart', 'main'),
          returnsNormally);
    });
  });
}
