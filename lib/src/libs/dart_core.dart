import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/functions.dart';
import 'package:dart_eval/src/eval/primitives.dart';

final dartCore = <String, EvalField>{
  'print': EvalField(
      'print',
      EvalFunctionImpl(DartMethodBody(callable: (s1, s2, gen, params, {EvalValue? target}) {
        print(params[0].value.realValue);
        return EvalNull();
      }), [ParameterDefinition('object', EvalType.objectType, true, false, false, false, null)]),
      null,
      Getter(null)),
  EvalType.numType.refName: EvalField(EvalType.numType.refName, EvalNumClass.instance, null, Getter(null)),
  EvalType.boolType.refName: EvalField(EvalType.boolType.refName, EvalBoolClass.instance, null, Getter(null)),
  EvalType.intType.refName: EvalField(EvalType.intType.refName, EvalIntClass.instance, null, Getter(null)),
  EvalType.stringType.refName: EvalField(EvalType.stringType.refName, EvalStringClass.instance, null, Getter(null)),
};
