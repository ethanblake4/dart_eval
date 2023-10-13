/// A continuation represents a state of the VM that can be saved and resumed during an async suspension
class Continuation {
  const Continuation(
      {required this.programOffset,
      required this.frameOffset,
      required this.frame,
      required this.args});

  final int programOffset;
  final int frameOffset;
  final List<Object?> frame;
  final List<Object?> args;
}
