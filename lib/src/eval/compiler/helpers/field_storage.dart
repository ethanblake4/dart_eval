import 'package:analyzer/dart/ast/ast.dart';

/// Abstract fields declare accessors; external fields are implemented outside
/// the guest class. Neither owns an instance slot.
bool hasInstanceFieldStorage(FieldDeclaration field) =>
    !field.isStatic &&
    field.abstractKeyword == null &&
    field.externalKeyword == null;

bool isExternalVariable(VariableDeclaration variable) =>
    switch (variable.parent?.parent) {
      FieldDeclaration field => field.externalKeyword != null,
      TopLevelVariableDeclaration field => field.externalKeyword != null,
      _ => false,
    };
