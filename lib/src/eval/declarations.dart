import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/class.dart';
import 'package:dart_eval/src/eval/expressions.dart';
import 'package:dart_eval/src/eval/functions.dart';
import 'package:dart_eval/src/eval/primitives.dart';

import '../../dart_eval.dart';
import 'generics.dart';

abstract class DartDeclaration {
  const DartDeclaration({required this.visibility, required this.isStatic});

  final DeclarationVisibility visibility;
  final bool isStatic;

  Map<String, EvalField> declare(DeclarationContext context, EvalScope lexicalScope, EvalScope currentScope);
}

enum DeclarationContext { TOPLEVEL, CLASS, CLASS_FIELD, STATEMENT }

enum DeclarationVisibility { PRIVATE, PUBLIC, UNSPECIFIED }

abstract class DartInterface {
  const DartInterface(this.declarations);

  final List<DartDeclaration> declarations;
}

EvalType _resolveType(TypeAnnotation type, EvalScope lexicalScope) {
  if (type is NamedType) {
    final ref = lexicalScope.lookup(type.name.name);
    if (ref?.value is EvalAbstractClass) {
      return (ref!.value as EvalAbstractClass).delegatedType;
    }
  }
  throw ArgumentError('Anonymous function types not supported yet ${type}');
}

class DartVariableDeclarationList extends DartDeclaration {
  const DartVariableDeclarationList(this.vars,
      {required this.isLate,
      required this.isFinal,
      required DeclarationVisibility visibility,
      required this.type,
      required bool isStatic})
      : super(visibility: visibility, isStatic: isStatic);

  final List<DartVariableDeclaration> vars;
  final bool isLate;
  final bool isFinal;
  final TypeAnnotation? type;

  @override
  Map<String, EvalField> declare(DeclarationContext context, EvalScope lexicalScope, EvalScope currentScope) {
    final m = <String, EvalField>{};
    for (final v in vars) {
      final d = v.declaredVariable(context, type == null ? null : _resolveType(type!, lexicalScope), lexicalScope,
          currentScope, isStatic, isFinal, type == null ? null : type!.question != null);
      m[d.name] = d;
    }
    return m;
  }
}

class DartVariableDeclaration {
  const DartVariableDeclaration(this.name, this.initializer, {required this.isLate});

  final String name;
  final EvalExpression? initializer;
  final bool isLate;

  EvalField declaredVariable(DeclarationContext context, EvalType? type, EvalScope lexicalScope, EvalScope currentScope,
      bool isStatic, bool isFinal, bool? isNullable) {
    EvalValue? value;
    Getter? getter;
    final setter = isFinal ? null : Setter(null);
    if (isStatic) {
      assert(lexicalScope == currentScope, 'Current scope must be equal to lexical scope for statics');
      late EvalExpression _initializer;
      if (initializer == null) {
        _initializer = (isNullable ?? true) ? EvalNullExpression(-1, -1) : (throw ArgumentError.notNull(name));
      } else {
        _initializer = initializer!;
      }
      getter = Getter.deferred(name, type ?? EvalType.dynamicType, currentScope, EvalScope.empty, _initializer);
    } else {
      late EvalExpression _initializer;
      if (initializer == null) {
        _initializer = (isNullable ?? true) ? EvalNullExpression(-1, -1) : (throw ArgumentError.notNull(name));
      } else {
        _initializer = initializer!;
      }
      value = _initializer.eval(lexicalScope, currentScope);
      getter = Getter(null);
    }
    return EvalField(name, value, setter, getter);
  }
}

class DartFunctionDeclaration extends DartDeclaration {
  DartFunctionDeclaration(this.name, this.functionBody,
      {required bool isStatic, required DeclarationVisibility visibility})
      : super(isStatic: isStatic, visibility: visibility);

  final String name;
  EvalFunctionExpression functionBody;

  @override
  Map<String, EvalField> declare(DeclarationContext context, EvalScope lexicalScope, EvalScope currentScope) {
    final func = functionBody.eval(lexicalScope, currentScope);
    return {name: EvalField(name, func, null, Getter(null))};
  }
}

class PlaceholderDeclaration extends DartDeclaration {
  PlaceholderDeclaration(this.name) : super(visibility: DeclarationVisibility.UNSPECIFIED, isStatic: false);

  final String name;

  @override
  Map<String, EvalField> declare(DeclarationContext context, EvalScope lexicalScope, EvalScope currentScope) {
    return {name: EvalField(name, EvalNull(), null, null)};
  }
}

class DartClassDeclaration extends DartDeclaration {
  DartClassDeclaration(this.name, this.generics, this.declarations, this.isAbstract, this.extendsClause, {required this.parseContext})
      : super(isStatic: true, visibility: DeclarationVisibility.UNSPECIFIED);

  final String name;
  final EvalGenericsList generics;
  final List<DartDeclaration> declarations;
  final bool isAbstract;
  final ParseContext parseContext;
  // TODO "extends Something<T>"
  final String extendsClause;

  @override
  Map<String, EvalField> declare(DeclarationContext context, EvalScope lexicalScope, EvalScope currentScope) {
    final type = EvalType(name, name, parseContext.sourceFile, [], true);
    final extendsType = EvalType(extendsClause, extendsClause, '', [], false);
    final value = isAbstract
        ? EvalAbstractClass(declarations, generics, type, lexicalScope, sourceFile: parseContext.sourceFile,
        superclassName: extendsType)
        : EvalClass(declarations, type, lexicalScope, generics, sourceFile: parseContext.sourceFile, superclassName: extendsType);
    return {name: EvalField(name, value, null, Getter(null))};
  }
}

class DartMethodDeclaration extends DartDeclaration {
  DartMethodDeclaration(this.name, this.body, this.params, bool isStatic)
      : super(visibility: DeclarationVisibility.UNSPECIFIED, isStatic: isStatic);
  String name;
  DartMethodBody? body;
  List<ParameterDefinition> params;

  @override
  Map<String, EvalField> declare(DeclarationContext context, EvalScope lexicalScope, EvalScope currentScope) {
    if (body == null) {
      throw ArgumentError('Must override all methods of an abstract class: $name()');
    }

    if (isStatic) {
      assert(lexicalScope == currentScope, 'Current scope must be equal to lexical scope for statics');
    }

    final v = EvalFunctionImpl(body!, params, inheritedScope: currentScope, lexicalScope: lexicalScope);
    return {name: EvalField(name, v, null, Getter(null))};
  }
}

class DartConstructorDeclaration extends DartDeclaration {
  DartConstructorDeclaration(this.name) : super(visibility: DeclarationVisibility.UNSPECIFIED, isStatic: true);

  final String name;

  @override
  Map<String, EvalField> declare(DeclarationContext context, EvalScope lexicalScope, EvalScope currentScope) {
    // TODO: implement declare
    throw UnimplementedError();
  }
}
