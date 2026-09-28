import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('ByteData inherits TypedData properties', () {
    final runtime = Compiler().compileWriteAndLoad({
      'example': {
        'main.dart': '''
          import 'dart:typed_data';

          int main() {
            final data = ByteData(4);
            return data.buffer.lengthInBytes + data.offsetInBytes;
          }
        ''',
      },
    });
    expect(runtime.executeLib('package:example/main.dart', 'main'), 4);
  });
}
