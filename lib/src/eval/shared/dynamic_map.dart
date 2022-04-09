import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';

typedef _MappingFunc = $Value Function(dynamic o);

final _runtimeTypeMapping = <Type, _MappingFunc> {
  String: (o) => $String(o)
};

$Value mapDynamic(dynamic o) => _runtimeTypeMapping[o.runtimeType]!(o);