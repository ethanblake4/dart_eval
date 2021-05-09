import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/declarations.dart';
import 'package:dart_eval/src/eval/functions.dart';
import 'package:dart_eval/src/eval/generics.dart';
import 'package:dart_eval/src/eval/object.dart';

/// Defines a static class reference (not its object instance)
class EvalAbstractClass extends EvalValueImpl<Type> implements DartInterface, EvalRuntimeType {
  EvalAbstractClass(this.declarations, this.generics, this.delegatedType, EvalScope lexicalScope,
      {String? sourceFile, this.superclassName, Type? realValue})
      : super(EvalType.typeType,
            sourceFile: sourceFile,
            fieldListBreakout: EvalFieldListBreakout.withFields({}),
            realValue: realValue) {
    this.lexicalScope = EvalObjectLexicalScope(lexicalScope);
    final inheritedScope = EvalObjectScope();
    addFields(_breakoutStaticDeclarations(declarations, this.lexicalScope, inheritedScope));
    inheritedScope.object = this;
    this.lexicalScope.object = this;
  }

  static EvalFieldListBreakout _breakoutStaticDeclarations(List<DartDeclaration> declarations, EvalScope lexicalScope, EvalScope inheritedScope) {
    final entries = declarations
        .where((declaration) => declaration.isStatic)
        .expand((declaration) => declaration.declare(DeclarationContext.CLASS, lexicalScope, inheritedScope).entries);
    return EvalFieldListBreakout.withFields(Map.fromEntries(entries));
  }

  final EvalGenericsList generics;
  final EvalType? superclassName;
  late EvalObjectLexicalScope lexicalScope;

  @override
  final List<DartDeclaration> declarations;

  @override
  final EvalType delegatedType;

  List<DartDeclaration> getAllDeclarations(EvalScope lexicalScope) {
    if (superclassName == null) {
      return declarations;
    }

    final superclass = lexicalScope.lookup(superclassName!.refName)!.value as EvalAbstractClass;
    if (superclass is EvalBridgeAbstractClass) {
      return declarations;
    }

    return superclass.getAllDeclarations(lexicalScope).followedBy(declarations).toList();
  }

  @override
  String toString() {
    return 'EvalAbstractClass{delegatedType: $delegatedType}';
  }
}

class EvalBridgeAbstractClass extends EvalAbstractClass with ValueInterop<Type> {
  EvalBridgeAbstractClass(List<DartDeclaration> declarations,  EvalType delegatedType,
      EvalScope lexicalScope, Type realValue, {EvalGenericsList generics = EvalGenericsList.empty})
      : super(declarations, generics, delegatedType, lexicalScope,
            realValue: realValue, superclassName: delegatedType.supertypes[0], sourceFile: delegatedType.refSourceFile);

  @override
  Type get realValue => super.realValue!;

  @override
  String toString() {
    return 'BridgeAbstract{}';
  }
}

class EvalClass extends EvalAbstractClass implements EvalCallable {
  EvalClass(
      List<DartDeclaration> declarations, EvalType delegatedType, EvalScope lexicalScope, EvalGenericsList generics,
      {String? sourceFile, EvalType? superclassName, Type? realValue})
      : super(declarations, generics, delegatedType, lexicalScope,
            sourceFile: sourceFile, superclassName: superclassName, realValue: realValue);

  @override
  EvalType get returnType => delegatedType;

