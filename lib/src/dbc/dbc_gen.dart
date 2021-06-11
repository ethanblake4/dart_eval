
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/dbc/dbc_executor.dart';
import 'package:dart_eval/src/dbc/dbc_writer.dart';

class DbcGen {
  final out = <DbcOp>[];

  void generate(String source) {
    final d = parseString(content: source, throwIfDiagnostics: false);

    if (d.errors.isNotEmpty) {
      d.errors.forEach((element) {
        print(element);
      });
      throw ArgumentError();
    }

    final ctx = DbcGenContext(0);

    d.unit.declarations.forEach((d) {
      _parseDeclaration(d, ctx);
    });

    final ob = DbcWriter().write(out);

    DbcExecutor(ob.buffer.asByteData()).execute();
  }

  void pushOp(DbcGenContext ctx, DbcOp op, int length) {
    out.add(op);
    ctx.position += length;
  }

  void enterScope(DbcGenContext ctx, int offset, String name) {
    var op = PushScope.make(ctx.sourceFile, offset, name);
    pushOp(ctx, op, PushScope.len(op));
    ctx.enterScope();
  }

  void exitScope(DbcGenContext ctx) {
    pushOp(ctx, PopScope.make(), PopScope.LEN);
    ctx.exitScope();
  }

  void _parseDeclaration(Declaration d, DbcGenContext ctx) {
    if (d is ClassDeclaration) {
      for (final m in d.members) {
        _parseDeclaration(m, ctx);
      }
    } else if (d is MethodDeclaration) {
      ctx.jumplist['${d.name.name}'] = ctx.position;
      ctx.functionName = d.name.name;
      final b = d.body;
      if (b is BlockFunctionBody) {
        _parseBlock(b.block, ctx, name: d.name.name + '()');
      }
    } else if (d is FunctionDeclaration) {
      ctx.jumplist['${d.name.name}'] = ctx.position;
      ctx.functionName = d.name.name;
      final b = d.functionExpression.body;
      if (b is BlockFunctionBody) {
        _parseBlock(b.block, ctx, name: d.name.name + '()');
      }
    }
  }

  void _parseStatement(Statement s, DbcGenContext ctx) {
    if (s is Block) {
      _parseBlock(s, ctx);
    } else if (s is VariableDeclarationStatement) {
      _parseVariableDeclarationList(s.variables, ctx);
    } else if (s is ExpressionStatement) {
      _parseExpression(s.expression, ctx, canReturnValue: true, forSet: false);
    } else if (s is ReturnStatement) {
      _parseReturn(s, ctx);
    }
  }

  void _parseReturn(ReturnStatement r, DbcGenContext ctx) {
    int l;
    if (r.expression == null) {
      l = ctx.newRegister(Dbc.I32_LEN);
      pushOp(ctx, Setvc.make(l, 0), Setvc.LEN);
    } else {
      l = _parseExpression(r.expression!, ctx).toRegister(false);
    }
    if(ctx.functionName == 'main') {
      pushOp(ctx, Exit.make(l), Exit.LEN);
    } else {
      pushOp(ctx, Setrv.make(l), Setrv.LEN);
    }
  }

  void _parseBlock(Block b, DbcGenContext ctx, {String name = '<block>'}) {
    enterScope(ctx, b.offset, name);
    for (final s in b.statements) {
      _parseStatement(s, ctx);
    }
    exitScope(ctx);
  }

  void _parseVariableDeclarationList(VariableDeclarationList l, DbcGenContext ctx) {
    for (final li in l.variables) {
      final init = li.initializer;
      if(init != null) {
        final res = _parseExpression(init, ctx, canReturnValue: true);
        if (res.type == ResultReference.TYPE_VALUE) {
          final v = res.value!;
          final _ol = v.toConstantStack(ctx);
          pushOp(ctx, _ol.op, _ol.length);
          ctx.scopeAdd(li.name.name, Variable(_ol.register, li.isFinal, v));
        } else if (res.type == ResultReference.TYPE_VARIABLE) {
          final r = ctx.newRegister();
          pushOp(ctx, Setvv.make(r, res.toRegister(false)), Setvv.LEN);
          ctx.scopeAdd(li.name.name, Variable(r, li.isFinal, res.variable!.value));
        } else if (res.type == ResultReference.TYPE_REGISTER) {
          final r = ctx.newRegister();
          pushOp(ctx, Setvv.make(r, res.register!), Setvv.LEN);
          ctx.scopeAdd(li.name.name, Variable(r, li.isFinal, null));
        }
      }
    }
  }

  ResultReference _parseExpression(Expression e, DbcGenContext ctx, {bool canReturnValue = false, bool forSet = false}) {

    if (e is AssignmentExpression) {
      final R = _parseExpression(e.rightHandSide, ctx, canReturnValue: true, forSet: false);
      final L = _parseExpression(e.leftHandSide, ctx, canReturnValue: false, forSet: true);

      if (L.type != ResultReference.TYPE_VARIABLE && L.type != ResultReference.TYPE_REGISTER) {
        throw ParseError('Assignment: LHS is not a register');
      }

      if (R.type == ResultReference.TYPE_VALUE) {
        final _ol = R.value!.toConstantStack(ctx, register: L.register);
        pushOp(ctx, _ol.op, _ol.length);
      } else if (R.type == ResultReference.TYPE_VARIABLE || R.type == ResultReference.TYPE_REGISTER) {
        pushOp(ctx, Setvv.make(L.toRegister(true), R.toRegister(false)), Setvv.LEN);
      } else {
        throw ParseError('Cannot assign: unknown reference type');
      }
      return L;
    } else if (e is Literal) {
      return _parseLiteral(e, ctx, canReturnValue: canReturnValue, forSet: forSet);
    } else if (e is Identifier) {
      return _parseIdentifier(e, ctx, canReturnValue: canReturnValue, forSet: forSet);
    }
    throw ParseError('Unknown expression ${e.runtimeType}');
  }

