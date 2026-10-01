import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

const _bridgeLibrary = 'package:call_bridge/call_bridge.dart';
const _library = 'package:implicit_bridge/main.dart';
const _source = r'''
import 'package:call_bridge/call_bridge.dart';
class MethodGuest extends MethodHost {}
class GetterGuest extends GetterHost {}
class FieldGuest extends FieldHost {}
class MethodGrandchild extends MethodGuest {}
mixin SourceCall {
  int call(int value) => value + 2;
}
class SourceOverride extends MethodHost with SourceCall {}
class OnlyInterface implements MethodHost {
  dynamic noSuchMethod(Invocation invocation) => 9;
}
class GetterOnlyValue {
  int reads = 0;
  Function get call {
    reads++;
    return () => 17;
  }
}
bool main() {
  dynamic method = MethodGuest();
  if (method(4) != 5 || method.call(5) != 6) return false;
  dynamic grandchild = MethodGrandchild();
  dynamic override = SourceOverride();
  if (grandchild(4) != 5 || override(4) != 6) return false;
  for (dynamic value in [GetterGuest(), FieldGuest()]) {
    try { value(4); return false; } on NoSuchMethodError {}
    if (value.call(4) != 5 || (value.call)(5) != 6) return false;
  }
  dynamic interfaceOnly = OnlyInterface();
  if (interfaceOnly(4) != 9) return false;
  final getterOnly = GetterOnlyValue();
  dynamic holder = Holder(getterOnly);
  if (holder.item() != 17 || getterOnly.reads != 1) return false;
  try { (holder.item)(); return false; } on NoSuchMethodError {}
  if (getterOnly.reads != 1) return false;
  return holder.item.call() == 17 && getterOnly.reads == 2;
}
''';

BridgeClassDef _declaration(
  String name, {
  bool getter = false,
  bool field = false,
}) {
  final type = BridgeTypeRef(BridgeTypeSpec(_bridgeLibrary, name));
  const invoke = BridgeMethodDef(
    BridgeFunctionDef(
      returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
      params: [
        BridgeParameter(
          'value',
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
          false,
        ),
      ],
    ),
  );
  const read = BridgeMethodDef(
    BridgeFunctionDef(
      returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
    ),
  );
  return BridgeClassDef(
    BridgeClassType(type),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(returns: BridgeTypeAnnotation(type)),
      ),
    },
    methods: getter || field ? {} : {'call': invoke},
    getters: getter ? {'call': read} : {},
    fields: field
        ? {
            'call': const BridgeFieldDef(
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
            ),
          }
        : {},
    bridge: true,
  );
}

class _CallBridge with $Bridge {
  @override
  $Value? $bridgeGet(String name) {
    if (name != 'call') throw StateError(name);
    return $Function(
      (runtime, target, r, s, c) => $int((r as $int).$value + 1),
    );
  }

  @override
  void $bridgeSet(String name, $Value value) => throw StateError(name);
}

const _holderType = BridgeTypeRef(BridgeTypeSpec(_bridgeLibrary, 'Holder'));
const _holderDeclaration = BridgeClassDef(
  BridgeClassType(_holderType),
  constructors: {
    '': BridgeConstructorDef(
      BridgeFunctionDef(
        returns: BridgeTypeAnnotation(_holderType),
        params: [
          BridgeParameter(
            'item',
            BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object)),
            false,
          ),
        ],
      ),
    ),
  },
  getters: {
    'item': BridgeMethodDef(
      BridgeFunctionDef(
        returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
      ),
    ),
  },
  wrap: true,
);

class _Holder implements $Instance {
  _Holder(this.item);
  final $Value? item;
  @override
  Object get $value => this;
  @override
  Object get $reified => this;
  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType(_holderType.spec!);
  @override
  $Value? $getProperty(Runtime runtime, String name) =>
      name == 'item' ? item : throw StateError(name);
  @override
  void $setProperty(Runtime runtime, String name, $Value value) =>
      throw StateError(name);
}

void main() {
  test('implicit guest bridge calls require an actual inherited method', () {
    final compiler = Compiler()
      ..defineBridgeClasses([
        _declaration('MethodHost'),
        _declaration('GetterHost', getter: true),
        _declaration('FieldHost', field: true),
        _holderDeclaration,
      ]);
    final program = compiler.compile({
      'implicit_bridge': {'main.dart': _source},
    });
    for (final candidate in [program, Program.read(program.write().buffer)]) {
      final flags = {
        for (final type in candidate.typedProgram.classes)
          type.name: type.hasBridgeCallMethod,
      };
      expect(flags['MethodGuest'], true);
      expect(flags['GetterGuest'], false);
      expect(flags['FieldGuest'], false);
      expect(flags['MethodGrandchild'], true);
      expect(flags['SourceOverride'], false);
      expect(flags['OnlyInterface'], false);
      final runtime = Runtime.ofProgram(candidate);
      for (final name in ['MethodHost', 'GetterHost', 'FieldHost']) {
        runtime.registerBridgeFuncRegisters(
          _bridgeLibrary,
          '$name.',
          (runtime, r, s, c) => _CallBridge(),
          isBridge: true,
        );
      }
      runtime.registerBridgeFuncRegisters(
        _bridgeLibrary,
        'Holder.',
        (runtime, r, s, c) => _Holder(r as $Value?),
      );
      expect(runtime.executeLib(_library, 'main'), true);
    }
  });
}
