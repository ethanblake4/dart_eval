// ignore_for_file: non_constant_identifier_names

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart' hide $Invocation;
import 'package:dart_eval/src/eval/runtime/runtime.dart';

/// Invocation needs both native factory wrappers and a subclassable bridge.
/// Keep this binding together so factory results and guest implementations
/// share the same declaration.
class $Invocation$bridge extends Invocation with $Bridge<Invocation> {
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) =>
      $Invocation$bridge();

  @override
  Symbol get memberName => $_get('memberName') as Symbol;

  @override
  List<Type> get typeArguments => ($_get('typeArguments') as List).cast<Type>();

  @override
  List<dynamic> get positionalArguments => $_get('positionalArguments') as List;

  @override
  Map<Symbol, dynamic> get namedArguments =>
      ($_get('namedArguments') as Map).cast<Symbol, dynamic>();

  @override
  bool get isMethod => $_get('isMethod') as bool;

  @override
  bool get isGetter => $_get('isGetter') as bool;

  @override
  bool get isSetter => $_get('isSetter') as bool;

  @override
  bool get isAccessor => $_get('isAccessor') as bool;

  @override
  $Value? $bridgeGet(String identifier) => switch (identifier) {
    'typeArguments' => $List.wrap(super.typeArguments),
    'isAccessor' => $bool(super.isAccessor),
    'memberName' ||
    'positionalArguments' ||
    'namedArguments' ||
    'isMethod' ||
    'isGetter' ||
    'isSetter' => throw NoSuchMethodError.withInvocation(
      this,
      Invocation.getter(Symbol(identifier)),
    ),
    _ => $Object(this).$getProperty($runtime, identifier),
  };

  @override
  void $bridgeSet(String identifier, $Value value) =>
      $Object(this).$setProperty($runtime, identifier, value);
}

