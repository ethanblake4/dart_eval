import 'package:dart_eval/src/eval/bridge/declaration.dart';

class DeclarationOrPrefix {
  DeclarationOrPrefix(this.sourceLib, {this.declaration, this.children});

  int sourceLib;
  DeclarationOrBridge? declaration;
  Map<String, DeclarationOrBridge>? children;
}
