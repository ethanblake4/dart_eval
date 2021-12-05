class CompileError implements Exception {
  final String message;

  CompileError(this.message);

  @override
  String toString() {
    return 'CompileError: $message';
  }
}