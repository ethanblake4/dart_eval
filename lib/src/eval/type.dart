import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/class.dart';

import 'value.dart';

/// Represents the type of an [EvalValue]
class EvalType {
  /// The [dynamic] type from dart:core
  static const EvalType dynamicType =
      EvalType('dynamic', 'dynamic', 'dart:core', [], true);

  /// The [Object] type from dart:core
  static const EvalType objectType =
      EvalType('Object', 'Object', 'dart:core', [dynamicType], true);

  /// The [Null] type from dart:core
  static const EvalType nullType =
      EvalType('Null', 'Null', 'dart:core', [dynamicType], true);

  /// The [Type] type from dart:core
  static const EvalType typeType =
      EvalType('Type', 'Type', 'dart:core', [objectType], true);

  /// The [Function] type from dart:core
  static const EvalType functionType =
      EvalType('Function', 'Function', 'dart:core', [objectType], true);

  /// The [num] type from dart:core
  static const EvalType numType =
      EvalType('num', 'num', 'dart:core', [objectType], true);

  /// The [int] type from dart:core
  static const EvalType intType =
      EvalType('int', 'int', 'dart:core', [numType], true);

  /// The [bool] type from dart:core
  static const EvalType boolType =
      EvalType('bool', 'bool', 'dart:core', [objectType], true);

  /// The [String] type from dart:core
  static const EvalType stringType =
      EvalType('String', 'String', 'dart:core', [objectType], true);

  /// The [List] type from dart:core
  static const EvalType listType =
      EvalType('List', 'List', 'dart:core', [objectType], true);

  /// The [Map] type from dart:core
  static const EvalType mapType =
      EvalType('Map', 'Map', 'dart:core', [objectType], true);

  /// The [DateTime] type from dart:core
  static const EvalType DateTimeType =
      EvalType('DateTime', 'DateTime', 'dart:core', [objectType], true);

  /// Create an [EvalType]
  const EvalType(this.name, this.refName, this.refSourceFile, this.supertypes,
      this.resolved,
      {this.generics});

  /// Create an [EvalType] from an analyzer [TypeAnnotation]
  factory EvalType.fromAnnotation(
      TypeAnnotation annotation, String sourceFile) {
    // The annotation's type field does not provide any info with an unresolved AST
    if (annotation is NamedType) {
      return EvalType(
          annotation.name.name, annotation.name.name, sourceFile, [], false);
    }
    throw ArgumentError('Anonymous function types not yet supported');
  }

  /// Name of this type in the current scope
  /// This will be different from [refName] if it is used as a generic param
  final String name;

  /// The original reference name of this type, unaffected by generics
  final String refName;

  /// Source file where the type is defined
  final String refSourceFile;

  /// A list of generics defined on this type
  final Map<String, EvalType>? generics;

  /// All supertypes of this type, including superclasses, interfaces, and mixins
  final List<EvalType> supertypes;

  /// Whether this type has been resolved to determine its supertypes
  final bool resolved;

  @override
  String toString() {
    var genericsString = '';
    if (generics != null) {
      genericsString = '<${generics!.values.join(', ')}>';
    }
    return 'type: ' + name == refName
        ? '$name$genericsString'
        : '"$name" ($refName$genericsString)';
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
  int get hashCode =>
      refName.hashCode ^ refSourceFile.hashCode ^ generics.hashCode;

  EvalType? resolve(EvalScope lexicalScope) {
    if (resolved) return this;
    final f = lexicalScope.lookup(name)?.value;
    if (f is EvalAbstractClass) {
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
