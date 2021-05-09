import 'package:dart_eval/src/eval/class.dart';
import 'package:dart_eval/src/eval/functions.dart';
import 'package:dart_eval/src/eval/generics.dart';
import 'package:dart_eval/src/libs/dart_core.dart';

import '../../dart_eval.dart';
import 'object.dart';

final dartCoreScope = EvalScope(null, {});

class EvalNull extends EvalValue with ValueInterop {
  EvalNull() : super(EvalType.nullType, realValue: null);

  @override
  EvalValue evalGetField(String name, {bool internalGet = false}) {
    throw UnimplementedError();
  }

  @override
  void evalSetField(String name, EvalValue value, {bool internalSet = false}) {
    throw UnimplementedError();
  }

  @override
  EvalField evalGetFieldRaw(String name) {
    throw UnimplementedError();
  }

  @override
  void evalSetGetter(String name, Getter getter) {
  }
}

class EvalObjectClass extends EvalBridgeAbstractClass {
  EvalObjectClass(EvalScope lexicalScope)
      : super([
          //DartFunctionDeclaration('toString', functionBody, isStatic: false, visibility: visibility)
        ], EvalType.objectType, lexicalScope, Object);

  static final instance = EvalObjectClass(dartCoreScope);
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
      : super([], EvalType.numType, lexicalScope, num);

  static final instance = EvalNumClass(dartCoreScope);
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
      : super([], EvalType.intType, lexicalScope, int);

  static final instance = EvalIntClass(dartCoreScope);
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
      : super([], EvalType.boolType, lexicalScope, bool);

  static final instance = EvalBoolClass(dartCoreScope);
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
      : super([], EvalType.stringType, lexicalScope, String);

  static final instance = EvalStringClass(dartCoreScope);
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

  static final instance = EvalListClass(dartCoreScope);
}

class EvalList extends EvalObject<List<EvalValue>> {
  EvalList(List<EvalValue> value)
    : super(EvalListClass.instance, realValue: value, fields: {
    '[]': EvalField(
        '[]',
        EvalFunctionImpl(DartMethodBody(callable: (lex, s2, gen, params, {EvalValue? target}) {
          return target!.realValue![params[0].value];
        }), []),
        null,
        Getter(null)),
  });

  @override
  List<dynamic> evalReifyFull() {
    return <dynamic>[
      ...realValue!.map<dynamic>((e) => e.evalReifyFull())
    ];
  }
}

class EvalMapClass extends EvalAbstractClass {
  EvalMapClass(EvalScope lexicalScope)
      : super([], EvalGenericsList([EvalGenericParam('K'), EvalGenericParam('V')]), EvalType.listType, lexicalScope,
      superclassName: EvalType.objectType);

  static final instance = EvalMapClass(dartCoreScope);
}

class EvalMap extends EvalObject<Map<EvalValue, EvalValue>> {
  EvalMap(Map<EvalValue, EvalValue> value)
      : super(EvalMapClass.instance, realValue: value, fields: {
    '[]': EvalField(
        '[]',
        EvalFunctionImpl(DartMethodBody(callable: (lex, s2, gen, params, {EvalValue? target}) {
          return target!.realValue![params[0].value];
        }), []),
        null,
        Getter(null)),
  });

  @override
  Map<dynamic, dynamic> evalReifyFull() {
    return realValue!.map((key, value) =>
          MapEntry(key.evalReifyFull(), value.evalReifyFull()));
  }
}

