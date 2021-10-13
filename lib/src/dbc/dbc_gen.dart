import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/dbc/dbc_executor.dart';
import 'package:dart_eval/src/dbc/dbc_writer.dart';

class DbcGen {
  final out = <DbcOp>[];

  DbcExecutor generate(String source) {
    final d = parseString(content: source, throwIfDiagnostics: false);

    if (d.errors.isNotEmpty) {
      d.errors.forEach((element) {
        print(element);
      });
      throw ArgumentError();
    }

    final ctx = DbcGenContext(0);

    final topLevelDeclarationsMap = <String, Declaration>{};

    ctx.visibleTypes = _coreDeclarations;

    d.unit.declarations.forEach((d) {
      if (d is NamedCompilationUnitMember) {
        topLevelDeclarationsMap[d.name.name] = d;
        if (d is ClassDeclaration) {
          ctx.visibleTypes[d.name.name] = TypeRef(0, d.name.name);
        }
      } else {
        throw ArgumentError('not a NamedCompilationUnitMember');
      }
    });

    ctx.topLevelDeclarationsMap = topLevelDeclarationsMap;

    topLevelDeclarationsMap.forEach((key, value) {
      _parseDeclaration(value, ctx);
      ctx.scopeFrameOffset = 0;
      ctx.allocNest = [0];
    });

    final ob = DbcWriter().write(<int, Map<String, int>>{0: ctx.topLevelDeclarationPositions}, out);

    return DbcExecutor(ob.buffer.asByteData())
      ..loadProgram();
  }

  int pushOp(DbcGenContext ctx, DbcOp op, int length) {
    out.add(op);
    ctx.position += length;
    return out.length - 1;
  }

  int enterScope(DbcGenContext ctx, AstNode scopeHost, int offset, String name) {
    final position = out.length;
    var op = PushScope.make(ctx.sourceFile, offset, name);
    pushOp(ctx, op, PushScope.len(op));
    ctx.locals.add({});
    return position;
  }

  void exitScope(DbcGenContext ctx) {
    pushOp(ctx, PopScope.make(), PopScope.LEN);
    ctx.locals.removeLast();
  }

  int? _parseDeclaration(Declaration d, DbcGenContext ctx) {
    if (d is ClassDeclaration) {
      for (final m in d.members) {
        _parseDeclaration(m, ctx)!;
      }
    } else if (d is MethodDeclaration) {
      ctx.functionName = d.name.name;
      final b = d.body;
      int? pos;
      if (b is BlockFunctionBody) {
        pos = _parseBlock(b.block, ctx, name: d.name.name + '()').position;
      } else {
        throw ArgumentError('Unknown function body type ${b.runtimeType}');
      }

      if (d.isStatic) {
        ctx.topLevelDeclarationPositions[d.name.name] = pos;
      }
      return pos;
    } else if (d is FunctionDeclaration) {
      ctx.functionName = d.name.name;
      ctx.topLevelDeclarationPositions[d.name.name] = enterScope(ctx, d, d.offset, d.name.name + '()');
      final b = d.functionExpression.body;
      StatementInfo? stInfo;
      if (b is BlockFunctionBody) {
        stInfo = _parseBlock(b.block, ctx, name: d.name.name + '()');
      }
      if (stInfo == null || !(stInfo.willAlwaysReturn || stInfo.willAlwaysThrow)) {
        pushOp(ctx, Return.make(-1), Return.LEN);
      }
      ctx.locals.removeLast();
    }
  }

  StatementInfo _parseStatement(Statement s, DbcGenContext ctx) {
    if (s is Block) {
      return _parseBlock(s, ctx);
    } else if (s is VariableDeclarationStatement) {
      _parseVariableDeclarationList(s.variables, ctx);
      return StatementInfo(-1);
    } else if (s is ExpressionStatement) {
      _parseExpression(s.expression, ctx);
      return StatementInfo(-1);
    } else if (s is ReturnStatement) {
      _parseReturn(s, ctx);
      return StatementInfo(-1, willAlwaysReturn: true);
    }
    return StatementInfo(-1);
  }

  void _buildClassInstantiator(DbcGenContext ctx, ClassDeclaration cls) {
    if (cls.isAbstract) {
      throw ArgumentError('Cannot create instantiator for abstract class');
    }


    //final j = pushOp(ctx, , length)
  }

  StatementInfo _parseBlock(Block b, DbcGenContext ctx, {String name = '<block>'}) {
    final position = out.length;
    ctx.allocNest.add(0);

    var willAlwaysReturn = false;
    var willAlwaysThrow = false;

    for (final s in b.statements) {
      final stInfo = _parseStatement(s, ctx);

      if (stInfo.willAlwaysThrow) {
        willAlwaysThrow = true;
        break;
      }
      if (stInfo.willAlwaysReturn) {
        willAlwaysReturn = true;
        break;
      }
    }

    if (!willAlwaysThrow && !willAlwaysReturn) {
      final nestCount = ctx.allocNest.removeLast();

      for (var i = 0; i < nestCount; i++) {
        pushOp(ctx, Pop.make(), Pop.LEN);
      }
    }

    return StatementInfo(position, willAlwaysReturn: willAlwaysReturn, willAlwaysThrow: willAlwaysThrow);
  }

