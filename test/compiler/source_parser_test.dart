import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/model/diagnostic_mode.dart';
import 'package:dart_eval/src/eval/compiler/model/source.dart';
import 'package:test/test.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:dart_eval/src/eval/compiler/util/source_loader.dart';

void main() {
  final uri = Uri.parse('package:syntax/main.dart');
  test('ordinary methods accept final parameters', () {
    final unit = parseDartSource(
      uri,
      'class A { num parse(final String text) => 0; }',
      DiagnosticMode.throwIfError,
      languageVersion: Version(3, 3, 0),
    );
    expect(unit.declarations, hasLength(1));
  });

  const primaryConstructor = 'class A { const new(); }';
  test('recent package syntax uses its package language version', () {
    final source = DartSource(
      uri.toString(),
      primaryConstructor,
      languageVersion: Version(3, 13, 0),
    );
    final units = SourceLoader().load(
      [source],
      roots: {uri},
      entrypoints: [],
      diagnosticMode: DiagnosticMode.throwIfError,
    );
    expect(units.single.declarations, hasLength(1));
    expect(
      () => DartSource(
        uri.toString(),
        primaryConstructor,
        languageVersion: Version(3, 3, 0),
      ).load(DiagnosticMode.throwIfError),
      throwsA(isA<CompileError>()),
    );
  });

  test('source overrides lower the package language version', () {
    final source = DartSource(
      uri.toString(),
      '// @dart=3.3\nclass A { num parse(final String text) => 0; }',
      languageVersion: Version(3, 13, 0),
    );
    expect(source.load(DiagnosticMode.throwIfError).declarations, hasLength(1));
    expect(
      () => DartSource(
        uri.toString(),
        '// @dart=3.3\n$primaryConstructor',
        languageVersion: Version(3, 13, 0),
      ).load(DiagnosticMode.throwIfError),
      throwsA(isA<CompileError>()),
    );
  });

  test('language version participates in source cache identity', () {
    const text = 'class A { num parse(final String text) => 0; }';
    final loader = SourceLoader();
    List<Object> load(Version version) => loader.load(
      [DartSource(uri.toString(), text, languageVersion: version)],
      roots: {uri},
      entrypoints: [],
      diagnosticMode: DiagnosticMode.throwIfError,
    );
    expect(load(Version(3, 3, 0)), hasLength(1));
    expect(() => load(Version(3, 13, 0)), throwsA(isA<CompileError>()));
  });

  test('sources without metadata keep latest analyzer syntax', () {
    expect(
      DartSource(
        uri.toString(),
        primaryConstructor,
      ).load(DiagnosticMode.throwIfError).declarations,
      hasLength(1),
    );
  });

  test('explicit compiler experiments remain parseable', () {
    final unit = parseDartSource(
      uri,
      'class Consumer<in T> {} void main() { null.{ return; }; }',
      DiagnosticMode.throwIfError,
    );
    expect(unit.declarations, hasLength(2));
  });

  test('parser errors identify the source and line', () {
    expect(
      () => parseDartSource(
        uri,
        'void main() {\n  var value = ;\n}',
        DiagnosticMode.throwIfError,
      ),
      throwsA(
        isA<CompileError>().having(
          (error) => error.message,
          'message',
          contains('package:syntax/main.dart:2:'),
        ),
      ),
    );
  });
}
