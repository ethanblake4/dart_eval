import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:test/test.dart';

const _source = r'''
// @dart=3.8
extension type const E(Null value) {}
extension type Ref(Object? value) {}
E produce() => const E(null);
Ref roundTrip(Ref value) => value;
Object? disclose(Ref value) => value;
Ref lexical<Object>(Object value) => Ref(value);
bool verify() {
  const E e = E(null);
  final raw = Object();
  final reference = Ref(raw);
  final absent = Ref(null);
  if (!identical(e, null) || e.value != null || e != null) return false;
  if (!identical(reference, raw) || !identical(reference.value, raw)) return false;
  if (!identical(roundTrip(reference), raw) || !identical(disclose(reference), raw)) return false;
  if (!identical(lexical(raw), raw)) return false;
  if (!identical(new Ref(raw), raw) || !identical(Ref.new(raw), raw)) return false;
  if (!identical(absent, null) || absent.value != null || absent != null) return false;
  if (e is Object || absent is Object || e is! Object? || absent is! Object?) return false;
  if (e is! Null || e is! Ref || reference is E) return false;
  if (e?.value != null || absent?.value != null || absent?.toString() != null) return false;
  if (reference?.toString() != raw.toString()) return false;
  if (!identical(absent?..toString(), null)) return false;
  try { e!; return false; } catch (_) {}
  try { absent!; return false; } catch (_) {}
  if (!identical(reference!, raw)) return false;
  if ((e as Null) != null || !identical(raw as Ref, raw)) return false;
  final values = <E>[e];
  if (values is! List<Null> || List<E> != List<Null>) return false;
  if ((e,) is! (Null,) || produce is! Null Function()) return false;
  if (E != Null || List<Ref> != List<Object?>) return false;
  final present = <Ref>[?absent, ?reference];
  return present.length == 1 && identical(present.single, raw);
}
void main() {
  if (!verify()) throw StateError('extension representation identity');
}
''';

