import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

const _library = 'package:github_regressions/main.dart';

Iterable<Runtime> _runtimes(String source) sync* {
  final program = Compiler().compile({
    'github_regressions': {'main.dart': source},
  });
  yield Runtime.ofProgram(program);
  yield Runtime(program.write().buffer);
}

void main() {
  test('#299 dynamic map fallback supports toString inside a loop', () {
    for (final runtime in _runtimes('''
      String main() {
        dynamic rows = [
          {'faixa_aging': null, 'valor_em_aberto': 10.0},
          {'faixa_aging': '31-60', 'valor_em_aberto': 5.0},
        ];
        final result = <String>[];
        for (final row in rows) {
          final faixa = (row['faixa_aging'] ?? 'N/A').toString();
          result.add(faixa);
        }
        return result.join(',');
      }
    ''')) {
      expect(runtime.executeLib(_library, 'main'), 'N/A,31-60');
    }
  });

  test('#298 missing map key short-circuits nullable string access', () {
    for (final runtime in _runtimes('''
      String main() {
        final json = {'title': 'One Piece Movie 01'};
        final String? englishTitle = json['title_en'];
        if (englishTitle != null && englishTitle.isNotEmpty) {
          return englishTitle;
        }
        return json['title']!;
      }
    ''')) {
      expect(runtime.executeLib(_library, 'main'), 'One Piece Movie 01');
    }
  });

  test('#298 map reads after nested lookup break retain their values', () {
    for (final runtime in _runtimes('''
      String main() {
        final rows = [
          {'numero_venda': '001', 'valor_em_aberto': 10.0},
          {'numero_venda': '002', 'valor_em_aberto': 20.0},
          {'numero_venda': 'missing', 'valor_em_aberto': 30.0},
        ];
        final taxasRows = [
          {'numero_venda': '001', 'valor_em_aberto': 2.5},
          {'numero_venda': '002', 'valor_em_aberto': 3.5},
        ];
        final result = <String>[];
        for (final row in rows) {
          dynamic taxa;
          for (final t in taxasRows) {
            if (row['numero_venda'] == t['numero_venda']) {
              taxa = t;
              break;
            }
          }
          final abertoRaw = row['valor_em_aberto'];
          if (abertoRaw is num && taxa != null) {
            final taxaRaw = taxa['valor_em_aberto'];
            if (taxaRaw is num) {
              result.add((abertoRaw + taxaRaw).toStringAsFixed(2));
            }
          }
        }
        return result.join(',');
      }
    ''')) {
      expect(runtime.executeLib(_library, 'main'), '12.50,23.50');
    }
  });

  test('#297 map literal exceeding the old 255-slot frame stays intact', () {
    final entries = [for (var i = 0; i < 320; i++) "'k$i': 'v$i'"];
    for (final runtime in _runtimes('''
      Map<String, dynamic> main() => {${entries.join(',')}};
    ''')) {
      final result = runtime.executeLib(_library, 'main') as Map;
      expect(result, {for (var i = 0; i < 320; i++) 'k$i': 'v$i'});
    }
  });

  test('#228 nested typed and raw maps support indexed assignment', () {
    for (final runtime in _runtimes('''
      String main() {
        Map<String, Map> typed = {'a': {'b': 'c'}};
        Map raw = {'a': {'b': 'c'}};
        typed['a']!['b'] = 'd';
        raw['a']['b'] = 'e';
        return typed['a']!['b'] + raw['a']['b'];
      }
    ''')) {
      expect(runtime.executeLib(_library, 'main'), 'de');
    }
  });

  test('#251 nested ternary handles a host-supplied map string', () {
    for (final runtime in _runtimes('''
      dynamic main(Map<String, dynamic> data) {
        final StageStatus = data['StageStatus'];
        return StageStatus == 'Outstanding' ? 1 :
            (StageStatus == 'Current' ? 2 : 3);
      }
    ''')) {
      for (final (status, expected) in [
        ('Outstanding', 1),
        ('Current', 2),
        ('Other', 3),
      ]) {
        expect(
          runtime.executeLib(
            _library,
            'main',
            arguments: {
              'data': $Map.wrap({$String('StageStatus'): $String(status)}),
            },
          ),
          expected,
        );
      }
    }
  });

  test(
    '#245 returned closure maps a dynamic host list with a guest callback',
    () {
      for (final runtime in _runtimes('''
      Function main() =>
          (items) => items.map((item) => item + ' processed').toList();
    ''')) {
        final callback = runtime.executeLib(_library, 'main') as EvalCallable;
        final result = callback.call(
          runtime,
          null,
          $List.wrap([$String('hello'), $String('world')]),
          null,
          1,
        );
        expect(result!.$reified, ['hello processed', 'world processed']);
      }
    },
  );

  test('#209 UTF-8 encoding retains its Uint8List return type', () {
    for (final runtime in _runtimes('''
      import 'dart:convert';
      import 'dart:typed_data';
      bool main() {
        Uint8List bytes = utf8.encode('hello');
        return bytes.buffer.asUint8List().join(',') == '104,101,108,108,111';
      }
    ''')) {
      expect(runtime.executeLib(_library, 'main'), isTrue);
    }
  });
}
