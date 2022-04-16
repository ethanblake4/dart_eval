class CompileError implements Exception {
  final String message;

  const CompileError(this.message);

  @override
  String toString() {
    return 'CompileError: $message';
  }
}

class NotReferencableError extends CompileError {

  const NotReferencableError(String message) : super(message);

  @override
  String toString() {
    return 'NotReferencableError: $message';
  }
}