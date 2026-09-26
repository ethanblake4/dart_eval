import 'support/comparison.dart';

// Incrementally validate delimited log records across chunk boundaries.
// dart compile exe benchmark/int_fields.dart -o .dart_tool/int-fields-baseline.exe
// .dart_tool/int-fields-baseline.exe [batches] [samples]
const _source = r'''
class LogCursor {
  int offset = 0;
  int line = 1;
  int column = 0;
  int fieldStart = 0;
  int recordStart = 0;
  int fieldsInRecord = 0;
  int records = 0;
  int errors = 0;
  int fieldBytes = 0;
  int recordBytes = 0;

  void feed(String chunk) {
    for (var i = 0; i < chunk.length; i++) {
      final code = chunk.codeUnitAt(i);
      offset++;
      if (code == 124) {
        fieldBytes += offset - fieldStart - 1;
        fieldStart = offset;
        fieldsInRecord++;
        column++;
      } else if (code == 10) {
        fieldBytes += offset - fieldStart - 1;
        recordBytes += offset - recordStart - 1;
        if (fieldsInRecord != 3) errors++;
        records++;
        line++;
        column = 0;
        fieldsInRecord = 0;
        fieldStart = offset;
        recordStart = offset;
      } else {
        column++;
      }
    }
  }

  int get checksum => offset * 3 + line * 11 + column * 17 +
      records * 19 + errors * 23 + fieldBytes * 29 + recordBytes * 31;
}

int main(int batches) {
  final chunks = <String>[
    '2026-09-26|INFO|api|ready\n2026-09-26|WARN|',
    'cache|slow\n2026-09-26|ERROR|db|timeout\n',
    '2026-09-26|INFO|auth|',
    'accepted\n2026-09-26|WARN|missing\n',
  ];
  final cursor = LogCursor();
  for (var batch = 0; batch < batches; batch++) {
    for (final chunk in chunks) {
      cursor.feed(chunk);
    }
  }
  return cursor.checksum;
}
''';

void main(List<String> args) => runComparison(
  args,
  name: 'int_fields',
  source: _source,
  parameter: 'batches',
  unit: 'batch',
  iterations: 5000,
  warmupIterations: 50,
  defaultSamples: 15,
);
