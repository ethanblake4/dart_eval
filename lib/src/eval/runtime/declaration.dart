import 'package:dart_eval/src/eval/runtime/class.dart';
import 'package:dart_eval/src/eval/runtime/function.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';


abstract class DbcDeclaration {}

/// A class is an instance of [Type]
class DbcClass extends DbcInstanceImpl implements DbcDeclaration {
  DbcClass(this.superclass, this.mixins, this.getters, this.setters, this.methods)
      : super(DbcClassClass.instance, DbcTypeClass(), const []);

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
  var $value;

  @override
  IDbcValue? $getProperty(Runtime runtime, String identifier) {
    // TODO: implement evalGetProperty
    throw UnimplementedError();
  }

  @override
  void $setProperty(Runtime runtime, String identifier, IDbcValue value) {
    // TODO: implement evalSetProperty
    throw UnimplementedError();
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
  get $reified => throw UnimplementedError();

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
  set values(List<Object?> _values) => throw UnimplementedError();

  @override
  // TODO: implement evalClass
  get evalClass => throw UnimplementedError();

}