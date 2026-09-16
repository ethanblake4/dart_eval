import 'dart:collection';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'typed_interop.dart';

/// Lazy boundary views preserve aliases, cycles, and mutation in both directions.
abstract final class TypedHostCollections {
  static final _runtimeCaches = Expando<_CollectionCaches>();
  static final _standaloneCache = _CollectionCaches();

  static _CollectionCaches _cacheFor(Runtime? runtime) => runtime == null
      ? _standaloneCache
      : _runtimeCaches[runtime] ??= _CollectionCaches();
  static final _origins = Expando<Object>();
  static final _contexts = Expando<_CollectionContext>();

  static $Value box(Object collection, Runtime? runtime) {
    final cache = _cacheFor(runtime);
    final existing = cache.boxed[collection];
    if (existing != null) return existing;
    Object? read(Object? value) =>
        TypedInterop.boxExternal(value, runtime: runtime);
    Object? write(Object? value) =>
        TypedInterop.exportExternal(value, runtime: runtime);
    final Object backing;
    final $Value wrapper;
    switch (collection) {
      case List<Object?>():
        backing = _ListView(collection, read, write);
        wrapper = $List.wrap(backing as List<Object?>);
      case Map<Object?, Object?>():
        backing = _MapView(collection, read, write);
        wrapper = $Map.wrap(backing as Map<Object?, Object?>);
      case Set<Object?>():
        backing = _SetView(collection, read, write);
        wrapper = $Set.wrap(backing as Set<Object?>);
      default:
        throw ArgumentError.value(collection, 'collection');
    }
    cache.boxed[collection] = wrapper;
    _origins[backing] = collection;
    _contexts[wrapper] = _CollectionContext(runtime);
    return wrapper;
  }

  static Object export(
    Object collection,
    $Value owner,
    Runtime? requestedRuntime,
  ) {
    // A statically boxed collection may already be a bridge wrapper when it
    // entered through a host adapter. Peel that layer before cache lookup so
    // returning a host collection preserves its original identity.
    if (collection case final $List nested) {
      return export(nested.$value, nested, requestedRuntime);
    }
    if (collection case final $Map nested) {
      return export(nested.$value, nested, requestedRuntime);
    }
    if (collection case final $Set nested) {
      return export(nested.$value, nested, requestedRuntime);
    }
    final origin = _origins[collection];
    if (origin != null) return origin;
    final runtime = requestedRuntime ?? _contexts[owner]?.runtime;
    final cache = _cacheFor(runtime);
    final existing = cache.exported[collection];
    if (existing != null) return existing;
    Object? read(Object? value) =>
        TypedInterop.exportExternal(value, runtime: runtime);
    Object? write(Object? value) =>
        TypedInterop.boxExternal(value, runtime: runtime);
    final Object view = switch (collection) {
      List<Object?>() => _ListView(collection, read, write),
      Map<Object?, Object?>() => _MapView(collection, read, write),
      Set<Object?>() => _SetView(collection, read, write),
      _ => throw ArgumentError.value(collection, 'collection'),
    };
    cache.exported[collection] = view;
    cache.boxed[view] = owner;
    _contexts[owner] ??= _CollectionContext(runtime);
    return view;
  }
}

final class _CollectionCaches {
  final boxed = Expando<$Value>();
  final exported = Expando<Object>();
}

final class _CollectionContext {
  const _CollectionContext(this.runtime);
  final Runtime? runtime;
}

typedef _Convert = Object? Function(Object?);

final class _ListView extends ListBase<Object?> {
  _ListView(this.backing, this.read, this.write);
  final List<Object?> backing;
  final _Convert read, write;
  @override
  int get length => backing.length;
  @override
  set length(int value) => backing.length = value;
  @override
  Object? operator [](int index) => read(backing[index]);
  @override
  void operator []=(int index, Object? value) => backing[index] = write(value);
  @override
  void add(Object? value) => backing.add(write(value));
  @override
  void addAll(Iterable<Object?> values) {
    for (final value in values.map(write).toList()) {
      backing.add(value);
    }
  }

  @override
  void insert(int index, Object? value) => backing.insert(index, write(value));
  @override
  void insertAll(int index, Iterable<Object?> values) {
    RangeError.checkValueInInterval(index, 0, length, 'index');
    for (final value in values.map(write).toList()) {
      backing.insert(index++, value);
    }
  }

  @override
  void replaceRange(int start, int end, Iterable<Object?> values) {
    RangeError.checkValidRange(start, end, length);
    final replacement = values.map(write).toList();
    final removed = end - start;
    final shared = replacement.length < removed ? replacement.length : removed;
    for (var i = 0; i < shared; i++) {
      backing[start + i] = replacement[i];
    }
    if (replacement.length < removed) {
      backing.removeRange(start + replacement.length, end);
    } else {
      for (var i = shared; i < replacement.length; i++) {
        backing.insert(start + i, replacement[i]);
      }
    }
  }
}

final class _MapView extends MapBase<Object?, Object?> {
  _MapView(this.backing, this.read, this.write);
  final Map<Object?, Object?> backing;
  final _Convert read, write;
  @override
  Iterable<Object?> get keys => backing.keys.map(read);
  @override
  Object? operator [](Object? key) => read(backing[write(key)]);
  @override
  void operator []=(Object? key, Object? value) =>
      backing[write(key)] = write(value);
  @override
  bool containsKey(Object? key) => backing.containsKey(write(key));
  @override
  Object? remove(Object? key) => read(backing.remove(write(key)));
  @override
  void clear() => backing.clear();
}

final class _SetView extends SetBase<Object?> {
  _SetView(this.backing, this.read, this.write);
  final Set<Object?> backing;
  final _Convert read, write;
  @override
  int get length => backing.length;
  @override
  Iterator<Object?> get iterator => backing.map(read).iterator;
  @override
  bool add(Object? value) => backing.add(write(value));
  @override
  bool contains(Object? value) => backing.contains(write(value));
  @override
  bool remove(Object? value) => backing.remove(write(value));
  @override
  Object? lookup(Object? value) => read(backing.lookup(write(value)));
  @override
  Set<Object?> toSet() => Set.of(this);
}