  void _parseReturn(ReturnStatement s, DbcGenContext ctx) {
    if (s.expression == null) {
      pushOp(ctx, Return.make(-1), Return.LEN);
    } else {
      final value = _parseExpression(s.expression!, ctx);
      pushOp(ctx, Return.make(value.scopeFrameOffset), Return.LEN);
    }
  }

  Variable _parseExpression(Expression e, DbcGenContext ctx) {
    if (e is Literal) {
      final literalValue = _parseLiteral(e, ctx);
      return _pushBuiltinValue(literalValue, ctx);
    } else if (e is AssignmentExpression) {
      final L = _parseExpression(e.leftHandSide, ctx);
      final R = _parseExpression(e.rightHandSide, ctx);

      if (!R.type.isAssignableTo(L.type)) {
        throw ArgumentError('Syntax error: cannot assign value of type ${R.type} to ${L.type}');
      }

      pushOp(ctx, CopyValue.make(L.scopeFrameOffset, R.scopeFrameOffset), CopyValue.LEN);
      return L;
    } else if (e is Identifier) {
      return _parseIdentifier(e, ctx);
    } else if (e is MethodInvocation) {
      final Variable? L;
      if (e.target != null) {
        L = _parseExpression(e.target!, ctx);
        throw ArgumentError('Cannot method target');
      }
      final method = _parseIdentifier(e.methodName, ctx);
      if (method.methodOffset == null) {
        throw ArgumentError('Cannot call ${e.methodName.name} as it is not a valid method');
      }
      pushOp(ctx, Call.make(method.methodOffset!), Call.LEN);
      pushOp(ctx, PushReturnValue.make(), PushReturnValue.LEN);
      ctx.allocNest.last++;
      return Variable(ctx.scopeFrameOffset++, method.methodReturnType ?? _dynamicType);
    }
    throw ArgumentError('Unknown expression type ${e.runtimeType}');
  }

  void _parseVariableDeclarationList(VariableDeclarationList l, DbcGenContext ctx) {
    TypeRef? type;
    if (l.type != null) {
      type = getTypeRefFromAnnotation(ctx, l.type!);
    }

    for (final li in l.variables) {
      final init = li.initializer;
      if (init != null) {
        final res = _parseExpression(init, ctx);
        if (ctx.locals.last.containsKey(li.name.name)) {
          throw ArgumentError('Cannot declare variable ${li.name.name} multiple times in the same scope');
        }
        ctx.locals.last[li.name.name] = Variable(res.scopeFrameOffset, type ?? res.type);
      }
    }
  }

  TypeRef getTypeRefFromAnnotation(DbcGenContext ctx, TypeAnnotation typeAnnotation) {
    if (!(typeAnnotation is NamedType)) {
      throw ArgumentError('No support for generic function types yet');
    }
    return ctx.visibleTypes[typeAnnotation.name.name]!;
  }

  TypeRef getTypeRef(DbcGenContext ctx, String name) {
    return ctx.visibleTypes[name]!;
  }

  Variable _pushBuiltinValue(BuiltinValue value, DbcGenContext ctx) {
    if (value.type == BuiltinValueType.intType) {
      pushOp(ctx, PushConstantInt.make(value.intval!), PushConstantInt.LEN);
      ctx.allocNest.last++;
      return Variable(ctx.scopeFrameOffset++, _intType);
    } else if (value.type == BuiltinValueType.stringType) {
      final op = PushConstantString.make(value.stringval!);
      pushOp(ctx, op, PushConstantString.len(op));
      ctx.allocNest.last++;
      return Variable(ctx.scopeFrameOffset++, _stringType);;
    } else {
      throw ArgumentError('Cannot push unknown builtin value type ${value.type}');
    }
  }

  BuiltinValue _parseLiteral(Literal l, DbcGenContext ctx) {
    if (l is IntegerLiteral) {
      return BuiltinValue(intval: l.value);
    } else if (l is SimpleStringLiteral) {
      return BuiltinValue(stringval: l.stringValue);
    }
    throw ArgumentError('Unknown literal type ${l.runtimeType}');
  }

