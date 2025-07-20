import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/declaration/constructor.dart';
import 'package:dart_eval/src/eval/compiler/declaration/declaration.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/helpers/argument_list.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';
import 'package:dart_eval/src/eval/compiler/scope.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

void compileEnumDeclaration(CompilerContext ctx, EnumDeclaration d,
    {bool statics = false}) {
  final type = TypeRef.lookupDeclaration(ctx, ctx.library, d);
  final $runtimeType = ctx.typeRefIndexMap[type];
  final clsName = d.name.lexeme;
  ctx.instanceDeclarationPositions[ctx.library]![clsName] = [
    {},
    {},
    {},
    $runtimeType
  ];
  ctx.instanceGetterIndices[ctx.library]![clsName] = {};
  final constructors = <ConstructorDeclaration>[];
  final fields = <FieldDeclaration>[];
  final methods = <MethodDeclaration>[];
  for (final m in d.members) {
    if (m is ConstructorDeclaration) {
      constructors.add(m);
    } else if (m is FieldDeclaration) {
      if (!m.isStatic) {
        fields.add(m);
      }
    } else {
      m as MethodDeclaration;
      methods.add(m);
    }
  }
  var i = 0;
  if (constructors.isEmpty) {
    ctx.resetStack(position: 0);
    ctx.currentClass = d;
    compileDefaultConstructor(ctx, d, fields);
  }

  ctx.resetStack(position: 0);
  final pos = beginMethod(ctx, d, d.offset, '$clsName.index (get)');
  ctx.pushOp(PushObjectPropertyImpl.make(0, 0), PushObjectPropertyImpl.length);
  ctx.pushOp(Return.make(1), Return.LEN);
  ctx.instanceDeclarationPositions[ctx.library]![clsName]![0]['index'] = pos;
  i++;
  i++;

  for (final m in <ClassMember>[...fields, ...methods, ...constructors]) {
    ctx.resetStack(
        position: m is ConstructorDeclaration ||
                (m is MethodDeclaration && m.isStatic)
            ? 0
            : 1);
    ctx.currentClass = d;
    compileDeclaration(m, ctx, parent: d, fieldIndex: i, fields: fields);
    if (m is FieldDeclaration) {
      i += m.fields.variables.length;
    }
  }

  var idx = 0;
  for (final constant in d.constants) {
    final cName = constant.name.lexeme;
    ctx.resetStack(position: 0);
    final pos = beginMethod(ctx, constant, constant.offset, '$cName*i');
    final cstrName = constant.arguments?.constructorSelector?.name.name ?? '';
    final method = IdentifierReference(null, d.name.lexeme).getValue(ctx);
    final offset = method.methodOffset ??
        (throw CompileError(
            'Cannot instantiate enum $clsName (no valid constructor $cstrName)'));

    final cstr =
        ctx.topLevelDeclarationsMap[offset.file]![offset.name ?? '$clsName.'];

    final vIndex = BuiltinValue(intval: idx).push(ctx).boxIfNeeded(ctx);
    final vName = BuiltinValue(stringval: cName).push(ctx);

    ctx.pushOp(PushArg.make(vIndex.scopeFrameOffset), PushArg.LEN);
    ctx.pushOp(PushArg.make(vName.scopeFrameOffset), PushArg.LEN);

    final dec = cstr?.declaration;
    if (constant.arguments != null && dec != null) {
      final fpl = (dec as ConstructorDeclaration).parameters.parameters;
      compileArgumentList(
          ctx, constant.arguments!.argumentList, ctx.library, fpl, dec,
          source: constant);
    }

    final loc = ctx.pushOp(Call.make(offset.offset ?? -1), Call.length);
    if (offset.offset == null) {
      ctx.offsetTracker.setOffset(loc, offset);
    }
    ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);
    final V = Variable.alloc(ctx, type);
    final name = '$clsName.$cName';
    final index = ctx.topLevelGlobalIndices[ctx.library]![name]!;
    ctx.pushOp(SetGlobal.make(index, V.scopeFrameOffset), SetGlobal.LEN);
    ctx.topLevelVariableInferredTypes[ctx.library]![name] = type;
    ctx.topLevelGlobalInitializers[ctx.library]![name] = pos;
    ctx.runtimeGlobalInitializerMap[index] = pos;
    ctx.pushOp(Return.make(V.scopeFrameOffset), Return.LEN);
    idx++;
  }

  ctx.currentClass = null;
  ctx.resetStack();
}
