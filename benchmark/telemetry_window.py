import sys
import time


def main(events):
    devices = 64
    window = 16
    readings = [0] * (devices * window)
    sums = [0] * devices
    counts = [0] * devices
    positions = [0] * devices
    alerts = [0] * devices
    state = 123456789
    alert_score = 0

    for event in range(events):
        state = (state * 1103515245 + 12345) & 0x7fffffff
        device = (state >> 8) & 63
        state = (state * 1103515245 + 12345) & 0x7fffffff
        reading = 20 + ((state >> 9) % 81)
        if event % 97 == 0:
            reading += 180
        if event % 131 == 0:
            reading = 0

        count = counts[device]
        total = sums[device]
        if count >= 8 and reading * count > total * 2:
            alerts[device] += 1
            alert_score += device + reading
        slot = device * window + positions[device]
        old = readings[slot]
        readings[slot] = reading
        sums[device] = total + reading - old
        if count < window:
            counts[device] = count + 1
        positions[device] = (positions[device] + 1) & 15

    checksum = alert_score
    for device in range(devices):
        checksum += sums[device] * (device + 1) + alerts[device] * 17
    return checksum


if __name__ == '__main__':
    events = int(sys.argv[1]) if len(sys.argv) > 1 else 100000
    samples = int(sys.argv[2]) if len(sys.argv) > 2 else 7
    if events < 1 or samples < 7:
        raise ValueError('Positive events and at least seven samples required')

    checksum = 0
    for _ in range(2):
        checksum += main(1000)
    times = []
    for _ in range(samples):
        start = time.perf_counter()
        checksum += main(events)
        times.append((time.perf_counter() - start) * 1000)
    times.sort()
    median = times[len(times) // 2]
    print(f'telemetry_window median_ms={median:.3f} '
          f'min_ms={times[0]:.3f} max_ms={times[-1]:.3f} '
          f'ns/event={median * 1000000 / events:.2f}')
    print(f'checksum={checksum}')
