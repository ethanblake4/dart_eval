/// A library providing a Dart bytecode compiler and interpreter.
library;

export 'src/eval/eval.dart';
export 'src/eval/runtime/runtime.dart' show Runtime;
export 'src/eval/compiler/compiler.dart';
export 'src/eval/compiler/program.dart';
export 'src/eval/runtime/override.dart' hide runtimeOverride;
export 'src/eval/compiler/model/diagnostic_mode.dart';
