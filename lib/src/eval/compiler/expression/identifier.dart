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
  return compileIdentifierAsReference(id, ctx).getValue(ctx, id);
}

Reference compileIdentifierAsReference(Identifier id, CompilerContext ctx) {
  if (id is SimpleIdentifier) {
    return IdentifierReference(null, id.name);
  } else if (id is PrefixedIdentifier) {
    try {
      final L = compileIdentifier(id.prefix, ctx);
      return IdentifierReference(L, id.identifier.name);
    } on PrefixError {
      return IdentifierReference(null, '${id.prefix}.${id.identifier.name}');
    }
  }
  throw CompileError('Unknown identifier ${id.runtimeType}');
}

Variable compilePrefixedIdentifier(
    String prefix, String name, CompilerContext ctx) {
  return compilePrefixedIdentifierAsReference(prefix, name).getValue(ctx);
}

Reference compilePrefixedIdentifierAsReference(
    String prefix, String identifier) {
  return PrefixedIdentifierReference(prefix, identifier);
}

Pair<TypeRef, DeclarationOrBridge>? resolveInstanceDeclaration(
    CompilerContext ctx, int library, String $class, String name) {
  final dec = ctx.instanceDeclarationsMap[library]![$class]?[name];

  if (dec != null) {
    final $type = ctx.visibleTypes[library]![$class]!;
    return Pair($type, DeclarationOrBridge(-1, declaration: dec));
  }

  final $classDec = ctx.topLevelDeclarationsMap[library]![$class]!;

  if ($classDec.isBridge) {
    final bridge = $classDec.bridge as BridgeClassDef;
    final method = bridge.methods[name];
    if (method != null) {
      final $type = ctx.visibleTypes[library]![$class]!;
      return Pair($type, DeclarationOrBridge(-1, bridge: method));
    }
    final getter = bridge.getters[name];
    final setter = bridge.setters[name];

    if (getter != null || setter != null) {
      final $type = ctx.visibleTypes[library]![$class]!;
      final setter0 = setter == null
          ? null
          : DeclarationOrBridge<MethodDeclaration, BridgeMethodDef>(-1,
              bridge: setter);
      return Pair($type, GetSet(-1, bridge: getter, setter: setter0));
    }

    final field = bridge.fields[name];
    if (field != null) {
      final $type = ctx.visibleTypes[library]![$class]!;
      return Pair($type, DeclarationOrBridge(-1, bridge: field));
    }

    final $extends = bridge.type.$extends;
    if ($extends != null) {
      final type = TypeRef.fromBridgeTypeRef(ctx, $extends);
      if (type.file < 0) {
        return null;
      }
      return resolveInstanceDeclaration(ctx, type.file, type.name, name);
    }

    return null;
  } else {
    final getter = ctx.instanceDeclarationsMap[library]![$class]?['$name*g'];
    final setter = ctx.instanceDeclarationsMap[library]![$class]?['$name*s'];
    if (getter != null || setter != null) {
      final $type = ctx.visibleTypes[library]![$class]!;
      final getset = GetSet(-1,
          declaration: getter as MethodDeclaration,
          setter: setter == null
              ? null
              : DeclarationOrBridge(-1,
                  declaration: setter as MethodDeclaration));
      return Pair($type, getset);
    }
  }
  final $dec = $classDec.declaration!;
  final $withClause = $dec is ClassDeclaration
      ? $dec.withClause
      : ($dec is EnumDeclaration ? $dec.withClause : null);
  final $extendsClause = $dec is ClassDeclaration ? $dec.extendsClause : null;
  if ($withClause != null) {
    for (final $mixin in $withClause.mixinTypes) {
      final mixinType = ctx.visibleTypes[library]![$mixin.name2.stringValue!]!;
      final result =
          resolveInstanceDeclaration(ctx, mixinType.file, mixinType.name, name);
      if (result != null) {
        return result;
      }
    }
  }
  if ($extendsClause != null) {
    final prefix = $extendsClause.superclass.importPrefix;
    final extendsType = ctx.visibleTypes[library]![
        '${prefix != null ? '${prefix.name.value()}.' : ''}'
            '${$extendsClause.superclass.name2.value()}']!;
    return resolveInstanceDeclaration(
        ctx, extendsType.file, extendsType.name, name);
  } else {
    final $type = ctx.visibleTypes[library]![$class]!;
    final objectType = CoreTypes.object.ref(ctx);
    if ($type != objectType) {
      return resolveInstanceDeclaration(ctx, objectType.file, 'Object', name);
    }
  }
  return null;
}

class GetSet extends DeclarationOrBridge<MethodDeclaration, BridgeMethodDef> {
  GetSet(super.sourceLib, {this.setter, super.declaration, super.bridge});

  DeclarationOrBridge<MethodDeclaration, BridgeMethodDef>? setter;
}

DeclarationOrBridge<Declaration, BridgeDeclaration>? resolveStaticDeclaration(
    CompilerContext ctx, int library, String $class, String name) {
  return ctx.topLevelDeclarationsMap[library]!['${$class}.$name'];
}
