import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:dart_eval/src/eval/compiler/source.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/compiler/program.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/src/eval/runtime/ops/all_ops.dart';

import 'context.dart';
import 'errors.dart';
import 'offset_tracker.dart';

part 'compiler_builtins.dart';

class Compiler {
  final out = <DbcOp>[];

  Program compile(Map<String, Map<String, String>> packages) {
    var dartSourceSize = 0;
    final ctx = CompilerContext(0);

    final packageMap = <String, Map<String, int>>{};
    final indexMap = <int, List<String>>{};
    final partMap = <int, List<String>>{};
    final partOfMap = <int, String>{};
    final libraryMap = <String, int>{};
    final importMap = <int, List<ImportDirective>>{};
    final topLevelDeclarationsMap = <int, Map<String, Declaration>>{};
    final instanceDeclarationsMap = <int, Map<String, Map<String, Declaration>>>{};

    var fileIndex = 0;

    int? resolveUri(List<String> resolvedUriParts) {
      return packageMap[resolvedUriParts[0]]?[resolvedUriParts[1]];
    }

    List<String> resolvedUriParts(String currentPackage, String currentFile, String uri) {
      String package = currentPackage, file, targetFile;
      if (uri.startsWith('package:')) {
        final content = uri.substring(8);
        package = content.substring(0, content.indexOf('/'));
        file = content.substring(content.indexOf('/') + 1);
        targetFile = file;
      } else {
        file = uri;
        if (!currentFile.contains('/')) {
          targetFile = file;
        } else {
          final currentFileNest = currentFile.split('/');
          targetFile = [...currentFileNest.take(currentFileNest.length - 1), ...file.split('/')].join('/');
        }
      }
      return [package, targetFile];
    }

    packages.forEach((package, libraries) {
      packageMap[package] = {};

      libraries.forEach((filename, source) {
        dartSourceSize += source.length;
        final unit = _parse(source);

        final imports = <ImportDirective>[];
        var myIndex = libraryMap["'package:$package/$filename'"];

        for (final directive in unit.directives) {
          if (directive is PartDirective) {
            final uri = directive.uri.stringValue;
            if (uri == null) {
              throw CompileError('Part URIs cannot use string interpolation');
            }
            if (!uri.startsWith('package:') && uri.contains(':')) {
              throw CompileError('Invalid URI in part directive: starts with ${uri.split(':')[0]}:');
            }
            final uriParts = resolvedUriParts(package, filename, uri);
            final file = resolveUri(uriParts);
            if (file != null) {
              if (partOfMap[file] != "'$filename'") {
                throw CompileError('$package/$filename contains a part directive for $uri, '
                    'but there is no corresponding part of directive');
              }
              myIndex = file;
            } else {
              final idx = myIndex ?? (myIndex = fileIndex++);
              final formattedUri = 'package:${uriParts[0]}/${uriParts[1]}';
              if (!partMap.containsKey(idx)) {
                partMap[idx] = [formattedUri];
              } else {
                partMap[idx]!.add(formattedUri);
              }
            }
            libraryMap["'package:$package/$filename'"] = myIndex;
            indexMap[myIndex] = [package, filename];
          } else if (directive is PartOfDirective) {
            if (unit.directives.length > 1) {
              throw CompileError('"part of" when included must be the only directive in a part');
            }
            final uri = directive.uri?.stringValue;
            final library = directive.libraryName;
            if (uri == null && library == null) {
              throw CompileError('Part URIs cannot use string interpolation');
            }
            if (uri != null) {
              if (!uri.startsWith('package:') && uri.contains(':')) {
                throw CompileError('Invalid URI in part of directive: starts with ${uri.split(':')[0]}:');
              }
              final uriParts = resolvedUriParts(package, filename, uri);
              final file = resolveUri(uriParts);
              final formattedUri = 'package:${uriParts[0]}/${uriParts[1]}';
              final myFormattedUri = 'package:$package/$filename';
              if (file != null) {
                if (partMap[file] == null || !partMap[file]!.contains(myFormattedUri)) {
                  throw CompileError('$package/$filename contains a part of directive for $uri, '
                      'but there is no corresponding part directive');
                }
                partMap[file]!.remove(myFormattedUri);
                myIndex = file;
              } else {
                myIndex = libraryMap["'$formattedUri'"] ?? fileIndex++;
                libraryMap["'$formattedUri'"] = myIndex;
              }
              partOfMap[myIndex] = formattedUri;
            } else {
              throw CompileError('No support for named libraries yet');
            }
          } else if (directive is ImportDirective) {
            imports.add(directive);
          } else {
            throw CompileError('Unknown directive type ${directive.runtimeType}');
          }
        }

        myIndex ??= fileIndex++;
        packageMap[package]![filename] = myIndex;
        indexMap[myIndex] ??= [package, filename];
        importMap[myIndex] = imports;

        ctx.visibleTypes[myIndex] ??= {..._coreDeclarations};
        ctx.visibleDeclarations[myIndex] ??= {};
        topLevelDeclarationsMap[myIndex] ??= {};
        instanceDeclarationsMap[myIndex] ??= {};

        unit.declarations.forEach((d) {
          if (d is NamedCompilationUnitMember) {
            if (topLevelDeclarationsMap[myIndex]!.containsKey(d.name.name)) {
              throw CompileError('Cannot define "${d.name.name} twice in the same library"');
            }
            topLevelDeclarationsMap[myIndex]![d.name.name] = d;
            if (d is ClassDeclaration) {
              instanceDeclarationsMap[myIndex]![d.name.name] = {};
              ctx.visibleTypes[myIndex]![d.name.name] = TypeRef(myIndex!, d.name.name);
              d.members.forEach((member) {
                if (member is MethodDeclaration) {
                  instanceDeclarationsMap[myIndex]![d.name.name]![member.name.name] = member;
                } else if (member is FieldDeclaration) {
                  member.fields.variables.forEach((field) {
                    instanceDeclarationsMap[myIndex]![d.name.name]![field.name.name] = field;
                  });
                } else if (member is ConstructorDeclaration) {
                  topLevelDeclarationsMap[myIndex]!['${d.name.name}.${member.name?.name ?? ""}'] = member;
                } else {
                  throw CompileError('Not a NamedCompilationUnitMember');
                }
              });
            }
          } else {
            throw CompileError('Not a NamedCompilationUnitMember');
          }
        });

        ctx.visibleDeclarations[myIndex]!.addAll(topLevelDeclarationsMap[myIndex]!
            .map((key, value) => MapEntry(key, DeclarationOrPrefix(myIndex!, declaration: value))));
      });
    });

    importMap.forEach((file, imports) {
      final myUri = indexMap[file]!;
      for (final imp in imports) {
        final uri = imp.uri.stringValue;
        if (uri == null) {
          throw CompileError('Import URI is not a string');
        }
        final resolvedLibrary = resolveUri(resolvedUriParts(myUri[0], myUri[1], uri))!;
        ctx.visibleTypes[file] ??= {};
        ctx.visibleDeclarations[file] ??= {};
        var prefix = imp.prefix?.name ?? '';
        if (prefix != '') {
          prefix = '$prefix.';
        }
        ctx.visibleTypes[resolvedLibrary]!.forEach((key, value) {
          ctx.visibleTypes[file]!['$prefix$key'] = value;
        });
        if (prefix == '') {
          ctx.visibleDeclarations[file]!.addAll(topLevelDeclarationsMap[resolvedLibrary]!
              .map((key, value) => MapEntry(key, DeclarationOrPrefix(resolvedLibrary, declaration: value))));
        } else {
          ctx.visibleDeclarations[file]![prefix] =
              DeclarationOrPrefix(resolvedLibrary, children: topLevelDeclarationsMap[resolvedLibrary]);
        }
      }
    });

    ctx.topLevelDeclarationsMap = topLevelDeclarationsMap;
    ctx.instanceDeclarationsMap = instanceDeclarationsMap;

    topLevelDeclarationsMap.forEach((key, value) {
      ctx.topLevelDeclarationPositions[key] = {};
      ctx.instanceDeclarationPositions[key] = {};
      print('Generating package:${indexMap[key]!.join("/")}...');
      value.forEach((lib, declaration) {
        if (declaration is ConstructorDeclaration || declaration is MethodDeclaration) {
          return;
        }
        ctx.library = key;
        _parseDeclaration(declaration, ctx);
        ctx.scopeFrameOffset = 0;
        ctx.allocNest = [0];
      });
    });

    print('Compiled from $dartSourceSize characters Dart source');

    return Program(ctx.topLevelDeclarationPositions, ctx.instanceDeclarationPositions, ctx.offsetTracker.apply(out));
  }

