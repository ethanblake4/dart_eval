import 'dart:convert';
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_interop.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

const source = '''
import 'dart:convert';
bool stringKeys(dynamic value) => value is Map<String, dynamic>;
bool intKeys(dynamic value) => value is Map<int, dynamic>;
dynamic guestMap() => <String, dynamic>{'guest': 1};
bool main() {
  final codec = json.fuse(utf8.fuse(base64Url));
  for (final text in ['{}', '{"nested":[{"value":1}]}']) {
    dynamic direct = json.decode(text);
    dynamic fused = codec.decode(base64Url.encode(utf8.encode(text)));
    if (direct is! Map<String, dynamic> || fused is! Map<String, dynamic>) return false;
    if (fused is Map<int, dynamic> || fused is Map<String, int>) return false;
    if (text != '{}') {
      dynamic list = fused['nested'];
      if (list is! List<dynamic> || list is List<int>) return false;
      if (list[0] is! Map<String, dynamic>) return false;
    }
  }
  return true;
}
''';

bool nativeFixture() {
  final codec = json.fuse(utf8.fuse(base64Url));
  for (final text in ['{}', '{"nested":[{"value":1}]}']) {
    final direct = json.decode(text);
    final fused = codec.decode(base64Url.encode(utf8.encode(text)));
    if (direct is! Map<String, dynamic> || fused is! Map<String, dynamic>) {
      return false;
    }
    if (fused is Map<int, dynamic> || fused is Map<String, int>) return false;
    if (text != '{}') {
      final list = fused['nested'];
      if (list is! List<dynamic> || list is List<int>) return false;
      if (list[0] is! Map<String, dynamic>) return false;
    }
  }
  return true;
}

void main() {
  test(
    'native direct and fused JSON witnesses',
    () => expect(nativeFixture(), isTrue),
  );
  final program = Compiler().compile({
    'codec_witness': {'main.dart': source},
  });
  for (final (mode, runtime) in [
    ('fresh', Runtime.ofProgram(program)),
    ('encoded', Runtime(program.write().buffer)),
  ]) {
    test(
      '$mode direct and fused JSON preserve actual collection witnesses',
      () {
        expect(
          runtime.executeLib('package:codec_witness/main.dart', 'main'),
          isTrue,
        );
      },
    );
    test(
      '$mode host witness uses type, preserves backing and guest identity',
      () {
        bool accepts(Object host, String function) =>
            runtime.executeLib(
                  'package:codec_witness/main.dart',
                  function,
                  arguments: {
                    'value': TypedInterop.boxExternal(host, runtime: runtime),
                  },
                )
                as bool;
        final host = <String, dynamic>{};
        expect(accepts(host, 'stringKeys'), isTrue);
        expect(accepts(host, 'intKeys'), isFalse);
        expect(accepts(<int, dynamic>{1: 'one'}, 'stringKeys'), isFalse);
        expect(
          accepts(<Object?, Object?>{'looks': 'string-keyed'}, 'stringKeys'),
          isFalse,
        );
        final boxed = TypedInterop.boxExternal(host, runtime: runtime)! as $Map;
        TypedInterop.invoke(
          runtime,
          boxed,
          '[]=',
          2,
          $String('added'),
          $int(9),
        );
        expect(host['added'], 9);
        host['native'] = 11;
        expect(
          (TypedInterop.invoke(runtime, boxed, '[]', 1, $String('native'), null)
                  as $int)
              .$value,
          11,
        );
        expect(
          () => TypedInterop.invoke(runtime, boxed, '[]=', 2, $int(2), $int(3)),
          throwsA(isA<TypeError>()),
        );
        expect(
          TypedInterop.exportExternal(boxed, runtime: runtime),
          same(host),
        );
        final guest = runtime.executeLib(
          'package:codec_witness/main.dart',
          'guestMap',
        );
        final guestBox = TypedInterop.boxExternal(guest, runtime: runtime)!;
        final exported = TypedInterop.exportExternal(
          guestBox,
          runtime: runtime,
        );
        expect(
          TypedInterop.boxExternal(exported, runtime: runtime),
          same(guestBox),
        );
      },
    );
  }
}
