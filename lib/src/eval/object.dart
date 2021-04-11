import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/class.dart';
import 'package:dart_eval/src/eval/functions.dart';

typedef BridgeInstantiator<T> = T Function(
    String constructorName, List<dynamic> positionalArgs, Map<String, dynamic> namedArgs);

/// Oops! We need classes that extend StatelessWidget to ACTUALLY extend StatelessWidget.
/// So we can create a wrapper (easier, at least short term) or turn EvalObject into a mixin (oof)
class EvalObject<T> extends EvalValueImpl<T> implements EvalCallable {
  EvalObject(this.evalPrototype, {String? sourceFile, required Map<String, EvalField> fields, T? realValue})
      : super(evalPrototype.delegatedType,
            sourceFile: sourceFile, realValue: realValue, fieldListBreakout: EvalFieldListBreakout.withFields(fields));

  final EvalAbstractClass evalPrototype;

  /// For callable classes
  @override
  EvalValue call(EvalScope lexicalScope, EvalScope inheritedScope, List<EvalType> generics, List<Parameter> args,
      {EvalValue? target}) {
    //if (getField('call') != null) {}
    throw UnimplementedError('Not a callable class');
  }
}

mixin EvalBridgeObjectMixin<T> on ValueInterop<T> implements EvalObject<T> {
  @override
  EvalAbstractClass get evalPrototype;

  @override
  T? reifyFull() {
    return realValue;
  }

  @override
  String? get sourceFile => evalPrototype.sourceFile;

  @override
  EvalType get evalType => evalPrototype.delegatedType;

  @override
  EvalValue call(EvalScope lexicalScope, EvalScope inheritedScope, List<EvalType> generics, List<Parameter> args,
      {EvalValue? target}) {
    if (getField('call') != null) {}
    throw UnimplementedError('Not a callable class');
  }
}

mixin BridgeRectifier<T> on EvalBridgeObjectMixin<T> {
  @override
  T get realValue => this as T;

  EvalBridgeData get evalBridgeData;
  set evalBridgeData(EvalBridgeData data);

  @override
  EvalAbstractClass get evalPrototype => evalBridgeData.prototype;

  EvalValue? getFieldOrNull(String name) {
    if (evalBridgeData.fields.containsKey(name)) {
      final field = evalBridgeData.fields[name]!;
      return field.getter?.get?.call(evalPrototype.lexicalScope, EvalScope.empty, [], [], target: field.value) ??
          field.value!;
    } else {
      return null;
    }
  }

  /// Default implementation of [getField] for a bridge-rectified class
  /// Override this for any fields or methods where the definition or implementation might NOT be provided by Eval code
  @override
  EvalValue getField(String name) {
    return getFieldOrNull(name) ?? (throw ArgumentError('No field named $name'));
  }

  @override
  EvalValue setField(String name, EvalValue value, {bool internalSet = false}) {
    return evalBridgeData.setField(name, value, internalSet: internalSet, source: this);
  }

  dynamic bridgeCall(String name, [List<EvalValue> positional = const [], Map<String, EvalValue> named = const {}]) {
    final fields = evalBridgeData.fields;
    final objScope = EvalObjectScope()..object = this;

    final func = fields.containsKey(name) ? (fields[name]!.value as EvalFunction) : getField(name) as EvalFunction;
    return func
        .call(EvalScope(null, {'this': EvalField('this', this, null, Getter(null))}), objScope, [],
            [for (final p in positional) Parameter(p), for (final n in named.entries) NamedParameter(n.key, n.value)],
            target: this)
        .reifyFull();
  }
}

class EvalBridgeData {
  EvalBridgeData(this.prototype);
  final EvalAbstractClass prototype;
  final Map<String, EvalField> fields = {};

  EvalValue setField(String name, EvalValue value, {required bool internalSet, required EvalValue source}) {
    if (internalSet) {
      return fields[name]!.value = value;
    }
    final setter = fields[name]!.setter;
    if (setter == null) {
      throw ArgumentError('No setter for field $name');
    }
    if (setter.set == null) {
      return fields[name]!.value = value;
    } else {
      final thisScope = EvalScope(null, {'this': EvalField('this', source, null, Getter(null))});
      return setter.set!.call(thisScope, EvalScope.empty, [], [Parameter(value)]);
    }
  }
}

class EvalBridgeObject<T> extends EvalObject<T> with ValueInterop<T>, EvalBridgeObjectMixin<T> {
  EvalBridgeObject(EvalBridgeAbstractClass prototype,
      {String? sourceFile, required Map<String, EvalField> fields, this.realValue})
      : super(prototype, fields: fields, sourceFile: sourceFile, realValue: realValue);

  @override
  T? realValue;
}
