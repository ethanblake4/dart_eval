import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/declarations.dart';
import 'package:dart_eval/src/eval/functions.dart';
import 'package:dart_eval/src/eval/generics.dart';
import 'package:dart_eval/src/eval/object.dart';

/// Defines a static class reference (not its object instance)
class EvalAbstractClass extends EvalValueImpl<Type> implements DartInterface, EvalRuntimeType {
  EvalAbstractClass(this.declarations, this.generics, this.delegatedType, this.lexicalScope,
      {String? sourceFile, this.superclassName, Type? realValue})
      : super(EvalType.typeType,
            sourceFile: sourceFile,
            fieldListBreakout: _breakoutStaticDeclarations(declarations, lexicalScope),
            realValue: realValue);

  static EvalFieldListBreakout _breakoutStaticDeclarations(List<DartDeclaration> declarations, EvalScope lexicalScope) {
    final entries = declarations
        .where((declaration) => declaration.isStatic)
        .expand((declaration) => declaration.declare(DeclarationContext.CLASS, lexicalScope, lexicalScope).entries);
    return EvalFieldListBreakout.withFields(Map.fromEntries(entries));
  }

  final EvalGenericsList generics;
  final EvalType? superclassName;
  final EvalScope lexicalScope;

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
}

class EvalBridgeAbstractClass extends EvalAbstractClass with ValueInterop<Type> {
  EvalBridgeAbstractClass(List<DartDeclaration> declarations, EvalGenericsList generics, EvalType delegatedType,
      EvalScope lexicalScope, Type realValue, {EvalType? superclassName = EvalType.objectType, String? sourceFile})
      : super(declarations, generics, delegatedType, lexicalScope,
            realValue: realValue, superclassName: superclassName, sourceFile: sourceFile);

  @override
  Type get realValue => super.realValue!;
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
  EvalObject call(EvalScope lexicalScope, EvalScope inheritedScope, List<EvalType> generics, List<Parameter> args,
      {EvalValue? target}) {
    //final f = EvalAbstractClass(declarations, generics, delegatedType, lexicalScope);
    final newScope = EvalObjectScope();

    if (superclassName != null) {
      //print('!!superclass!!!' + delegatedType.name);
      //print(superclassName!);
      final superclass = lexicalScope.lookup(superclassName!.refName)!.value as EvalAbstractClass;

      if (superclass is EvalBridgeClass) {
        // TODO

        final me = superclass.instantiate('', [], {}) as BridgeRectifier;
        me.evalBridgeData = EvalBridgeData(this);
        final _declarations = getAllDeclarations(lexicalScope);
        final entries = _declarations.where((declaration) => !declaration.isStatic).expand(
            (declaration) => declaration.declare(DeclarationContext.CLASS_FIELD, this.lexicalScope, newScope).entries);
        me.evalBridgeData.fields..addAll(Map.fromEntries(entries));

        final cstr = getField('');
        if (!(cstr is EvalFunction)) {
          throw ArgumentError('Default constructor is not a function');
        }
        cstr.call(lexicalScope, newScope, generics, args, target: me);
        // ignore: empty_catches

        newScope.object = me;

        return me;
      }
    }
    final _declarations = getAllDeclarations(lexicalScope);

    final entries = _declarations.where((declaration) => !declaration.isStatic).expand(
        (declaration) => declaration.declare(DeclarationContext.CLASS_FIELD, this.lexicalScope, newScope).entries);

    final entryMap = Map.fromEntries(entries);
    final cstr = getField('');
    if (!(cstr is EvalFunction)) {
      throw ArgumentError('Default constructor is not a function');
    }

    /// Map.fromEntries overwrites earlier occurrences with later ones
    final o = EvalObject(this, sourceFile: sourceFile, fields: entryMap);
    newScope.object = o;
    cstr.call(lexicalScope, newScope, generics, args, target: o);

    return o;
  }
}

class EvalBridgeClass<D> extends EvalBridgeAbstractClass implements EvalClass {
  EvalBridgeClass(List<DartDeclaration> declarations, EvalGenericsList generics, EvalType delegatedType,
      EvalScope lexicalScope, Type realValue, this.instantiate, {EvalType? superclassName, String? sourceFile})
      : super(declarations, generics, delegatedType, lexicalScope, realValue,
            superclassName: superclassName, sourceFile: sourceFile);

  BridgeInstantiator<D> instantiate;

  @override
  EvalBridgeObject<D> call(
      EvalScope lexicalScope, EvalScope inheritedScope, List<EvalType> generics, List<Parameter> args,
      {EvalValue? target}) {
    final newScope = EvalObjectScope();
    final _declarations = getAllDeclarations(lexicalScope);

    final entries = _declarations.where((declaration) => !declaration.isStatic).expand(
        (declaration) => declaration.declare(DeclarationContext.CLASS_FIELD, this.lexicalScope, newScope).entries);

    final spl = Parameter.coalesceNamed(args);
    final o = EvalBridgeObject<D>(this, fields: Map.fromEntries(entries));
    newScope.object = o;
    o.realValue = instantiate('', spl.positional.map((e) => e.value).toList(), spl.named);

    return o;
  }

  @override
  EvalType get returnType => delegatedType;
}
