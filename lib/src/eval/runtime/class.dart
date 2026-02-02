import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/declaration/field.dart';
import 'package:dart_eval/src/eval/runtime/exception.dart';
import 'package:dart_eval/src/eval/runtime/function.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/base.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/num.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/type.dart';

/// Interface for objects with a backing value. Those can be stored to the
/// execution frame and passed as arguments. Related to this is the term
/// "boxing" (and "unboxing"): wrapping an object in a [$Value] (usually
/// by calling a "wrap" method), and unwrapping (with [$value]).
abstract class $Value {
  /// Index of the class [Type] in the runtime dictionary. By definition
  /// can change from run to run, so it's customary to use [Runtime.lookupType]
  /// in implementations.
  int $getRuntimeType(Runtime runtime);

  /// The backing Dart value of this [$Value].
  dynamic get $value;

  /// Fully reify the underlying value so it can be used in a Dart context.
  /// For example, recursively transform collections into their underlying
  /// [$value]s.
  dynamic get $reified;
}

/// Interface for objects with properties and methods. Given the nature
/// of Dart (that virtually everything is an object), most classes
/// (including wrappers) implement this interface.
abstract class $Instance implements $Value {
  /// Get a property by [identifier] on this instance
  $Value? $getProperty(Runtime runtime, String identifier);

  /// Set a property by [identifier] on this instance to [value]
  void $setProperty(Runtime runtime, String identifier, $Value value);
}

/// Usually an instance of a class defined inside the evaluated code.
class $InstanceImpl implements $Instance {
  /// Class type. For signature definitions and implementations of methods
  /// and fields.
  final EvalClass evalClass;

  /// A superclass for this instance. Can also be an [$InstanceImpl].
  final $Instance? evalSuperclass;

  /// List of property values. This field is accessed directly only from
  /// the generated getters and setters, see [compileFieldDeclaration].
  late final List<Object?> values;

  $InstanceImpl(this.evalClass, this.evalSuperclass, this.values);

  @override
  int $getRuntimeType(Runtime runtime) => evalClass.delegatedType;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    final getter = evalClass.getters[identifier];
    if (getter == null) {
      final method = evalClass.methods[identifier];
      if (method == null) {
        if (evalSuperclass == null) {
          return getCoreObjectProperty(identifier);
        }
        return evalSuperclass!.$getProperty(runtime, identifier);
      }
      return EvalStaticFunctionPtr(this, method);
    }
    runtime.args.add(this);
    runtime.bridgeCall(getter);
    try {
      return runtime.returnValue as $Value;
    } on TypeError {
      throw InvalidUnboxedValueException(
        'Expected \$Value for "$identifier" field',
        runtime.returnValue,
      );
    }
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    final setter = evalClass.setters[identifier];
    if (setter == null) {
      if (evalSuperclass != null) {
        return evalSuperclass!.$setProperty(runtime, identifier, value);
      } else {
        throw EvalUnknownPropertyException(identifier);
      }
    }

    runtime.args.add(this);
    runtime.args.add(value);
    runtime.bridgeCall(setter);
  }

  $Value? getCoreObjectProperty(String identifier) {
    switch (identifier) {
      case 'hashCode':
        return $int(hashCode);
      case 'toString':
        return __toString;
      case '==':
        return __equals;
      case '!=':
        return __notEquals;
      case 'runtimeType':
        return $TypeImpl(evalClass.delegatedType);
      default:
        throw EvalUnknownPropertyException(identifier);
    }
  }

  static const $Function __equals = $Function(_equals);

  static $Value? _equals(Runtime runtime, $Value? target, List<$Value?> args) {
    final other = args[0];
    return $bool(target == other);
  }

  static const $Function __notEquals = $Function(_notEquals);

  static $Value? _notEquals(
    Runtime runtime,
    $Value? target,
    List<$Value?> args,
  ) {
    final other = args[0];
    return $bool(target != other);
  }

  static const $Function __toString = $Function(_toString);

  static $Value? _toString(
    Runtime runtime,
    $Value? target,
    List<$Value?> args,
  ) {
    return $String('object Object');
  }

  @override
  Never get $reified => throw UnimplementedError();

  @override
  Never get $value => throw UnimplementedError();
}
