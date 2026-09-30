import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('private super calls retain their library through mixin aliases', () {
    final program = Compiler().compile({
      'private_mixin': {
        'library.dart': r'''
          class _Base {
            int _secret() => 42;
            int baseValue() => _secret();
          }
          typedef PublicBase = _Base;
          mixin _Mixin on PublicBase {
            int fromBase() => super._secret();
            int _secret() => super._secret();
          }
          typedef PublicMixin = _Mixin;
          int libraryValue(PublicMixin value) => value._secret();
        ''',
        'main.dart': r'''
          import 'library.dart';
          class Derived extends PublicBase with PublicMixin {
            int _secret() => 99;
          }
          int main() {
            final value = Derived();
            if (value.fromBase() != 42) return -1;
            if (value._secret() != 99) return -2;
            if (libraryValue(value) != 42) return -3;
            if (value.baseValue() != 42) return -4;
            return 0;
          }
        ''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:private_mixin/main.dart', 'main'), 0);
    }
  });
}
