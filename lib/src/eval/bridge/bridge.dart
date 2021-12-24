import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/runtime/class.dart';
import 'package:dart_eval/src/eval/runtime/function.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

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

mixin DbcBridgeInstance on Object implements IDbcValue, DbcInstance {

  IDbcValue? $bridgeGet(String identifier);

  void $bridgeSet(String identifier, IDbcValue value);

  @override
  IDbcValue? $getProperty(Runtime runtime, String identifier) {
    try {
      return Runtime.bridgeData[this]!.subclass!.$getProperty(runtime, identifier);
    } on UnimplementedError catch (_) {
      return $bridgeGet(identifier);
    }
  }

  @override
  void $setProperty(Runtime runtime, String identifier, IDbcValue value) {
    try {
      return Runtime.bridgeData[this]!.subclass!.$setProperty(runtime, identifier, value);
    } on UnimplementedError catch (_) {
      $bridgeSet(identifier, value);
    }
  }

  dynamic $invoke(String method, List<IDbcValue?> args) {
    final runtime = Runtime.bridgeData[this]!.runtime;
    return ($getProperty(runtime, method) as DbcFunction).call(runtime, this, args)?.$reified;
  }

  @override
  DbcBridgeInstance get $value => this;

  @override
  DbcBridgeInstance get $reified => this;
}

class BridgeSuperShim implements DbcInstance {
  BridgeSuperShim();

  late DbcBridgeInstance bridge;

  @override
  IDbcValue? $getProperty(Runtime runtime, String name) => bridge.$bridgeGet(name);

  @override
  void $setProperty(Runtime runtime, String name, IDbcValue value) => bridge.$bridgeSet(name, value);

  @override
  DbcBridgeInstance get $reified => bridge;

  @override
  DbcBridgeInstance get $value => bridge;
}

class BridgeDelegatingShim implements DbcInstance {
  const BridgeDelegatingShim();

  @override
  IDbcValue? $getProperty(Runtime runtime, String name) => throw UnimplementedError();

  @override
  void $setProperty(Runtime runtime, String name, IDbcValue value) => throw UnimplementedError();

  @override
  DbcBridgeInstance get $reified => throw UnimplementedError();

  @override
  DbcBridgeInstance get $value => throw UnimplementedError();
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