  ResultReference _parseLiteral(Literal e, DbcGenContext ctx, {bool canReturnValue = false, bool forSet = false}) {
    if (e is IntegerLiteral) {
      final v = e.value;
      if (v == null) {
        throw ParseError('Not a valid int value');
      }
      if (canReturnValue) {
        return BuiltinValue(intval: v).toResultRef();
      }
      final l = ctx.newRegister(Dbc.I32_LEN);
      pushOp(ctx, Setvc.make(l, v), Setvc.LEN);
      return ResultReference(ResultReference.TYPE_VARIABLE, register: l);
    } else if (e is StringLiteral) {
      final v = e.stringValue;
      if (v == null) {
        throw ParseError('Not a valid string value');
      }
      if (canReturnValue) {
        return BuiltinValue(stringval: v).toResultRef();
      }
      final len = Dbc.istr_len(v);
      final l = ctx.newRegister(len);
      final op = Setvcstr.make(l, v);
      pushOp(ctx, op, Setvcstr.len(op));

      return ResultReference(ResultReference.TYPE_REGISTER, register: l);
    }
    throw ParseError('Unknown literal ${e.runtimeType}');
  }

  ResultReference _parseIdentifier(Identifier id, DbcGenContext ctx, {bool canReturnValue = false, bool forSet = false}) {
    if (id is SimpleIdentifier) {
      final v = ctx.scopeLookup(id.name);
      if (v == null) {
        throw ParseError('No variable in scope $v');
      }
      if(v.isFinal && forSet) {
        throw ParseError('Cannot assign a value to a final variable ${id.name}');
      }
      if (canReturnValue && v.isFinal) {
        return ResultReference(ResultReference.TYPE_VALUE, value: v.value);
      }

      return ResultReference(ResultReference.TYPE_VARIABLE, variable: v);
    }
    throw ParseError('Unknown identifier ${id.runtimeType}');
  }
}

class ResultReference {
  ResultReference(this.type, {this.variable, this.value, this.register});

  static const int TYPE_VARIABLE = 0;
  static const int TYPE_OBJECT_PROPERTYREF = 1;
  static const int TYPE_VALUE = 2;
  static const int TYPE_REGISTER = 3;

  final int type;
  final Variable? variable;
  final BuiltinValue? value;
  final int? register;

  int toRegister(bool set) {
    if (type == TYPE_REGISTER) {
      return register!;
    } else if (type == TYPE_VARIABLE) {
      return set ? variable!.set() : variable!.get();
    }
    throw ParseError('Cannot convert reference to register');
  }
}

class ParseError extends ArgumentError {
  ParseError(String message) : super(message);
}

class DbcGenContext {
  DbcGenContext(this.sourceFile);

  int position = 0;
  String functionName = '';
  List<Map<String, Variable>> scopeStack = [];
  int registerPos = 0;
  Map<String, int> jumplist = {};
  int sourceFile;

  Variable? scopeLookup(String name) {
    for(var frame = scopeStack.length; frame > 0; frame--) {
      if (scopeStack[frame - 1].containsKey(name)) {
        return scopeStack[frame - 1][name];
      }
    }
  }

  void enterScope() {
    scopeStack.add(<String, Variable>{});
  }

  void exitScope() {
    scopeStack.removeLast();
  }

  void scopeAdd(String name, Variable v) {
    scopeStack.last[name] = v;
  }

  int newRegister([int len = 0]) {
    final r = registerPos;
    registerPos += 1;
    return r;
  }
}

class Variable {
  Variable(this._register, this.isFinal, this.value) : _gets = 0, _sets = 0;

  final int _register;

  bool isFinal;
  BuiltinValue? value;

  int _gets;
  int _sets;

  int get() {
    _gets++;
    return _register;
  }

  int set() {
    _sets++;
    return _register;
  }
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

  ResultReference toResultRef() {
    return ResultReference(ResultReference.TYPE_VALUE, value: this);
  }

  OpAndLen toConstantStack(DbcGenContext ctx, {int? register}) {
    switch (type) {
      case BuiltinValueType.intType:
        final reg = register ?? ctx.newRegister(Setvc.LEN);
        return OpAndLen(Setvc.make(reg, intval!), Setvc.LEN, reg);
      case BuiltinValueType.stringType:
        final len = Setvcstr.lenX(stringval!);
        final reg = register ?? ctx.newRegister(len);
        return OpAndLen(Setvcstr.make(reg, stringval!), len, reg);
      default:
        throw ParseError('cannot generate constant for $type');
    }
  }
}

class OpAndLen {
  const OpAndLen(this.op, this.length, this.register);

  final DbcOp op;
  final int length;
  final int register;
}

enum BuiltinValueType {
  intType,
  stringType,
  doubleType
}