  Runtime compileWriteAndLoad(Map<String, Map<String, String>> packages) {
    final program = compile(packages);

    final ob = program.write();

    return Runtime(ob.buffer.asByteData());
  }

  CompilationUnit _parse(String source) {
    final d = parseString(content: source, throwIfDiagnostics: false);
    if (d.errors.isNotEmpty) {
      for (final error in d.errors) {
        stderr.addError(error);
      }
      throw CompileError('Parsing error(s)');
    }
    return d.unit;
  }

  int pushOp(CompilerContext ctx, DbcOp op, int length) {
    out.add(op);
    ctx.position += length;
    return out.length - 1;
  }

  int rewriteOp(CompilerContext ctx, int where, DbcOp newOp, int lengthAdjust) {
    out[where] = newOp;
    ctx.position += lengthAdjust;
    return where;
  }

  int enterScope(CompilerContext ctx, AstNode scopeHost, int offset, String name) {
    final position = out.length;
    var op = PushScope.make(ctx.library, offset, name);
    pushOp(ctx, op, PushScope.len(op));
    ctx.locals.add({});
    return position;
  }

  void exitScope(CompilerContext ctx) {
    pushOp(ctx, PopScope.make(), PopScope.LEN);
    ctx.locals.removeLast();
  }

  int? _parseDeclaration(Declaration d, CompilerContext ctx,
      {Declaration? parent, int? fieldIndex, List<FieldDeclaration>? fields}) {
    if (d is ClassDeclaration) {
      ctx.instanceDeclarationPositions[ctx.library]![d.name.name] = [{}, {}, {}];
      final constructors = <ConstructorDeclaration>[];
      final fields = <FieldDeclaration>[];
      final methods = <MethodDeclaration>[];
      for (final m in d.members) {
        if (m is ConstructorDeclaration) {
          constructors.add(m);
        } else if (m is FieldDeclaration) {
          fields.add(m);
        } else {
          m as MethodDeclaration;
          methods.add(m);
        }
      }
      var i = 0;
      for (final m in <ClassMember>[...fields, ...methods, ...constructors]) {
        final _a = m is ConstructorDeclaration ? 0 : 1;
        ctx.scopeFrameOffset = _a;
        ctx.allocNest = [_a];
        _parseDeclaration(m, ctx, parent: d, fieldIndex: i, fields: fields);
        if (m is FieldDeclaration) {
          i += m.fields.length - 1;
        }
        i++;
      }
      ctx.scopeFrameOffset = 0;
      ctx.allocNest = [0];
    } else if (d is MethodDeclaration) {
      final b = d.body;
      if (!(parent is NamedCompilationUnitMember)) {
        throw CompileError('Parent of a method declaration must be named');
      }
      final pos = enterScope(ctx, d, d.offset, parent.name.name + '.' + d.name.name + '()');

      StatementInfo? stInfo;
      if (b is BlockFunctionBody) {
        stInfo = _parseBlock(
            b.block, AlwaysReturnType.fromAnnotation(ctx, ctx.library, d.returnType, _dynamicType), ctx,
            name: d.name.name + '()');
      } else {
        throw CompileError('Unknown function body type ${b.runtimeType}');
      }

      if (stInfo == null || !(stInfo.willAlwaysReturn || stInfo.willAlwaysThrow)) {
        pushOp(ctx, Return.make(-1), Return.LEN);
      }

      ctx.locals.removeLast();

      if (d.isStatic) {
        ctx.topLevelDeclarationPositions[ctx.library]!['${parent.name.name}.${d.name.name}'] = pos;
      } else {
        ctx.instanceDeclarationPositions[ctx.library]![parent.name.name]![2][d.name.name] = pos;
      }
      return pos;
    } else if (d is FunctionDeclaration) {
      ctx.topLevelDeclarationPositions[ctx.library]![d.name.name] = enterScope(ctx, d, d.offset, d.name.name + '()');
      final b = d.functionExpression.body;
      StatementInfo? stInfo;
      if (b is BlockFunctionBody) {
        stInfo = _parseBlock(
            b.block, AlwaysReturnType.fromAnnotation(ctx, ctx.library, d.returnType, _dynamicType), ctx,
            name: d.name.name + '()');
      }
      if (stInfo == null || !(stInfo.willAlwaysReturn || stInfo.willAlwaysThrow)) {
        pushOp(ctx, Return.make(-1), Return.LEN);
      }
      ctx.locals.removeLast();
    } else if (d is FieldDeclaration) {
      parent as ClassDeclaration;
      var _fieldIndex = fieldIndex!;
      for (final field in d.fields.variables) {
        final pos = enterScope(ctx, d, d.offset, parent.name.name + '.' + field.name.name + ' (get)');
        pushOp(ctx, PushObjectPropertyImpl.make(0, _fieldIndex), PushObjectPropertyImpl.LEN);
        pushOp(ctx, Return.make(1), Return.LEN);
        ctx.instanceDeclarationPositions[ctx.library]![parent.name.name]![0][field.name.name] = pos;

        if (!(field.isFinal || field.isConst)) {
          final setterPos = enterScope(ctx, d, d.offset, parent.name.name + '.' + field.name.name + ' (set)');
          pushOp(ctx, SetObjectPropertyImpl.make(0, _fieldIndex, 1), SetObjectPropertyImpl.LEN);
          pushOp(ctx, Return.make(1), Return.LEN);
          ctx.instanceDeclarationPositions[ctx.library]![parent.name.name]![1][field.name.name] = setterPos;
        }

        _fieldIndex++;
      }
    } else if (d is ConstructorDeclaration) {
      _parseConstructorDeclaration(ctx, d, parent as ClassDeclaration, fields!);
    } else {
      throw CompileError('No support for ${d.runtimeType}');
    }
  }

