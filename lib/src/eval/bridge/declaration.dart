import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/bridge/bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';

class BridgeTypeDescriptor {
  const BridgeTypeDescriptor(this.library, this.name,
      {this.$extends = const BridgeTypeDescriptor.builtin(EvalTypes.objectType),
        this.$implements = const <BridgeTypeDescriptor>[],
        this.$with = const <BridgeTypeDescriptor>[]})
      : builtin = null;

  const BridgeTypeDescriptor.builtin(this.builtin)
      : library = null,
        name = null,
        $extends = null,
        $implements = const <BridgeTypeDescriptor>[],
        $with = const <BridgeTypeDescriptor>[];

  final TypeRef? builtin;
  final String? library;
  final String? name;
  final BridgeTypeDescriptor? $extends;
  final List<BridgeTypeDescriptor> $implements;
  final List<BridgeTypeDescriptor> $with;
}

class BridgeDeclaration {
  const BridgeDeclaration();
}

class BridgeClass<T extends BridgeInstance> extends BridgeDeclaration {
  const BridgeClass(this.type,
      {required this.constructors, required this.methods, required this.fields});

  final BridgeTypeDescriptor type;
  final Map<String, BridgeConstructor<T>> constructors;
  final Map<String, BridgeFunction> methods;
  final Map<String, BridgeField> fields;

  BridgeClass copyWith({BridgeTypeDescriptor? type}) {
    return BridgeClass(type ?? this.type, constructors: constructors, methods: methods, fields: fields);
  }
}

class BridgeFunction extends BridgeDeclaration {
  const BridgeFunction(this.positionalParams, [this.namedParams = const {}]);

  final List<BridgeParameter> positionalParams;
  final Map<String, BridgeParameter> namedParams;
}

class BridgeConstructor<T extends BridgeInstance> extends BridgeFunction {
  const BridgeConstructor(this.instantiator, List<BridgeParameter> positionalParams,
      [Map<String, BridgeParameter> namedParams = const {}])
      : super(positionalParams, namedParams);

  final T Function(List<Object?> args) instantiator;
}

class BridgeField {
  const BridgeField();
}

class BridgeParameter {
  const BridgeParameter({this.optional = false, this.type});

  final bool optional;
  final TypeRef? type;
}

class DeclarationOrBridge<T extends Declaration, R extends BridgeDeclaration> {
  DeclarationOrBridge({this.declaration, this.bridge}) : assert(declaration != null || bridge != null);

  T? declaration;
  R? bridge;

  bool get isBridge => bridge != null;
}
