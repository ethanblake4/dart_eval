import 'package:dart_eval/src/eval/compiler/offset_tracker.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';

/// Compile-time only data describing how to perform a static-dispatch function call (e.g. when the exact function
/// to be called is known at compile time)
class StaticDispatch {
  const StaticDispatch(this.offset, this.returnType);

  final DeferredOrOffset offset;
  final ReturnType returnType;
}