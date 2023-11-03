class BindingGenerationError implements Exception {
  final String message;
  const BindingGenerationError(this.message);

  @override
  String toString() {
    return 'BindingGenerationError: $message';
  }
}
