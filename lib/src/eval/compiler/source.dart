
import 'package:dart_eval/dart_eval_bridge.dart';

class DeclarationOrPrefix {
  DeclarationOrPrefix(this.sourceLib, {this.declaration, this.children});

  int sourceLib;
  DeclarationOrBridge? declaration;
  Map<String, DeclarationOrBridge>? children;
}