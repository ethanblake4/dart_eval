class EvalUnknownPropertyException implements Exception {
  const EvalUnknownPropertyException(this.name);

  final String name;

  @override
  String toString() => 'EvalUnknownPropertyException ($name)';
}

class ProgramExit implements Exception {
  final int exitCode;

  ProgramExit(this.exitCode);
}