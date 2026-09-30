/// A selected SDK multitest source. The original URI is retained by callers.
final class SdkMultitestVariant {
  const SdkMultitestVariant(this.key, this.source, this.outcomes);

  final String? key;
  final String source;
  final Set<String> outcomes;

  bool get isNegative =>
      outcomes.contains('syntax error') ||
      outcomes.contains('compile-time error');
  bool get isRuntimeError => !isNegative && outcomes.contains('runtime error');
  bool get hasStaticWarning => outcomes.contains('static type warning');
}

/// Mirrors the pinned SDK test runner's `Annotation.tryParse` and line
/// selection. Empty excluded lines preserve source locations and imports
/// are collected from each selected source rather than the combined file.
List<SdkMultitestVariant> splitSdkMultitest(String source) {
  final firstNewline = source.indexOf('\n');
  final separator = firstNewline > 0 && source[firstNewline - 1] == '\r'
      ? '\r\n'
      : '\n';
  final selected = <String, List<String>>{'none': []};
  final outcomes = <String, Set<String>>{'none': {}};
  var hasAnnotations = false;
  for (final line in source.split(separator)) {
    final marker = line.indexOf('//#');
    final annotation = marker < 0
        ? const <String>[]
        : line
              .substring(marker + 3)
              .split(':')
              .map((part) => part.trim())
              .where((part) => part.isNotEmpty)
              .toList();
    if (annotation.length < 2) {
      for (final lines in selected.values) {
        lines.add(line);
      }
      continue;
    }
    hasAnnotations = true;
    final key = annotation[0];
    selected.putIfAbsent(key, () => List.of(selected['none']!));
    for (final entry in selected.entries) {
      entry.value.add(entry.key == key ? line : '');
    }
    final expected = outcomes.putIfAbsent(key, () => {});
    if (annotation[1] != 'continued') {
      for (final outcome in annotation[1].split(',')) {
        if (_outcomes.contains(outcome.trim())) expected.add(outcome.trim());
      }
    }
  }
  if (!hasAnnotations) return [SdkMultitestVariant(null, source, const {})];
  return [
    for (final entry in selected.entries)
      if (entry.key == 'none' || outcomes[entry.key]!.isNotEmpty)
        SdkMultitestVariant(
          entry.key,
          entry.value.join(separator),
          outcomes[entry.key]!,
        ),
  ];
}

const _outcomes = {
  'ok',
  'syntax error',
  'compile-time error',
  'runtime error',
  'static type warning',
};
