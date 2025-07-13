import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

void main() {
  group('ABC Analysis tests', () {
    late Compiler compiler;

    setUp(() {
      compiler = Compiler();
    });

    test('Basic ABC analysis calculation', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': '''
            // Função auxiliar para calcular percentual
            double calculatePercentage({
              required double value,
              required double totalValue,
            }) {
              if (totalValue == 0) return 0.0;
              return (value / totalValue) * 100;
            }

            // Enum para categorias ABC
            enum AbcCategory {
              A,
              B,
              C,
            }

            // Classe para itens ABC
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
            }

            // Classe para estatísticas ABC
            class AbcStatistics {
              final int categoryACount;
              final int categoryBCount;
              final int categoryCCount;
              final double categoryAValue;
              final double categoryBValue;
              final double categoryCValue;
              final double categoryAPercentage;
              final double categoryBPercentage;
              final double categoryCPercentage;

              AbcStatistics({
                required this.categoryACount,
                required this.categoryBCount,
                required this.categoryCCount,
                required this.categoryAValue,
                required this.categoryBValue,
                required this.categoryCValue,
                required this.categoryAPercentage,
                required this.categoryBPercentage,
                required this.categoryCPercentage,
              });
            }

            // Resultado da análise ABC
            class AbcAnalysisResult {
              final List<AbcItem> items;
              final double totalValue;
              final int totalItems;
              final AbcStatistics statistics;

              AbcAnalysisResult({
                required this.items,
                required this.totalValue,
                required this.totalItems,
                required this.statistics,
              });
            }

            // Classe para calcular estatísticas
            class AbcHelperCalculateStatistics {
              AbcStatistics run({
                required List<AbcItem> items,
                required double totalValue,
              }) {
                int categoryACount = 0;
                int categoryBCount = 0;
                int categoryCCount = 0;
                double categoryAValue = 0.0;
                double categoryBValue = 0.0;
                double categoryCValue = 0.0;

                for (AbcItem item in items) {
                  switch (item.category) {
                    case AbcCategory.A:
                      categoryACount += 1;
                      categoryAValue += item.value;
                      break;
                    case AbcCategory.B:
                      categoryBCount += 1;
                      categoryBValue += item.value;
                      break;
                    case AbcCategory.C:
                      categoryCCount += 1;
                      categoryCValue += item.value;
                      break;
                  }
                }

                return AbcStatistics(
                  categoryACount: categoryACount,
                  categoryBCount: categoryBCount,
                  categoryCCount: categoryCCount,
                  categoryAValue: categoryAValue,
                  categoryBValue: categoryBValue,
                  categoryCValue: categoryCValue,
                  categoryAPercentage: calculatePercentage(
                    value: categoryAValue,
                    totalValue: totalValue,
                  ),
                  categoryBPercentage: calculatePercentage(
                    value: categoryBValue,
                    totalValue: totalValue,
                  ),
                  categoryCPercentage: calculatePercentage(
                    value: categoryCValue,
                    totalValue: totalValue,
                  ),
                );
              }
            }

            // Classe para ordenação ABC
            class AbcSort {
              final List<AbcItem> items;
              final bool descending;

              AbcSort(this.items, {this.descending = true});

              void sort() {
                items.sort((AbcItem a, AbcItem b) {
                  final AbcCategory? categoryA = a.category;
                  final AbcCategory? categoryB = b.category;

                  if (categoryA == null && categoryB == null) return 0;
                  if (categoryA == null && categoryB != null) return 1;
                  if (categoryA != null && categoryB == null) return -1;

                  final int orderA = _getCategoryOrder(categoryA!);
                  final int orderB = _getCategoryOrder(categoryB!);

                  if (descending) {
                    return orderA.compareTo(orderB);
                  } else {
                    return orderB.compareTo(orderA);
                  }
                });
              }

              int _getCategoryOrder(AbcCategory category) {
                switch (category) {
                  case AbcCategory.A:
                    return 0;
                  case AbcCategory.B:
                    return 1;
                  case AbcCategory.C:
                    return 2;
                }
              }
            }

            // Classe principal para análise ABC
            class AbcHelper {
              final List<AbcItem> items;
              final double categoryAThreshold;
              final double categoryBThreshold;

              AbcHelper(
                this.items, {
                this.categoryAThreshold = 80.0,
                this.categoryBThreshold = 95.0,
              });

              AbcAnalysisResult calculateAbc() {
                if (items.isEmpty) {
                  return AbcAnalysisResult(
                    items: <AbcItem>[],
                    totalValue: 0.0,
                    totalItems: 0,
                    statistics: AbcStatistics(
                      categoryACount: 0,
                      categoryBCount: 0,
                      categoryCCount: 0,
                      categoryAValue: 0.0,
                      categoryBValue: 0.0,
                      categoryCValue: 0.0,
                      categoryAPercentage: 0.0,
                      categoryBPercentage: 0.0,
                      categoryCPercentage: 0.0,
                    ),
                  );
                }

                double totalValue = items.fold(0.0, (double sum, AbcItem item) => sum + item.value);
                List<AbcItem> sortedItems = List<AbcItem>.from(items);
                sortedItems.sort((AbcItem a, AbcItem b) => b.value.compareTo(a.value));

                double cumulativeValue = 0.0;
                List<AbcItem> classifiedItems = <AbcItem>[];

                for (int i = 0; i < sortedItems.length; i++) {
                  AbcItem item = sortedItems[i];
                  cumulativeValue += item.value;
                  double cumulativePercentage = (cumulativeValue / totalValue) * 100;
                  double individualPercentage = (item.value / totalValue) * 100;

                  AbcCategory category;
                  if (cumulativePercentage <= categoryAThreshold) {
                    category = AbcCategory.A;
                  } else if (cumulativePercentage <= categoryBThreshold) {
                    category = AbcCategory.B;
                  } else {
                    category = AbcCategory.C;
                  }

                  AbcItem updatedItem = item.copyWith(
                    category: category,
                    cumulativePercentage: cumulativePercentage,
                    individualPercentage: individualPercentage,
                  );

                  classifiedItems.add(updatedItem);
                }

                AbcStatistics statistics = AbcHelperCalculateStatistics().run(
                  items: classifiedItems,
                  totalValue: totalValue,
                );

                AbcSort(classifiedItems).sort();

                return AbcAnalysisResult(
                  items: classifiedItems,
                  totalValue: totalValue,
                  totalItems: items.length,
                  statistics: statistics,
                );
              }

              List<AbcItem> filterByCategory(AbcCategory category) {
                return items.where((AbcItem item) => item.category == category).toList();
              }
            }

            // Classe para agrupamento e processamento
            class GroupAndProcessor {
              static List<T> processSimple<TItem, TKey, TValue, T>(
                List<TItem> items, {
                required TKey Function(TItem item) keyExtractor,
                required TValue Function(TItem item) valueExtractor,
                required TValue Function(TValue current, TValue toAdd) valueCombiner,
                required T Function(TKey key, TValue combinedValue) processor,
              }) {
                Map<TKey, TValue> groupedData = {};

                for (var item in items) {
                  final TKey key = keyExtractor(item);
                  final TValue value = valueExtractor(item);

                  if (groupedData.containsKey(key)) {
                    final TValue? currentValue = groupedData[key];
                    if (currentValue != null) {
                      groupedData[key] = valueCombiner(currentValue, value);
                    }
                  } else {
                    groupedData[key] = value;
                  }
                }

                List<T> results = <T>[];
                for (var entry in groupedData.entries) {
                  final TKey key = entry.key;
                  final TValue combinedValue = entry.value;
                  final T result = processor(key, combinedValue);
                  results.add(result);
                }

                return results;
              }
            }

            String main() {
              // Dados de teste
              final items = [
                AbcItem(id: '1', name: 'Item A', value: 50.0),
                AbcItem(id: '2', name: 'Item B', value: 30.0),
                AbcItem(id: '3', name: 'Item C', value: 15.0),
                AbcItem(id: '4', name: 'Item D', value: 3.0),
                AbcItem(id: '5', name: 'Item E', value: 2.0),
              ];

              // Executar análise ABC
              final helper = AbcHelper(items);
              final result = helper.calculateAbc();

              // Verificar resultados
              return 'Total: \${result.totalValue.toString()}, Items: \${result.totalItems}, A: \${result.statistics.categoryACount}, B: \${result.statistics.categoryBCount}, C: \${result.statistics.categoryCCount}';
            }
          '''
        }
      });

      expect(
          (runtime.executeLib('package:eval_test/main.dart', 'main') as $String)
              .$value,
          'Total: 100.0, Items: 5, A: 2, B: 1, C: 2');
    });

    test('ABC analysis with empty list', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': '''
            // Função auxiliar para calcular percentual
            double calculatePercentage({
              required double value,
              required double totalValue,
            }) {
              if (totalValue == 0) return 0.0;
              return (value / totalValue) * 100;
            }

            enum AbcCategory { A, B, C }

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
            }

            class AbcStatistics {
              final int categoryACount;
              final int categoryBCount;
              final int categoryCCount;
              final double categoryAValue;
              final double categoryBValue;
              final double categoryCValue;
              final double categoryAPercentage;
              final double categoryBPercentage;
              final double categoryCPercentage;

              AbcStatistics({
                required this.categoryACount,
                required this.categoryBCount,
                required this.categoryCCount,
                required this.categoryAValue,
                required this.categoryBValue,
                required this.categoryCValue,
                required this.categoryAPercentage,
                required this.categoryBPercentage,
                required this.categoryCPercentage,
              });
            }

            class AbcAnalysisResult {
              final List<AbcItem> items;
              final double totalValue;
              final int totalItems;
              final AbcStatistics statistics;

              AbcAnalysisResult({
                required this.items,
                required this.totalValue,
                required this.totalItems,
                required this.statistics,
              });
            }

            class AbcHelper {
              final List<AbcItem> items;
              final double categoryAThreshold;
              final double categoryBThreshold;

              AbcHelper(
                this.items, {
                this.categoryAThreshold = 80.0,
                this.categoryBThreshold = 95.0,
              });

              AbcAnalysisResult calculateAbc() {
                if (items.isEmpty) {
                  return AbcAnalysisResult(
                    items: <AbcItem>[],
                    totalValue: 0.0,
                    totalItems: 0,
                    statistics: AbcStatistics(
                      categoryACount: 0,
                      categoryBCount: 0,
                      categoryCCount: 0,
                      categoryAValue: 0.0,
                      categoryBValue: 0.0,
                      categoryCValue: 0.0,
                      categoryAPercentage: 0.0,
                      categoryBPercentage: 0.0,
                      categoryCPercentage: 0.0,
                    ),
                  );
                }

                return AbcAnalysisResult(
                  items: <AbcItem>[],
                  totalValue: 0.0,
                  totalItems: 0,
                  statistics: AbcStatistics(
                    categoryACount: 0,
                    categoryBCount: 0,
                    categoryCCount: 0,
                    categoryAValue: 0.0,
                    categoryBValue: 0.0,
                    categoryCValue: 0.0,
                    categoryAPercentage: 0.0,
                    categoryBPercentage: 0.0,
                    categoryCPercentage: 0.0,
                  ),
                );
              }
            }

            String main() {
              final items = <AbcItem>[];
              final helper = AbcHelper(items);
              final result = helper.calculateAbc();

              return 'Empty: \${result.totalValue.toString()}, Items: \${result.totalItems}';
            }
          '''
        }
      });

      expect(
          (runtime.executeLib('package:eval_test/main.dart', 'main') as $String)
              .$value,
          'Empty: 0.0, Items: 0');
    });

    test('ABC analysis with custom thresholds', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': '''
            // Função auxiliar para calcular percentual
            double calculatePercentage({
              required double value,
              required double totalValue,
            }) {
              if (totalValue == 0) return 0.0;
              return (value / totalValue) * 100;
            }

            enum AbcCategory { A, B, C }

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
            }

            class AbcStatistics {
              final int categoryACount;
              final int categoryBCount;
              final int categoryCCount;
              final double categoryAValue;
              final double categoryBValue;
              final double categoryCValue;
              final double categoryAPercentage;
              final double categoryBPercentage;
              final double categoryCPercentage;

              AbcStatistics({
                required this.categoryACount,
                required this.categoryBCount,
                required this.categoryCCount,
                required this.categoryAValue,
                required this.categoryBValue,
                required this.categoryCValue,
                required this.categoryAPercentage,
                required this.categoryBPercentage,
                required this.categoryCPercentage,
              });
            }

            class AbcAnalysisResult {
              final List<AbcItem> items;
              final double totalValue;
              final int totalItems;
              final AbcStatistics statistics;

              AbcAnalysisResult({
                required this.items,
                required this.totalValue,
                required this.totalItems,
                required this.statistics,
              });
            }

            class AbcHelperCalculateStatistics {
              AbcStatistics run({
                required List<AbcItem> items,
                required double totalValue,
              }) {
                int categoryACount = 0;
                int categoryBCount = 0;
                int categoryCCount = 0;
                double categoryAValue = 0.0;
                double categoryBValue = 0.0;
                double categoryCValue = 0.0;

                for (AbcItem item in items) {
                  if (item.category == AbcCategory.A) {
                    categoryACount++;
                    categoryAValue += item.value;
                  } else if (item.category == AbcCategory.B) {
                    categoryBCount++;
                    categoryBValue += item.value;
                  } else if (item.category == AbcCategory.C) {
                    categoryCCount++;
                    categoryCValue += item.value;
                  }
                }

                return AbcStatistics(
                  categoryACount: categoryACount,
                  categoryBCount: categoryBCount,
                  categoryCCount: categoryCCount,
                  categoryAValue: categoryAValue,
                  categoryBValue: categoryBValue,
                  categoryCValue: categoryCValue,
                  categoryAPercentage: calculatePercentage(
                    value: categoryAValue,
                    totalValue: totalValue,
                  ),
                  categoryBPercentage: calculatePercentage(
                    value: categoryBValue,
                    totalValue: totalValue,
                  ),
                  categoryCPercentage: calculatePercentage(
                    value: categoryCValue,
                    totalValue: totalValue,
                  ),
                );
              }
            }

            class AbcSort {
              final List<AbcItem> items;
              final bool descending;

              AbcSort(this.items, {this.descending = true});

              void sort() {
                items.sort((AbcItem a, AbcItem b) {
                  final AbcCategory? categoryA = a.category;
                  final AbcCategory? categoryB = b.category;

                  if (categoryA == null && categoryB == null) return 0;
                  if (categoryA == null && categoryB != null) return 1;
                  if (categoryA != null && categoryB == null) return -1;

                  final int orderA = _getCategoryOrder(categoryA!);
                  final int orderB = _getCategoryOrder(categoryB!);

                  if (descending) {
                    return orderA.compareTo(orderB);
                  } else {
                    return orderB.compareTo(orderA);
                  }
                });
              }

              int _getCategoryOrder(AbcCategory category) {
                switch (category) {
                  case AbcCategory.A:
                    return 0;
                  case AbcCategory.B:
                    return 1;
                  case AbcCategory.C:
                    return 2;
                }
              }
            }

            class AbcHelper {
              final List<AbcItem> items;
              final double categoryAThreshold;
              final double categoryBThreshold;

              AbcHelper(
                this.items, {
                this.categoryAThreshold = 80.0,
                this.categoryBThreshold = 95.0,
              });

              AbcAnalysisResult calculateAbc() {
                if (items.isEmpty) {
                  return AbcAnalysisResult(
                    items: <AbcItem>[],
                    totalValue: 0.0,
                    totalItems: 0,
                    statistics: AbcStatistics(
                      categoryACount: 0,
                      categoryBCount: 0,
                      categoryCCount: 0,
                      categoryAValue: 0.0,
                      categoryBValue: 0.0,
                      categoryCValue: 0.0,
                      categoryAPercentage: 0.0,
                      categoryBPercentage: 0.0,
                      categoryCPercentage: 0.0,
                    ),
                  );
                }

                double totalValue = items.fold(0.0, (double sum, AbcItem item) => sum + item.value);
                List<AbcItem> sortedItems = List<AbcItem>.from(items);
                sortedItems.sort((AbcItem a, AbcItem b) => b.value.compareTo(a.value));

                double cumulativeValue = 0.0;
                List<AbcItem> classifiedItems = <AbcItem>[];

                for (int i = 0; i < sortedItems.length; i++) {
                  AbcItem item = sortedItems[i];
                  cumulativeValue += item.value;
                  double cumulativePercentage = (cumulativeValue / totalValue) * 100;
                  double individualPercentage = (item.value / totalValue) * 100;

                  AbcCategory category;
                  if (cumulativePercentage <= categoryAThreshold) {
                    category = AbcCategory.A;
                  } else if (cumulativePercentage <= categoryBThreshold) {
                    category = AbcCategory.B;
                  } else {
                    category = AbcCategory.C;
                  }

                  AbcItem updatedItem = item.copyWith(
                    category: category,
                    cumulativePercentage: cumulativePercentage,
                    individualPercentage: individualPercentage,
                  );

                  classifiedItems.add(updatedItem);
                }

                AbcStatistics statistics = AbcHelperCalculateStatistics().run(
                  items: classifiedItems,
                  totalValue: totalValue,
                );

                AbcSort(classifiedItems).sort();

                return AbcAnalysisResult(
                  items: classifiedItems,
                  totalValue: totalValue,
                  totalItems: items.length,
                  statistics: statistics,
                );
              }
            }

            String main() {
              final items = [
                AbcItem(id: '1', name: 'Item A', value: 60.0),
                AbcItem(id: '2', name: 'Item B', value: 25.0),
                AbcItem(id: '3', name: 'Item C', value: 10.0),
                AbcItem(id: '4', name: 'Item D', value: 5.0),
              ];

              // Usar thresholds customizados: 60% para A, 85% para B
              final helper = AbcHelper(items, categoryAThreshold: 60.0, categoryBThreshold: 85.0);
              final result = helper.calculateAbc();

              return 'Custom: A=\${result.statistics.categoryACount}, B=\${result.statistics.categoryBCount}, C=\${result.statistics.categoryCCount}';
            }
          '''
        }
      });

      expect(
          (runtime.executeLib('package:eval_test/main.dart', 'main') as $String)
              .$value,
          'Custom: A=1, B=1, C=2');
    });

    test('Group processor with ABC data', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': '''
            enum AbcCategory { A, B, C }

            class AbcItem {
              final String id;
              final String name;
              final double value;
              AbcCategory? category;

              AbcItem({
                required this.id,
                required this.name,
                required this.value,
                this.category,
              });
            }

            class GroupAndProcessor {
              static List<T> processSimple<TItem, TKey, TValue, T>(
                List<TItem> items, {
                required TKey Function(TItem item) keyExtractor,
                required TValue Function(TItem item) valueExtractor,
                required TValue Function(TValue current, TValue toAdd) valueCombiner,
                required T Function(TKey key, TValue combinedValue) processor,
              }) {
                Map<TKey, TValue> groupedData = {};

                for (var item in items) {
                  final TKey key = keyExtractor(item);
                  final TValue value = valueExtractor(item);

                  if (groupedData.containsKey(key)) {
                    final TValue? currentValue = groupedData[key];
                    if (currentValue != null) {
                      groupedData[key] = valueCombiner(currentValue, value);
                    }
                  } else {
                    groupedData[key] = value;
                  }
                }

                List<T> results = <T>[];
                for (var entry in groupedData.entries) {
                  final TKey key = entry.key;
                  final TValue combinedValue = entry.value;
                  final T result = processor(key, combinedValue);
                  results.add(result);
                }

                return results;
              }
            }

            String main() {
              final items = [
                AbcItem(id: '1', name: 'Item A1', value: 50.0)..category = AbcCategory.A,
                AbcItem(id: '2', name: 'Item A2', value: 30.0)..category = AbcCategory.A,
                AbcItem(id: '3', name: 'Item B1', value: 15.0)..category = AbcCategory.B,
                AbcItem(id: '4', name: 'Item C1', value: 3.0)..category = AbcCategory.C,
                AbcItem(id: '5', name: 'Item C2', value: 2.0)..category = AbcCategory.C,
              ];

              final result = GroupAndProcessor.processSimple<AbcItem, String, double, String>(
                items,
                keyExtractor: (item) => item.category.toString(),
                valueExtractor: (item) => item.value,
                valueCombiner: (current, toAdd) => current + toAdd,
                processor: (category, totalValue) => '\${category}: \${totalValue.toString()}',
              );

              result.sort();
              return result.join(', ');
            }
          '''
        }
      });

      expect(
          (runtime.executeLib('package:eval_test/main.dart', 'main') as $String)
              .$value,
          'AbcCategory.A: 80.0, AbcCategory.B: 15.0, AbcCategory.C: 5.0');
    });
  });
}
