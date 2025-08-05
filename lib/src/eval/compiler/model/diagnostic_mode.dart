/// Defines the diagnostic modes for the dart_eval compiler.
/// These modes control how the compiler handles parsing diagnostics,
/// such as errors, warnings, and informational messages.
enum DiagnosticMode {
  throwIfError,
  throwIfErrorOrWarning,
  throwErrorPrintWarnings,
  throwErrorPrintAll,
  printErrors,
  printErrorsAndWarnings,
  printAll,
  ignore
}
