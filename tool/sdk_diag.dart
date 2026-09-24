/// Diagnostic runner for the sdk_language suite: runs every runnable test,
/// captures the real failure reason, and prints a clustered report.
///
/// Usage: dart run tool/sdk_diag.dart [dirFilter...]
///   e.g. dart run tool/sdk_diag.dart closure/ method/
///   (no args = every runnable test; may take a while)
library;

import 'dart:async';
import 'dart:io';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/model/source.dart';

import '../test/sdk_language/sdk_language.dart';

/// The suite's eval'd tests can leave pending timers/futures that throw
/// after `main` returns; guard the zone so one such test can't kill the run.
Future<void> main(List<String> args) {
  final done = Completer<void>();
  runZonedGuarded(() async {
    try {
      await _run(args);
    } finally {
      done.complete();
    }
  }, (e, st) => stderr.writeln('unhandled async error: $e'));
  return done.future;
}

Future<void> _run(List<String> args) async {
  final suite = await SdkSuite.load();
  var tests = suite.allTests().where((t) => t.kind == TestKind.runnable);
  if (args.isNotEmpty) {
    tests = tests.where((t) => args.any((a) => t.relPath.startsWith(a)));
  }
  // DIAG_SKIP='a/,b/c_test.dart' skips tests whose relPath starts with an
  // entry; DIAG_TRACE=1 echoes each relPath before running it (for locating
  // tests that crash the isolate outright).
  final skip = (Platform.environment['DIAG_SKIP'] ?? '')
      .split(',')
      .where((s) => s.isNotEmpty)
      .toList();
  if (skip.isNotEmpty) {
    tests = tests.where((t) => !skip.any((s) => t.relPath.startsWith(s)));
  }
  final trace = Platform.environment['DIAG_TRACE'] == '1';
  final list = tests.toList();
  stderr.writeln('running ${list.length} tests');

  var compiler = Compiler();
  var i = 0;
  final failures = <String, List<String>>{}; // signature -> relPaths
  final details = <String, String>{}; // signature -> one example error
  var passed = 0, skipped = 0;

  for (final t in list) {
    i++;
    if (trace) stderr.writeln('#$i ${t.relPath}');
    if (i % 300 == 0) {
      compiler = Compiler();
      stderr.writeln('[$i/${list.length}]');
    }
    final List<DartSource> sources;
    try {
      sources = suite.collectSources(t);
    } on UnsupportedError {
      skipped++;
      continue;
    }
    compiler.entrypoints
      ..clear()
      ..add('/${t.relPath}');
    try {
      final program = compiler.compileSources(sources);
      final runtime = Runtime(program.write().buffer);
      runtime.executeLib(t.uri, 'main');
      passed++;
    } catch (e, st) {
      final sig = _signature(e, st);
      failures.putIfAbsent(sig, () => []).add(t.relPath);
      details[sig] = '$e\n${st.toString().split('\n').take(4).join('\n')}';
    }
  }

  final out = File(Platform.environment['DIAG_OUT'] ?? '/tmp/failures.tsv');
  final buf = StringBuffer();
  for (final e in failures.entries) {
    for (final p in e.value) {
      buf.writeln('${e.key}\t$p');
    }
  }
  out.writeAsStringSync(buf.toString());

  stdout.writeln(
    'passed=$passed skipped=$skipped failed=${list.length - passed - skipped}',
  );
  final sorted = failures.entries.toList()
    ..sort((a, b) => b.value.length.compareTo(a.value.length));
  for (final e in sorted) {
    stdout.writeln('\n=== [${e.value.length}] ${e.key}');
    stdout.writeln('    example: ${e.value.first}');
    stdout.writeln('    ${details[e.key]!.split('\n').take(3).join('\n    ')}');
    if (e.value.length <= 12) {
      for (final p in e.value) {
        stdout.writeln('      - $p');
      }
    } else {
      for (final p in e.value.take(12)) {
        stdout.writeln('      - $p');
      }
      stdout.writeln('      ... ${e.value.length - 12} more');
    }
  }
}

String _signature(Object e, StackTrace st) {
  var s = e.toString();
  // TypedInstance is an eval'd exception escaping uncaught — unwrap it to the
  // eval class name + message so real root causes cluster instead of every
  // uncaught throw sharing one signature.
  if (e is TypedInstance) {
    final cls = e.program.classes[e.classId].name;
    var detail = '';
    for (final v in e.values) {
      if (v != null) {
        detail = ' ${v.toString()}';
        break;
      }
    }
    s = '$cls:$detail'
        .replaceAll(RegExp(r'package:sdk_language/[^\s,)]+'), '<src>')
        .replaceAll(RegExp(r'\b\d+\b'), 'N');
    if (s.length > 160) s = s.substring(0, 160);
    return s;
  }
  // Normalize paths/numbers so identical root causes cluster.
  s = s.replaceAll(RegExp(r'package:sdk_language/[^\s,)]+'), '<src>');
  s = s.replaceAll(RegExp(r"'[^']{20,}'"), "'…'");
  s = s.replaceAll(RegExp(r'\b\d+\b'), 'N');
  if (s.length > 120) s = s.substring(0, 120);
  final frame = st
      .toString()
      .split('\n')
      .firstWhere((l) => l.contains('package:dart_eval'), orElse: () => '')
      .replaceAll(RegExp(r'package:dart_eval/'), '')
      .replaceAll(RegExp(r':\d+:\d+'), '')
      .trim();
  return '$s @$frame';
}
