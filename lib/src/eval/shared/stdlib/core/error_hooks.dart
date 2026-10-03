import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_instance.dart';

import 'base.dart' show $null;
import 'errors.dart';

$Value? noSuchMethodErrorWithInvocation(
  Runtime runtime,
  $Value? _,
  List<$Value?> args,
) {
  final receiver = args[0];
  return $NoSuchMethodError.wrap(
    NoSuchMethodError.withInvocation(
      receiver is TypedInstance ? receiver.dispatchRoot : receiver?.$reified,
      args[1]!.$reified as Invocation,
    ),
  );
}

final _languageInvocations = Expando<bool>('language invocation');

/// Native public Invocation constructors use a redacted error message. A
/// language-generated invocation retains the member spelling in diagnostics.
Invocation languageInvocation(Invocation invocation) {
  _languageInvocations[invocation] = true;
  return invocation;
}

NoSuchMethodError formatLanguageNoSuchMethodError(
  NoSuchMethodError error,
  Invocation invocation,
) => _languageInvocations[invocation] == true
    ? _LanguageNoSuchMethodError(error, invocation.memberName)
    : error;

class _LanguageNoSuchMethodError extends Error implements NoSuchMethodError {
  _LanguageNoSuchMethodError(this.error, this.memberName);

  final NoSuchMethodError error;
  final Symbol memberName;

  @override
  StackTrace? get stackTrace => error.stackTrace ?? super.stackTrace;

  @override
  String toString() {
    final symbol = memberName.toString();
    final name = symbol.substring(8, symbol.length - 2);
    return error.toString().replaceFirst('has no $name ', "has no '$name' ");
  }
}

$Value? assertionError(Runtime runtime, $Value? _, List<$Value?> args) {
  final value = args.isEmpty ? null : args.first;
  Object? message;
  if (value != null) {
    try {
      message = value.$reified;
    } catch (_) {
      // Guest instances can provide a message without a host representation.
      return _GuestAssertionError(value);
    }
  }
  return $AssertionError.wrap(AssertionError(message));
}

void configureAssertionForCompile(BridgeDeclarationRegistry registry) {
  registry.defineBridgeTopLevelFunction(
    BridgeFunctionDeclaration(
      'dart:core',
      'dart_eval_assertionFailure',
      BridgeFunctionDef(
        returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.assertionError)),
        params: [
          BridgeParameter(
            'message',
            BridgeTypeAnnotation(
              BridgeTypeRef(CoreTypes.object),
              nullable: true,
            ),
            false,
          ),
        ],
        namedParams: [],
      ),
    ),
  );
}

void configureAssertionForRuntime(Runtime runtime) {
  runtime.registerBridgeFuncRegisters(
    'dart:core',
    'dart_eval_assertionFailure',
    (runtime, r, s, c) => r == null || r is $null
        ? $AssertionError.wrap(_NullAssertionError())
        : assertionError(runtime, null, [r as $Value?]),
  );
}

class _NullAssertionError extends AssertionError {
  @override
  String toString() => 'Assertion failed: is not true';
}

/// Retains the guest message until it is read from the assertion error.
class _GuestAssertionError extends $AssertionError {
  _GuestAssertionError(this.guestMessage)
    : super.wrap(AssertionError(guestMessage));

  final $Value guestMessage;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) =>
      identifier == 'message'
      ? guestMessage
      : super.$getProperty(runtime, identifier);
}
