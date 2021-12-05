import 'package:dart_eval/src/eval/compiler/type.dart';

import 'offset_tracker.dart';

class Variable {
  Variable(this.scopeFrameOffset, this.type, this.nullable,
      {this.methodOffset, this.methodReturnType, this.boxed = true});

  final int scopeFrameOffset;
  final TypeRef type;
  final DeferredOrOffset? methodOffset;
  final ReturnType? methodReturnType;
  final bool boxed;

  bool? nullable;
  String? name;
  int? frameIndex;
}