  void _parseConstructorDeclaration(
      CompilerContext ctx, ConstructorDeclaration d, ClassDeclaration parent, List<FieldDeclaration> fields) {
    final n = '${parent.name.name}.${d.name?.name ?? ""}';

    ctx.topLevelDeclarationPositions[ctx.library]![n] = enterScope(ctx, d, d.offset, '$n()');

    ctx.allocNest.add(d.parameters.parameters.length);
    ctx.scopeFrameOffset = d.parameters.parameters.length;

    SuperConstructorInvocation? $superInitializer;
    final otherInitializers = <ConstructorInitializer>[];
    for (final initializer in d.initializers) {
      if (initializer is SuperConstructorInvocation) {
        $superInitializer = initializer;
      } else if ($superInitializer != null) {
        throw CompileError('Super constructor invocation must be last in the initializer list');
      } else {
        otherInitializers.add(initializer);
      }
    }

    final fieldIndices = <String, int>{};
    var i = 0;
    for (final fd in fields) {
      for (final field in fd.fields.variables) {
        fieldIndices[field.name.name] = i;
        i++;
      }
    }

    final $extends = parent.extendsClause;
    final Variable $super;

    /*if ($extends == null) {
      $super = _pushBuiltinValue(BuiltinValue(), ctx);
    } else {
      final extendsWhat = ctx.visibleDeclarations[ctx.library]![$extends.superclass.name]!;

      if ($superInitializer != null) {
        final argsPair = _parseArgumentList(ctx, $superInitializer.argumentList);
        final _args = argsPair.first;
        final _namedArgs = argsPair.second;

        AlwaysReturnType? mReturnType;
        final _argTypes = _args.map((e) => e.type).toList();
        final _namedArgTypes = _namedArgs.map((key, value) => MapEntry(key, value.type));


        //final method = _parseIdentifier($superInitializer.constructorName, ctx);
        if (method.methodOffset == null) {
          throw CompileError('Cannot call ${e.methodName.name} as it is not a valid method');
        }
        final offset = method.methodOffset!;
        final loc = pushOp(ctx, Call.make(offset.offset ?? -1), Call.LEN);
        if (offset.offset == null) {
          ctx.offsetTracker.setOffset(loc, offset);
        }
        mReturnType = method.methodReturnType?.toAlwaysReturnType(_argTypes, _namedArgTypes) ??
            AlwaysReturnType(_dynamicType, true);

        pushOp(ctx, PushReturnValue.make(), PushReturnValue.LEN);
        ctx.allocNest.last++;

        return Variable(ctx.scopeFrameOffset++, mReturnType?.type ?? _dynamicType, mReturnType?.nullable ?? true,
            boxed: L == null && !_unboxedAcrossFunctionBoundaries.contains(mReturnType?.type));
      }
    }*/

    $super = _pushBuiltinValue(BuiltinValue(), ctx);

    final op = CreateClass.make(ctx.library, $super.scopeFrameOffset, parent.name.name, i);
    pushOp(ctx, op, CreateClass.len(op));
    final instOffset = ctx.scopeFrameOffset++;
    final resolvedParams = _resolveFPLDefaults(ctx, d.parameters, false);

    i = 0;

    for (final param in resolvedParams) {
      if (param is FieldFormalParameter) {
        pushOp(ctx, SetObjectPropertyImpl.make(instOffset, fieldIndices[param.identifier.name]!, i),
            SetObjectPropertyImpl.LEN);
      } else {
        param as SimpleFormalParameter;
        var type = _dynamicType;
        if (param.type != null) {
          type = TypeRef.fromAnnotation(ctx, ctx.library, param.type!);
        }
        ctx.locals.last[param.identifier!.name] = Variable(i, type, param.type?.question != null);
      }

      i++;
    }

    for (final init in otherInitializers) {
      if (init is ConstructorFieldInitializer) {
        final V = _parseExpression(init.expression, ctx);
        pushOp(ctx, SetObjectPropertyImpl.make(instOffset, fieldIndices[init.fieldName.name]!, V.scopeFrameOffset),
            SetObjectPropertyImpl.LEN);
      } else {
        throw CompileError('${init.runtimeType} initializer is not supported');
      }
    }

    pushOp(ctx, Return.make(instOffset), Return.LEN);
    ctx.locals.removeLast();
  }

