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
  $Value? $getProperty(Runtime runtime, String identifier) {
    final InstanceDefaultPropsGetter? g =
        props.getters.firstWhereOrNull((e) => e.name == identifier);

    if (g != null) {
      return g.run(runtime, this);
    }

    final InstanceDefaultPropsMethod? m =
        props.methods.firstWhereOrNull((e) => e.name == identifier);

    if (m != null) {
      return $Function((_, target, args) {
        return m.run(runtime, this, args);
      });
    }

    return superclass?.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    superclass?.$setProperty(runtime, identifier, value);
  }
}

class InstanceDefaultProps {
  BridgeDeclaration? _declaration;

  BridgeDeclaration get declaration {
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
      methods: {
        ...Map.fromEntries(
          methods.map(
            (e) => MapEntry(e.name, e.definition),
          ),
        ),
      },
      wrap: true,
    );

    return _declaration!;
  }

  void defineCompiler(BridgeDeclarationRegistry registry) {
    if (declaration is BridgeClassDef) {
      registry.defineBridgeClass(declaration as BridgeClassDef);
    } else if (declaration is BridgeEnumDef) {
      registry.defineBridgeEnum(declaration as BridgeEnumDef);
    } else if (declaration is BridgeFunctionDeclaration) {
      registry.defineBridgeTopLevelFunction(
          declaration as BridgeFunctionDeclaration);
    }
  }

  void registerRuntime(Runtime runtime) {
    for (var e in constructors) {
      runtime.registerBridgeFunc(
        fileName,
        '$className.${e.name}',
        e.run,
      );
    }

    for (var e in gettersStatic) {
      runtime.registerBridgeFunc(
        fileName,
        '$className.${e.name}*g',
        e.run,
      );
    }
  }

  List<InstanceDefaultPropsConstructor> get constructors => [];

  List<InstanceDefaultPropsGetterStatic> get gettersStatic => [];

  List<InstanceDefaultPropsGetter> get getters => [];

  List<InstanceDefaultPropsMethod> get methods => [];

  @mustBeOverridden
  BridgeClassType get type => throw UnimplementedError();

  @mustBeOverridden
  String get fileName => throw UnimplementedError();

  @mustBeOverridden
  String get className => throw UnimplementedError();
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

abstract class InstanceDefaultPropsMethod<T extends $Value> {
  String get name;

  BridgeMethodDef get definition;

  $Value? run(Runtime runtime, T target, List<$Value?> args);
}
