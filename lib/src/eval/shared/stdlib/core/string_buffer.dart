import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/num.dart';
import 'package:dart_eval/src/eval/shared/stdlib/io/string_sink.dart';
import 'base.dart';

/// dart_eval wrapper for [StringBuffer]
class $StringBuffer implements StringBuffer, $Instance {
  /// Compile-time bridge declaration of [$StringBuffer]
  static const $declaration = BridgeClassDef(
      BridgeClassType(BridgeTypeRef(CoreTypes.stringBuffer),
          isAbstract: false, $implements: [BridgeTypeRef(IoTypes.stringSink)]),
      constructors: {
        '': BridgeConstructorDef(BridgeFunctionDef(
            returns:
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.stringBuffer)),
            params: [
              BridgeParameter('content',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)), true),
            ],
            namedParams: []))
      },
      methods: {
        'write': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
            params: [
              BridgeParameter(
                  'object',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object),
                      nullable: true),
                  false),
            ],
            namedParams: [])),
        'writeAll': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
            params: [
              BridgeParameter(
                  'objects',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.iterable)),
                  false),
              BridgeParameter(
                  'separator',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string),
                      nullable: true),
                  true),
            ],
            namedParams: [])),
        'writeln': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
            params: [
              BridgeParameter(
                  'object',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object),
                      nullable: true),
                  true),
            ],
            namedParams: [])),
        'writeCharCode': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
            params: [
              BridgeParameter('charCode',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)), false),
            ],
            namedParams: [])),
        'clear': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
            params: [])),
      },
      getters: {
        'length': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
            params: [])),
        'isEmpty': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
            params: [])),
        'isNotEmpty': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
            params: [])),
      },
      wrap: true);

  /// Wrap a [StringBuffer] in a [$StringBuffer].
  $StringBuffer.wrap(this.$value) : _superclass = $StringSink.wrap($value);

  /// Create a new [$StringBuffer] with the given content.
  static $StringBuffer $new(
      Runtime runtime, $Value? target, List<$Value?> args) {
    return $StringBuffer.wrap(StringBuffer(args[0]?.$value ?? ""));
  }

  @override
  final StringBuffer $value;

  @override
  StringBuffer get $reified => $value;

  final $Instance _superclass;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'clear':
        return __clear;
      case 'length':
        return $int($value.length);
      case 'isEmpty':
        return $bool($value.isEmpty);
      case 'isNotEmpty':
        return $bool($value.isNotEmpty);
      default:
        return _superclass.$getProperty(runtime, identifier);
    }
  }

  static const $Function __clear = $Function(_clear);
  static $Value? _clear(Runtime runtime, $Value? target, List<$Value?> args) {
    target!.$value.clear();
    return null;
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {}

  @override
  int $getRuntimeType(Runtime runtime) =>
      runtime.lookupType(CoreTypes.stringBuffer);

  @override
  bool operator ==(Object other) => $value == other;

  @override
  int get hashCode => $value.hashCode;

  @override
  void clear() => $value.clear();

  @override
  int get length => $value.length;

  @override
  bool get isEmpty => $value.isEmpty;

  @override
  bool get isNotEmpty => $value.isNotEmpty;

  @override
  void write(Object? object) => $value.write(object);

  @override
  void writeAll(Iterable<dynamic> objects, [String separator = ""]) =>
      $value.writeAll(objects, separator);

  @override
  void writeln([Object? object = ""]) => $value.writeln(object);

  @override
  void writeCharCode(int charCode) => $value.writeCharCode(charCode);

  @override
  String toString() => $value.toString();
}
