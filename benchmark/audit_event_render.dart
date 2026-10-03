import 'package:dart_eval/dart_eval.dart';

// Render multiline audit events with mixed String, int and bool values.
// Build the host with AOT. Arguments: events samples interpolation|buffer
// parts (6|12|24) short|long. Event setup runs during warmup, before timing.
const _eventSource = r'''
class AuditEvent {
  final String timestamp;
  final String tenant;
  final String actor;
  final String action;
  final String resource;
  final String requestId;
  final int status;
  final int elapsed;
  final int bytes;
  final int attempt;
  final bool success;
  final String message;
  AuditEvent(this.timestamp, this.tenant, this.actor, this.action,
      this.resource, this.requestId, this.status, this.elapsed,
      this.bytes, this.attempt, this.success, this.message);
}
''';

const _fields = <(String, String)>[
  ('time', 'timestamp'),
  ('tenant', 'tenant'),
  ('status', 'status'),
  ('elapsed_ms', 'elapsed'),
  ('success', 'success'),
  ('message', 'message'),
  ('actor', 'actor'),
  ('action', 'action'),
  ('resource', 'resource'),
  ('request', 'requestId'),
  ('bytes', 'bytes'),
  ('attempt', 'attempt'),
  ('context.time', 'timestamp'),
  ('context.tenant', 'tenant'),
  ('outcome.status', 'status'),
  ('outcome.elapsed_ms', 'elapsed'),
  ('outcome.success', 'success'),
  ('outcome.message', 'message'),
  ('context.actor', 'actor'),
  ('context.action', 'action'),
  ('context.resource', 'resource'),
  ('context.request', 'requestId'),
  ('outcome.bytes', 'bytes'),
  ('outcome.attempt', 'attempt'),
];

const _valueIndices = [0, 1, 6, 7, 10, 11, 2, 3, 4, 5, 8, 9];

List<List<Object>> _events(bool longMessages) {
  final detail = longMessages
      ? ' Inventory reservations were reconciled against the warehouse feed;'
            ' the final allocation and customer notification were recorded.'
      : '';
  return [
    [
      '2026-10-03T09:41:00Z',
      'north',
      'ada',
      'create',
      'orders/1042',
      'req-a17',
      201,
      18,
      640,
      1,
      true,
      'Order accepted.$detail',
    ],
    [
      '2026-10-03T09:41:01Z',
      'west',
      'ben',
      'update',
      'orders/1043',
      'req-b28',
      409,
      37,
      128,
      2,
      false,
      'Reservation conflict.$detail',
    ],
    [
      '2026-10-03T09:41:02Z',
      'south',
      'cy',
      'ship',
      'orders/1044',
      'req-c39',
      200,
      24,
      1024,
      1,
      true,
      'Shipment scheduled.$detail',
    ],
    [
      '2026-10-03T09:41:03Z',
      'east',
      'dia',
      'cancel',
      'orders/1045',
      'req-d40',
      200,
      9,
      256,
      3,
      true,
      'Cancellation confirmed.$detail',
    ],
  ];
}

String _literal(Object value) => value is String
    ? "'${value.replaceAll('\\', '\\\\').replaceAll("'", "\\'")}'"
    : value.toString();

/// Source generation changes only the renderer, keeping input and checksum work
/// identical across the interpolation and explicit-buffer causal control.
String sourceFor(String mode, int parts, {bool longMessages = false}) {
  if (mode != 'interpolation' && mode != 'buffer') {
    throw ArgumentError.value(mode, 'mode');
  }
  if (parts != 6 && parts != 12 && parts != 24) {
    throw ArgumentError.value(parts, 'parts');
  }
  final fields = _fields.take(parts);
  final renderer = mode == 'interpolation'
      ? "return '${fields.map((field) => '${field.$1}=\${e.${field.$2}}\\n').join()}';"
      : 'final out = StringBuffer();\n'
            '${fields.map((field) => "out.write('${field.$1}='); out.write(e.${field.$2}); out.write('\\n');").join('\n')}\n'
            'return out.toString();';
  final events = _events(
    longMessages,
  ).map((event) => 'AuditEvent(${event.map(_literal).join(', ')})').join(',\n');
  return '''$_eventSource
final events = <AuditEvent>[$events];
String render(AuditEvent e) {
  $renderer
}
int main(int count) {
  var checksum = 0;
  for (var i = 0; i < count; i++) {
    final text = render(events[i & 3]);
    checksum += text.length + text.codeUnitAt(0) * 31 +
        text.codeUnitAt(text.length ~/ 2) +
        text.codeUnitAt(text.length - 2) * 7;
  }
  return checksum;
}
''';
}

int expectedChecksum(int count, int parts, {bool longMessages = false}) {
  final scores = _events(longMessages).map((event) {
    final out = StringBuffer();
    for (var field = 0; field < parts; field++) {
      out.write(_fields[field].$1);
      out.write('=');
      out.write(event[_valueIndices[field % 12]]);
      out.write('\n');
    }
    final text = out.toString();
    return text.length +
        text.codeUnitAt(0) * 31 +
        text.codeUnitAt(text.length ~/ 2) +
        text.codeUnitAt(text.length - 2) * 7;
  }).toList();
  final cycles = count ~/ 4;
  return cycles * scores.fold<int>(0, (sum, score) => sum + score) +
      scores.take(count & 3).fold<int>(0, (sum, score) => sum + score);
}

void main(List<String> args) {
  final count = args.isEmpty ? 20000 : int.parse(args[0]);
  final samples = args.length < 2 ? 15 : int.parse(args[1]);
  final mode = args.length < 3 ? 'interpolation' : args[2];
  final parts = args.length < 4 ? 12 : int.parse(args[3]);
  final length = args.length < 5 ? 'short' : args[4];
  if (count < 1 || samples < 7 || (length != 'short' && length != 'long')) {
    throw ArgumentError('Positive count, at least seven samples, short|long');
  }
  final longMessages = length == 'long';
  const library = 'package:audit_event_render/main.dart';
  final compiler = Compiler()..entrypoints.add(library);
  final program = compiler.compile({
    'audit_event_render': {
      'main.dart': sourceFor(mode, parts, longMessages: longMessages),
    },
  });
  final expected = expectedChecksum(count, parts, longMessages: longMessages);
  for (final (label, runtime) in [
    ('fresh', Runtime.ofProgram(program)),
    ('serialized', Runtime(program.write().buffer)),
  ]) {
    int run(int events) =>
        runtime.executeLib(library, 'main', arguments: {'count': events})
            as int;
    for (var warm = 0; warm < 2; warm++) {
      if (run(100) !=
          expectedChecksum(100, parts, longMessages: longMessages)) {
        throw StateError('$label warmup checksum mismatch');
      }
    }
    final times = <double>[];
    for (var sample = 0; sample < samples; sample++) {
      final watch = Stopwatch()..start();
      final result = run(count);
      watch.stop();
      if (result != expected) {
        throw StateError('$label checksum $result != $expected');
      }
      times.add(watch.elapsedMicroseconds / 1000);
    }
    final raw = List<double>.of(times);
    times.sort();
    final median = times[times.length ~/ 2];
    print(
      'audit_event_render_${mode}_${parts}_$length $label '
      'median_ms=${median.toStringAsFixed(3)} '
      'ns/event=${(median * 1000000 / count).toStringAsFixed(2)} '
      'raw_ms=${raw.map((time) => time.toStringAsFixed(3)).join(',')} '
      'checksum=$expected',
    );
  }
}
