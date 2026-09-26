import 'package:dart_eval/dart_eval.dart';

// A hand-rolled JSON parser and serializer — the string-scanning,
// map/list-building codec pattern real codecs share (no dart:convert).
// Run with: dart compile exe benchmark/json_codec.dart -o json_codec.exe
// Then: json_codec.exe [iterations] [samples]

const _source = r'''
class Parser {
  Parser(this.s);
  final String s;
  int pos = 0;

  int get len => s.length;

  void ws() {
    while (pos < len) {
      final c = s.codeUnitAt(pos);
      if (c == 32 || c == 9 || c == 10 || c == 13) { pos++; } else { break; }
    }
  }

  Object? value() {
    ws();
    final c = s.codeUnitAt(pos);
    if (c == 123) return object();
    if (c == 91) return array();
    if (c == 34) return string();
    if (c == 116) { pos += 4; return true; }
    if (c == 102) { pos += 5; return false; }
    if (c == 110) { pos += 4; return null; }
    return number();
  }

  Map<String, Object?> object() {
    pos++;
    final m = <String, Object?>{};
    ws();
    if (s.codeUnitAt(pos) == 125) { pos++; return m; }
    while (true) {
      ws();
      final key = string();
      ws();
      pos++;
      m[key] = value();
      ws();
      final c = s.codeUnitAt(pos);
      if (c == 44) { pos++; continue; }
      pos++;
      return m;
    }
  }

  List<Object?> array() {
    pos++;
    final l = <Object?>[];
    ws();
    if (s.codeUnitAt(pos) == 93) { pos++; return l; }
    while (true) {
      l.add(value());
      ws();
      final c = s.codeUnitAt(pos);
      if (c == 44) { pos++; continue; }
      pos++;
      return l;
    }
  }

  String string() {
    pos++;
    var start = pos;
    StringBuffer? buf;
    while (pos < len) {
      final c = s.codeUnitAt(pos);
      if (c == 34) break;
      if (c == 92) {
        (buf ??= StringBuffer()).write(s.substring(start, pos));
        pos++;
        final e = s.codeUnitAt(pos);
        if (e == 110) { buf!.write('\n'); } else if (e == 116) { buf!.write('\t'); }
        else if (e == 117) { buf!.write(String.fromCharCode(hex4())); }
        else { buf!.write(String.fromCharCode(e)); }
        pos++;
        start = pos;
        continue;
      }
      pos++;
    }
    final tail = s.substring(start, pos);
    pos++;
    if (buf == null) return tail;
    buf.write(tail);
    return buf.toString();
  }

  int hex4() {
    var v = 0;
    for (var i = 0; i < 4; i++) {
      final c = s.codeUnitAt(pos);
      var d = c - 48;
      if (d > 9) d = (c | 32) - 87;
      v = v * 16 + d;
      pos++;
    }
    return v;
  }

  num number() {
    var neg = false;
    if (s.codeUnitAt(pos) == 45) { neg = true; pos++; }
    var n = 0;
    while (pos < len) {
      final c = s.codeUnitAt(pos);
      if (c < 48 || c > 57) break;
      n = n * 10 + c - 48;
      pos++;
    }
    if (pos < len && s.codeUnitAt(pos) == 46) {
      pos++;
      var scale = 0.1;
      var frac = 0.0;
      while (pos < len) {
        final c = s.codeUnitAt(pos);
        if (c < 48 || c > 57) break;
        frac += (c - 48) * scale;
        scale *= 0.1;
        pos++;
      }
      final v = n + frac;
      return neg ? -v : v;
    }
    return neg ? -n : n;
  }
}

void writeString(String v, StringBuffer b) {
  b.write('"');
  var start = 0;
  for (var i = 0; i < v.length; i++) {
    final c = v.codeUnitAt(i);
    if (c == 34 || c == 92) {
      if (i > start) { b.write(v.substring(start, i)); }
      b.write('\\');
      b.writeCharCode(c);
      start = i + 1;
    } else if (c == 10) {
      if (i > start) { b.write(v.substring(start, i)); }
      b.write('\\n');
      start = i + 1;
    }
  }
  if (v.length > start) { b.write(v.substring(start)); }
  b.write('"');
}

void writeValue(Object? v, StringBuffer b) {
  if (v == null) { b.write('null'); return; }
  if (v is bool) { b.write(v ? 'true' : 'false'); return; }
  if (v is num) { b.write(v); return; }
  if (v is String) { writeString(v, b); return; }
  if (v is List) {
    b.write('[');
    for (var i = 0; i < v.length; i++) {
      if (i > 0) { b.write(','); }
      writeValue(v[i], b);
    }
    b.write(']');
    return;
  }
  final m = v as Map;
  b.write('{');
  var first = true;
  m.forEach((key, val) {
    if (!first) { b.write(','); }
    first = false;
    writeString(key as String, b);
    b.write(':');
    writeValue(val, b);
  });
  b.write('}');
}

String makeDoc(int seed) {
  var x = seed;
  int next() { x = (x * 1103515245 + 12345) & 0x7fffffff; return x; }
  final b = StringBuffer();
  b.write('{"items":[');
  for (var i = 0; i < 40; i++) {
    if (i > 0) b.write(',');
    b.write('{"id":');
    b.write(next() % 100000);
    b.write(',"name":"user_');
    b.write(next() % 9999);
    b.write('","tags":["alpha","b');
    b.write(next() % 999);
    b.write('","g"],"score":');
    b.write((next() % 10000) / 100);
    b.write(',"ok":');
    b.write(next() % 3 == 0 ? 'true' : 'false');
    b.write(',"meta":null}');
  }
  b.write('],"count":40}');
  return b.toString();
}

int checksum(Object? v) {
  if (v is List) {
    var n = v.length;
    for (final e in v) { n += checksum(e); }
    return n;
  }
  if (v is Map) {
    var n = v.length;
    v.forEach((k, e) { n += k.length + checksum(e); });
    return n;
  }
  if (v is String) return v.length;
  if (v is int) return v & 0xff;
  if (v is double) return v.toInt() & 0xff;
  return v == null ? 0 : 1;
}

int main(int n) {
  var total = 0;
  for (var i = 0; i < n; i++) {
    final doc = makeDoc(123456789 + i * 2654435761);
    final parsed = Parser(doc).value();
    final out = StringBuffer();
    writeValue(parsed, out);
    total += out.length + checksum(parsed);
  }
  return total;
}
''';

