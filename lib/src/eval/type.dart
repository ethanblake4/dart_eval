import 'package:_fe_analyzer_shared/src/base/syntactic_entity.dart';
import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/class.dart';

import 'value.dart';


/// Represents the type of an [EvalValue]
class EvalType {
  static const EvalType dynamicType = EvalType('dynamic', 'dynamic', 'dart:core', [], true);
  static const EvalType objectType = EvalType('Object', 'Object', 'dart:core', [dynamicType], true);
  static const EvalType nullType = EvalType('Null', 'Null', 'dart:core', [dynamicType], true);
  static const EvalType typeType = EvalType('Type', 'Type', 'dart:core', [objectType], true);
  static const EvalType functionType = EvalType('Function', 'Function', 'dart:core', [objectType],true);
  static const EvalType numType = EvalType('num', 'num', 'dart:core', [objectType],true);
  static const EvalType intType = EvalType('int', 'int', 'dart:core', [numType], true);
  static const EvalType boolType = EvalType('bool', 'bool', 'dart:core', [objectType],true);
  static const EvalType stringType = EvalType('String', 'String', 'dart:core', [objectType],true);
  static const EvalType listType = EvalType('List', 'List', 'dart:core', [objectType],true);

  const EvalType(this.name, this.refName, this.refSourceFile, this.supertypes, this.resolved, {this.generics});

  factory EvalType.fromAnnotation(TypeAnnotation annotation, String sourceFile) {
    // The annotation's type field does not provide any info with an unresolved AST
    if(annotation is NamedType) {
      return EvalType(annotation.name.name, annotation.name.name, sourceFile, [], false);
    }
    throw ArgumentError('Anonymous function types not yet supported');
  }

  final String name;
  final String refName;
  final String refSourceFile;
  final Map<String, EvalType>? generics;
  final List<EvalType> supertypes;
  final bool resolved;

  @override
  String toString() {
    var genericsString = '';
    if (generics != null) {
      genericsString = '<${generics!.values.join(', ')}>';
    }
    return name == refName ? '$name$genericsString' : '"$name" ($refName$genericsString)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvalType &&
          runtimeType == other.runtimeType &&
          refName == other.refName &&
          refSourceFile == other.refSourceFile &&
          generics == other.generics;

  @override
  int get hashCode => refName.hashCode ^ refSourceFile.hashCode ^ generics.hashCode;

  EvalType? resolve(EvalScope lexicalScope) {
    if(resolved) return this;
    final f = lexicalScope.lookup(name)?.value;
    if(f is EvalAbstractClass) {
      return f.delegatedType;
    }
    return null;
  }
}

/// The dart:core Type class
class EvalRuntimeType {
  EvalRuntimeType(this.delegatedType);

  /// The type that this Type references
  final EvalType delegatedType;
}