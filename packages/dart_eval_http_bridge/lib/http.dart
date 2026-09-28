/// Bindings for the `package:http/http.dart` GET API.
library;

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:http/http.dart' as http;

/// Enables `http.get` and its response in code compiled by dart_eval.
/// A [NetworkPermission] is required for each URL, including redirects.
class HttpPlugin implements EvalPlugin {
  @override
  String get identifier => 'package:http';

  @override
  void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeTopLevelFunction(_getDeclaration);
    registry.defineBridgeClass($HttpResponse.declaration);
  }

  @override
  void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters('package:http/http.dart', 'get', _get);
  }

  static const _responseType = BridgeTypeRef(
    BridgeTypeSpec('package:http/http.dart', 'Response'),
  );

  static const _getDeclaration = BridgeFunctionDeclaration(
    'package:http/http.dart',
    'get',
    BridgeFunctionDef(
      returns: BridgeTypeAnnotation(
        BridgeTypeRef(CoreTypes.future, [BridgeTypeAnnotation(_responseType)]),
      ),
      params: [
        BridgeParameter(
          'url',
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.uri)),
          false,
        ),
      ],
      namedParams: [
        BridgeParameter(
          'headers',
          BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.map, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
            ]),
            nullable: true,
          ),
          true,
        ),
      ],
    ),
  );

  static $Value _get(Runtime runtime, Object? r, Object? s, Object? c) {
    final url = (r as $Value).$reified as Uri;
    runtime.assertPermission('network', url.toString());
    final headers = s is $Value && s is! $null
        ? (s.$reified as Map).cast<String, String>()
        : null;
    return $Future.wrap(_fetch(runtime, url, headers));
  }

  static Future<$HttpResponse> _fetch(
    Runtime runtime,
    Uri url,
    Map<String, String>? headers,
  ) async {
    final client = http.Client();
    headers = headers == null ? null : Map.of(headers);
    try {
      for (var redirects = 0; ; redirects++) {
        final request = http.Request('GET', url)..followRedirects = false;
        if (headers != null) request.headers.addAll(headers);
        final response = await client.send(request);
        final location = response.headers['location'];
        if (location == null ||
            !const {301, 302, 303, 307, 308}.contains(response.statusCode)) {
          return $HttpResponse.wrap(await http.Response.fromStream(response));
        }
        if (redirects >= request.maxRedirects) {
          throw http.ClientException('Too many redirects', url);
        }
        await response.stream.drain<void>();
        final nextUrl = url.resolve(location);
        runtime.assertPermission('network', nextUrl.toString());
        if (nextUrl.scheme != url.scheme ||
            nextUrl.host != url.host ||
            nextUrl.port != url.port) {
          headers?.removeWhere(
            (name, _) => const {
              'authorization',
              'cookie',
              'proxy-authorization',
            }.contains(name.toLowerCase()),
          );
        }
        url = nextUrl;
      }
    } finally {
      client.close();
    }
  }
}

/// Runtime wrapper for the fields of [http.Response] used by simple GET calls.
class $HttpResponse implements $Instance {
  $HttpResponse.wrap(this.$value);

  @override
  final http.Response $value;

  static const type = BridgeTypeRef(
    BridgeTypeSpec('package:http/http.dart', 'Response'),
  );

  static const declaration = BridgeClassDef(
    BridgeClassType(type),
    constructors: {},
    fields: {
      'body': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
      ),
      'statusCode': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
      ),
      'headers': BridgeFieldDef(
        BridgeTypeAnnotation(
          BridgeTypeRef(CoreTypes.map, [
            BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
            BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
          ]),
        ),
      ),
    },
    wrap: true,
  );

  @override
  $Value? $getProperty(Runtime runtime, String identifier) =>
      switch (identifier) {
        'body' => $String($value.body),
        'statusCode' => $int($value.statusCode),
        'headers' => $Map.wrap(
          $value.headers.map(
            (key, value) => MapEntry($String(key), $String(value)),
          ),
        ),
        _ => $Object($value).$getProperty(runtime, identifier),
      };

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) =>
      throw UnsupportedError('Response is read only');

  @override
  Object get $reified => $value;

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType(type.spec!);
}