  List<NormalFormalParameter> _resolveFPLDefaults(CompilerContext ctx, FormalParameterList fpl, bool isInstanceMethod) {
    final normalized = <NormalFormalParameter>[];
    var hasEncounteredOptionalPositionalParam = false;
    var hasEncounteredNamedParam = false;
    var _paramIndex = isInstanceMethod ? 1 : 0;
    for (final param in fpl.parameters) {
      if (param.isNamed) {
        if (hasEncounteredOptionalPositionalParam) {
          throw CompileError('Cannot mix named and optional positional parameters');
        }
        hasEncounteredNamedParam = true;
      } else if (param.isOptionalPositional) {
        if (hasEncounteredNamedParam) {
          throw CompileError('Cannot mix named and optional positional parameters');
        }
        hasEncounteredOptionalPositionalParam = true;
      }

      if (param is DefaultFormalParameter) {
        normalized.add(param.parameter);
        if (param.defaultValue != null) {
          final _reserve = JumpIfNonNull.make(_paramIndex, -1);
          final _reserveOffset = pushOp(ctx, _reserve, JumpIfNonNull.LEN);
          final V = _parseExpression(param.defaultValue!, ctx);
          pushOp(ctx, CopyValue.make(_paramIndex, V.scopeFrameOffset), CopyValue.LEN);
          rewriteOp(ctx, _reserveOffset, JumpIfNonNull.make(_paramIndex, out.length), 0);
        }
      } else {
        param as NormalFormalParameter;
        normalized.add(param);
      }

      _paramIndex++;
    }
    return normalized;
  }

