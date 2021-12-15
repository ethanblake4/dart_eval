import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/offset_tracker.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

Variable compileIdentifier(Identifier id, CompilerContext ctx) {
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

      final returnType = TypeRef.lookupClassDeclaration(ctx, declaration.sourceLib, decl);
      final DeferredOrOffset offset;

      if (ctx.topLevelDeclarationPositions[declaration.sourceLib]?.containsKey(id.name + '.') ?? false) {
        offset = DeferredOrOffset(
            file: declaration.sourceLib, offset: ctx.topLevelDeclarationPositions[ctx.library]![id.name + '.']);
      } else {
        offset = DeferredOrOffset(file: declaration.sourceLib, name: id.name + '.');
      }

      return Variable(-1, functionType, methodOffset: offset, methodReturnType: AlwaysReturnType(returnType, false));
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

    return Variable(-1, functionType, methodOffset: offset, methodReturnType: AlwaysReturnType(returnType, nullable));
  } else if (id is PrefixedIdentifier) {
    final L = compileIdentifier(id.prefix, ctx);
    if (!ctx.instanceDeclarationsMap.containsKey(L.type.file)) {
      throw UnimplementedError('temp: Internal file');
    }
    if (!ctx.instanceDeclarationsMap[L.type.file]!.containsKey(L.type.name)) {
      throw UnimplementedError('temp: Not a class');
    }

    final op = PushObjectProperty.make(L.scopeFrameOffset, id.identifier.name);
    ctx.pushOp(op, PushObjectProperty.len(op));

    return Variable.alloc(ctx, TypeRef.lookupFieldType(ctx, L.type, id.identifier.name));
  }
  throw CompileError('Unknown identifier ${id.runtimeType}');
}