// ignore_for_file: depend_on_referenced_packages

import 'package:meta/meta.dart';
import 'package:collection/collection.dart';

import '../../../dart_eval_bridge.dart';

class $InstanceDefault<T extends Object> implements $Instance {
  final InstanceDefaultProps props;

  $InstanceDefault.wrap(
    this.$value, {
    this.superclass,
    required this.props,
  });

  final $Instance? superclass;

  final T $value;

  T get $reified => $value;

  @override
  int $getRuntimeType(Runtime runtime) {
    return runtime.lookupType(props.type.type.spec!);
  }

  @override
  $Value? $getProperty(
    Runtime runtime,
    String identifier,
  ) {
    return props.getProperty(
      runtime,
      identifier,
      this,
      notFoundCallback: () => superclass?.$getProperty(runtime, identifier),
    );
  }

  @override
  void $setProperty(
    Runtime runtime,
    String identifier,
    $Value value,
  ) {
    props.setProperty(
      runtime,
      identifier,
      value,
      this,
      notFoundCallback: () => superclass?.$setProperty(
        runtime,
        identifier,
        value,
      ),
    );
  }
}

abstract class IInstanceDefaultProps {
  void defineCompiler(BridgeDeclarationRegistry registry);

  void registerRuntime(Runtime runtime);
}

class InstanceDefaultProps<T extends $Value> implements IInstanceDefaultProps {
  BridgeClassDef? _declaration;

  bool get bridge => false;

  BridgeClassDef get declaration {
    _declaration ??= BridgeClassDef(
      type,
      constructors: Map.fromEntries(
        constructors.map(
          (e) => MapEntry(e.name, e.definition),
        ),
      ),
      getters: {
        ...Map.fromEntries(
          getters.map(
            (e) => MapEntry(e.name, e.definition),
          ),
        ),
        ...Map.fromEntries(
          gettersStatic.map(
            (e) => MapEntry(e.name, e.definition),
          ),
        ),
      },
      fields: {
        ...Map.fromEntries(
          fields.map(
            (e) => MapEntry(e.name, e.definition),
          ),
        ),
      },
      methods: {
        ...Map.fromEntries(
          methods.map(
            (e) => MapEntry(e.name, e.definition),
          ),
        ),
      },
      bridge: bridge,
      wrap: !bridge,
    );

    return _declaration!;
  }

  @override
  void defineCompiler(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass(declaration);
  }

  @override
  void registerRuntime(Runtime runtime) {
    for (var e in constructors) {
      runtime.registerBridgeFunc(
        fileName,
        '$className.${e.name}',
        e.run,
        isBridge: bridge,
      );
    }

    for (var e in gettersStatic) {
      runtime.registerBridgeFunc(
        fileName,
        '$className.${e.name}*g',
        e.run,
        isBridge: bridge,
      );
    }
  }

  List<InstanceDefaultPropsConstructor> get constructors => [];

  List<InstanceDefaultPropsGetterStatic> get gettersStatic => [];

  List<InstanceDefaultPropsGetter> get getters => [];

  List<InstanceDefaultPropsField> get fields => [];

  List<InstanceDefaultPropsMethod> get methods => [];

  @mustBeOverridden
  BridgeClassType get type => throw UnimplementedError();

  String get fileName => type.type.spec!.library;

  String get className => type.type.spec!.name;

  $Value? getProperty(
    Runtime runtime,
    String identifier,
    T target, {
    $Value? Function()? notFoundCallback,
  }) {
    final InstanceDefaultPropsGetter? g =
        getters.firstWhereOrNull((e) => e.name == identifier);

    if (g != null) {
      return g.run(runtime, target);
    }

    final InstanceDefaultPropsField? f =
        fields.firstWhereOrNull((e) => e.name == identifier);

    if (f != null) {
      return f.getValue(runtime, target);
    }

    final InstanceDefaultPropsMethod? m =
        methods.firstWhereOrNull((e) => e.name == identifier);

    if (m != null) {
      return $Function((_, __, args) {
        return m.run(runtime, target, args);
      });
    }

    if (notFoundCallback != null) {
      return notFoundCallback();
    }

    return null;
  }

  void setProperty(
    Runtime runtime,
    String identifier,
    $Value value,
    T target, {
    void Function()? notFoundCallback,
  }) {
    final InstanceDefaultPropsField? f =
        fields.firstWhereOrNull((e) => e.name == identifier);

    if (f != null) {
      f.setValue(runtime, target, value);

      return;
    }

    if (notFoundCallback != null) {
      notFoundCallback();
    }
  }
}

abstract class InstanceDefaultPropsBase {
  String get name;

  BridgeDeclaration get definition;

  $Value? run(Runtime runtime, $Value? target, List<$Value?> args);
}

abstract class InstanceDefaultPropsConstructor
    extends InstanceDefaultPropsBase {
  BridgeConstructorDef get definition;
}

abstract class InstanceDefaultPropsGetterStatic
    extends InstanceDefaultPropsBase {
  BridgeMethodDef get definition;
}

abstract class InstanceDefaultPropsGetter<T extends $Value> {
  String get name;

  BridgeMethodDef get definition;

  $Value? run(Runtime runtime, T target);
}

abstract class InstanceDefaultPropsField<T extends $Value> {
  String get name;

  BridgeFieldDef get definition;

  $Value? getValue(Runtime runtime, T target);

  void setValue(Runtime runtime, T target, $Value value);
}

abstract class InstanceDefaultPropsMethod<T extends $Value> {
  String get name;

  BridgeMethodDef get definition;

  $Value? run(Runtime runtime, T target, List<$Value?> args);
}