void main(List<String> args) {
  final iterations = args.isEmpty ? 4000 : int.parse(args[0]);
  final samples = args.length < 2 ? 7 : int.parse(args[1]);
  final compiler = Compiler();
  compiler.entrypoints.add('package:json_codec/main.dart');
  final program = compiler.compile({
    'json_codec': {'main.dart': _source},
  });
  final runtime = Runtime(program.write().buffer);
  int run(int n) =>
      runtime.executeLib(
        'package:json_codec/main.dart',
        'main',
        arguments: {'n': n},
      )
          as int;
  var checksum = 0;
  for (var warm = 0; warm < 2; warm++) {
    checksum += run(50);
  }
  final times = <double>[];
  for (var sample = 0; sample < samples; sample++) {
    final watch = Stopwatch()..start();
    final result = run(iterations);
    watch.stop();
    checksum += result;
    times.add(watch.elapsedMicroseconds / 1000);
  }
  final raw = List<double>.of(times);
  times.sort();
  final median = times[times.length ~/ 2];
  print(
    'json_codec median_ms=${median.toStringAsFixed(3)} '
    'min_ms=${times.first.toStringAsFixed(3)} '
    'max_ms=${times.last.toStringAsFixed(3)} '
    'ns/iteration=${(median * 1000000 / iterations).toStringAsFixed(2)} '
    'raw_ms=${raw.map((value) => value.toStringAsFixed(3)).join(',')}',
  );
  print('checksum=$checksum');
}
