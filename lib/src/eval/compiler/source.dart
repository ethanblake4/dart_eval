
import 'package:analyzer/dart/ast/ast.dart';

class DeclarationOrPrefix {
  DeclarationOrPrefix(this.sourceLib, {this.declaration, this.children});

  int sourceLib;
  Declaration? declaration;
  Map<String, Declaration>? children;
}