void main() {
  test(
    'static members and secondary constructors preserve representations',
    () {
      final program = Compiler().compile({
        'extension_members': {
          'support.dart': '''
const seed = 7;
extension type Count(int? value) {
  Count.regular(this.value);
  Count.named({this.value});
  Count.optional([this.value = seed]);
  Count.increment(int n) : value = n + 1;
  const Count._(this.value);
  const Count.constNamed({this.value = seed});
  const Count.same(int n) : value = n;
  static const Count first = Count._(1);
  static Count get second => Count(2);
  static Count? get absent => null;
}
extension type Box<T>(T value) {
  Box.named(this.value);
  static Box<U> make<U, V>(U value) => Box(value);
}
extension type Bag<T>(List<T> value) {
  Bag.empty() : value = <T>[];
}
''',
          'main.dart': '''
import 'dart:async';
import 'support.dart' as support;
int calls = 0;
int next() { calls++; return 3; }
bool verify() {
  final first = support.Count.regular(next());
  final second = support.Count.named(value: next());
  final third = support.Count.optional();
  final increment = support.Count.increment(next());
  const constant = support.Count.constNamed();
  const same = support.Count.same(9);
  final inferred = support.Box.named(4);
  final generic = support.Box.make<String, int>('hi');
  final empty = support.Bag<int>.empty();
  FutureOr<support.Count> shorthand = .regular(5);
  return identical(first, 3) && identical(second, 3) && calls == 3 &&
      identical(third, 7) && identical(increment, 4) && identical(constant, 7) &&
      identical(same, 9) && empty.value is List<int> &&
      identical(support.Count.named(), null) &&
      support.Count.first.value == 1 && support.Count.second.value == 2 &&
      support.Count.absent == null && [inferred] is List<int> &&
      generic.value == 'hi' && identical(shorthand, 5);
}
void main() {}
''',
        },
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(
          runtime.executeLib('package:extension_members/main.dart', 'verify'),
          true,
        );
      }
    },
  );
  test('generic extension representations apply use-site type arguments', () {
    final program = Compiler().compile({
      'generic_representation': {
        'main.dart': '''
import 'dart:async';
extension type Box<T>(T value) {}
extension type Bag<T>(List<T> values) {}
extension type Nested<T>(Box<T> value) {}
extension type Indirect<T>(Box<T> value) {}
extension type Wrapped<T>(Box<Box<T>> value) {}
extension type Wrapper<T>(Box<T> value) {}
extension type Synthesized<T>(Wrapper<Wrapper<T>> value) {}
extension type Named<T>.primary(T value) {
  Named.redirect(T value) : this.primary(value);
  Named.fromList(List<T> values) : this.primary(values.first);
}
bool verify() {
  final box = Box<int>(7);
  final bag = Bag<int>(<int>[1, 2]);
  final nested = Nested<int>(box);
  final repeated = Box<Box<int>>(box);
  final absent = Box<int?>(null);
  final inferred = Box(9);
  final named = Named<int>.redirect(11);
  final inferredNamed = Named.redirect(12);
  final inferredList = Named.fromList([14]);
  final indirect = Indirect<Indirect<int>>(
      Box<Indirect<int>>(Indirect<int>(Box<int>(13))));
  final wrapped = Wrapped<int>(Box<Box<int>>(Box<int>(15)));
  final synthesized = Synthesized<int>(
      Wrapper<Wrapper<int>>(Box<Wrapper<int>>(Wrapper<int>(Box<int>(16)))));
  Box<num> contextual = Box(10);
  final Type boxType = Box<int>;
  final Type bagType = Bag<int>;
  final Type nestedType = Nested<int>;
  final Type listType = List<int>;
  FutureOr<Box<int>> shorthand = .new(8);
  return box.value == 7 && bag.values is List<int> &&
      identical(nested.value, 7) && identical(repeated.value, 7) &&
      identical(absent, null) &&
      boxType == int && bagType == listType && nestedType == int &&
      shorthand is int && shorthand == 8 &&
      inferred.value == 9 && contextual.value == 10 && named.value == 11 &&
      [inferredNamed] is List<int> && inferredNamed.value == 12 &&
      [inferredList] is List<int> && inferredList.value == 14 &&
      identical(indirect, 13) && identical(wrapped, 15) &&
      identical(synthesized, 16);
}
void main() {}
''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib(
          'package:generic_representation/main.dart',
          'verify',
        ),
        true,
      );
    }
  });
  for (final source in [
    "extension type E(int value) { E.wrong(this.other); }",
    "extension type E(int value) { E.twice(this.value) : value = 2; }",
    "extension type E(int value) { E.body(this.value) {} }",
    "extension type E(int value) { int get doubled => value * 2; }",
    "extension type E(int value) { E.wrong(int n) : other = n; }",
    "extension type E<T extends num>(T value) { E.named(this.value); } "
        "void check() { E<String>.named('wrong'); }",
    "extension type E(int value) { const E.constant(this.value); } "
        "int next() => 1; void check() { const E.constant(next()); }",
  ]) {
    test(
      'secondary extension representation rejects invalid source: $source',
      () {
        expect(
          () => Compiler().compile({
            'extension_secondary_negative': {
              'main.dart': '$source\nvoid main() {}',
            },
          }),
          throwsA(isA<CompileError>()),
        );
      },
    );
  }
  for (final construction in [
    "Box<int>('wrong')",
    "Bag<int>(<String>['wrong'])",
    "Bounded<String>('wrong')",
    "Box<int, String>(1)",
  ]) {
    test('generic extension representation rejects $construction', () {
      expect(
        () => Compiler().compile({
          'generic_representation_negative': {
            'main.dart':
                '''
extension type Box<T>(T value) {}
extension type Bag<T>(List<T> values) {}
extension type Bounded<T extends num>(T value) {}
void main() { $construction; }
''',
          },
        }),
        throwsA(isA<CompileError>()),
      );
    });
  }
  for (final declarations in [
    'extension type Cycle<T>(Cycle<List<T>> value) {}',
    'extension type A<T>(B<A<T>> value) {} '
        'extension type B<T>(T value) {}',
    'extension type A<T>(B<A<List<T>>> value) {} '
        'extension type B<T>(T value) {}',
  ]) {
    test(
      'generic extension representation cycle is rejected: $declarations',
      () {
        expect(
          () => Compiler().compile({
            'generic_representation_cycle': {
              'main.dart':
                  '''
$declarations
void main() {}
''',
            },
          }),
          throwsA(isA<CompileError>()),
        );
      },
    );
  }

  for (final constructor in ['_primary', '_private']) {
    test(
      'imported private extension constructor $constructor is inaccessible',
      () {
        expect(
          () => Compiler().compile({
            'extension_private': {
              'support.dart': '''
extension type Count._primary(int value) {
  Count._private(int n) : this._primary(n);
}
''',
              'main.dart':
                  '''
import 'support.dart';
void main() { Count.$constructor(1); }
''',
            },
          }),
          throwsA(isA<CompileError>()),
        );
      },
    );
  }
  test('extension type literals retain extensions on Type', () {
    final program = Compiler().compile({
      'extension_literal': {
        'support.dart': 'extension type Count(int value) {}',
        'main.dart': '''
import 'support.dart' as support;
extension Describe on Type { int describe() => 42; }
int main() => (support.Count).describe();
''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:extension_literal/main.dart', 'main'),
        42,
      );
    }
  });
  test('redirects bind arguments once in the extension declaring scope', () {
    final program = Compiler().compile({
      'extension_redirect': {
        'support.dart': r'''
const seed = 7;
extension type const Count._primary(int value) {
  const Count._from([int n = seed]) : this._primary(n);
  const Count.named({int n = seed}) : this._from(n);
}
extension type const Maybe(Object? value) {
  const Maybe.empty() : this(null);
  const Maybe.present(Object value) : this(value);
}
''',
        'main.dart': r'''
import 'support.dart' as support;
int calls = 0;
int next() { calls++; return 3; }
bool verify() {
  final seed = 100;
  const first = support.Count.named();
  final second = support.Count.named(n: next());
  final raw = Object();
  final values = <support.Maybe>[
    ?support.Maybe.empty(), ?support.Maybe.present(raw),
  ];
  return first.value == 7 && second.value == 3 && calls == 1 && seed == 100 &&
      values.length == 1 && identical(values.single, raw);
}
void main() {}
''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:extension_redirect/main.dart', 'verify'),
        true,
      );
    }
  });
  for (final version in ['3.8', '3.9']) {
    test('extension representation identity with Dart $version flow rules', () {
      final program = Compiler().compile({
        'extension_identity': {
          'main.dart': _source.replaceFirst('@dart=3.8', '@dart=$version'),
        },
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(
          runtime.executeLib('package:extension_identity/main.dart', 'verify'),
          true,
        );
      }
    });
  }

  for (final body in [
    'Null consume(E e) => e;',
    'Object consume(Ref r) => r;',
    'int consume(Ref r) => r.length;',
    'void consume(Ref r) { r.value = null; }',
    'E consume() => E(1);',
    'const r = Ref(null);',
    'E consume() => E(value: null);',
    'E consume() => E(null, null);',
  ]) {
    test('extension representation rejects invalid source: $body', () {
      expect(
        () => Compiler().compile({
          'extension_negative': {
            'main.dart':
                '''
// @dart=3.8
extension type const E(Null value) {}
extension type Ref(Object? value) {}
$body
void main() {}
''',
          },
        }),
        throwsA(isA<CompileError>()),
      );
    });
  }
}
