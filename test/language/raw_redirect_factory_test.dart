import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test(
    'raw const factory target infers callback and reordered class types',
    () {
      final program = Compiler().compile({
        'probe': {
          'factory.dart': '''
          typedef Accessor<T> = int Function(T);
          abstract class Reader<T> {
            const factory Reader(Map<String, Accessor<T>> accessors) = ReaderImpl;
            int read(T value);
          }
          class ReaderImpl<E> implements Reader<E> {
            final Map<String, Accessor<E>> accessors;
            const ReaderImpl(this.accessors);
            int read(E value) => accessors['read']!(value);
          }
          abstract class Pair<L, R> {
            factory Pair(L left, R right) = PairImpl;
            L get left;
            R get right;
          }
          class PairImpl<A, B> implements Pair<B, A> {
            final B left;
            final A right;
            PairImpl(this.left, this.right);
          }
        ''',
          'main.dart': '''
          import 'factory.dart';
          int main() {
            final reader = Reader<int>({'read': (int value) => value + 1});
            final pair = Pair<String, int>('left', 6);
            if (pair.left != 'left') return 0;
            return reader.read(pair.right);
          }
        ''',
        },
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(runtime.executeLib('package:probe/main.dart', 'main'), 7);
      }
    },
  );
}