  Variable _parseIdentifier(Identifier id, DbcGenContext ctx) {
    if (id is SimpleIdentifier) {
      for (var i = ctx.locals.length - 1; i >= 0; i--) {
        if (ctx.locals[i].containsKey(id.name)) {
          return ctx.locals[i][id.name]!;
        }
      }
      if (ctx.topLevelDeclarationPositions.containsKey(id.name)) {
        final declaration = ctx.topLevelDeclarationsMap[id.name];
        if (!(declaration is FunctionDeclaration)) {
          throw ArgumentError('No support for class identifiers');
        }
        TypeRef? returnType;
        if (declaration.returnType != null) {
          returnType = getTypeRefFromAnnotation(ctx, declaration.returnType!);
        };
        return Variable(
            -1, _functionType, methodOffset: ctx.topLevelDeclarationPositions[id.name], methodReturnType: returnType);
      }
    }
    throw ArgumentError('Unknown identifier ${id.runtimeType}');
  }
}

class DbcGenContext {
  DbcGenContext(this.sourceFile);

  int position = 0;
  int scopeFrameOffset = 0;
  String functionName = '';
  List<List<AstNode>> scopeNodes = [];
  List<Map<String, Variable>> locals = [];
  Map<String, Declaration> topLevelDeclarationsMap = {};
  Map<String, TypeRef> visibleTypes = {};
  Map<String, int> topLevelDeclarationPositions = {};
  List<int> allocNest = [0];
  int sourceFile;
}

class Variable {
  Variable(this.scopeFrameOffset, this.type, {this.methodOffset, this.methodReturnType});

  final int scopeFrameOffset;
  final TypeRef type;
  final int? methodOffset;
  final TypeRef? methodReturnType;
}

class StatementInfo {
  StatementInfo(this.position, {this.willAlwaysReturn = false, this.willAlwaysThrow = false});

  final int position;
  final bool willAlwaysReturn;
  final bool willAlwaysThrow;
}

class BuiltinValue {
  BuiltinValue({this.intval, this.doubleval, this.stringval}) {
    if (intval != null) {
      type = BuiltinValueType.intType;
    } else if (stringval != null) {
      type = BuiltinValueType.stringType;
    } else if (doubleval != null) {
      type = BuiltinValueType.doubleType;
    }
  }

  late BuiltinValueType type;
  final int? intval;
  final double? doubleval;
  final String? stringval;

  int get length {
    switch (type) {
      case BuiltinValueType.intType:
      case BuiltinValueType.doubleType:
        return 4;
      case BuiltinValueType.stringType:
        return 1 + stringval!.length;
    }
  }
}

enum BuiltinValueType { intType, stringType, doubleType }

class TypeRef {
  const TypeRef(this.file, this.name,
      {this.extendsType, this.implementsType = const [], this.withType = const [], this.genericParams = const [
      ], this.specifiedTypeArgs = const []});

  final int file;
  final String name;
  final TypeRef? extendsType;
  final List<TypeRef> implementsType;
  final List<TypeRef> withType;
  final List<GenericParam> genericParams;
  final List<TypeRef> specifiedTypeArgs;

  List<TypeRef> get allSupertypes => [if (extendsType != null) extendsType!, ...implementsType, ...withType];

  bool isAssignableTo(TypeRef slot, {List<TypeRef>? overrideGenerics}) {
    final generics = overrideGenerics ?? specifiedTypeArgs;

    if (this == slot) {
      for (var i = 0; i < generics.length; i++) {
        if (slot.specifiedTypeArgs.length >= i - 1) {
          if (!generics[i].isAssignableTo(slot.specifiedTypeArgs[i])) {
            return false;
          }
        }
      }
      return true;
    };

    for (final type in allSupertypes) {
      if (type.isAssignableTo(slot, overrideGenerics: generics)) {
        return true;
      };
    }
    return false;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is TypeRef && runtimeType == other.runtimeType && file == other.file && name == other.name;

  @override
  int get hashCode => file.hashCode ^ name.hashCode;

  @override
  String toString() {
    return name;
  }
}

class GenericParam {
  const GenericParam(this.name, this.extendsType);

  final String name;
  final TypeRef? extendsType;
}

const int _dartCoreFile = -1;
const TypeRef _dynamicType = TypeRef(_dartCoreFile, 'dynamic');
const TypeRef _objectType = TypeRef(_dartCoreFile, 'Object', extendsType: _dynamicType);
const TypeRef _numType = TypeRef(_dartCoreFile, 'num', extendsType: _objectType);
const TypeRef _intType = TypeRef(_dartCoreFile, 'int', extendsType: _numType);
const TypeRef _doubleType = TypeRef(_dartCoreFile, 'double', extendsType: _numType);
const TypeRef _stringType = TypeRef(_dartCoreFile, 'String', extendsType: _objectType);
const TypeRef _mapType = TypeRef(_dartCoreFile, 'Map', extendsType: _objectType);
const TypeRef _listType = TypeRef(_dartCoreFile, 'List', extendsType: _objectType);
const TypeRef _functionType = TypeRef(_dartCoreFile, 'Function', extendsType: _objectType);

const Map<String, TypeRef> _coreDeclarations = {
  'String': _stringType,
  'int': _intType,
  'double': _doubleType,
  'Map': _mapType,
  'List': _listType
};
