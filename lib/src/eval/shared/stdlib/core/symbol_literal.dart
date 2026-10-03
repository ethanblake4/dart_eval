import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart'
    show TypedRuntimeInterop;
import 'package:dart_eval/stdlib/core.dart';

void configureSymbolLiteralsForCompile(BridgeDeclarationRegistry registry) {
  registry.defineBridgeTopLevelFunction(
    const BridgeFunctionDeclaration(
      'dart:core',
      '_privateSymbolLiteral',
      BridgeFunctionDef(
        returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.symbol)),
        params: [
          BridgeParameter(
            'name',
            BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
            false,
          ),
          BridgeParameter(
            'library',
            BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
            false,
          ),
        ],
      ),
    ),
  );
}

void configureSymbolLiteralsForRuntime(Runtime runtime) {
  runtime.registerBridgeFuncRegisters(
    'dart:core',
    '_privateSymbolLiteral',
    (runtime, name, library, _) => _guestMemberSymbolValue(
      (name as $String).$value,
      (library as $String).$value,
      runtime: runtime,
    ),
  );
}

Symbol guestMemberSymbol(String name, String library, {Runtime? runtime}) =>
    _guestMemberSymbolValue(name, library, runtime: runtime).$value;

$Symbol _guestMemberSymbolValue(
  String name,
  String library, {
  Runtime? runtime,
}) {
  if (!name.startsWith('_')) return $Symbol.wrap(Symbol(name));
  final symbol = $Symbol.wrap(_PrivateSymbol(name, library));
  if (runtime == null) return symbol;
  return runtime.internConst(symbol, runtime.lookupType(CoreTypes.symbol))
      as $Symbol;
}

/// A private literal carries the guest library's identity. Symbol's public
/// constructor creates a different kind of symbol even for the same spelling.
final class _PrivateSymbol implements Symbol {
  const _PrivateSymbol(this.name, this.library);

  final String name;
  final String library;

  @override
  bool operator ==(Object other) =>
      other is _PrivateSymbol && name == other.name && library == other.library;

  @override
  int get hashCode => Object.hash(name, library);

  @override
  String toString() => 'Symbol("$name")';
}
