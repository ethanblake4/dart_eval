import 'package:dart_eval/dart_eval.dart';

// Generate and scan request headers with mixed casing and changing values.
// dart compile exe benchmark/http_headers.dart -o .dart_tool/http_headers.exe
// .dart_tool/http_headers.exe [requests] [samples]
const _source = r'''
String makeRequest(int seed) {
  final names = <String>[
    'Host', 'content-type', 'X-Request-Id', 'Cache-Control',
    'Authorization', 'Content-Length', 'ACCEPT', 'X-Trace',
  ];
  final b = StringBuffer();
  var state = seed;
  for (var line = 0; line < 32; line++) {
    state = (state * 1103515245 + 12345) & 0x7fffffff;
    final kind = line & 7;
    b.write(names[kind]);
    b.write(': ');
    if (kind == 0) {
      b.write('node'); b.write(state % 97); b.write('.example');
    } else if (kind == 1) {
      b.write('application/json');
    } else if (kind == 3) {
      b.write('max-age='); b.write(state % 180);
    } else if (kind == 4) {
      b.write('Bearer '); b.write(state % 1000000);
    } else if (kind == 6) {
      b.write('text/plain');
    } else if (kind == 7) {
      b.write('a'); b.write(state % 10000);
    } else {
      b.write(state % 100000);
    }
    b.write('\r\n');
  }
  b.write('\r\n');
  return b.toString();
}

int scan(String request) {
  var pos = 0;
  var score = 0;
  var hosts = 0;
  var authorization = 0;
  var bodyBytes = 0;
  while (pos < request.length) {
    if (request.codeUnitAt(pos) == 13) break;
    var nameHash = 0;
    while (request.codeUnitAt(pos) != 58) {
      var c = request.codeUnitAt(pos++);
      if (c >= 65 && c <= 90) c += 32;
      nameHash = (nameHash * 33 + c) & 0x7fffffff;
    }
    pos++;
    while (request.codeUnitAt(pos) == 32 || request.codeUnitAt(pos) == 9) {
      pos++;
    }
    var valueHash = 0;
    var length = 0;
    while (request.codeUnitAt(pos) != 13) {
      final c = request.codeUnitAt(pos++);
      valueHash = (valueHash * 33 + c) & 0x7fffffff;
      if (nameHash == 157516714) length = length * 10 + c - 48;
    }
    pos += 2;
    if (nameHash == 3862238) hosts++;
    if (nameHash == 1914971089) authorization++;
    if (nameHash == 157516714) bodyBytes += length;
    score = (score + (nameHash ^ valueHash)) & 0x7fffffff;
  }
  return (score + hosts * 31 + authorization * 131 + bodyBytes) & 0x7fffffff;
}

int main(int requests) {
  var checksum = 0;
  for (var i = 0; i < requests; i++) {
    checksum += scan(makeRequest(123456789 + i * 2654435761));
  }
  return checksum;
}
''';

void main(List<String> args) {
  final requests = args.isEmpty ? 1000 : int.parse(args[0]);
  final samples = args.length < 2 ? 7 : int.parse(args[1]);
  if (requests < 1 || samples < 7) {
    throw ArgumentError(
      'Positive requests and at least seven samples required',
    );
  }
  final compiler = Compiler();
  compiler.entrypoints.add('package:http_headers/main.dart');
  final program = compiler.compile({
    'http_headers': {'main.dart': _source},
  });
  final runtime = Runtime(program.write().buffer);
  int run(int n) =>
      runtime.executeLib(
            'package:http_headers/main.dart',
            'main',
            arguments: {'requests': n},
          )
          as int;

  var checksum = 0;
  for (var warm = 0; warm < 2; warm++) {
    checksum += run(10);
  }
  final times = <double>[];
  for (var sample = 0; sample < samples; sample++) {
    final watch = Stopwatch()..start();
    checksum += run(requests);
    watch.stop();
    times.add(watch.elapsedMicroseconds / 1000);
  }
  times.sort();
  final median = times[times.length ~/ 2];
  print(
    'http_headers median_ms=${median.toStringAsFixed(3)} '
    'min_ms=${times.first.toStringAsFixed(3)} '
    'max_ms=${times.last.toStringAsFixed(3)} '
    'ns/request=${(median * 1000000 / requests).toStringAsFixed(2)}',
  );
  print('checksum=$checksum');
}
