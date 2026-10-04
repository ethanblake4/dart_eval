import 'package:control_flow_graph/control_flow_graph.dart' as cfg;
import 'package:analyzer/dart/ast/ast.dart' show FormalParameter;
import 'package:dart_eval/dart_eval_bridge.dart' show CoreTypes;

import '../../ir/bridge.dart' as bridge;
import '../../ir/closures.dart' as closures;
import '../../ir/collection.dart' as collection;
import '../../ir/flow.dart' as flow;
import '../../ir/function.dart' as fn;
import '../../ir/globals.dart' as globals;
import '../../ir/objects.dart' as objects;
import '../../ir/primitives.dart' as primitives;
import '../context.dart';
import '../invocation/deferred.dart';
import '../type.dart';

typedef _Class = (int, String);

/// Dispatch tables retain bodies for embedding, but an unused table entry
/// does not make a weak tear-off live. Track calls and selectors separately,
/// retaining all members of objects that escape into opaque host code.
Set<int> strongFunctions(
  CompilerContext context,
  Set<int> roots,
  int Function(DeferredOrOffset) resolve,
) {
  final functions = {...roots};
  final classes = <_Class>{};
  final selectors = <String>{'toString', 'hashCode', '==', 'noSuchMethod'};
  final escaped = <_Class>{};
  final callbacks = <int>{};
  final values = <(int, cfg.SSA), Set<_Class>>{};
  final callableValues = <(int, cfg.SSA), Set<int>>{};
  final parameters = <(int, int), Set<_Class>>{};
  final callableParameters = <(int, int), Set<int>>{};
  final captures = <(int, int), Set<_Class>>{};
  final callableCaptures = <(int, int), Set<int>>{};
  final returns = <int, Set<_Class>>{};
  final callableReturns = <int, Set<int>>{};
  final globalValues = <int, Set<_Class>>{};
  final globalCallables = <int, Set<int>>{};
  final heap = <_Class>{};
  final heapCallables = <int>{};
  const unknown = (-1, '*');
  var changed = true;
  void add<T>(Set<T> target, Iterable<T> source) {
    final count = target.length;
    target.addAll(source);
    changed |= count != target.length;
  }

  void merge<K, V>(Map<K, Set<V>> target, K key, Iterable<V> source) =>
      add(target.putIfAbsent(key, () => <V>{}), source);
  Iterable<_Class> valueClasses(int id, Iterable<cfg.SSA> inputs) =>
      inputs.expand((input) => values[(id, input)] ?? const <_Class>{});
  Iterable<int> valueCallables(int id, Iterable<cfg.SSA> inputs) =>
      inputs.expand((input) => callableValues[(id, input)] ?? const <int>{});
  void pass(int callee, int index, int caller, cfg.SSA argument) {
    merge(parameters, (callee, index), valueClasses(caller, [argument]));
    merge(callableParameters, (
      callee,
      index,
    ), valueCallables(caller, [argument]));
  }

  bool mayContainGuest(TypeRef type) => type is FunctionTypeRef
      ? false
      : type.isSpec(CoreTypes.dynamic) ||
            type.isSpec(CoreTypes.object) ||
            !type.isDartCore ||
            interfaceArgumentsOf(type).any(mayContainGuest);
  for (final root in roots) {
    final types = context.functionParameterTypes[root] ?? const <TypeRef>[];
    for (var i = 0; i < types.length; i++) {
      if (mayContainGuest(types[i])) merge(parameters, (root, i), [unknown]);
    }
  }
  while (changed) {
    changed = false;
    for (final key in classes.toList()) {
      final type = context.visibleTypes[key.$1]?[key.$2];
      final bridgeSubclass =
          type != null &&
          context.typeSystem
              .superclassChain(type)
              .any(
                (link) =>
                    nominalDeclOf(link) is BridgeTypeDecl &&
                    !link.isSpec(CoreTypes.object) &&
                    !link.isSpec(CoreTypes.dynamic),
              );
      final members = context.instanceDeclarationPositions[key.$1]![key.$2]!;
      for (final group in members.values) {
        for (final entry in group.entries) {
          if (entry.value >= 0 &&
              (bridgeSubclass ||
                  escaped.contains(unknown) ||
                  escaped.contains(key) ||
                  selectors.contains(entry.key.split('::').last))) {
            add(functions, [entry.value]);
          }
        }
      }
    }
    for (final callback in callbacks.toList()) {
      add(escaped, returns[callback] ?? const <_Class>{});
      add(callbacks, callableReturns[callback] ?? const <int>{});
    }
    for (final id in functions.toList()) {
      add(functions, context.inlinedCallees[id] ?? const <int>{});
      for (final parameter
          in context.functionParameters[id] ?? const <FormalParameter>[]) {
        final thunk = context.defaultThunkCache[parameter.defaultClause?.value];
        if (thunk != null) add(functions, [thunk]);
      }
      final graph = context.ssaFunctionGraphs[id]!;
      for (final block in graph.graph.vertices) {
        for (final op in graph[block]!.code) {
          final inputs = op.readsFrom;
          final inputClasses = valueClasses(id, inputs).toSet();
          final inputCallables = valueCallables(id, inputs).toSet();
          switch (op) {
            case objects.CreateClass(:final library, :final name):
              add(classes, [(library, name)]);
              merge(
                values,
                (id, op.target),
                [(library, name), ...inputClasses],
              );
            case closures.CreateClosure():
              if (op.weak) continue;
              final callee = resolve(op.target);
              add(functions, [
                callee,
                ...op.defaultThunks.where((id) => id >= 0),
              ]);
              merge(callableValues, (id, op.result), [callee]);
              for (var i = 0; i < op.captures.length; i++) {
                merge(captures, (
                  callee,
                  i,
                ), valueClasses(id, [op.captures[i]]));
                merge(callableCaptures, (
                  callee,
                  i,
                ), valueCallables(id, [op.captures[i]]));
              }
              if (op.boundReceiver && op.captures.isNotEmpty) {
                pass(callee, 0, id, op.captures.first);
              }
            case fn.Parameter(:final index):
              merge(values, (
                id,
                op.target,
              ), parameters[(id, index)] ?? const <_Class>{});
              merge(callableValues, (
                id,
                op.target,
              ), callableParameters[(id, index)] ?? const <int>{});
            case closures.LoadCapture(:final index):
              merge(values, (
                id,
                op.result,
              ), captures[(id, index)] ?? const <_Class>{});
              merge(callableValues, (
                id,
                op.result,
              ), callableCaptures[(id, index)] ?? const <int>{});
            case flow.Call():
              final callee = resolve(op.target);
              add(functions, [callee]);
              for (var i = 0; i < op.arguments.length; i++) {
                pass(callee, i, id, op.arguments[i]);
              }
              if (op.result != null) {
                merge(values, (
                  id,
                  op.result!,
                ), returns[callee] ?? const <_Class>{});
                merge(callableValues, (
                  id,
                  op.result!,
                ), callableReturns[callee] ?? const <int>{});
              }
            case flow.Return() || flow.ReturnAsync():
              merge(returns, id, inputClasses);
              merge(callableReturns, id, inputCallables);
            case globals.SetGlobal(:final index):
              merge(globalValues, index, inputClasses);
              merge(globalCallables, index, inputCallables);
            case globals.LoadGlobal(:final index):
              final initializer = context.runtimeGlobalInitializerMap[index];
              if (initializer != null) add(functions, [initializer]);
              merge(values, (
                id,
                op.target,
              ), globalValues[index] ?? const <_Class>{});
              merge(callableValues, (
                id,
                op.target,
              ), globalCallables[index] ?? const <int>{});
            case bridge.InvokeExternal():
              add(escaped, inputClasses);
              add(callbacks, inputCallables);
              merge(values, (id, op.target), [unknown, ...inputClasses]);
              merge(callableValues, (id, op.target), inputCallables);
            case objects.InvokeDynamic(:final name) ||
                objects.LoadPropertyDynamic(:final name) ||
                objects.SetPropertyDynamic(:final name):
              add(selectors, [name.split('::').last]);
              var hasGuestTarget = false;
              for (final key in classes.toList()) {
                final groups =
                    context.instanceDeclarationPositions[key.$1]![key.$2]!;
                for (final group in groups.values) {
                  for (final member in group.entries) {
                    if (member.value < 0 ||
                        member.key.split('::').last != name) {
                      continue;
                    }
                    hasGuestTarget = true;
                    final callee = member.value;
                    final count =
                        context.functionSignatures[callee]!.parameters.length;
                    for (var i = 0; i < count; i++) {
                      merge(parameters, (callee, i), inputClasses);
                      merge(callableParameters, (callee, i), inputCallables);
                    }
                    if (op.writesTo != null) {
                      merge(values, (
                        id,
                        op.writesTo!,
                      ), returns[callee] ?? const <_Class>{});
                      merge(callableValues, (
                        id,
                        op.writesTo!,
                      ), callableReturns[callee] ?? const <int>{});
                      if (op is objects.LoadPropertyDynamic) {
                        merge(callableValues, (id, op.writesTo!), [callee]);
                      }
                    }
                  }
                }
              }
              final receiver = switch (op) {
                objects.InvokeDynamic(:final object) => object,
                objects.LoadPropertyDynamic(:final object) => object,
                objects.SetPropertyDynamic(:final object) => object,
                _ => throw StateError('Unreachable dynamic operation'),
              };
              final receiverClasses = values[(id, receiver)];
              if (!hasGuestTarget ||
                  receiverClasses == null ||
                  receiverClasses.isEmpty ||
                  receiverClasses.contains(unknown)) {
                // A host member can inspect any guest object it receives.
                add(escaped, inputClasses);
                add(callbacks, inputCallables);
              }
              if (op is objects.SetPropertyDynamic) {
                add(heap, valueClasses(id, [op.variable]));
                add(heapCallables, valueCallables(id, [op.variable]));
              }
            case closures.InvokeClosure():
              add(selectors, ['call']);
              for (final callee in valueCallables(id, [op.closure]).toList()) {
                final count =
                    context.functionSignatures[callee]!.parameters.length;
                for (var i = 0; i < count; i++) {
                  merge(parameters, (callee, i), inputClasses);
                  merge(callableParameters, (callee, i), inputCallables);
                }
                merge(values, (
                  id,
                  op.result,
                ), returns[callee] ?? const <_Class>{});
                merge(callableValues, (
                  id,
                  op.result,
                ), callableReturns[callee] ?? const <int>{});
              }
            default:
              if (op is objects.SetPropertyStatic) {
                add(heap, valueClasses(id, [op.value]));
                add(heapCallables, valueCallables(id, [op.value]));
              } else if (op is collection.ListAppend ||
                  op is collection.ListSet ||
                  op is collection.MapSet ||
                  op is collection.SetAdd ||
                  op is closures.WriteCaptureCell) {
                add(heap, inputClasses);
                add(heapCallables, inputCallables);
                for (final input in inputs) {
                  merge(values, (id, input), inputClasses);
                  merge(callableValues, (id, input), inputCallables);
                }
              } else if (op is cfg.Assign ||
                  op is cfg.PhiNode ||
                  op is objects.InternConst ||
                  op is objects.LoadThis ||
                  op is objects.LoadSuper ||
                  op is bridge.PrepareBridgeArgument ||
                  op is primitives.BoxList ||
                  op is primitives.BoxMap ||
                  op is primitives.BoxSet ||
                  op is primitives.MaybeBoxNull ||
                  op is primitives.Unbox ||
                  op is closures.NewCaptureCell ||
                  op is objects.LoadPropertyStatic ||
                  op is closures.ReadCaptureCell ||
                  op is collection.IndexList ||
                  op is collection.IndexMap) {
                final readsHeap =
                    op is objects.LoadPropertyStatic ||
                    op is closures.ReadCaptureCell ||
                    op is collection.IndexList ||
                    op is collection.IndexMap;
                merge(
                  values,
                  (id, op.writesTo!),
                  [
                    if (op is! objects.LoadPropertyStatic) ...inputClasses,
                    if (readsHeap) ...heap,
                  ],
                );
                merge(
                  callableValues,
                  (id, op.writesTo!),
                  [...inputCallables, if (readsHeap) ...heapCallables],
                );
              }
          }
        }
      }
    }
  }
  return functions;
}
