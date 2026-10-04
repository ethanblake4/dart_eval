import 'dart:typed_data';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_interop.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void main() {
  test(
    'native List views preserve host identity, float types and readonly storage',
    () {
      final program = Compiler().compile({
        'native_lists': {
          'main.dart': r'''
          import 'dart:typed_data';
          bool bytes(dynamic value) => value is Uint8List &&
              value is List<int> && value is Iterable<int> &&
              value is! List<String> && value is! Float32List;
          bool floats(dynamic value) => value is Float32List &&
              value is List<double> && value is List<num> &&
              value is! List<int> && value is! Uint8List;
          dynamic echo(dynamic value) => value;
          void write(dynamic value) { value[0] = 258; }
          bool readonly(dynamic value) {
            try { value[0] = 7; } on UnsupportedError { return true; }
            return false;
          }
        ''',
        },
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(runtime.wrap(null), isA<$null>());
        final bytes = Uint8List.fromList([1, 2]);
        final views = [
          $List.view(bytes, (value) => $int(value)),
          TypedInterop.boxExternal(bytes, runtime: runtime),
          runtime.wrap(bytes),
          runtime.wrap(bytes, recursive: true),
        ];
        for (final view in views) {
          Object? call(String name) => runtime.executeLib(
            'package:native_lists/main.dart',
            name,
            arguments: {'value': view},
          );
          expect(call('bytes'), true);
          expect(identical(call('echo'), bytes), true);
          call('write');
          expect(bytes[0], 2);
        }
        final floats = Float32List.fromList([1.5]);
        expect(
          runtime.executeLib(
            'package:native_lists/main.dart',
            'floats',
            arguments: {'value': $List.view(floats, (value) => $double(value))},
          ),
          true,
        );
        final readonly = bytes.asUnmodifiableView();
        expect(
          runtime.executeLib(
            'package:native_lists/main.dart',
            'readonly',
            arguments: {'value': $List.view(readonly, (value) => $int(value))},
          ),
          true,
        );
        expect(bytes[0], 2);
      }
    },
  );

  test('native codec List results retain Uint8List dispatch and witnesses', () {
    for (final (mode, result) in runDynamicFixture(r'''
      import 'dart:io';
      import 'dart:typed_data';

      String main() {
        final codec = ZLibCodec();
        List<int> decoded = codec.decode(codec.encode([1, 2, 3]));
        if (decoded is! Uint8List || decoded is! TypedData) return 'class';
        if (decoded is! List<int> || decoded is! Iterable<int>) return 'generic';
        if (decoded is List<String> || decoded is Float32List) return 'negative';
        final bytes = decoded as Uint8List;
        if (!identical(bytes, decoded)) return 'identity';
        final alias = bytes.buffer.asUint8List();
        alias[0] = 257;
        if (decoded[0] != 1) return 'alias';
        decoded[1] = 258;
        if (alias[1] != 2) return 'write';
        if (decoded.sublist(1) is! Uint8List) return 'sublist';
        final copy = List<int>.of(decoded);
        copy.addAll(decoded);
        copy.setRange(0, 3, decoded);
        if (copy.join(',') != '1,2,3,1,2,3') return 'copy';
        dynamic untyped = decoded;
        try {
          untyped[0] = 'bad';
          return 'element accepted';
        } on TypeError {}
        try {
          untyped as List<String>;
          return 'cast accepted';
        } on TypeError {}
        try {
          decoded.add(4);
          return 'growable';
        } on UnsupportedError {}
        return decoded.join(',');
      }
    ''')) {
      expect(result, const DynamicFixtureResult.value('1,2,3'), reason: mode);
    }
  });
}