  /// Call the default constructor.
  /// If there is no default constructor, this method will throw an error.
  @override
  EvalObject call(EvalScope _lex, EvalScope inheritedScope, List<EvalType> generics, List<Parameter> args,
      {EvalValue? target}) {
    final newScope = EvalObjectScope();
    final objectLexicalScope = EvalObjectLexicalScope(lexicalScope);

    if (superclassName != null) {
      final superclass = lexicalScope.lookup(superclassName!.refName)!.value as EvalAbstractClass;

      if (superclass is EvalBridgeClass) {
        final me = superclass.instantiate('', [], {}) as BridgeRectifier;
        me.evalBridgeData = EvalBridgeData(this);
        final _declarations = getAllDeclarations(lexicalScope);
        final entries = _declarations.where((declaration) => !declaration.isStatic).expand(
            (declaration) => declaration.declare(DeclarationContext.CLASS_FIELD, objectLexicalScope, newScope).entries);
        me.evalBridgeData.fields.addAll(Map.fromEntries(entries));

        try {
          final cstr = evalGetField('');
          if (!(cstr is EvalFunction)) {
            throw ArgumentError('Default constructor is not a function');
          }
          cstr.call(objectLexicalScope, newScope, generics, args, target: me);
        // ignore: empty_catches
        } catch (e) {
          // No requirement that the constructor is present
        }

        newScope.object = me;
        objectLexicalScope.object = me;

        return me;
      }
    }
    final _declarations = getAllDeclarations(lexicalScope);

    final entries = _declarations.where((declaration) => !declaration.isStatic).expand(
        (declaration) => declaration.declare(DeclarationContext.CLASS_FIELD, objectLexicalScope, newScope).entries);

    final entryMap = Map.fromEntries(entries);
    final cstr = evalGetField('');
    if (!(cstr is EvalFunction)) {
      throw ArgumentError('Default constructor is not a function');
    }

    /// Map.fromEntries overwrites earlier occurrences with later ones
    final o = EvalObject(this, sourceFile: evalSourceFile, fields: entryMap);
    newScope.object = o;
    objectLexicalScope.object = o;
    cstr.call(objectLexicalScope, newScope, generics, args, target: o);

    return o;
  }

  @override
  String toString() {
    return 'EvalClass{delegatedType: $delegatedType}';
  }
}

class EvalBridgeClass<D> extends EvalBridgeAbstractClass implements EvalClass {
  EvalBridgeClass(List<DartDeclaration> declarations, EvalType delegatedType,
      EvalScope lexicalScope, Type realValue, this.instantiate, {EvalGenericsList generics = EvalGenericsList.empty})
      : super(declarations, delegatedType, lexicalScope, realValue, generics: generics);

  BridgeInstantiator<D> instantiate;

  BridgeRectifier<D> construct(String constructor, EvalScope lexicalScope, EvalScope inheritedScope,
      List<EvalType> generics, List<Parameter> args) {

    final newScope = EvalObjectScope();
    final objectLexicalScope = EvalObjectLexicalScope(this.lexicalScope);
    final spl = Parameter.coalesceNamed(args);

    final me = instantiate(constructor, spl.positional.map((e) => e.value.evalReifyFull()).toList(), spl.named.map(
        (k, v) => MapEntry(k, v.evalReifyFull())
    )) as BridgeRectifier<D>;
    me.evalBridgeData = EvalBridgeData(this);
    final _declarations = getAllDeclarations(this.lexicalScope);
    final entries = _declarations.where((declaration) => !declaration.isStatic).expand(
            (declaration) => declaration.declare(DeclarationContext.CLASS_FIELD, objectLexicalScope, newScope).entries);
    me.evalBridgeData.fields.addAll(Map.fromEntries(entries));

    try {
      final cstr = evalGetField(constructor);
      if (!(cstr is EvalFunction)) {
        throw ArgumentError('Constructor "$constructor" is not a function');
      }
      cstr.call(objectLexicalScope, newScope, generics, args, target: me);
      // ignore: empty_catches
    } catch (e) {
      // No requirement that the constructor is present
    }

    newScope.object = me;
    objectLexicalScope.object = me;

    return me;
  }

  @override
  BridgeRectifier<D> call(
      EvalScope lexicalScope, EvalScope inheritedScope, List<EvalType> generics, List<Parameter> args,
      {EvalValue? target}) {
    return construct('', this.lexicalScope, EvalScope.empty, generics, args);
  }

  @override
  EvalType get returnType => delegatedType;

  @override
  String toString() {
    return 'EvalBridgeClass{delegatedType: $delegatedType}';
  }
}