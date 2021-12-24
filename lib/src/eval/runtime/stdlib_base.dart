import 'package:dart_eval/src/eval/runtime/exception.dart';
import 'package:dart_eval/src/eval/runtime/function.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

import 'class.dart';

class DbcNull implements IDbcValue {
  const DbcNull();

  @override
  Null get $value => null;

  @override
  Null get $reified => null;
}

class DbcObject implements DbcInstance {
  const DbcObject();

  @override
  dynamic get $value => null;

  @override
  dynamic get $reified => $value;

  @override
  DbcInstance? get evalSuperclass => null;

  @override
  DbcValue? $getProperty(Runtime runtime, String identifier) {
    throw UnimplementedError();
  }

  @override
  void $setProperty(Runtime runtime, String identifier, IDbcValue value) {
    throw UnimplementedError();
  }
}

class DbcBool implements DbcInstance {
  DbcBool(this.$value);

  @override
  bool $value;

  @override
  IDbcValue? $getProperty(Runtime runtime, String identifier) {
    switch(identifier) {}
    return evalSuperclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, IDbcValue value) {

  }

  @override
  DbcInstance evalSuperclass = DbcObject();

  @override
  bool get $reified => $value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DbcNum && runtimeType == other.runtimeType && $value == other.$value;

  @override
  int get hashCode => $value.hashCode;

  @override
  String toString() {
    return 'DbcBool{${$value}}';
  }
}

class DbcNum<T extends num> implements DbcInstance {
  DbcNum(this.$value);

  @override
  T $value;

  @override
  IDbcValue? $getProperty(Runtime runtime, String identifier) {
    switch(identifier) {
      case '+':
        return __plus;
      case '-':
        return __minus;
      case '<':
        return __lt;
    }
    return evalSuperclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, IDbcValue value) {
    throw UnimplementedError();
  }

  @override
  DbcInstance evalSuperclass = DbcObject();

  @override
  T get $reified => $value;

  static const DbcFunctionImpl __plus = DbcFunctionImpl(_plus);
  static IDbcValue? _plus(Runtime runtime, IDbcValue? target, List<IDbcValue?> args) {
    final other = args[0];
    final _evalResult = target!.$value + other!.$value;

    if (_evalResult is int) {
      return DbcInt(_evalResult);
    }
    if (_evalResult is double) {
      return DbcDouble(_evalResult);
    }

    throw UnimplementedError();
  }

  static const DbcFunctionImpl __minus = DbcFunctionImpl(_minus);
  static IDbcValue? _minus(Runtime runtime, IDbcValue? target, List<IDbcValue?> args) {
    final other = args[0];
    final _evalResult = target!.$value - other!.$value;

    if (_evalResult is int) {
      return DbcInt(_evalResult);
    }
    if (_evalResult is double) {
      return DbcDouble(_evalResult);
    }

    throw UnimplementedError();
  }

  static const DbcFunctionImpl __lt = DbcFunctionImpl(_lt);
  static IDbcValue? _lt(Runtime runtime, IDbcValue? target, List<IDbcValue?> args) {
    final other = args[0];
    final _evalResult = target!.$value < other!.$value;

    if (_evalResult is bool) {
      return DbcBool(_evalResult);
    }

    throw UnimplementedError();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DbcNum && runtimeType == other.runtimeType && $value == other.$value;

  @override
  int get hashCode => $value.hashCode;
}

class DbcInt extends DbcNum<int> {

  DbcInt(int evalValue) : super(evalValue);

  @override
  IDbcValue? $getProperty(Runtime runtime, String identifier) {
    return super.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, IDbcValue value) {
    return super.$setProperty(runtime, identifier, value);
  }

  @override
  DbcInstance get evalSuperclass => throw UnimplementedError();

  @override
  int get $reified => $value;

  @override
  String toString() {
    return $value.toString();
  }
}

class DbcDouble extends DbcNum<double> {

  DbcDouble(double evalValue) : super(evalValue);

  @override
  IDbcValue? $getProperty(Runtime runtime, String identifier) {
    return super.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, IDbcValue value) {
    return super.$setProperty(runtime, identifier, value);
  }

  @override
  DbcInstance get evalSuperclass => throw UnimplementedError();

  @override
  double get $reified => $value;
}

class DbcInvocation implements DbcInstance {

  DbcInvocation.getter(this.positionalArguments);

  final DbcList2? positionalArguments;

  @override
  IDbcValue? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'positionalArguments':
        return positionalArguments;
    }
  }

  @override
  void $setProperty(Runtime runtime, String identifier, IDbcValue value) {

  }

  @override
  DbcInstance? get evalSuperclass => throw UnimplementedError();

  @override
  dynamic get $value => throw UnimplementedError();

  @override
  dynamic get $reified => throw UnimplementedError();

}


class DbcList2 implements DbcInstance {

  DbcList2(this.$value);

  @override
  final List<DbcValue> $value;

  @override
  DbcInstance evalSuperclass = DbcObject();

  @override
  IDbcValue? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case '[]':

    }
  }

  @override
  void $setProperty(Runtime runtime, String identifier, IDbcValue value) {
    throw EvalUnknownPropertyException(identifier);
  }



  @override
  List get $reified => $value.map((e) => e.$reified).toList();
}