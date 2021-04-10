import '../../dart_eval.dart';

abstract class Reference {
  EvalValue? get value;
  set value(EvalValue? newValue);
}