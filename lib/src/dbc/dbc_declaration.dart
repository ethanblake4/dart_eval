import 'package:dart_eval/src/dbc/dbc_class.dart';
import 'package:dart_eval/src/dbc/dbc_function.dart';

abstract class DbcDeclaration {
  DbcVmInterface get evalVm;
}

/// A class is an instance of [Type]
class DbcClass extends DbcInstanceImpl implements DbcDeclaration {
  DbcClass(this.evalVm, this.superclass, this.mixins, Map<String, int> lookupGetter, Map<String, int> lookupSetter)
      : super(DbcTypeClass(evalVm));

  @override
  final DbcVmInterface evalVm;

  @override
  final List<Object> values = [];

  final DbcClass? superclass;
  final List<DbcClass?> mixins;

  final Map<String, int> getters = {};
  final Map<String, int> setters = {};
  final Map<String, int> methods = {};
}