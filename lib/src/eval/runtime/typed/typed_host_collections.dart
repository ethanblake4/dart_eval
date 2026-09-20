import 'dart:collection';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart'
    show TypedRuntimeInterop;
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

  static $Value box(Object collection, Runtime? runtime, {int? runtimeTypeId}) {
    final cache = _cacheFor(runtime);
    final existing = cache.boxed[collection];
    if (existing != null &&
        (runtimeTypeId == null ||
            (runtime != null &&
                runtime.isTypedValueType(existing, runtimeTypeId)))) {
      return existing;
    }
    if (runtimeTypeId case final typeId?) {
      final typed = cache.typedBoxed[collection]?[typeId];
      if (typed != null) return typed;
    }
    Object? read(Object? value) =>
        TypedInterop.boxExternal(value, runtime: runtime);
    Object? write(Object? value) =>
        TypedInterop.exportExternal(value, runtime: runtime);
    final Object backing;
    final $Value wrapper;
    switch (collection) {
      case List<Object?>():
        backing = _ListView(collection, read, write);
        wrapper = $List.wrap(
          backing as List<Object?>,
          runtimeTypeId: runtimeTypeId,
          runtime: runtime,
        );
      case Map<Object?, Object?>():
        backing = _MapView(collection, read, write, write, write);
        wrapper = $Map.wrap(
          backing as Map<Object?, Object?>,
          runtimeTypeId: runtimeTypeId,
          runtime: runtime,
        );
      case Set<Object?>():
        backing = _SetView(collection, read, write, write);
        wrapper = $Set.wrap(
          backing as Set<Object?>,
          runtimeTypeId: runtimeTypeId,
          runtime: runtime,
        );
      default:
        throw ArgumentError.value(collection, 'collection');
    }
    cache.boxed[collection] ??= wrapper;
    if (runtimeTypeId case final typeId?) {
      (cache.typedBoxed[collection] ??= {})[typeId] = wrapper;
    }
    _origins[backing] = collection;
    _contexts[wrapper] = _CollectionContext(runtime);
    return wrapper;
  }

  /// Attach an export declaration's generic contract to an otherwise raw
  /// guest collection wrapper without discarding its lazy element adapter.
  static $Value adoptRuntimeType(
    $Value value,
    Runtime runtime,
    int runtimeTypeId,
  ) {
    final cache = _cacheFor(runtime);
    final cached = cache.typedBoxed[value]?[runtimeTypeId];
    if (cached != null) return cached;

    Object? check(Object? candidate, int argumentIndex) {
      runtime.assertTypedTypeArgument(candidate, runtimeTypeId, argumentIndex);
      return candidate;
    }

    final Object backing;
    final $Value wrapper;
    switch (value) {
      case $List():
        backing = _ListView(
          value.$value.cast<Object?>(),
          (candidate) => candidate,
          (candidate) => check(candidate, 0),
        );
        wrapper = $List.wrap(
          backing as List<Object?>,
          runtimeTypeId: runtimeTypeId,
          runtime: runtime,
        );
      case $Map():
        backing = _MapView(
          value.$value.cast<Object?, Object?>(),
          (candidate) => candidate,
          (candidate) => candidate,
          (candidate) => check(candidate, 0),
          (candidate) => check(candidate, 1),
        );
        wrapper = $Map.wrap(
          backing as Map<Object?, Object?>,
          runtimeTypeId: runtimeTypeId,
          runtime: runtime,
        );
      case $Set():
        backing = _SetView(
          value.$value.cast<Object?>(),
          (candidate) => candidate,
          (candidate) => candidate,
          (candidate) => check(candidate, 0),
        );
        wrapper = $Set.wrap(
          backing as Set<Object?>,
          runtimeTypeId: runtimeTypeId,
          runtime: runtime,
        );
      default:
        throw ArgumentError.value(value, 'value', 'Expected a collection');
    }
    _origins[backing] = export(value.$value, value, runtime);
    _contexts[wrapper] = _CollectionContext(runtime);
    (cache.typedBoxed[value] ??= {})[runtimeTypeId] = wrapper;
    return wrapper;
  }

  static Object export(
    Object collection,
    $Value owner,
    Runtime? requestedRuntime,
  ) {
    if (owner case final $MappedListView<Object?> mapped) {
      return mapped.hostBacking;
    }
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
    Object? query(Object? value) =>
        TypedInterop.boxExternal(value, runtime: runtime);
    Object? write(Object? value, int argumentIndex) {
      final boxed = TypedInterop.boxExternal(value, runtime: runtime);
      if (runtime != null) {
        runtime.assertTypedTypeArgument(
          boxed,
          owner.$getRuntimeType(runtime),
          argumentIndex,
        );
      }
      return boxed;
    }

    final Object view = switch (collection) {
      List<Object?>() => _ListView(
        collection,
        read,
        (value) => write(value, 0),
      ),
      Map<Object?, Object?>() => _MapView(
        collection,
        read,
        query,
        (value) => write(value, 0),
        (value) => write(value, 1),
      ),
      Set<Object?>() => _SetView(
        collection,
        read,
        query,
        (value) => write(value, 0),
      ),
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
  final typedBoxed = Expando<Map<int, $Value>>();
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
  set length(int value) {
    if (value > length) write(null);
    backing.length = value;
  }

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
  _MapView(
    this.backing,
    this.read,
    this.queryKey,
    this.writeKey,
    this.writeValue,
  );
  final Map<Object?, Object?> backing;
  final _Convert read, queryKey, writeKey, writeValue;
  @override
  Iterable<Object?> get keys => backing.keys.map(read);
  @override
  Object? operator [](Object? key) => read(backing[queryKey(key)]);
  @override
  void operator []=(Object? key, Object? value) =>
      backing[writeKey(key)] = writeValue(value);
  @override
  bool containsKey(Object? key) => backing.containsKey(queryKey(key));
  @override
  Object? remove(Object? key) => read(backing.remove(queryKey(key)));
  @override
  void clear() => backing.clear();
}

final class _SetView extends SetBase<Object?> {
  _SetView(this.backing, this.read, this.query, this.write);
  final Set<Object?> backing;
  final _Convert read, query, write;
  @override
  int get length => backing.length;
  @override
  Iterator<Object?> get iterator => backing.map(read).iterator;
  @override
  bool add(Object? value) => backing.add(write(value));
  @override
  bool contains(Object? value) => backing.contains(query(value));
  @override
  bool remove(Object? value) => backing.remove(query(value));
  @override
  Object? lookup(Object? value) => read(backing.lookup(query(value)));
  @override
  Set<Object?> toSet() => Set.of(this);
}
