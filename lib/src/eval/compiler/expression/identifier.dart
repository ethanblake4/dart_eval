import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

import '../util.dart';

Variable compileIdentifier(Identifier id, CompilerContext ctx) {
  return compileIdentifierAsReference(id, ctx).getValue(ctx);
}

Reference compileIdentifierAsReference(Identifier id, CompilerContext ctx) {
  if (id is SimpleIdentifier) {
    return Reference(null, id.name);
  } else if (id is PrefixedIdentifier) {
    final L = compileIdentifier(id.prefix, ctx);
    if (!ctx.instanceDeclarationsMap.containsKey(L.type.file)) {
      throw UnimplementedError('Internal file');
    }
    if (!ctx.instanceDeclarationsMap[L.type.file]!.containsKey(L.type.name)) {
      throw UnimplementedError('Not a class');
    }
    return Reference(L, id.identifier.name);
  }
  throw CompileError('Unknown identifier ${id.runtimeType}');
}

Pair<TypeRef, Declaration>? resolveInstanceDeclaration(
    CompilerContext ctx, int library, String $class, String name) {
  final dec = ctx.instanceDeclarationsMap[library]![$class]?[name];
  if (dec != null) {
    final $type = ctx.visibleTypes[library]![$class]!;
    return Pair($type, dec);
  }
  final _$classDec = ctx.topLevelDeclarationsMap[library]![$class]!;

  if (_$classDec.isBridge) {
    throw CompileError('Bridge declaration not supported in instance');
  }
  final $classDec = _$classDec.declaration! as ClassDeclaration;
  if ($classDec.withClause != null) {
    for (final $mixin in $classDec.withClause!.mixinTypes2) {
      final mixinType = ctx.visibleTypes[library]![$mixin.name.name]!;
      final result = resolveInstanceDeclaration(ctx, mixinType.file, mixinType.name, name);
      if (result != null) {
        return result;
      }
    }
  }
  if ($classDec.extendsClause != null) {
    final extendsType = ctx.visibleTypes[library]![$classDec.extendsClause!.superclass2.name.name]!;
    return resolveInstanceDeclaration(ctx, extendsType.file, extendsType.name, name);
  }
  return null;
}
