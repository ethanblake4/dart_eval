// ignore_for_file: depend_on_referenced_packages

import 'package:meta/meta.dart';
import 'package:collection/collection.dart';

import '../../../dart_eval_bridge.dart';
import '../../../stdlib/core.dart';

class $InstanceDefaultEnum<T> implements $Instance {
  final InstanceDefaultEnumProps props;

  $InstanceDefaultEnum.wrap(
    this.$value, {
    this.superclass,
    required this.props,
  });

  final $Instance? superclass;

  final T $value;

  T get $reified => $value;

  @override
  int $getRuntimeType(Runtime runtime) {
    return runtime.lookupType(props.type.spec!);
  }

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    final InstanceDefaultEnumPropsGetter? g =
        props.getters.firstWhereOrNull((e) => e.name == identifier);

    if (g != null) {
      return g.run(runtime, this);
    }

    final InstanceDefaultPropsMethod? m =
        props.methods.firstWhereOrNull((e) => e.name == identifier);

    if (m != null) {
      return $Function((_, __, args) {
        return m.run(runtime, this, args);
      });
    }

    return superclass?.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    superclass?.$setProperty(runtime, identifier, value);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is $InstanceDefaultEnum<T> && other.$value == $value;
  }

  @override
  int get hashCode {
    return $value.hashCode;
  }
}

class InstanceDefaultEnumProps implements IInstanceDefaultProps {
  BridgeDeclaration? _declaration;

  BridgeDeclaration get declaration {
    _declaration ??= BridgeEnumDef(
      type,
      values: values.map((e) => (e.$reified as Enum).name).toList(),
      methods: {
        ...Map.fromEntries(
          methods.map(
            (e) => MapEntry(e.name, e.definition),
          ),
        ),
      },
    );

    return _declaration!;
  }

  @override
  void defineCompiler(BridgeDeclarationRegistry registry) {
    if (declaration is BridgeEnumDef) {
      registry.defineBridgeEnum(declaration as BridgeEnumDef);
    }
  }

  @override
  void registerRuntime(Runtime runtime) {
    runtime.registerBridgeEnumValues(
      fileName,
      className,
      Map.fromEntries(
        values.map((e) => MapEntry((e.$reified as Enum).name, e)),
      ),
    );
  }

  List<InstanceDefaultEnumPropsGetter> get getters => [];

  List<InstanceDefaultPropsMethod> get methods => [
        _InstanceDefaultPropsMethod(),
      ];

  @mustBeOverridden
  List<$Value> get values => throw UnimplementedError();

  @mustBeOverridden
  BridgeTypeRef get type => throw UnimplementedError();

  String get className => type.spec!.name;

  String get fileName => type.spec!.library;
}

abstract class InstanceDefaultEnumPropsGetter<T extends $Value> {
  String get name;

  BridgeMethodDef get definition;

  $Value? run(Runtime runtime, T target);
}

class _InstanceDefaultPropsMethod implements InstanceDefaultPropsMethod {
  @override
  String get name => 'toString';

  @override
  BridgeMethodDef get definition => const BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            $String.$type,
            nullable: false,
          ),
        ),
      );

  @override
  $Value? run(
    Runtime runtime,
    $Value target,
    List<$Value?> args,
  ) {
    return $String(target.$reified.toString());
  }
}
