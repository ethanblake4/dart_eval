import 'dart:io';
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart' show $Value;
import 'package:dart_eval/dart_eval_security.dart';
import 'package:dart_eval/src/eval/shared/stdlib/io/link.dart';
import 'package:test/test.dart';

class _FakeLink implements Link {
  @override
  final String path = 'link-probe';
  int calls = 0;
  @override
  String targetSync() {
    calls++;
    return 'destination';
  }

  @override
  Future<String> target() async => targetSync();
  @override
  String resolveSymbolicLinksSync() {
    calls++;
    return path;
  }

  @override
  Future<String> resolveSymbolicLinks() async => resolveSymbolicLinksSync();
  @override
  void createSync(String target, {bool recursive = false}) {
    calls++;
  }

  @override
  Future<Link> create(String target, {bool recursive = false}) async {
    createSync(target);
    return this;
  }

  @override
  void updateSync(String target) {
    calls++;
  }

  @override
  Future<Link> update(String target) async {
    updateSync(target);
    return this;
  }

  @override
  Link renameSync(String newPath) {
    calls++;
    return Link(newPath);
  }

  @override
  Future<Link> rename(String newPath) async => renameSync(newPath);
  @override
  void deleteSync({bool recursive = false}) {
    calls++;
  }

  @override
  Future<FileSystemEntity> delete({bool recursive = false}) async {
    deleteSync();
    return this;
  }

  @override
  bool existsSync() {
    calls++;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const library = 'package:link_probe/main.dart';
  test(
    'fresh and encoded Link API enforces receiver and destination permissions',
    () async {
      final program = Compiler().compile({
        'link_probe': {
          'main.dart': r'''
import 'dart:io';
String construct() => Link('link-probe').path;
String fromUri() => Link.fromUri(Uri.file('link-probe')).path;
String inherited(Link link) { FileSystemEntity entity = link; return entity.path; }
bool exists(Link link) { FileSystemEntity entity = link; return entity.existsSync(); }
String read(Link link) => link.targetSync();
String resolve(Link link) => link.resolveSymbolicLinksSync();
Future<String> readAsync(Link link) => link.target();
Future<String> resolveAsync(Link link) => link.resolveSymbolicLinks();
void create(Link link) => link.createSync('destination');
void update(Link link) => link.updateSync('destination');
Future<Link> createAsync(Link link) => link.create('destination');
Future<Link> updateAsync(Link link) => link.update('destination');
void delete(Link link) => link.deleteSync();
Future<FileSystemEntity> deleteAsync(Link link) => link.delete();
Link rename(Link link) => link.renameSync('link-probe-renamed');
Future<Link> renameAsync(Link link) => link.rename('link-probe-renamed');
''',
        },
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        final host = _FakeLink();
        final wrapped = $Link.wrap(host);
        Object? call(String name) =>
            runtime.executeLib(library, name, arguments: {'link': wrapped});
        expect(runtime.executeLib(library, 'construct'), 'link-probe');
        expect(runtime.executeLib(library, 'fromUri'), 'link-probe');
        expect(call('inherited'), host.path);
        const reads = [
          'read',
          'resolve',
          'readAsync',
          'resolveAsync',
          'exists',
        ];
        const writes = [
          'create',
          'update',
          'createAsync',
          'updateAsync',
          'delete',
          'deleteAsync',
          'rename',
          'renameAsync',
        ];
        for (final method in [...reads, ...writes]) {
          expect(() => call(method), throwsA(isA<Exception>()), reason: method);
        }
        expect(host.calls, 0);
        runtime.grant(FilesystemPermission.file('unrelated-link'));
        expect(() => call('read'), throwsA(isA<Exception>()));
        expect(host.calls, 0);
        runtime.grant(FilesystemReadPermission.file(host.path));
        for (final method in reads) {
          await Future<Object?>.value(call(method));
        }
        expect(host.calls, reads.length);
        expect(() => call('create'), throwsA(isA<Exception>()));
        runtime.grant(FilesystemWritePermission.file(host.path));
        for (final method in writes.where(
          (name) => !name.startsWith('rename'),
        )) {
          await Future<Object?>.value(call(method));
        }
        final beforeRename = host.calls;
        for (final method in ['rename', 'renameAsync']) {
          expect(() => call(method), throwsA(isA<Exception>()));
        }
        expect(host.calls, beforeRename);
        runtime.grant(FilesystemWritePermission.file('link-probe-renamed'));
        for (final method in ['rename', 'renameAsync']) {
          final result = await Future<Object?>.value(call(method));
          final link = (result is $Value ? result.$value : result) as Link;
          expect(link.path, 'link-probe-renamed');
        }
        expect(host.calls, beforeRename + 2);
      }
    },
  );
}
