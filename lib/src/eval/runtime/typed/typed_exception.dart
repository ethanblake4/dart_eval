/// Absolute bytecode destinations owned by one function.
final class TypedExceptionRegion {
  const TypedExceptionRegion(
    this.functionId, {
    this.catchTarget = -1,
    this.finallyTarget = -1,
  });
  final int functionId, catchTarget, finallyTarget;
}

/// A compiler-generated continuation after leaving protected scopes.
/// Return operands stay in typed spills; this metadata holds no values.
final class TypedCompletionJump {
  const TypedCompletionJump(this.functionId, this.target, this.targetDepth);
  final int functionId, target, targetDepth;
}
