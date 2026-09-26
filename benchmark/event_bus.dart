import 'support/comparison.dart';

// Dispatch application events through a snapshot of subscriptions. An alert
// listener changes another subscription while the current event is in flight.
// dart compile exe benchmark/event_bus.dart -o .dart_tool/event-baseline.exe
// .dart_tool/event-baseline.exe [events] [samples]
const _source = r'''
class Event {
  Event(this.category, this.text);
  final String category;
  final String text;
}

typedef EventListener = void Function(Event);

class EventBus {
  final List<EventListener> _listeners = [];

  void subscribe(EventListener listener) => _listeners.add(listener);
  void unsubscribe(EventListener listener) => _listeners.remove(listener);

  void publish(Event event) {
    final snapshot = _listeners.toList();
    for (final listener in snapshot) {
      listener(event);
    }
  }
}

class AuditSink {
  int seen = 0;
  int bytes = 0;

  void onEvent(Event event) {
    seen++;
    bytes += event.text.length;
  }
}

int main(int events) {
  final bus = EventBus();
  final audit = AuditSink();
  final auditListener = audit.onEvent;
  var orderCount = 0;
  var orderBytes = 0;
  var transientCount = 0;
  var toggles = 0;
  var attached = true;

  void orderListener(Event event) {
    if (event.category == 'order' && event.text != 'cancelled') {
      orderCount++;
      orderBytes += event.text.length;
    }
  }

  void transientListener(Event event) {
    if (event.category != 'system') {
      transientCount++;
    }
  }

  void controller(Event event) {
    if (event.category != 'alert') return;
    toggles++;
    if (attached) {
      bus.unsubscribe(transientListener);
    } else {
      bus.subscribe(transientListener);
    }
    attached = !attached;
  }

  bus.subscribe(controller);
  bus.subscribe(auditListener);
  bus.subscribe(orderListener);
  bus.subscribe(transientListener);

  final categories = ['order', 'system', 'alert', 'order', 'audit', 'alert'];
  final messages = [
    'created', 'paid', 'retry', 'delivered', 'ack', 'cancelled',
  ];
  for (var i = 0; i < events; i++) {
    bus.publish(Event(categories[i % 6], messages[(i * 5 + 1) % 6]));
  }
  return audit.seen * 1000003 + audit.bytes * 1009 + orderCount * 97 +
      orderBytes * 31 + transientCount * 7 + toggles;
}
''';

void main(List<String> args) => runComparison(
  args,
  name: 'event_bus',
  source: _source,
  parameter: 'events',
  unit: 'event',
  iterations: 60000,
  warmupIterations: 1000,
);
