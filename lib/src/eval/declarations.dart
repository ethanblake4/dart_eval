import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/class.dart';
import 'package:dart_eval/src/eval/expressions.dart';
import 'package:dart_eval/src/eval/functions.dart';

import '../../dart_eval.dart';
import 'generics.dart';

/// A custom declaration function
typedef DartDeclaratorFunc = Map<String, EvalField> Function(
    DeclarationContext context, EvalScope lexicalScope, EvalScope currentScope);

/// A declaration declares one or more fields, and assigns them their lexical scope if one is needed
abstract class DartDeclaration {
  const DartDeclaration({required this.visibility, required this.isStatic});

  /// The visibility of this declaration. Not currently used and may be removed in the future.
  final DeclarationVisibility visibility;

  /// Whether this declaration is static. Some declarations can only be static, like top-level fields.
  final bool isStatic;

  /// Declare fields
  /// Warning: [declare] is not allowed to have dependencies on other classes
  Map<String, EvalField> declare(DeclarationContext context,
      EvalScope lexicalScope, EvalScope currentScope);
}

/// Custom declaration that takes a [DartDeclaratorFunc] to perform user-defined declaration
class DartBridgeDeclaration extends DartDeclaration {
  DartBridgeDeclaration(
      {required DeclarationVisibility visibility, required this.declarator})
      : super(visibility: visibility, isStatic: true);

  /// The function that defines how this declaration will be declared
  final DartDeclaratorFunc declarator;

  @override
  Map<String, EvalField> declare(DeclarationContext context,
      EvalScope lexicalScope, EvalScope currentScope) {
    return declarator(context, lexicalScope, currentScope);
  }
}

/// The context in which a declaration is declared
enum DeclarationContext { TOPLEVEL, CLASS, CLASS_FIELD, STATEMENT }

/// Visibility of a declaration. Not currently used and may be removed in the future.
enum DeclarationVisibility { PRIVATE, PUBLIC, UNSPECIFIED }

abstract class DartInterface {
  const DartInterface(this.declarations);

  final List<DartDeclaration> declarations;
}

/* EvalType _resolveType(TypeAnnotation type, EvalScope lexicalScope) {
  if (type is NamedType) {
    final ref = lexicalScope.lookup(type.name.name);
    if (ref?.value is EvalAbstractClass) {
      return (ref!.value as EvalAbstractClass).delegatedType;
    }
  }
  throw ArgumentError('Anonymous function types not supported yet $type');
}*/

/// A variable declaration list declares one or more variables of a specified type,
/// with optional initial values.
/// See [VariableDeclarationList]
class DartVariableDeclarationList extends DartDeclaration {
  const DartVariableDeclarationList(this.vars,
      {required this.isLate,
      required this.isFinal,
      required DeclarationVisibility visibility,
      required this.type,
      required bool isStatic})
      : super(visibility: visibility, isStatic: isStatic);

  /// Variables to be declared
  final List<DartVariableDeclaration> vars;

  /// Whether this list is declared with the `late` keyword
  final bool isLate;

  /// Whether this list is declared with the `final` keyword
  final bool isFinal;

  /// The type annotation, if any
  final TypeAnnotation? type;

  @override
  Map<String, EvalField> declare(DeclarationContext context,
      EvalScope lexicalScope, EvalScope currentScope) {
    final m = <String, EvalField>{};
    for (final v in vars) {
      final d = v.declaredVariable(context, null, lexicalScope, currentScope,
          isStatic, isFinal, type == null ? null : type!.question != null);
      m[d.name] = d;
    }
    return m;
  }
}

/// A variable declaration declares a single variable. Called by [DartVariableDeclarationList]
/// See [VariableDeclaration]
class DartVariableDeclaration {
  const DartVariableDeclaration(this.name, this.initializer,
      {required this.isLate});

  final String name;
  final EvalExpression? initializer;
  final bool isLate;

  EvalField declaredVariable(
      DeclarationContext context,
      EvalType? type,
      EvalScope lexicalScope,
      EvalScope currentScope,
      bool isStatic,
      bool isFinal,
      bool? isNullable) {
    EvalValue? value;
    Getter? getter;
    final setter = isFinal ? null : Setter(null);
    if (isStatic) {
      late EvalExpression _initializer;
      if (initializer == null) {
        _initializer = (isNullable ?? true)
            ? EvalNullExpression(-1, -1)
            : (throw ArgumentError.notNull(name));
      } else {
        _initializer = initializer!;
      }
      getter = Getter.deferred(name, type ?? EvalType.dynamicType, lexicalScope,
          currentScope, _initializer);
    } else {
      getter = Getter(null);
      late EvalExpression _initializer;
      if (initializer == null && (isNullable ?? true)) {
        _initializer = EvalNullExpression(-1, -1);
      } else if (initializer == null) {
        value = null;
        return EvalField(name, value, setter, getter);
      } else {
        _initializer = initializer!;
      }
      value = _initializer.eval(lexicalScope, currentScope);
    }
    return EvalField(name, value, setter, getter);
  }
}

