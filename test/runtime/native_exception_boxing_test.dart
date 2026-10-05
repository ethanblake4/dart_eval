import 'dart:io';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/dart_eval_security.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_exception_state.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

const _library = 'package:boxing/main.dart';
const _bridge = 'package:boxing/host.dart';
const _markerSpec = BridgeTypeSpec(_bridge, 'Marker');

class _Marker implements Exception {}

class _MarkerWrapper extends $Object {
  _MarkerWrapper(_Marker super.value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType(_markerSpec);
}

class _ExceptionPlugin implements EvalPlugin {
  _ExceptionPlugin(this.error);
  final Object error;

  @override
  String get identifier => _bridge;

  @override
  void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass(
      const BridgeClassDef(
        BridgeClassType(
          BridgeTypeRef(_markerSpec),
          $implements: [BridgeTypeRef(CoreTypes.exception)],
        ),
        constructors: {},
        methods: {},
        getters: {},
        setters: {},
        fields: {},
        wrap: true,
      ),
    );
    registry.defineBridgeTopLevelFunction(
      const BridgeFunctionDeclaration(
        _bridge,
        'fail',
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
        ),
      ),
    );
  }

  @override
  void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      _bridge,
      'fail',
      (_, r, s, c) => throw error,
    );
    runtime.addTypeAutowrapper(
      (value) => value is _Marker ? _MarkerWrapper(value) : null,
    );
  }
}

Iterable<(String, Runtime)> _runtimes(Program program) sync* {
  yield ('fresh', Runtime.ofProgram(program));
  yield ('encoded', Runtime(program.write().buffer));
}

Object? _host(Object? value) => value is $Value ? value.$reified : value;

void main() {
  test(
    'real missing-file subtype retains fields through sync and async catches',
    () async {
      final directory = Directory.systemTemp.createTempSync('eval-boxing-');
      addTearDown(() => directory.deleteSync());
      final path = '${directory.path}/missing';
      late FileSystemException hostError;
      try {
        File(path).readAsStringSync();
        fail('Missing file unexpectedly exists');
      } on FileSystemException catch (error) {
        hostError = error;
      }
      expect(hostError, isA<PathNotFoundException>());
      final compiler = Compiler()..addPlugin(_ExceptionPlugin(hostError));
      final program = compiler.compile({
        'boxing': {
          'main.dart': r'''
        import 'dart:io';
        import 'host.dart';
        Object rethrowHost(String path) {
          try {
            try { fail(); } on FileSystemException { rethrow; }
          } on FileSystemException catch (caught) { return caught; }
          throw StateError('uncaught');
        }
        Object read(String path) {
          try { File(path).readAsStringSync(); }
          on FileSystemException catch (caught) {
            if (caught is! Exception || caught.path != path ||
                caught.message.isEmpty || caught.osError == null ||
                !caught.toString().contains(path)) throw StateError('fields');
            try { rethrow; } on FileSystemException catch (again) {
              if (!identical(caught, again)) throw StateError('identity');
              return again;
            }
          }
          throw StateError('uncaught');
        }
        Object base(String path) {
          try { File(path).readAsStringSync(); }
          on Exception catch (caught) {
            if (caught is! FileSystemException) throw StateError('erased');
            return caught;
          }
          throw StateError('uncaught');
        }
        Future<Object> awaited(String path) async {
          try { await File(path).readAsString(); }
          on FileSystemException catch (caught) { return caught; }
          throw StateError('uncaught');
        }
      ''',
        },
      });
      for (final (kind, runtime) in _runtimes(program)) {
        runtime.addPlugin(_ExceptionPlugin(hostError));
        runtime.grant(FilesystemReadPermission.file(path));
        for (final entry in ['read', 'base', 'awaited', 'rethrowHost']) {
          final result = runtime.executeLib(
            _library,
            entry,
            arguments: {'path': path},
          );
          final caught = _host(result is Future ? await result : result);
          expect(caught, isA<PathNotFoundException>(), reason: '$kind $entry');
          if (entry == 'rethrowHost') expect(caught, same(hostError));
          final error = caught as FileSystemException;
          expect(error.path, path);
          expect(error.message, hostError.message);
          expect(error.osError?.errorCode, hostError.osError?.errorCode);
          expect(error.osError?.message, hostError.osError?.message);
          expect(error.toString(), hostError.toString());
        }
      }
    },
  );

  test(
    'registered non-IO exceptions, strict negatives and fallback preserve identity',
    () {
      final compiler = Compiler()..addPlugin(_ExceptionPlugin(_Marker()));
      final program = compiler.compile({
        'boxing': {
          'main.dart': r'''
        import 'dart:io';
        import 'host.dart';
        Object main() {
          try {
            try { fail(); }
            on FileSystemException { throw StateError('wrong catch'); }
            on Marker catch (caught) {
              if (caught is! Exception) throw StateError('base');
              rethrow;
            }
          } on Marker catch (caught) { return caught; }
          on FormatException catch (caught) { return caught; }
          on StateError catch (caught) { return caught; }
          on Exception catch (caught) { return caught; }
          throw StateError('uncaught');
        }
      ''',
        },
      });
      for (final error in <Object>[
        _Marker(),
        FormatException('format'),
        StateError('state'),
        Exception('fallback'),
      ]) {
        for (final (kind, runtime) in _runtimes(program)) {
          runtime.addPlugin(_ExceptionPlugin(error));
          expect(
            _host(runtime.executeLib(_library, 'main')),
            same(error),
            reason: kind,
          );
        }
      }
    },
  );

  test(
    'built-in wrappers allow isolate bootstrap; user closures remain rejected',
    () {
      final program = Compiler().compile({
        'boxing': {'main.dart': 'int main() => 0;'},
      });
      for (final (_, runtime) in _runtimes(program)) {
        expect(runtime.guestIsolateProgram(), isNotEmpty);
        runtime.addTypeAutowrapper((value) => null);
        expect(runtime.guestIsolateProgram, throwsUnsupportedError);
      }
      final runtime = Runtime.ofProgram(program)..initialize();
      final failure = StateError('wrapper failed');
      runtime.addTypeAutowrapper((value) => throw failure);
      expect(() => runtime.wrapRegistered(Object()), throwsA(same(failure)));
      expect(() => runtime.wrap(Object()), throwsA(same(failure)));
      expect(
        () => TypedExceptionState.boxException(Exception(), runtime),
        throwsA(same(failure)),
      );
      final standard = StateError('standard');
      expect(
        TypedExceptionState.boxException(standard, runtime)?.$value,
        same(standard),
      );
      final boxed = $Exception.wrap(Exception());
      expect(TypedExceptionState.boxException(boxed, runtime), same(boxed));
      final fallback = Exception('no runtime');
      expect(
        TypedExceptionState.boxException(fallback, null)?.$value,
        same(fallback),
      );
    },
  );
}
