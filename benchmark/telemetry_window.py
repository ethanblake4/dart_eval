from support.comparison import run_comparison


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
    run_comparison(
        'telemetry_window', main, unit='event',
        iterations=100000, warmup_iterations=1000,
    )
