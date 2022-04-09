import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/bridge/declaration/type.dart';
import 'package:dart_eval/src/eval/runtime/stdlib/core/collection.dart';
import 'package:dart_eval/src/eval/runtime/stdlib/core/iterator.dart';
import 'package:dart_eval/src/eval/runtime/stdlib/core/pattern.dart';

import 'core/print.dart';
/*
typedef _Fd = BridgeFieldDeclaration;

const _functionTd = BridgeClassTypeDeclaration.builtin(EvalTypes.functionType);

const dartCoreLib = {
  'print': $BridgeField(_Fd(_functionTd, sets: false), get$print, null),
  'List.filled': $BridgeField(_Fd(_functionTd, sets: false), get$List_filled, null),
  'List.generate': $BridgeField(_Fd(_functionTd, sets: false), get$List_generate, null)
};

const dartCoreBridge = {
  'Iterable': $Iterable$bridge.$classDef,
  'Iterator': $Iterator$bridge.$classDef,
  'Pattern': $Pattern$bridge.$classDef
};*/