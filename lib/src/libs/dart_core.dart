import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/functions.dart';
import 'package:dart_eval/src/eval/primitives.dart';
import 'package:dart_eval/src/libs/core_datetime.dart';

final dartCore = <DartDeclaration>[
  DartBridgeDeclaration(
      visibility: DeclarationVisibility.PUBLIC,
      declarator: (ctx, lex, cur) => {
            EvalType.DateTimeType.refName: EvalField(
                EvalType.DateTimeType.refName,
                EvalDateTime.cls = EvalDateTime.clsgen(lex),
                null,
                Getter(null))
          }),
  DartBridgeDeclaration(
      visibility: DeclarationVisibility.PUBLIC,
      declarator: (ctx, lex, cur) => {
            'print': EvalField(
                'print',
                EvalFunctionImpl(DartMethodBody(
                    callable: (s1, s2, gen, params, {EvalValue? target}) {
                  print(params[0].value.realValue);
                  return EvalNull();
                }), [
                  ParameterDefinition('object', EvalType.objectType, true,
                      false, false, false, null)
                ]),
                null,
                Getter(null)),
            EvalType.numType.refName: EvalField(EvalType.numType.refName,
                EvalNumClass.instance, null, Getter(null)),
            EvalType.boolType.refName: EvalField(EvalType.boolType.refName,
                EvalBoolClass.instance, null, Getter(null)),
            EvalType.intType.refName: EvalField(EvalType.intType.refName,
                EvalIntClass.instance, null, Getter(null)),
            EvalType.stringType.refName: EvalField(EvalType.stringType.refName,
                EvalStringClass.instance, null, Getter(null)),
            EvalType.objectType.refName: EvalField(EvalType.objectType.refName,
                EvalObjectClass.instance, null, Getter(null))
          }),
];
