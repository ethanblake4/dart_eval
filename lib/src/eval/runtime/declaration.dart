import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/runtime/class.dart';

/// A class is an instance of [Type]
class EvalClass extends $InstanceImpl {
  EvalClass(this.delegatedType, this.superclass, this.mixins, this.getters,
      this.setters, this.methods)
      : super(EvalClassClass.instance, null, const []);

  factory EvalClass.fromJson(List def) {
    return EvalClass(def[3] as int, null, [], (def[0] as Map).cast(),
        (def[1] as Map).cast(), (def[2] as Map).cast());
  }

  final int delegatedType;

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType(CoreTypes.type);

  @override
  // ignore: overridden_fields
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
  int $getRuntimeType(Runtime runtime) => throw UnimplementedError();

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    throw UnimplementedError();
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    throw UnimplementedError();
  }

  @override
  $Instance? get evalSuperclass => throw UnimplementedError();

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
  set values(List<Object?> values) => throw UnimplementedError();

  @override
  Never get evalClass => throw UnimplementedError();

  @override
  Never get $value => throw UnimplementedError();

  @override
  int get delegatedType => throw UnimplementedError();

  @override
  $Value? getCoreObjectProperty(String identifier) {
    throw UnimplementedError();
  }
}
