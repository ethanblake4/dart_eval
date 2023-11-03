import 'package:dart_eval/src/eval/bridge/declaration.dart';

class DeclarationOrPrefix {
  DeclarationOrPrefix({this.declaration, this.children});

  DeclarationOrBridge? declaration;
  Map<String, DeclarationOrBridge>? children;
}
