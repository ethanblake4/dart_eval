import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/bridge/bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';

class DbcBridgeTypeDescriptor {
  const DbcBridgeTypeDescriptor(this.library, this.name,
      {this.$extends = const DbcBridgeTypeDescriptor.builtin(DbcTypes.objectType),
        this.$implements = const <DbcBridgeTypeDescriptor>[],
        this.$with = const <DbcBridgeTypeDescriptor>[]})
      : builtin = null;

  const DbcBridgeTypeDescriptor.builtin(this.builtin)
      : library = null,
        name = null,
        $extends = null,
        $implements = const <DbcBridgeTypeDescriptor>[],
        $with = const <DbcBridgeTypeDescriptor>[];

  final TypeRef? builtin;
  final String? library;
  final String? name;
  final DbcBridgeTypeDescriptor? $extends;
  final List<DbcBridgeTypeDescriptor> $implements;
  final List<DbcBridgeTypeDescriptor> $with;
}

class DbcBridgeDeclaration {
  const DbcBridgeDeclaration();
}

class DbcBridgeClass<T extends DbcBridgeInstance> extends DbcBridgeDeclaration {
  const DbcBridgeClass(this.type,
      {required this.constructors, required this.methods, required this.fields});

  final DbcBridgeTypeDescriptor type;
  final Map<String, DbcBridgeConstructor<T>> constructors;
  final Map<String, DbcBridgeFunction> methods;
  final Map<String, DbcBridgeField> fields;

  DbcBridgeClass copyWith({DbcBridgeTypeDescriptor? type}) {
    return DbcBridgeClass(type ?? this.type, constructors: constructors, methods: methods, fields: fields);
  }
}

class DbcBridgeFunction extends DbcBridgeDeclaration {
  const DbcBridgeFunction(this.positionalParams, [this.namedParams = const {}]);

  final List<DbcBridgeParameter> positionalParams;
  final Map<String, DbcBridgeParameter> namedParams;
}

class DbcBridgeConstructor<T extends DbcBridgeInstance> extends DbcBridgeFunction {
  const DbcBridgeConstructor(this.instantiator, List<DbcBridgeParameter> positionalParams,
      [Map<String, DbcBridgeParameter> namedParams = const {}])
      : super(positionalParams, namedParams);

  final T Function(int evalId, List<Object?> args) instantiator;
}

class DbcBridgeField {
  const DbcBridgeField();
}

class DbcBridgeParameter {
  const DbcBridgeParameter({this.optional = false, this.type});

  final bool optional;
  final TypeRef? type;
}

class DeclarationOrBridge<T extends Declaration, R extends DbcBridgeDeclaration> {
  DeclarationOrBridge({this.declaration, this.bridge}) : assert(declaration != null || bridge != null);

  T? declaration;
  R? bridge;

  bool get isBridge => bridge != null;
}