  Pair<List<Variable>, Map<String, Variable>> _parseArgumentList(CompilerContext ctx, ArgumentList argumentList) {
    final _args = <Variable>[];
    final _namedArgs = <String, Variable>{};
    var hasEncounteredNamedArg = false;

    for (final arg in argumentList.arguments) {
      if (arg is NamedExpression) {
        _namedArgs[arg.name.label.name] = _parseExpression(arg.expression, ctx);
        hasEncounteredNamedArg = true;
      } else {
        if (hasEncounteredNamedArg) {
          throw CompileError('Positional arguments cannot occur after named arguments');
        }
        _args.add(_parseExpression(arg, ctx));
      }
    }

    for (final arg in _args) {
      final argOp = PushArg.make(arg.scopeFrameOffset);
      pushOp(ctx, argOp, PushArg.LEN);
    }

    for (final arg in _namedArgs.entries) {
      final argOp = PushNamedArg.make(arg.value.scopeFrameOffset, arg.key);
      pushOp(ctx, argOp, PushNamedArg.len(argOp));
    }

    return Pair(_args, _namedArgs);
  }

  StatementInfo _parseStatement(Statement s, AlwaysReturnType? expectedReturnType, CompilerContext ctx) {
    if (s is Block) {
      return _parseBlock(s, expectedReturnType, ctx);
    } else if (s is VariableDeclarationStatement) {
      _parseVariableDeclarationList(s.variables, ctx);
      return StatementInfo(-1);
    } else if (s is ExpressionStatement) {
      _parseExpression(s.expression, ctx);
      return StatementInfo(-1);
    } else if (s is ReturnStatement) {
      _parseReturn(s, expectedReturnType, ctx);
      return StatementInfo(-1, willAlwaysReturn: true);
    }
    return StatementInfo(-1);
  }