/// dart_eval wrapper binding for [Invocation]
class $Invocation implements Invocation, $Instance {
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Invocation.',
      $Invocation$bridge.$new,
      isBridge: true,
    );
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Invocation.method',
      $Invocation.$method,
      isBridge: true,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Invocation.genericMethod',
      $Invocation.$genericMethod,
      isBridge: true,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Invocation.getter',
      $Invocation.$getter,
      isBridge: true,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Invocation.setter',
      $Invocation.$setter,
      isBridge: true,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$Invocation]
  static const $spec = BridgeTypeSpec('dart:core', 'Invocation');

  /// Compile-time type declaration of [$Invocation]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$Invocation]
  static const $declaration = BridgeClassDef(
    BridgeClassType($type, isAbstract: true),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [],
        ),
        isFactory: false,
      ),

      'method': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'memberName',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.symbol, [])),
              false,
            ),

            BridgeParameter(
              'positionalArguments',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(
                    BridgeTypeRef(CoreTypes.object, []),
                    nullable: true,
                  ),
                ]),
                nullable: true,
              ),
              false,
            ),

            BridgeParameter(
              'namedArguments',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.map, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.symbol, [])),
                  BridgeTypeAnnotation(
                    BridgeTypeRef(CoreTypes.object, []),
                    nullable: true,
                  ),
                ]),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
        isFactory: true,
      ),

      'genericMethod': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'memberName',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.symbol, [])),
              false,
            ),

            BridgeParameter(
              'typeArguments',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.type, [])),
                ]),
                nullable: true,
              ),
              false,
            ),

            BridgeParameter(
              'positionalArguments',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(
                    BridgeTypeRef(CoreTypes.object, []),
                    nullable: true,
                  ),
                ]),
                nullable: true,
              ),
              false,
            ),

            BridgeParameter(
              'namedArguments',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.map, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.symbol, [])),
                  BridgeTypeAnnotation(
                    BridgeTypeRef(CoreTypes.object, []),
                    nullable: true,
                  ),
                ]),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
        isFactory: true,
      ),

      'getter': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'name',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.symbol, [])),
              false,
            ),
          ],
        ),
        isFactory: true,
      ),

      'setter': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'memberName',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.symbol, [])),
              false,
            ),

            BridgeParameter(
              'argument',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.object, []),
                nullable: true,
              ),
              false,
            ),
          ],
        ),
        isFactory: true,
      ),
    },

    methods: {},
    getters: {
      'memberName': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.symbol, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'typeArguments': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.list, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.type, [])),
            ]),
          ),
          namedParams: [],
          params: [],
        ),
      ),

      'positionalArguments': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.list, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
            ]),
          ),
          namedParams: [],
          params: [],
        ),
      ),

      'namedArguments': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.map, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.symbol, [])),
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
            ]),
          ),
          namedParams: [],
          params: [],
        ),
      ),

      'isMethod': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'isGetter': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'isSetter': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'isAccessor': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [],
        ),
      ),
    },
    setters: {},
    fields: {},
    wrap: false,
    bridge: true,
  );

  /// Wrapper for the [Invocation.method] constructor
  static $Value? $method(Runtime runtime, Object? r, Object? s, Object? c) {
    return $Invocation.wrap(
      Invocation.method(
        (r as $Value?)!.$value,
        (s as $Value?)!.$value,
        ((c is $Value ? c : null)?.$reified as Map?)?.cast<Symbol, Object?>(),
      ),
    );
  }

  /// Wrapper for the [Invocation.genericMethod] constructor
  static $Value? $genericMethod(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final arg2 = (c as List<Object?>)[0] as $Value?;
    final arg3OrNull = c.length > 1 ? c[1] as $Value? : null;

    return $Invocation.wrap(
      Invocation.genericMethod(
        (r as $Value?)!.$value,
        (s as $Value?)!.$value,
        arg2!.$value,
        (arg3OrNull?.$reified as Map?)?.cast<Symbol, Object?>(),
      ),
    );
  }

  /// Wrapper for the [Invocation.getter] constructor
  static $Value? $getter(Runtime runtime, Object? r, Object? s, Object? c) {
    return $Invocation.wrap(Invocation.getter((r as $Value?)!.$value));
  }

  /// Wrapper for the [Invocation.setter] constructor
  static $Value? $setter(Runtime runtime, Object? r, Object? s, Object? c) {
    return $Invocation.wrap(
      Invocation.setter((r as $Value?)!.$value, (s as $Value?)!.$reified),
    );
  }

  final $Instance _superclass;

  @override
  final Invocation $value;

  @override
  Invocation get $reified => $value;

  /// Wrap a [Invocation] in a [$Invocation]
  $Invocation.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'memberName':
        final memberName = $value.memberName;
        return $Symbol.wrap(memberName);
      case 'typeArguments':
        final typeArguments = $value.typeArguments;
        return $List.view(
          typeArguments,
          (e) => $Type(e),
          runtime: runtime,
          runtimeTypeId: runtime.internParameterizedType(CoreTypes.list, [
            runtime.lookupType(CoreTypes.type),
          ]),
        );
      case 'positionalArguments':
        final positionalArguments = $value.positionalArguments;
        return $List.view(
          positionalArguments,
          (e) => runtime.wrapAlways(e, recursive: true),
          runtime: runtime,
          runtimeTypeId: runtime.internParameterizedType(CoreTypes.list, [
            runtime.lookupType(CoreTypes.dynamic),
          ]),
        );
      case 'namedArguments':
        final namedArguments = $value.namedArguments;
        return $Map.wrap(
          Map<$Value, $Value>.unmodifiable({
            for (final entry in namedArguments.entries)
              $Symbol.wrap(entry.key): runtime.wrapAlways(
                entry.value,
                recursive: true,
              ),
          }),
        );
      case 'isMethod':
        final isMethod = $value.isMethod;
        return $bool(isMethod);
      case 'isGetter':
        final isGetter = $value.isGetter;
        return $bool(isGetter);
      case 'isSetter':
        final isSetter = $value.isSetter;
        return $bool(isSetter);
      case 'isAccessor':
        final isAccessor = $value.isAccessor;
        return $bool(isAccessor);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }

  @override
  Symbol get memberName => $value.memberName;

  @override
  List<Type> get typeArguments => $value.typeArguments;

  @override
  List<dynamic> get positionalArguments => $value.positionalArguments;

  @override
  Map<Symbol, dynamic> get namedArguments => $value.namedArguments;

  @override
  bool get isMethod => $value.isMethod;

  @override
  bool get isGetter => $value.isGetter;

  @override
  bool get isSetter => $value.isSetter;

  @override
  bool get isAccessor => $value.isAccessor;
}
