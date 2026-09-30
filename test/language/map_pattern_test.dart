import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _source = r'''
class ProbeMap<K, V> implements Map<K, V> {
  ProbeMap(this.backing, this.events);

  final Map<K, V> backing;
  final List<String> events;

  @override
  V? operator [](Object? key) {
    events.add('get:$key');
    return backing[key as K];
  }

  @override
  bool containsKey(Object? key) {
    events.add('contains:$key');
    return backing.containsKey(key);
  }

  @override
  int get length {
    events.add('length');
    throw StateError('Map patterns must not read length');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MapPretender {
  final events = <String>[];

  Object? operator [](Object? key) {
    events.add('get:$key');
    throw StateError('non-Map index access');
  }

  bool containsKey(Object? key) {
    events.add('contains:$key');
    throw StateError('non-Map containsKey access');
  }
}

bool matchesPresentNull(Object value) => switch (value) {
  {'present': null} => true,
  _ => false,
};

bool matchesOrdered(Object value) => switch (value) {
  {'first': 1, 'second': var second} => second == 2,
  _ => false,
};

int typedValue(Map<String, int> value) => switch (value) {
  {'value': int result} => result,
  _ => -1,
};

int capturedValue(Object value) {
  switch (value) {
    case {'first': int _ && var result} ||
        {'second': int _ && var result}:
      final saved = () => result;
      result++;
      return saved();
    default:
      return -1;
  }
}

int main() {
  final missingEvents = <String>[];
  if (matchesPresentNull(ProbeMap({'extra': 1}, missingEvents))) {
    throw StateError('missing key matched null');
  }
  if (missingEvents.join(',') != 'get:present,contains:present') {
    throw StateError('missing-key lookup order: $missingEvents');
  }

  final nullEvents = <String>[];
  if (!matchesPresentNull(
    ProbeMap({'present': null, 'extra': 1}, nullEvents),
  )) {
    throw StateError('present null did not match');
  }
  if (nullEvents.join(',') != 'get:present,contains:present') {
    throw StateError('present-null lookup order: $nullEvents');
  }

  final pretender = MapPretender();
  if (matchesPresentNull(pretender) || pretender.events.isNotEmpty) {
    throw StateError('unrelated map-like object was accessed');
  }

  final shortCircuitEvents = <String>[];
  if (matchesOrdered(
    ProbeMap({'first': 0, 'second': 2}, shortCircuitEvents),
  )) {
    throw StateError('failed first entry matched');
  }
  if (shortCircuitEvents.join(',') != 'get:first') {
    throw StateError('entry tests were eager: $shortCircuitEvents');
  }

  final typedEvents = <String>[];
  final typed = typedValue(ProbeMap({'value': 7}, typedEvents));
  if (typed != 7 || typedEvents.join(',') != 'get:value') {
    throw StateError('typed lookup path: $typed / $typedEvents');
  }

  if (capturedValue({'second': 9}) != 10) {
    throw StateError('OR pattern capture failed');
  }
  return 0;
}
''';

const _irrefutableSource = r'''
class DynamicBox {
  dynamic get value => 'wrong';
}

void expectFailure(bool typeError, void Function() body) {
  var failed = false;
  try {
    body();
  } catch (e) {
    failed = typeError ? e is TypeError : e is StateError;
  }
  if (!failed) throw StateError('wrong pattern failure kind');
}

T? readGeneric<T>(Map<String, T> map) {
  var {'value': value} = map;
  return value;
}

int main() {
  expectFailure(true, () {
    dynamic value = 'wrong';
    var (int result) = value;
  });
  expectFailure(true, () {
    dynamic value = ('wrong',);
    var (int result,) = value;
  });
  expectFailure(false, () {
    var <dynamic>[int _] = <String>['wrong'];
  });
  expectFailure(false, () {
    var <String, dynamic>{'value': int _} = <String, dynamic>{'value': 'wrong'};
  });
  expectFailure(false, () {
    var DynamicBox(value: int result) = DynamicBox();
  });
  expectFailure(false, () {
    var DynamicBox(value: int _) = DynamicBox();
  });
  dynamic missing = <String, Object?>{};
  var declarationFailed = false;
  try {
    var {'value': _} = missing;
  } on StateError {
    declarationFailed = true;
  }
  if (!declarationFailed) throw StateError('missing declaration key accepted');

  var assigned = 0;
  dynamic missingInt = <String, int>{};
  var assignmentFailed = false;
  try {
    ({'value': assigned} = missingInt);
  } on StateError {
    assignmentFailed = true;
  }
  if (!assignmentFailed) throw StateError('missing assignment key accepted');

  dynamic wrongLeaf = <String, dynamic>{'value': 'wrong'};
  var leafFailed = false;
  try {
    var {'value': int _} = wrongLeaf;
  } on TypeError {
    leafFailed = true;
  }
  if (!leafFailed) throw StateError('wrong typed leaf accepted');

  var first = 10, second = 20;
  var missingAssignmentFailed = false;
  try {
    ({'first': first, 'second': second} = <String, dynamic>{'first': 1});
  } on StateError {
    missingAssignmentFailed = true;
    if (first != 10 || second != 20) {
      throw StateError('failed map assignment changed its targets');
    }
  }
  if (!missingAssignmentFailed) throw StateError('missing assignment key accepted');

  try {
    [first, second] = <dynamic>[1, 'wrong'];
    throw StateError('wrong assignment leaf accepted');
  } on TypeError {
    if (first != 10 || second != 20) {
      throw StateError('failed list assignment changed its targets');
    }
  }

  dynamic dynamicList = <dynamic>[1];
  var contextFailed = false;
  try {
    var [int value] = dynamicList;
  } on TypeError {
    contextFailed = true;
  }
  if (!contextFailed) throw StateError('dynamic list ignored pattern context');
  var [int staticValue] = <dynamic>[1];
  if (staticValue != 1) throw StateError('static list checked wrong context');

  if (readGeneric<int?>({'value': null}) != null) {
    throw StateError('present null was not accepted for nullable T');
  }

  var captured = 1;
  final readCaptured = () => captured;
  ({'value': captured} = <String, int>{'value': 8});
  if (readCaptured() != 8) throw StateError('captured assignment was stale');
  void writeCaptured() {
    ({'value': captured} = <String, int>{'value': 10});
  }
  writeCaptured();
  if (readCaptured() != 10) throw StateError('closure assignment was stale');
  return 0;
}
''';

void _expectBothRuntimes(String package, String source) {
  final program = Compiler().compile({
    package: {'main.dart': source},
  });
  for (final runtime in [
    Runtime.ofProgram(program),
    Runtime(program.write().buffer),
  ]) {
    expect(runtime.executeLib('package:$package/main.dart', 'main'), 0);
  }
}

void main() {
  test('map patterns check keys lazily and preserve map semantics', () {
    _expectBothRuntimes('map_pattern', _source);
  });

  test('irrefutable map patterns throw and update captured assignments', () {
    _expectBothRuntimes('map_pattern_irrefutable', _irrefutableSource);
  });
}
