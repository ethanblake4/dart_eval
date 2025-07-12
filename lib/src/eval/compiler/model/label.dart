import 'package:dart_eval/src/eval/compiler/context.dart';

class CompilerLabel {
  final int offset;
  final int Function(CompilerContext ctx) cleanup;
  final String? name;
  final LabelType type;
  final List<int> continueHoles = [];

  CompilerLabel(this.type, this.offset, this.cleanup, {this.name});
}

class SimpleCompilerLabel implements CompilerLabel {
  @override
  get offset => -1;

  @override
  final String? name;

  @override
  get type => LabelType.block;

  @override
  final List<int> continueHoles = [];

  SimpleCompilerLabel({this.name});

  get cleanup => (CompilerContext ctx) {
        ctx.endAllocScopeQuiet();
        return -1;
      };
}

enum LabelType { loop, branch, block }
