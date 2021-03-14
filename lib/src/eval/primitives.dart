import 'package:dart_eval/src/eval/class.dart';
import 'package:dart_eval/src/eval/functions.dart';
import 'package:dart_eval/src/eval/generics.dart';

import '../../dart_eval.dart';
import 'object.dart';

class EvalNull extends EvalValue<Null> with ValueInterop<Null> {
  EvalNull() : super(EvalType.nullType, realValue: null);

  @override
  EvalValue getField(String name) {
    throw UnimplementedError();
  }

  @override
  void setField(String name, EvalValue value) {
    throw UnimplementedError();
  }
}

class EvalObjectClass extends EvalBridgeAbstractClass {
  EvalObjectClass(EvalScope lexicalScope)
      : super([
          //DartFunctionDeclaration('toString', functionBody, isStatic: false, visibility: visibility)
        ], EvalGenericsList([]), EvalType.objectType, lexicalScope, Object);

  static final instance = EvalObjectClass(EvalScope.empty);
}

class EvalRealObject<T extends Object> extends EvalBridgeObject<T> {
  EvalRealObject(T value, {EvalBridgeAbstractClass? cls, Map<String, EvalField>? fields})
      : super(cls ?? EvalObjectClass.instance, realValue: value, fields: {
          'hashCode': EvalField('hashCode', null, null,
              Getter(EvalCallableImpl((lex, _1, _2, _3, {EvalValue? target}) => EvalInt(lex.me<Object>().realValue!.hashCode)))),
          'toString': EvalField(
              'toString',
              EvalFunctionImpl(DartMethodBody(callable: (lex, s2, gen, params, {EvalValue? target}) {
                return EvalString(target!.realValue!.toString());
              }), []),
              null,
              Getter(null)),
          '+': EvalField(
              '+',
              EvalFunctionImpl(DartMethodBody(callable: (lex, s2, gen, params, {EvalValue? target}) {
                return EvalString(target!.realValue! + params[0].value.realValue!);
              }), []),
              null,
              Getter(null)),
          '-': EvalField(
              '-',
              EvalFunctionImpl(DartMethodBody(callable: (lex, s2, gen, params, {EvalValue? target}) {
                return EvalString(target!.realValue! - params[0].value.realValue!);
              }), []),
              null,
              Getter(null)),
          '/': EvalField(
              '/',
              EvalFunctionImpl(DartMethodBody(callable: (lex, s2, gen, params, {EvalValue? target}) {
                return EvalString(target!.realValue! / params[0].value.realValue!);
              }), []),
              null,
              Getter(null)),
          '*': EvalField(
              '*',
              EvalFunctionImpl(DartMethodBody(callable: (lex, s2, gen, params, {EvalValue? target}) {
                return EvalString(target!.realValue! * params[0].value.realValue!);
              }), []),
              null,
              Getter(null)),
          ...(fields ?? {}),
        });
}

class EvalNumClass extends EvalBridgeAbstractClass {
  EvalNumClass(EvalScope lexicalScope)
      : super([], EvalGenericsList([]), EvalType.numType, lexicalScope, num, superclassName: EvalType.objectType);

  static final instance = EvalNumClass(EvalScope.empty);
}

class EvalNum<T extends num> extends EvalRealObject<T> {
  EvalNum(T value, {EvalBridgeAbstractClass? cls, Map<String, EvalField>? fields})
      : super(value, cls: cls ?? EvalNumClass.instance, fields: {
          'isFinite': EvalField('isFinite', null, null,
              Getter(EvalCallableImpl((lex, _1, _2, _3, {EvalValue? target}) => EvalBool(lex.me<num>().realValue!.isFinite)))),
          'isInfinite': EvalField('isInfinite', null, null,
              Getter(EvalCallableImpl((lex, _1, _2, _3, {EvalValue? target}) => EvalBool(lex.me<num>().realValue!.isInfinite)))),
          ...(fields ?? {}),
        });

  @override
  T get realValue => super.realValue!;
}

class EvalIntClass extends EvalBridgeAbstractClass {
  EvalIntClass(EvalScope lexicalScope)
      : super([], EvalGenericsList([]), EvalType.intType, lexicalScope, int, superclassName: EvalType.numType);

  static final instance = EvalIntClass(EvalScope.empty);
}

class EvalInt extends EvalNum<int> {
  EvalInt(int value)
      : super(value, cls: EvalIntClass.instance, fields: {
          'isEven': EvalField('isEven', null, null,
              Getter(EvalCallableImpl((lex, _1, _2, _3, {EvalValue? target}) => EvalBool(lex.me<int>().realValue!.isEven)))),
          'isOdd': EvalField('isOdd', null, null,
              Getter(EvalCallableImpl((lex, _1, _2, _3, {EvalValue? target}) => EvalBool(lex.me<int>().realValue!.isOdd)))),
        });
}

class EvalBoolClass extends EvalBridgeAbstractClass {
  EvalBoolClass(EvalScope lexicalScope)
      : super([], EvalGenericsList([]), EvalType.boolType, lexicalScope, bool, superclassName: EvalType.boolType);

  static final instance = EvalBoolClass(EvalScope.empty);
}


class EvalBool extends EvalBridgeObject<bool> {
  EvalBool(bool value)
      : super(EvalBoolClass.instance, realValue: value, fields: {
          'hashCode':
              EvalField('hashCode', null, null, Getter(EvalCallableImpl((_0, _1, _2, _3, {EvalValue? target}) => EvalNum(value.hashCode))))
        });
}

class EvalStringClass extends EvalBridgeAbstractClass {
  EvalStringClass(EvalScope lexicalScope)
      : super([], EvalGenericsList([]), EvalType.stringType, lexicalScope, String, superclassName: EvalType.objectType);

  static final instance = EvalStringClass(EvalScope.empty);
}

class EvalString extends EvalRealObject<String> {
  EvalString(String value)
      : super(value, cls: EvalStringClass.instance, fields: {
          'isEmpty': EvalField('isEmpty', null, null,
              Getter(EvalCallableImpl((lex, _1, _2, _3, {EvalValue? target}) => EvalBool(lex.me<String>().realValue!.isEmpty)))),
        });
}

class EvalListClass extends EvalAbstractClass {
  EvalListClass(EvalScope lexicalScope)
      : super([], EvalGenericsList([EvalGenericParam('T')]), EvalType.listType, lexicalScope,
            superclassName: EvalType.objectType);

  static final instance = EvalListClass(EvalScope.empty);
}

/*class EvalList extends EvalObject {
  EvalList(List value)
    : super(EvalListClass.instance, realValue: value, fields: {

  })
}*/