  StatementInfo _parseBlock(Block b, AlwaysReturnType? expectedReturnType, CompilerContext ctx,
      {String name = '<block>'}) {
    final position = out.length;
    ctx.allocNest.add(0);

    var willAlwaysReturn = false;
    var willAlwaysThrow = false;

    for (final s in b.statements) {
      final stInfo = _parseStatement(s, expectedReturnType, ctx);

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

  void _parseReturn(ReturnStatement s, AlwaysReturnType? expectedReturnType, CompilerContext ctx) {
    if (s.expression == null) {
      pushOp(ctx, Return.make(-1), Return.LEN);
    } else {
      final expected = expectedReturnType?.type ?? _dynamicType;
      var value = _parseExpression(s.expression!, ctx);
      if (!value.type.isAssignableTo(expected)) {
        throw CompileError('Cannot return ${value.type} (expected: $expected)');
      }
      if (_unboxedAcrossFunctionBoundaries.contains(expected)) {
        if (value.boxed) {
          value = _unbox(ctx, value);
        }
      } else if (!value.boxed) {
        value = _box(ctx, value);
      }
      pushOp(ctx, Return.make(value.scopeFrameOffset), Return.LEN);
    }
  }

  Variable _parseExpression(Expression e, CompilerContext ctx) {
    if (e is Literal) {
      final literalValue = _parseLiteral(e, ctx);
      return _pushBuiltinValue(literalValue, ctx);
    } else if (e is AssignmentExpression) {
      final L = _parseExpression(e.leftHandSide, ctx);
      final R = _parseExpression(e.rightHandSide, ctx);

      if (!R.type.isAssignableTo(L.type)) {
        throw CompileError('Syntax error: cannot assign value of type ${R.type} to ${L.type}');
      }

      pushOp(ctx, CopyValue.make(L.scopeFrameOffset, R.scopeFrameOffset), CopyValue.LEN);
      return L;
    } else if (e is Identifier) {
      return _parseIdentifier(e, ctx);
    } else if (e is MethodInvocation) {
      return _parseMethodInvocation(ctx, e);
    } else if (e is BinaryExpression) {
      return _parseBinaryExpression(ctx, e);
    }

    throw CompileError('Unknown expression type ${e.runtimeType}');
  }

  Variable _parseBinaryExpression(CompilerContext ctx, BinaryExpression e) {
    var L = _parseExpression(e.leftOperand, ctx);
    var R = _parseExpression(e.rightOperand, ctx);

    final supportedIntIntrinsicOps = {TokenType.PLUS};

    if (L.type == _intType && supportedIntIntrinsicOps.contains(e.operator.type)) {
      if (L.boxed) {
        L = _unbox(ctx, L);
      }
      if (R.boxed) {
        R = _unbox(ctx, R);
      }
      if (e.operator.type == TokenType.PLUS) {
        // Integer intrinsic add
        pushOp(ctx, AddInts.make(L.scopeFrameOffset, R.scopeFrameOffset), AddInts.LEN);
        ctx.allocNest.last++;
        return Variable(ctx.scopeFrameOffset++, _intType, null, boxed: false);
      }
      throw CompileError('Internal error: Invalid intrinsic int op ${e.operator.type}');
    }

    if (!L.boxed) {
      L = _box(ctx, L);
    }

    if (!R.boxed) {
      R = _box(ctx, R);
    }

    final opMap = {TokenType.PLUS: '+', TokenType.MINUS: '-', TokenType.SLASH: '/', TokenType.STAR: '*'};

    var method = opMap[e.operator.type] ?? (throw CompileError('Unknown binary operator ${e.operator.type}'));

    final addendOp = PushArg.make(R.scopeFrameOffset);
    pushOp(ctx, addendOp, PushArg.LEN);

    final op = InvokeDynamic.make(L.scopeFrameOffset, method);
    pushOp(ctx, op, InvokeDynamic.len(op));

    pushOp(ctx, PushReturnValue.make(), PushReturnValue.LEN);
    ctx.allocNest.last++;

    final returnType = _queryMethodReturnType(ctx, L.type, method, [R.type], {});

    return Variable(ctx.scopeFrameOffset++, returnType?.type ?? _dynamicType, returnType?.nullable ?? true, boxed: true)
      ..frameIndex = ctx.locals.length - 1;
  }

  Variable _unbox(CompilerContext ctx, Variable V) {
    assert(V.boxed);
    pushOp(ctx, Unbox.make(V.scopeFrameOffset), Unbox.LEN);
    ctx.allocNest.last++;
    return ctx.locals[V.frameIndex!][V.name!] = Variable(ctx.scopeFrameOffset++, V.type, V.nullable, boxed: false)
      ..name = V.name
      ..frameIndex = V.frameIndex;
  }

  Variable _box(CompilerContext ctx, Variable V) {
    assert(!V.boxed);
    if (V.type != _intType) {
      throw CompileError('Can only box ints for now');
    }
    pushOp(ctx, BoxInt.make(V.scopeFrameOffset), BoxInt.LEN);
    ctx.allocNest.last++;
    final V2 = Variable(ctx.scopeFrameOffset++, _intType, V.nullable, boxed: true)
      ..name = V.name
      ..frameIndex = V.frameIndex;
    if (V.name != null) {
      ctx.locals[V.frameIndex!][V.name!] = V2;
    }
    return V2;
  }

  Variable _parseMethodInvocation(CompilerContext ctx, MethodInvocation e) {
    Variable? L;
    if (e.target != null) {
      L = _parseExpression(e.target!, ctx);
      // Push 'this'
      pushOp(ctx, PushArg.make(L.scopeFrameOffset), PushArg.LEN);
    }

    final argsPair = _parseArgumentList(ctx, e.argumentList);
    final _args = argsPair.first;
    final _namedArgs = argsPair.second;

    AlwaysReturnType? mReturnType;
    final _argTypes = _args.map((e) => e.type).toList();
    final _namedArgTypes = _namedArgs.map((key, value) => MapEntry(key, value.type));

    if (L != null) {
      final op = InvokeDynamic.make(L.scopeFrameOffset, e.methodName.name);
      pushOp(ctx, op, InvokeDynamic.len(op));

      mReturnType = _queryMethodReturnType(ctx, L.type, e.methodName.name, _argTypes, _namedArgTypes);
    } else {
      final method = _parseIdentifier(e.methodName, ctx);
      if (method.methodOffset == null) {
        throw CompileError('Cannot call ${e.methodName.name} as it is not a valid method');
      }
      final offset = method.methodOffset!;
      final loc = pushOp(ctx, Call.make(offset.offset ?? -1), Call.LEN);
      if (offset.offset == null) {
        ctx.offsetTracker.setOffset(loc, offset);
      }
      mReturnType = method.methodReturnType?.toAlwaysReturnType(_argTypes, _namedArgTypes) ??
          AlwaysReturnType(_dynamicType, true);
    }

    pushOp(ctx, PushReturnValue.make(), PushReturnValue.LEN);
    ctx.allocNest.last++;

    return Variable(ctx.scopeFrameOffset++, mReturnType?.type ?? _dynamicType, mReturnType?.nullable ?? true,
        boxed: L == null && !_unboxedAcrossFunctionBoundaries.contains(mReturnType?.type));
  }

  void _parseVariableDeclarationList(VariableDeclarationList l, CompilerContext ctx) {
    TypeRef? type;
    if (l.type != null) {
      type = TypeRef.fromAnnotation(ctx, ctx.library, l.type!);
    }
    final nullable = l.type?.question != null;

    for (final li in l.variables) {
      final init = li.initializer;
      if (init != null) {
        final res = _parseExpression(init, ctx);
        if (ctx.locals.last.containsKey(li.name.name)) {
          throw CompileError('Cannot declare variable ${li.name.name} multiple times in the same scope');
        }
        ctx.locals.last[li.name.name] = Variable(res.scopeFrameOffset, type ?? res.type, nullable, boxed: res.boxed)
          ..name = li.name.name
          ..frameIndex = ctx.locals.length - 1;
      }
    }
  }

  TypeRef getTypeRefFromClass(CompilerContext ctx, int library, ClassDeclaration cls) {
    return ctx.visibleTypes[library]![cls.name.name]!;
  }

  TypeRef getTypeRef(CompilerContext ctx, String name) {
    return ctx.visibleTypes[ctx.library]![name]!;
  }

  AlwaysReturnType? _queryMethodReturnType(
      CompilerContext ctx, TypeRef type, String method, List<TypeRef?> argTypes, Map<String, TypeRef?> namedArgTypes) {
    if (_knownMethods[type] != null && _knownMethods[type]!.containsKey(method)) {
      final knownMethod = _knownMethods[type]![method]!;
      final returnType = knownMethod.returnType;
      if (returnType == null) {
        return null;
      }
      return returnType.toAlwaysReturnType(argTypes, namedArgTypes);
    }

    return AlwaysReturnType.fromInstanceMethod(ctx, type, method, argTypes, namedArgTypes, _dynamicType);
  }

  Variable _pushBuiltinValue(BuiltinValue value, CompilerContext ctx) {
    if (value.type == BuiltinValueType.intType) {
      pushOp(ctx, PushConstantInt.make(value.intval!), PushConstantInt.LEN);
      ctx.allocNest.last++;
      return Variable(ctx.scopeFrameOffset++, _intType, null, boxed: false);
    } else if (value.type == BuiltinValueType.stringType) {
      final op = PushConstantString.make(value.stringval!);
      pushOp(ctx, op, PushConstantString.len(op));
      ctx.allocNest.last++;
      return Variable(ctx.scopeFrameOffset++, _stringType, null, boxed: false);
    } else if (value.type == BuiltinValueType.nullType) {
      final op = PushNull.make();
      pushOp(ctx, op, PushNull.LEN);
      ctx.allocNest.last++;
      return Variable(ctx.scopeFrameOffset++, _nullType, true, boxed: false);
    } else {
      throw CompileError('Cannot push unknown builtin value type ${value.type}');
    }
  }

  BuiltinValue _parseLiteral(Literal l, CompilerContext ctx) {
    if (l is IntegerLiteral) {
      return BuiltinValue(intval: l.value);
    } else if (l is SimpleStringLiteral) {
      return BuiltinValue(stringval: l.stringValue);
    } else if (l is NullLiteral) {
      return BuiltinValue();
    }
    throw CompileError('Unknown literal type ${l.runtimeType}');
  }

  Variable _parseIdentifier(Identifier id, CompilerContext ctx) {
    if (id is SimpleIdentifier) {
      for (var i = ctx.locals.length - 1; i >= 0; i--) {
        if (ctx.locals[i].containsKey(id.name)) {
          return ctx.locals[i][id.name]!..frameIndex = i;
        }
      }

      final declaration = ctx.visibleDeclarations[ctx.library]![id.name]!;
      final decl = declaration.declaration!;

      if (!(decl is FunctionDeclaration)) {
        decl as ClassDeclaration;

        final returnType = getTypeRefFromClass(ctx, declaration.sourceLib, decl);
        final DeferredOrOffset offset;

        if (ctx.topLevelDeclarationPositions[declaration.sourceLib]?.containsKey(id.name + '.') ?? false) {
          offset = DeferredOrOffset(
              file: declaration.sourceLib, offset: ctx.topLevelDeclarationPositions[ctx.library]![id.name + '.']);
        } else {
          offset = DeferredOrOffset(file: declaration.sourceLib, name: id.name + '.');
        }

        return Variable(-1, _functionType, null,
            methodOffset: offset, methodReturnType: AlwaysReturnType(returnType, false));
      }

      TypeRef? returnType;
      var nullable = true;
      if (decl.returnType != null) {
        returnType = TypeRef.fromAnnotation(ctx, declaration.sourceLib, decl.returnType!);
        nullable = decl.returnType!.question != null;
      }

      final DeferredOrOffset offset;
      if (ctx.topLevelDeclarationPositions[declaration.sourceLib]?.containsKey(id.name) ?? false) {
        offset = DeferredOrOffset(
            file: declaration.sourceLib, offset: ctx.topLevelDeclarationPositions[ctx.library]![id.name]);
      } else {
        offset = DeferredOrOffset(file: declaration.sourceLib, name: id.name);
      }

      return Variable(-1, _functionType, null,
          methodOffset: offset, methodReturnType: AlwaysReturnType(returnType, nullable));
    }
    throw CompileError('Unknown identifier ${id.runtimeType}');
  }
}

class StatementInfo {
  StatementInfo(this.position, {this.willAlwaysReturn = false, this.willAlwaysThrow = false});

  final int position;
  final bool willAlwaysReturn;
  final bool willAlwaysThrow;
}

const int _dartCoreFile = -1;

class Pair<T, T2> {
  Pair(this.first, this.second);

  T first;
  T2 second;
}

class A {
  A({this.q = "ada"});

  final String q;
}
