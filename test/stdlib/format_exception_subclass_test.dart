import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _library = 'package:format_exception9/main.dart';

class _NativeCborLikeFormatException extends FormatException {
  const _NativeCborLikeFormatException(super.message, [int? super.offset]);

  @override
  String toString() => 'guest-format';
}

String _guestFields(FormatException error) =>
    'message=${error.message == 'bad input'};'
    'sourceNull=${error.source == null};'
    'sourceFour=${error.source == 4};'
    'offsetNull=${error.offset == null};'
    'offsetFour=${error.offset == 4};'
    'toString=${error.toString()}';

void main() {
  test('FormatException supports guest subclasses and native catches', () {
    final program = Compiler().compile({
      'format_exception9': {
        'main.dart': r'''
          class CborLikeFormatException extends FormatException {
            const CborLikeFormatException(super.message, [int? super.offset]);

            @override
            String toString() => 'guest-format';
          }

          String main() {
            const empty = FormatException();
            const base = FormatException('base message', 'source text', 3);
            var guestResult = 'not-caught';
            var caughtAsFormatException = false;
            try {
              throw const CborLikeFormatException('bad input', 4);
            } on StateError {
              return 'guest caught as StateError';
            } on CborLikeFormatException catch (error) {
              if (error is! FormatException) return 'missing FormatException';
              guestResult = 'message=${error.message == 'bad input'};'
                  'sourceNull=${error.source == null};'
                  'sourceFour=${error.source == 4};'
                  'offsetNull=${error.offset == null};'
                  'offsetFour=${error.offset == 4};'
                  'toString=${error.toString()}';
              try {
                throw error;
              } on FormatException {
                caughtAsFormatException = true;
              } on StateError {
                return 'rethrow caught as StateError';
              }
            }

            var unrelatedCaught = false;
            try {
              throw StateError('unrelated');
            } on FormatException {
              return 'StateError caught as FormatException';
            } on StateError {
              unrelatedCaught = true;
            }

            var nativeResult = 'not-caught';
            try {
              int.parse('not-a-number');
            } on StateError {
              return 'native caught as StateError';
            } on FormatException catch (error) {
              nativeResult = '${error.message}|${error.source}|${error.offset}|${error.toString()}';
            }

            return 'empty=${empty.message}|${empty.source}|${empty.offset}|${empty.toString()};'
                'base=${base.message}|${base.source}|${base.offset}|${base.toString()};'
                'guest=$guestResult;asFormatException=$caughtAsFormatException;'
                'unrelated=$unrelatedCaught;'
                'native=$nativeResult';
          }
        ''',
      },
    });

    const empty = FormatException();
    const base = FormatException('base message', 'source text', 3);
    const nativeSubclass = _NativeCborLikeFormatException('bad input', 4);
    final native = _nativeParseError();
    final expected =
        'empty=${empty.message}|${empty.source}|${empty.offset}|${empty.toString()};'
        'base=${base.message}|${base.source}|${base.offset}|${base.toString()};'
        'guest=${_guestFields(nativeSubclass)};'
        'asFormatException=true;'
        'unrelated=true;'
        'native=${native.message}|${native.source}|${native.offset}|${native.toString()}';

    for (final (mode, runtime) in [
      ('fresh', Runtime.ofProgram(program)),
      ('encoded', Runtime(program.write().buffer)),
    ]) {
      expect(runtime.executeLib(_library, 'main'), expected, reason: mode);
    }
  });
}

FormatException _nativeParseError() {
  try {
    int.parse('not-a-number');
  } on FormatException catch (error) {
    return error;
  }
  throw StateError('Expected int.parse to throw FormatException');
}
