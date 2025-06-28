import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
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

  ctx.resetStack(position: 0);
  final namePos = beginMethod(ctx, d, d.offset, '$clsName.name (get)');
  ctx.pushOp(PushObjectPropertyImpl.make(0, 1), PushObjectPropertyImpl.length);
  ctx.pushOp(Return.make(1), Return.LEN);
  ctx.instanceDeclarationPositions[ctx.library]![clsName]![0]['name'] = namePos;
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
  final enumConstants = <String>[];

  for (final constant in d.constants) {
    final cName = constant.name.lexeme;
    enumConstants.add(cName);
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
    final vName = BuiltinValue(stringval: cName).push(ctx).boxIfNeeded(ctx);

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
    final _name = '$clsName.$cName';
    final _index = ctx.topLevelGlobalIndices[ctx.library]![_name]!;
    ctx.pushOp(SetGlobal.make(_index, V.scopeFrameOffset), SetGlobal.LEN);
    ctx.topLevelVariableInferredTypes[ctx.library]![_name] = type;
    ctx.topLevelGlobalInitializers[ctx.library]![_name] = pos;
    ctx.runtimeGlobalInitializerMap[_index] = pos;
    ctx.pushOp(Return.make(V.scopeFrameOffset), Return.LEN);
    idx++;
  }

  // Registrar CORRETAMENTE o getter values como uma propriedade estática
  if (enumConstants.isNotEmpty) {
    _compileEnumValues(ctx, d, type, enumConstants, clsName);
  }

  ctx.currentClass = null;
  ctx.resetStack();
}

void _compileEnumValues(CompilerContext ctx, EnumDeclaration d, TypeRef type,
    List<String> enumConstants, String clsName) {
  final valuesName = '$clsName.values';
  ctx.resetStack(position: 0);
  final pos = beginMethod(ctx, d, d.offset, '$clsName.values (get)');

  // Criar lista com todos os valores do enum (seguindo padrão do compilador)
  final listType =
      CoreTypes.list.ref(ctx).copyWith(specifiedTypeArgs: [type], boxed: false);

  ctx.pushOp(PushList.make(), PushList.LEN);
  final valuesList = Variable.alloc(ctx, listType);

  for (final constantName in enumConstants) {
    final enumValueName = '$clsName.$constantName';
    final globalIndex = ctx.topLevelGlobalIndices[ctx.library]![enumValueName]!;

    ctx.pushOp(LoadGlobal.make(globalIndex), LoadGlobal.LEN);
    ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);
    final enumValue = Variable.alloc(ctx, type);

    ctx.pushOp(
        ListAppend.make(
            valuesList.scopeFrameOffset, enumValue.scopeFrameOffset),
        ListAppend.LEN);
  }

  ctx.pushOp(BoxList.make(valuesList.scopeFrameOffset), BoxList.LEN);
  ctx.pushOp(Return.make(valuesList.scopeFrameOffset), Return.LEN);

  final finalListType = listType.copyWith(boxed: true);
  ctx.topLevelVariableInferredTypes[ctx.library]![valuesName] = finalListType;

  if (!ctx.topLevelGlobalIndices.containsKey(ctx.library)) {
    ctx.topLevelGlobalIndices[ctx.library] = {};
  }
  ctx.topLevelGlobalIndices[ctx.library]![valuesName] = ctx.globalIndex++;

  if (!ctx.topLevelGlobalInitializers.containsKey(ctx.library)) {
    ctx.topLevelGlobalInitializers[ctx.library] = {};
  }
  ctx.topLevelGlobalInitializers[ctx.library]![valuesName] = pos;
  ctx.runtimeGlobalInitializerMap[
      ctx.topLevelGlobalIndices[ctx.library]![valuesName]!] = pos;
}
