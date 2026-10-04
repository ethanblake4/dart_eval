import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:test/test.dart';

void main() {
  test(
    'value-class members initialize typed fields and preserve overrides',
    () {
      final program = Compiler().compile({
        'value_lowering': {
          'main.dart': _source,
          'metadata.dart': '''
class Metadata { const Metadata(); }
const valueClass = Metadata();
@valueClass
class Tagged {
  final int item;
  const Tagged(this.item);
}
bool unrelatedMarkerUnchanged() => Tagged(1) != Tagged(1);
''',
          'marker.dart': "const valueClass = 'valueClass';",
        },
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(
          runtime.executeLib('package:value_lowering/main.dart', 'main'),
          true,
        );
      }
    },
  );

  test(
    'generated value constructor checks required fields and their types',
    () {
      for (final arguments in ['', "item: 'bad'"]) {
        expect(
          () => Compiler().compile({
            'value_lowering': {
              'main.dart':
                  '''
const valueClass = 'valueClass';
@valueClass class Count { final int item; }
main() => Count($arguments);
''',
            },
          }),
          throwsA(isA<CompileError>()),
        );
      }
    },
  );
}

const _source = r'''
import 'metadata.dart' as metadata;
import 'marker.dart' as marker;
const valueClass = 'valueClass';
@valueClass
class Packet<T> {
  final T item;
  final String? label;
  final int version = 1;
  static int ignored = 0;
}
class Child extends Packet<int> {
  Child() : super(item: 9, label: 'n');
}
@valueClass
class Manual {
  final int item;
  Manual(this.item);
  bool operator ==(Object other) => other is Manual;
  int get hashCode => 17;
}
class Plain {
  final int item;
  Plain(this.item);
}
@valueClass
class Key {
  final int other;
  final int hash;
}
@marker.valueClass
class Prefixed {
  final int item;
}
bool main() {
  final first = Packet<int>(item: 9, label: 'n');
  final equal = Packet<int>(item: 9, label: 'n');
  final different = Packet<int>(item: 9, label: null);
  final key = Key(other: 1, hash: 11);
  final equalKey = Key(other: 1, hash: 11);
  Packet.ignored = 3;
  return first.item == 9 && first.version == 1 && first == equal &&
      first.hashCode == equal.hashCode && first != different &&
      first != Packet<num>(item: 9, label: 'n') && first != Child() &&
      Manual(1) == Manual(2) && Manual(1).hashCode == 17 &&
      Plain(1) != Plain(1) && metadata.unrelatedMarkerUnchanged() &&
      key == equalKey && key.hashCode == equalKey.hashCode &&
      key != Key(other: 2, hash: 11) &&
      key.hashCode != Key(other: 1, hash: 12).hashCode &&
      Prefixed(item: 3) == Prefixed(item: 3);
}
''';
