// Usage: dart run tool/ir_snapshot.dart [out.json] [--compare baseline.json]
//
// Compiles every runnable/negative sdk_language core test plus the
// self-contained eval programs embedded in benchmark/*.dart, and records a
// SHA-1 of `program.write()` per program. Tests that fail to compile record
// an outcome marker instead, so "compiles today" vs "errors today" diffs are
// also caught. With --compare, prints the programs whose snapshot changed.
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/model/source.dart';

import '../test/sdk_language/sdk_language.dart';

const _defaultOut = 'tool/ir_snapshot.json';

Future<Map<String, String>> _snapshot() async {
  final out = <String, String>{};

  // --- SDK language core set ---
  final suite = await SdkSuite.load();
  final tests = suite.coreTests();
  var compiler = Compiler();
  var sinceReset = 0;
  for (final t in tests) {
    if (t.kind == TestKind.unsupported) continue;
    final key = 'sdk/${t.relPath}';
    final List<DartSource> sources;
    try {
      sources = suite.collectSources(t);
    } on UnsupportedError {
      continue;
    }
    if (++sinceReset >= 200) {
      compiler = Compiler();
      sinceReset = 0;
    }
    compiler.entrypoints
      ..clear()
      ..add('/${t.relPath}');
    out[key] = _compile(compiler, sources);
  }

  // --- Benchmark programs ---
  for (final file in Directory('benchmark').listSync().whereType<File>().where(
    (f) => f.path.endsWith('.dart'),
  )) {
    final name = file.uri.pathSegments.last.replaceAll('.dart', '');
    final text = file.readAsStringSync();
    var i = 0;
    for (final m in RegExp(r"r?'''([\s\S]*?)'''").allMatches(text)) {
      final src = m.group(1)!;
      // Only self-contained programs: must define main(), contain no
      // string interpolation, and import nothing but supported dart: libs.
      if (!RegExp(r'\bmain\s*\(').hasMatch(src)) continue;
      if (src.contains(r'$')) continue;
      if (RegExp(r'''import\s+['"]package:''').hasMatch(src)) continue;
      out['bench/$name#$i'] = _compile(Compiler(), [
        DartSource('package:ir_snapshot_${name}_$i/main.dart', src),
      ]);
      i++;
    }
  }
  return out;
}

String _mark(Object? value) =>
    value == null
        ? '(new)'
        : value is String && value.startsWith('#')
        ? value
        : 'hash';

String _compile(Compiler compiler, List<DartSource> sources) {
  try {
    final program = compiler.compileSources(sources);
    return sha1.convert(program.write()).toString();
  } on CompileError {
    return '#COMPILE_ERROR';
  } catch (e) {
    return '#ERROR:${e.runtimeType}';
  }
}

Future<void> main(List<String> args) async {
  String? comparePath;
  var outPath = _defaultOut;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--compare') {
      comparePath = args[++i];
    } else if (args[i] == '--out') {
      outPath = args[++i];
    } else {
      outPath = args[i];
    }
  }

  final snapshot = await _snapshot();
  final encoder = const JsonEncoder.withIndent('  ');
  File(outPath).writeAsStringSync('${encoder.convert(snapshot)}\n');
  stderr.writeln('wrote ${snapshot.length} entries to $outPath');

  if (comparePath != null) {
    final baseline =
        jsonDecode(File(comparePath).readAsStringSync())
            as Map<String, dynamic>;
    final changed = <String>[
      for (final e in snapshot.entries)
        if (baseline[e.key] != e.value) e.key,
      for (final k in baseline.keys)
        if (!snapshot.containsKey(k)) k,
    ]..sort();
    if (changed.isEmpty) {
      print('no diffs');
    } else {
      print('${changed.length} diffs:');
      for (final k in changed) {
        final before = baseline[k];
        final after = snapshot[k];
        print(
          '  $k: ${_mark(before)} -> ${_mark(after)}',
        );
      }
      exitCode = 1;
    }
  }
}
