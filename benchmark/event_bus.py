from support.comparison import run_comparison


class Event:
    def __init__(self, category: str, text: str) -> None:
        self.category = category
        self.text = text


class EventBus:
    def __init__(self) -> None:
        self.listeners = []

    def subscribe(self, listener) -> None:
        self.listeners.append(listener)

    def unsubscribe(self, listener) -> None:
        self.listeners.remove(listener)

    def publish(self, event: Event) -> None:
        for listener in list(self.listeners):
            listener(event)


class AuditSink:
    def __init__(self) -> None:
        self.seen = 0
        self.bytes = 0

    def on_event(self, event: Event) -> None:
        self.seen += 1
        self.bytes += len(event.text)


def main(events: int) -> int:
    bus = EventBus()
    audit = AuditSink()
    audit_listener = audit.on_event
    order_count = 0
    order_bytes = 0
    transient_count = 0
    toggles = 0
    attached = True

    def order_listener(event: Event) -> None:
        nonlocal order_count, order_bytes
        if event.category == 'order' and event.text != 'cancelled':
            order_count += 1
            order_bytes += len(event.text)

    def transient_listener(event: Event) -> None:
        nonlocal transient_count
        if event.category != 'system':
            transient_count += 1

    def controller(event: Event) -> None:
        nonlocal attached, toggles
        if event.category != 'alert':
            return
        toggles += 1
        if attached:
            bus.unsubscribe(transient_listener)
        else:
            bus.subscribe(transient_listener)
        attached = not attached

    bus.subscribe(controller)
    bus.subscribe(audit_listener)
    bus.subscribe(order_listener)
    bus.subscribe(transient_listener)

    categories = ['order', 'system', 'alert', 'order', 'audit', 'alert']
    messages = ['created', 'paid', 'retry', 'delivered', 'ack', 'cancelled']
    for i in range(events):
        bus.publish(Event(categories[i % 6], messages[(i * 5 + 1) % 6]))

    return (audit.seen * 1000003 + audit.bytes * 1009 + order_count * 97
            + order_bytes * 31 + transient_count * 7 + toggles)


if __name__ == '__main__':
    run_comparison(
        'event_bus', main, unit='event',
        iterations=60000, warmup_iterations=1000,
    )
