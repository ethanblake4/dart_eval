import 'package:dart_eval/src/parse/source.dart';

import '../../dart_eval.dart';

abstract class EvalCollectionElement implements DartSourceNode {}

abstract class EvalMultiValuedCollectionElement implements EvalCollectionElement {
  List<EvalValue> evalMultiValue(EvalScope lexicalScope, EvalScope inheritedScope);
}