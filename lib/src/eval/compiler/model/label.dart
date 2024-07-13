import 'package:dart_eval/src/eval/compiler/context.dart';

class CompilerLabel {
  final int? offset;
  final int Function(CompilerContext ctx) cleanup;
  final String? name;
  final LabelType type;

  const CompilerLabel(this.name, this.type, this.cleanup, {this.offset});
}

class SimpleCompilerLabel implements CompilerLabel {
  get offset => -1;
  final String? name;
  get type => LabelType.block;

  const SimpleCompilerLabel({this.name});

  get cleanup => (CompilerContext ctx) {
        ctx.endAllocScopeQuiet();
        return -1;
      };
}

enum LabelType { loop, branch, block }
