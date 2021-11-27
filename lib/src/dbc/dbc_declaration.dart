import 'package:dart_eval/src/dbc/dbc_class.dart';
import 'package:dart_eval/src/dbc/dbc_function.dart';

abstract class DbcDeclaration {
  DbcVmInterface get evalVm;
}

/// A class is an instance of [Type]
class DbcClass extends DbcInstanceImpl implements DbcDeclaration {
  DbcClass(this.evalVm, this.superclass, this.mixins, this.getters, this.setters, this.methods)
      : super(DbcClassClass.instance, DbcTypeClass(evalVm));

  @override
  final DbcVmInterface evalVm;

  @override
  final List<Object> values = [];

  final DbcClass? superclass;
  final List<DbcClass?> mixins;

  final Map<String, int> getters;
  final Map<String, int> setters;
  final Map<String, int> methods;
}

class DbcClassClass implements DbcClass {

  static final instance = DbcClassClass();

  @override
  var evalValue;

  @override
  DbcValueInterface? evalGetProperty(String identifier) {
    // TODO: implement evalGetProperty
    throw UnimplementedError();
  }

  @override
  void evalSetProperty(String identifier, DbcValueInterface value) {
    // TODO: implement evalSetProperty
  }

  @override
  DbcInstance? get evalSuperclass => throw UnimplementedError();

  @override
  DbcVmInterface get evalVm => throw UnimplementedError();

  @override
  Map<String, int> get getters => throw UnimplementedError();

  @override
  Map<String, int> get methods => throw UnimplementedError();

  @override
  List<DbcClass?> get mixins => throw UnimplementedError();

  @override
  get reifiedValue => throw UnimplementedError();

  @override
  // TODO: implement setters
  Map<String, int> get setters => throw UnimplementedError();

  @override
  // TODO: implement superclass
  DbcClass? get superclass => throw UnimplementedError();

  @override
  // TODO: implement values
  List<Object> get values => throw UnimplementedError();

  @override
  // TODO: implement evalClass
  get evalClass => throw UnimplementedError();

}