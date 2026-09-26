from support.comparison import run_comparison


def main(appointments: int) -> int:
    starts = [0] * appointments
    ends = [0] * appointments
    state = 123456789
    next_start = 0

    for i in range(appointments):
        state = (state * 1103515245 + 12345) & 0x7fffffff
        next_start += 12 + state % 12
        state = (state * 1103515245 + 12345) & 0x7fffffff
        starts[i] = next_start
        ends[i] = next_start + 20 + ((state >> 8) % 61)

    booked_minutes = 0
    last_end = 0
    conflicts = 0
    conflict_minutes = 0
    for i in range(appointments):
        start = starts[i]
        end = ends[i]
        covered_from = start if start > last_end else last_end
        covered_to = end if end > last_end else last_end
        booked_minutes += covered_to - covered_from
        last_end = covered_to

        first = i - 6 if i > 6 else 0
        for j in range(first, i):
            overlap_start = start if start > starts[j] else starts[j]
            overlap_end = end if end < ends[j] else ends[j]
            if overlap_end > overlap_start:
                conflicts += 1
                conflict_minutes += overlap_end - overlap_start

    return booked_minutes + conflicts * 997 + conflict_minutes * 31


if __name__ == '__main__':
    run_comparison(
        'interval_overlap', main, unit='appointment',
        iterations=100000, warmup_iterations=1000,
    )