/// Declares a function
/// See [FunctionDeclaration]
class DartFunctionDeclaration extends DartDeclaration {
  DartFunctionDeclaration(this.name, this.functionBody,
      {required bool isStatic, required DeclarationVisibility visibility})
      : super(isStatic: isStatic, visibility: visibility);

  /// Name of the function
  final String name;

  /// Body of the function
  EvalFunctionExpression functionBody;

  @override
  Map<String, EvalField> declare(DeclarationContext context,
      EvalScope lexicalScope, EvalScope currentScope) {
    final func = functionBody.eval(lexicalScope, currentScope);
    return {name: EvalField(name, func, null, Getter(null))};
  }
}

/// Declares a class
/// See [ClassDeclaration]
class DartClassDeclaration extends DartDeclaration {
  DartClassDeclaration(this.name, this.generics, this.declarations,
      this.isAbstract, this.extendsClause,
      {required this.parseContext})
      : super(isStatic: true, visibility: DeclarationVisibility.UNSPECIFIED);

  /// Name of this class
  final String name;

  /// Generic type parameters supported by this class
  final EvalGenericsList generics;

  /// Declarations inside this class
  final List<DartDeclaration> declarations;

  /// Whether this class is an abstract class, and can't be instantiated
  final bool isAbstract;

  /// The parse context of this class
  final ParseContext parseContext;

  /// The extends clause of this class, or null
  ///
  /// TODO "extends Something<T>"
  final String? extendsClause;

  /// Declaring a class creates a [EvalClass] or [EvalAbstractClass]
  /// This is a static class reference, not an instance of the class
  @override
  Map<String, EvalField> declare(DeclarationContext context,
      EvalScope lexicalScope, EvalScope currentScope) {
    final type = EvalType(name, name, parseContext.sourceFile, [], true);
    final extendsType = extendsClause != null
        ? EvalType(extendsClause!, extendsClause!, '', [], false)
        : null;
    final value = isAbstract
        ? EvalAbstractClass(declarations, generics, type, lexicalScope,
            sourceFile: parseContext.sourceFile, superclassName: extendsType)
        : EvalClass(declarations, type, lexicalScope, generics,
            sourceFile: parseContext.sourceFile, superclassName: extendsType);
    return {name: EvalField(name, value, null, Getter(null))};
  }
}

/// Declares a method
/// See [MethodDeclaration]
class DartMethodDeclaration extends DartDeclaration {
  DartMethodDeclaration(this.name, this.body, this.params, bool isStatic)
      : super(
            visibility: DeclarationVisibility.UNSPECIFIED, isStatic: isStatic);

  /// Name of the method
  String name;

  /// The method body
  DartMethodBody? body;

  /// Parameters supported by this method
  List<ParameterDefinition> params;

  /// Declaring a method creates an [EvalFunction] which runs [body]
  @override
  Map<String, EvalField> declare(DeclarationContext context,
      EvalScope lexicalScope, EvalScope currentScope) {
    if (body == null) {
      throw ArgumentError(
          'Must override all methods of an abstract class: $name()');
    }

    final v = EvalFunctionImpl(body!, params,
        inheritedScope: currentScope, lexicalScope: lexicalScope);
    return {name: EvalField(name, v, null, Getter(null))};
  }
}

/// Declares a class constructor
/// See [ConstructorDeclaration] for syntax
class DartConstructorDeclaration extends DartDeclaration {
  DartConstructorDeclaration(this.name, this.params)
      : super(visibility: DeclarationVisibility.UNSPECIFIED, isStatic: true);

  /// The constructor's name, or an empty string for the unnamed constructor
  final String name;

  /// Parameters supported by this constructor
  final List<ParameterDefinition> params;

  /// Declaring a constructor creates a [EvalFunction] which constructs an [EvalObject] when called
  @override
  Map<String, EvalField> declare(DeclarationContext context,
      EvalScope lexicalScope, EvalScope currentScope) {
    final v = EvalFunctionImpl(DartMethodBody(callable:
        (EvalScope lexicalScope2, EvalScope inheritedScope2,
            List<EvalType> generics, List<Parameter> args,
            {EvalValue? target}) {
      if (target is EvalBridgeClass) {
        return target.construct(
            name, lexicalScope, currentScope, generics, args);
      }
      var i = 0;
      final argMap = Parameter.coalesceNamed(args).named;
      for (var param in params) {
        final vl = param.extractFrom(args, i, argMap);
        if (param.isField && vl != null) {
          target!.evalSetField(param.name, vl, internalSet: true);
        } else if (vl == null && param.dfValue != null) {
          target!.evalSetField(
              param.name, param.dfValue!.eval(lexicalScope, currentScope));
        }
        i++;
      }
      return target!;
    }), params);
    return {name: EvalField(name, v, null, Getter(null))};
  }
}
