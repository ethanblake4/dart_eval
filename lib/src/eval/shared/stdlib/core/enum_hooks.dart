import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_instance.dart';
import 'base.dart';
import 'num.dart';

// Guest enums use the compiler's synthetic index/name slots. Their storage may
// be native or boxed; host enums use the public SDK properties. Reading the
// name slot preserves EnumName semantics when an enum overrides `name`.

int _enumIndex($Value value) => value is TypedInstance
    ? TypedInstance.intField(value.values[0])
    : (value.$reified as Enum).index;

String _enumName($Value value) => value is TypedInstance
    ? switch (value.values[1]) {
        String name => name,
        final name => (name as $String).$value,
      }
    : (value.$reified as Enum).name;

$Value enumCompareByIndex(
  Runtime runtime,
  $Value? target,
  List<$Value?> args,
) => $int(_enumIndex(args[0]!) - _enumIndex(args[1]!));

$Value enumCompareByName(Runtime runtime, $Value? target, List<$Value?> args) =>
    $int(_enumName(args[0]!).compareTo(_enumName(args[1]!)));
