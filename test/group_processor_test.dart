import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

void main() {
  group('GroupAndProcessor tests', () {
    late Compiler compiler;

    setUp(() {
      compiler = Compiler();
    });

    test('Basic grouping and processing with simple data', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': '''
            /// Classe utilitária para agrupar e processar dados
            class GroupAndProcessor {
              /// Agrupa itens por chave e processa com callback
              static List<T> process<TItem, TKey, TValue, TExtraData, T>(
                List<TItem> items, {
                required TKey Function(TItem item) keyExtractor,
                required TValue Function(TItem item) valueExtractor,
                required TValue Function(TValue current, TValue toAdd) valueCombiner,
                required T Function(TKey key, TValue combinedValue, TExtraData? extraData) processor,
                TExtraData? Function(TItem item)? extraDataExtractor,
              }) {
                // Mapas para armazenar dados agrupados
                Map<TKey, TValue> groupedData = {};
                Map<TKey, TExtraData?> extraDataMap = {};

                // Agrupar itens por chave
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
                    // Armazenar dados extras apenas do primeiro item de cada grupo
                    if (extraDataExtractor != null) {
                      extraDataMap[key] = extraDataExtractor(item);
                    }
                  }
                }

                // Processar cada grupo com o callback
                List<T> results = [];
                for (var entry in groupedData.entries) {
                  final TKey key = entry.key;
                  final TValue combinedValue = entry.value;
                  final TExtraData? extraData = extraDataMap[key];

                  final T result = processor(key, combinedValue, extraData);
                  results.add(result);
                }

                return results;
              }

              /// Versão simplificada sem dados extras
              static List<T> processSimple<TItem, TKey, TValue, T>(
                List<TItem> items, {
                required TKey Function(TItem item) keyExtractor,
                required TValue Function(TItem item) valueExtractor,
                required TValue Function(TValue current, TValue toAdd) valueCombiner,
                required T Function(TKey key, TValue combinedValue) processor,
              }) {
                return process<TItem, TKey, TValue, Object?, T>(
                  items,
                  keyExtractor: keyExtractor,
                  valueExtractor: valueExtractor,
                  valueCombiner: valueCombiner,
                  processor: (key, combinedValue, extraData) => processor(key, combinedValue),
                );
              }

              /// Cria uma instância configurada para um tipo específico
              static GroupAndProcessorBuilder<TItem> builder<TItem>() {
                return GroupAndProcessorBuilder<TItem>();
              }
            }

            /// Builder para facilitar o uso da classe GroupAndProcessor
            class GroupAndProcessorBuilder<TItem> {
              /// Configura a chave para agrupar os itens
              GroupAndProcessorBuilderWithKey<TItem, TKey> groupBy<TKey>(
                TKey Function(TItem item) keyExtractor,
              ) {
                return GroupAndProcessorBuilderWithKey<TItem, TKey>(keyExtractor);
              }
            }

            /// Builder com chave configurada
            class GroupAndProcessorBuilderWithKey<TItem, TKey> {
              final TKey Function(TItem item) keyExtractor;

              GroupAndProcessorBuilderWithKey(this.keyExtractor);

              /// Configura o valor a ser extraído e combinado
              GroupAndProcessorBuilderWithValue<TItem, TKey, TValue> sumBy<TValue>(
                TValue Function(TItem item) valueExtractor,
                TValue Function(TValue current, TValue toAdd) valueCombiner,
              ) {
                return GroupAndProcessorBuilderWithValue<TItem, TKey, TValue>(
                  keyExtractor,
                  valueExtractor,
                  valueCombiner,
                );
              }

              /// Configuração específica para somar valores double
              GroupAndProcessorBuilderWithValue<TItem, TKey, double> sumDoubleBy(
                double Function(TItem item) valueExtractor,
              ) {
                return sumBy<double>(valueExtractor, (current, toAdd) => current + toAdd);
              }

              /// Configuração específica para somar valores int
              GroupAndProcessorBuilderWithValue<TItem, TKey, int> sumIntBy(
                int Function(TItem item) valueExtractor,
              ) {
                return sumBy<int>(valueExtractor, (current, toAdd) => current + toAdd);
              }
            }

            /// Builder com chave e valor configurados
            class GroupAndProcessorBuilderWithValue<TItem, TKey, TValue> {
              final TKey Function(TItem item) keyExtractor;
              final TValue Function(TItem item) valueExtractor;
              final TValue Function(TValue current, TValue toAdd) valueCombiner;

              GroupAndProcessorBuilderWithValue(
                this.keyExtractor,
                this.valueExtractor,
                this.valueCombiner,
              );

              /// Processa os itens com callback simples
              List<T> process<T>(
                List<TItem> items,
                T Function(TKey key, TValue combinedValue) processor,
              ) {
                return GroupAndProcessor.processSimple<TItem, TKey, TValue, T>(
                  items,
                  keyExtractor: keyExtractor,
                  valueExtractor: valueExtractor,
                  valueCombiner: valueCombiner,
                  processor: processor,
                );
              }

              /// Processa os itens com callback que inclui dados extras
              List<T> processWithExtra<TExtraData, T>(
                List<TItem> items,
                T Function(TKey key, TValue combinedValue, TExtraData? extraData) processor,
                TExtraData? Function(TItem item) extraDataExtractor,
              ) {
                return GroupAndProcessor.process<TItem, TKey, TValue, TExtraData, T>(
                  items,
                  keyExtractor: keyExtractor,
                  valueExtractor: valueExtractor,
                  valueCombiner: valueCombiner,
                  processor: processor,
                  extraDataExtractor: extraDataExtractor,
                );
              }
            }

            // Classe para teste
            class Person {
              final String name;
              final int age;
              final String department;
              final double salary;

              Person(this.name, this.age, this.department, this.salary);
            }

            String main() {
              // Dados de teste
              final people = [
                Person('João', 25, 'TI', 5000.0),
                Person('Maria', 30, 'TI', 6000.0),
                Person('Pedro', 35, 'RH', 4500.0),
                Person('Ana', 28, 'RH', 5500.0),
                Person('Carlos', 32, 'TI', 7000.0),
              ];

              // Agrupar por departamento e somar salários
              final result = GroupAndProcessor.processSimple<Person, String, double, String>(
                people,
                keyExtractor: (person) => person.department,
                valueExtractor: (person) => person.salary,
                valueCombiner: (current, toAdd) => current + toAdd,
                processor: (department, totalSalary) => 
                  '\${department}: \${totalSalary}',
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
          'RH: 10000.0, TI: 18000.0');
    });

    test('Builder pattern with extra data', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': '''
            /// [Repetir toda a implementação das classes aqui]
            class GroupAndProcessor {
              static List<T> process<TItem, TKey, TValue, TExtraData, T>(
                List<TItem> items, {
                required TKey Function(TItem item) keyExtractor,
                required TValue Function(TItem item) valueExtractor,
                required TValue Function(TValue current, TValue toAdd) valueCombiner,
                required T Function(TKey key, TValue combinedValue, TExtraData? extraData) processor,
                TExtraData? Function(TItem item)? extraDataExtractor,
              }) {
                Map<TKey, TValue> groupedData = {};
                Map<TKey, TExtraData?> extraDataMap = {};

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
                    if (extraDataExtractor != null) {
                      extraDataMap[key] = extraDataExtractor(item);
                    }
                  }
                }

                List<T> results = [];
                for (var entry in groupedData.entries) {
                  final TKey key = entry.key;
                  final TValue combinedValue = entry.value;
                  final TExtraData? extraData = extraDataMap[key];

                  final T result = processor(key, combinedValue, extraData);
                  results.add(result);
                }

                return results;
              }

              static List<T> processSimple<TItem, TKey, TValue, T>(
                List<TItem> items, {
                required TKey Function(TItem item) keyExtractor,
                required TValue Function(TItem item) valueExtractor,
                required TValue Function(TValue current, TValue toAdd) valueCombiner,
                required T Function(TKey key, TValue combinedValue) processor,
              }) {
                return process<TItem, TKey, TValue, Object?, T>(
                  items,
                  keyExtractor: keyExtractor,
                  valueExtractor: valueExtractor,
                  valueCombiner: valueCombiner,
                  processor: (key, combinedValue, extraData) => processor(key, combinedValue),
                );
              }

              static GroupAndProcessorBuilder<TItem> builder<TItem>() {
                return GroupAndProcessorBuilder<TItem>();
              }
            }

            class GroupAndProcessorBuilder<TItem> {
              GroupAndProcessorBuilderWithKey<TItem, TKey> groupBy<TKey>(
                TKey Function(TItem item) keyExtractor,
              ) {
                return GroupAndProcessorBuilderWithKey<TItem, TKey>(keyExtractor);
              }
            }

            class GroupAndProcessorBuilderWithKey<TItem, TKey> {
              final TKey Function(TItem item) keyExtractor;

              GroupAndProcessorBuilderWithKey(this.keyExtractor);

              GroupAndProcessorBuilderWithValue<TItem, TKey, TValue> sumBy<TValue>(
                TValue Function(TItem item) valueExtractor,
                TValue Function(TValue current, TValue toAdd) valueCombiner,
              ) {
                return GroupAndProcessorBuilderWithValue<TItem, TKey, TValue>(
                  keyExtractor,
                  valueExtractor,
                  valueCombiner,
                );
              }

              GroupAndProcessorBuilderWithValue<TItem, TKey, double> sumDoubleBy(
                double Function(TItem item) valueExtractor,
              ) {
                return sumBy<double>(valueExtractor, (current, toAdd) => current + toAdd);
              }

              GroupAndProcessorBuilderWithValue<TItem, TKey, int> sumIntBy(
                int Function(TItem item) valueExtractor,
              ) {
                return sumBy<int>(valueExtractor, (current, toAdd) => current + toAdd);
              }
            }

            class GroupAndProcessorBuilderWithValue<TItem, TKey, TValue> {
              final TKey Function(TItem item) keyExtractor;
              final TValue Function(TItem item) valueExtractor;
              final TValue Function(TValue current, TValue toAdd) valueCombiner;

              GroupAndProcessorBuilderWithValue(
                this.keyExtractor,
                this.valueExtractor,
                this.valueCombiner,
              );

              List<T> process<T>(
                List<TItem> items,
                T Function(TKey key, TValue combinedValue) processor,
              ) {
                return GroupAndProcessor.processSimple<TItem, TKey, TValue, T>(
                  items,
                  keyExtractor: keyExtractor,
                  valueExtractor: valueExtractor,
                  valueCombiner: valueCombiner,
                  processor: processor,
                );
              }

              List<T> processWithExtra<TExtraData, T>(
                List<TItem> items,
                T Function(TKey key, TValue combinedValue, TExtraData? extraData) processor,
                TExtraData? Function(TItem item) extraDataExtractor,
              ) {
                return GroupAndProcessor.process<TItem, TKey, TValue, TExtraData, T>(
                  items,
                  keyExtractor: keyExtractor,
                  valueExtractor: valueExtractor,
                  valueCombiner: valueCombiner,
                  processor: processor,
                  extraDataExtractor: extraDataExtractor,
                );
              }
            }

            class Sale {
              final String product;
              final int quantity;
              final double price;
              final String seller;

              Sale(this.product, this.quantity, this.price, this.seller);
            }

            String main() {
              final sales = [
                Sale('Notebook', 2, 2000.0, 'João'),
                Sale('Mouse', 10, 50.0, 'Maria'),
                Sale('Notebook', 1, 2000.0, 'Pedro'),
                Sale('Teclado', 5, 100.0, 'Ana'),
                Sale('Mouse', 3, 50.0, 'Carlos'),
              ];

              // Usando o builder pattern
              final result = GroupAndProcessor.builder<Sale>()
                  .groupBy<String>((sale) => sale.product)
                  .sumDoubleBy((sale) => sale.quantity * sale.price)
                  .processWithExtra<String, String>(
                    sales,
                    (product, totalValue, firstSeller) => 
                      '\${product}: \${totalValue} (primeiro: \${firstSeller})',
                    (sale) => sale.seller,
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
          'Mouse: 650.0 (primeiro: Maria), Notebook: 6000.0 (primeiro: João), Teclado: 500.0 (primeiro: Ana)');
    });

    test('Simple int sum using builder', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': '''
            /// [Repetir implementação das classes novamente]
            class GroupAndProcessor {
              static List<T> process<TItem, TKey, TValue, TExtraData, T>(
                List<TItem> items, {
                required TKey Function(TItem item) keyExtractor,
                required TValue Function(TItem item) valueExtractor,
                required TValue Function(TValue current, TValue toAdd) valueCombiner,
                required T Function(TKey key, TValue combinedValue, TExtraData? extraData) processor,
                TExtraData? Function(TItem item)? extraDataExtractor,
              }) {
                Map<TKey, TValue> groupedData = {};
                Map<TKey, TExtraData?> extraDataMap = {};

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
                    if (extraDataExtractor != null) {
                      extraDataMap[key] = extraDataExtractor(item);
                    }
                  }
                }

                List<T> results = [];
                for (var entry in groupedData.entries) {
                  final TKey key = entry.key;
                  final TValue combinedValue = entry.value;
                  final TExtraData? extraData = extraDataMap[key];

                  final T result = processor(key, combinedValue, extraData);
                  results.add(result);
                }

                return results;
              }

              static List<T> processSimple<TItem, TKey, TValue, T>(
                List<TItem> items, {
                required TKey Function(TItem item) keyExtractor,
                required TValue Function(TItem item) valueExtractor,
                required TValue Function(TValue current, TValue toAdd) valueCombiner,
                required T Function(TKey key, TValue combinedValue) processor,
              }) {
                return process<TItem, TKey, TValue, Object?, T>(
                  items,
                  keyExtractor: keyExtractor,
                  valueExtractor: valueExtractor,
                  valueCombiner: valueCombiner,
                  processor: (key, combinedValue, extraData) => processor(key, combinedValue),
                );
              }

              static GroupAndProcessorBuilder<TItem> builder<TItem>() {
                return GroupAndProcessorBuilder<TItem>();
              }
            }

            class GroupAndProcessorBuilder<TItem> {
              GroupAndProcessorBuilderWithKey<TItem, TKey> groupBy<TKey>(
                TKey Function(TItem item) keyExtractor,
              ) {
                return GroupAndProcessorBuilderWithKey<TItem, TKey>(keyExtractor);
              }
            }

            class GroupAndProcessorBuilderWithKey<TItem, TKey> {
              final TKey Function(TItem item) keyExtractor;

              GroupAndProcessorBuilderWithKey(this.keyExtractor);

              GroupAndProcessorBuilderWithValue<TItem, TKey, TValue> sumBy<TValue>(
                TValue Function(TItem item) valueExtractor,
                TValue Function(TValue current, TValue toAdd) valueCombiner,
              ) {
                return GroupAndProcessorBuilderWithValue<TItem, TKey, TValue>(
                  keyExtractor,
                  valueExtractor,
                  valueCombiner,
                );
              }

              GroupAndProcessorBuilderWithValue<TItem, TKey, double> sumDoubleBy(
                double Function(TItem item) valueExtractor,
              ) {
                return sumBy<double>(valueExtractor, (current, toAdd) => current + toAdd);
              }

              GroupAndProcessorBuilderWithValue<TItem, TKey, int> sumIntBy(
                int Function(TItem item) valueExtractor,
              ) {
                return sumBy<int>(valueExtractor, (current, toAdd) => current + toAdd);
              }
            }

            class GroupAndProcessorBuilderWithValue<TItem, TKey, TValue> {
              final TKey Function(TItem item) keyExtractor;
              final TValue Function(TItem item) valueExtractor;
              final TValue Function(TValue current, TValue toAdd) valueCombiner;

              GroupAndProcessorBuilderWithValue(
                this.keyExtractor,
                this.valueExtractor,
                this.valueCombiner,
              );

              List<T> process<T>(
                List<TItem> items,
                T Function(TKey key, TValue combinedValue) processor,
              ) {
                return GroupAndProcessor.processSimple<TItem, TKey, TValue, T>(
                  items,
                  keyExtractor: keyExtractor,
                  valueExtractor: valueExtractor,
                  valueCombiner: valueCombiner,
                  processor: processor,
                );
              }

              List<T> processWithExtra<TExtraData, T>(
                List<TItem> items,
                T Function(TKey key, TValue combinedValue, TExtraData? extraData) processor,
                TExtraData? Function(TItem item) extraDataExtractor,
              ) {
                return GroupAndProcessor.process<TItem, TKey, TValue, TExtraData, T>(
                  items,
                  keyExtractor: keyExtractor,
                  valueExtractor: valueExtractor,
                  valueCombiner: valueCombiner,
                  processor: processor,
                  extraDataExtractor: extraDataExtractor,
                );
              }
            }

            class Score {
              final String team;
              final int points;

              Score(this.team, this.points);
            }

            int main() {
              final scores = [
                Score('A', 10),
                Score('B', 8),
                Score('A', 15),
                Score('C', 12),
                Score('B', 7),
                Score('A', 5),
              ];

              // Usando sumIntBy
              final result = GroupAndProcessor.builder<Score>()
                  .groupBy<String>((score) => score.team)
                  .sumIntBy((score) => score.points)
                  .process<int>(
                    scores,
                    (team, totalPoints) => totalPoints,
                  );

              // Retornar a soma total de todos os pontos
              int total = 0;
              for (var points in result) {
                total += points;
              }
              return total;
            }
          '''
        }
      });

      expect(runtime.executeLib('package:eval_test/main.dart', 'main'), 57);
    });

    test('Empty list handling', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': '''
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

                List<T> results = [];
                for (var entry in groupedData.entries) {
                  final TKey key = entry.key;
                  final TValue combinedValue = entry.value;
                  final T result = processor(key, combinedValue);
                  results.add(result);
                }

                return results;
              }
            }

            class Item {
              final String name;
              final int value;

              Item(this.name, this.value);
            }

            int main() {
              final List<Item> emptyList = [];

              final result = GroupAndProcessor.processSimple<Item, String, int, String>(
                emptyList,
                keyExtractor: (item) => item.name,
                valueExtractor: (item) => item.value,
                valueCombiner: (current, toAdd) => current + toAdd,
                processor: (name, totalValue) => '\${name}: \${totalValue}',
              );

              return result.length;
            }
          '''
        }
      });

      expect(runtime.executeLib('package:eval_test/main.dart', 'main'), 0);
    });
  });
}
