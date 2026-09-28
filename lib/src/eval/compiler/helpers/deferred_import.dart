import 'package:dart_eval/src/eval/ir/bridge.dart';

import '../builtins.dart';
import '../context.dart';

String deferredImportKey(CompilerContext ctx, String prefix) =>
    '${ctx.library}:$prefix';

/// Enforce the prefix's loading state before evaluating member arguments.
void checkDeferredImport(CompilerContext ctx, String? prefix) {
  if (prefix == null ||
      !(ctx.deferredPrefixes[ctx.library]?.contains(prefix) ?? false)) {
    return;
  }
  final index =
      ctx.bridgeStaticFunctionIndices[ctx
          .libraryMap['dart:core']]!['deferred_checkLoaded']!;
  final key = BuiltinValue(
    stringval: deferredImportKey(ctx, prefix),
  ).push(ctx).boxIfNeeded(ctx);
  ctx.pushOp(InvokeExternal(ctx.svar('deferred_check'), index, [key.ssa]));
}
