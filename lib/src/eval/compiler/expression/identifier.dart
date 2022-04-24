import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/bridge/declaration.dart';
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
    return IdentifierReference(null, id.name);
  } else if (id is PrefixedIdentifier) {
    final L = compileIdentifier(id.prefix, ctx);
    if (ctx.instanceDeclarationsMap.containsKey(L.type.file)) {
      if (!ctx.instanceDeclarationsMap[L.type.file]!.containsKey(L.type.name)) {
        final idn = id.identifier.name;
        final tl = ctx.topLevelDeclarationsMap[L.type.file]![L.type.name]!;
        if (!tl.isBridge || !(tl.bridge is BridgeClassDeclaration)) {
          throw UnimplementedError('Trying to access ${id.prefix}.$idn on ${L.type}, which is not a class');
        }
        final cls = tl.bridge as BridgeClassDeclaration;
        if (!cls.fields.containsKey(idn) &&
            !cls.methods.containsKey(idn) &&
            !cls.getters.containsKey(idn) &&
            !cls.setters.containsKey(idn)) {
          throw CompileError('Bridge class ${L.type} does not have method/field/getter/setter "$idn"');
        }
      }
    }
    return IdentifierReference(L, id.identifier.name);
  }
  throw CompileError('Unknown identifier ${id.runtimeType}');
}

Pair<TypeRef, Declaration>? resolveInstanceDeclaration(CompilerContext ctx, int library, String $class, String name) {
  final dec = ctx.instanceDeclarationsMap[library]![$class]?[name];
  if (dec != null) {
    final $type = ctx.visibleTypes[library]![$class]!;
    return Pair($type, dec);
  }
  final _$classDec = ctx.topLevelDeclarationsMap[library]![$class]!;

  if (_$classDec.isBridge) {
    return null;
    throw CompileError('Bridge declaration not supported in instance: trying to lookup "$name" in "${$class}"');
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

DeclarationOrBridge<Declaration, BridgeDeclaration>? resolveStaticDeclaration(
    CompilerContext ctx, int library, String $class, String name) {
  return ctx.topLevelDeclarationsMap[library]![$class + '.' + name];
}
