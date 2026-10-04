// Usage: dart run tool/run_one.dart <relpath>
// Compile and run one SDK language fixture (including selected multitest
// variants), print each outcome, and return a non-zero exit code on failure.
import 'dart:io';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/model/source.dart';

import '../test/sdk_language/sdk_language.dart';

Future<void> main(List<String> args) async {
  if (args.length != 1) {
    stderr.writeln('Usage: dart run tool/run_one.dart <relpath>');
    exitCode = 64;
    return;
  }

  final suite = await SdkSuite.load();
  final fixture = suite.classify(args.single);
  stderr.writeln(
    'kind: ${fixture.kind} ${fixture.unsupportedReason ?? ''}',
  );

  final variants = suite.variants(fixture);
  final isMultitest = variants.length > 1 ||
      variants.any((variant) => variant.variantKey != null);
  final compiler = Compiler();
  var failed = false;

  for (final variant in variants) {
    final label = variant.variantKey ?? (isMultitest ? 'none' : 'main');
    final prefix = isMultitest ? '[$label] ' : '';

    if (variant.kind == TestKind.unsupported) {
      print('${prefix}SKIPPED: ${variant.unsupportedReason ?? 'unsupported'}');
      continue;
    }
    if (variant.kind == TestKind.negative &&
        suite.config.negativeMode == 'skip') {
      print('${prefix}SKIPPED: negative fixture (negative:skip)');
      continue;
    }

    final List<DartSource> sources;
    try {
      sources = suite.collectSources(variant);
    } on UnsupportedError catch (error, stack) {
      print('${prefix}SKIPPED: $error');
      _printStack(stack);
      continue;
    } catch (error, stack) {
      failed = true;
      print('${prefix}ERROR collecting sources: $error');
      _printDiagnostic(error, stack);
      continue;
    }

    setSdkEntrypoints(compiler, variant, sources);

    // Keep compilation outside the execution try/catch. An expected runtime
    // error only passes when the compiled program actually throws at runtime.
    final Program program;
    try {
      program = compiler.compileSources(sources);
    } on ArgumentError catch (error, stack) {
      if (isExpectedMissingSdkMainError(error, variant, sources)) {
        print('${prefix}PASSED (expected runtime error: $error)');
      } else {
        failed = true;
        print('${prefix}COMPILE ERROR: $error');
        _printDiagnostic(error, stack);
      }
      continue;
    } on CompileError catch (error, stack) {
      if (variant.kind == TestKind.negative) {
        print('${prefix}PASSED (expected compile error: $error)');
      } else {
        failed = true;
        print('${prefix}COMPILE ERROR: $error');
        _printDiagnostic(error, stack);
      }
      continue;
    } catch (error, stack) {
      failed = true;
      print('${prefix}COMPILE ERROR: $error');
      _printDiagnostic(error, stack);
      continue;
    }

    if (variant.kind == TestKind.negative) {
      failed = true;
      print('${prefix}FAILED: expected a compile error but compilation succeeded');
      continue;
    }

    final Runtime runtime;
    try {
      runtime = Runtime(program.write().buffer);
    } catch (error, stack) {
      failed = true;
      print('${prefix}ERROR constructing runtime: $error');
      _printDiagnostic(error, stack);
      continue;
    }

    try {
      await executeSdkMain(runtime, variant, sources);
      if (variant.kind == TestKind.runtimeError) {
        failed = true;
        print('${prefix}FAILED: expected a runtime error but main returned normally');
      } else {
        print('${prefix}PASSED');
      }
    } catch (error, stack) {
      if (variant.kind == TestKind.runtimeError) {
        print('${prefix}PASSED (expected runtime error: $error)');
      } else {
        failed = true;
        print('${prefix}ERROR: $error');
        _printDiagnostic(error, stack);
      }
    }
  }

  if (failed) exitCode = 1;
}

void _printDiagnostic(Object error, StackTrace stack) {
  if (error is TypedInstance) {
    // Show guest exception fields before the stack, including Expect failures.
    final program = error.program;
    print('eval class: ${program.classes[error.classId].name}');
    for (var i = 0; i < error.values.length; i++) {
      print('  value[$i]: ${error.values[i]}');
    }
  }
  _printStack(stack);
}

void _printStack(StackTrace stack) {
  print(stack.toString().split('\n').take(12).join('\n'));
}
