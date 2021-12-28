import 'package:dart_eval/src/eval/runtime/class.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

/// A class is an instance of [Type]
class EvalClass extends EvalInstanceImpl {
  EvalClass(this.superclass, this.mixins, this.getters, this.setters, this.methods)
      : super(EvalClassClass.instance, EvalTypeClass(), const []);

  @override
  final List<Object> values = [];

  final EvalClass? superclass;
  final List<EvalClass?> mixins;

  final Map<String, int> getters;
  final Map<String, int> setters;
  final Map<String, int> methods;
}

class EvalClassClass implements EvalClass {

  static final instance = EvalClassClass();

  @override
  EvalValue? $getProperty(Runtime runtime, String identifier) {
    throw UnimplementedError();
  }

  @override
  void $setProperty(Runtime runtime, String identifier, EvalValue value) {
    throw UnimplementedError();
  }

  @override
  EvalInstance? get evalSuperclass => throw UnimplementedError();

  @override
  Map<String, int> get getters => throw UnimplementedError();

  @override
  Map<String, int> get methods => throw UnimplementedError();

  @override
  List<EvalClass?> get mixins => throw UnimplementedError();

  @override
  Never get $reified => throw UnimplementedError();

  @override
  Map<String, int> get setters => throw UnimplementedError();

  @override
  EvalClass? get superclass => throw UnimplementedError();

  @override
  List<Object> get values => throw UnimplementedError();

  @override
  set values(List<Object?> _values) => throw UnimplementedError();

  @override
  Never get evalClass => throw UnimplementedError();

  @override
  Never get $value => throw UnimplementedError();
}