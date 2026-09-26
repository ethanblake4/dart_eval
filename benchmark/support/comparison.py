import sys
import time
from collections.abc import Callable
from statistics import median


def run_comparison(
    name: str,
    run: Callable[[int], int],
    *,
    unit: str,
    iterations: int,
    warmup_iterations: int,
    default_samples: int = 7,
) -> None:
    """Match comparison.dart's warmups, timing boundaries, and checksum."""
    count = int(sys.argv[1]) if len(sys.argv) > 1 else iterations
    samples = int(sys.argv[2]) if len(sys.argv) > 2 else default_samples
    if count < 1 or samples < 7:
        raise ValueError('Positive iterations and at least seven samples required')

    checksum = 0
    for _ in range(2):
        checksum += run(warmup_iterations)
    times = []
    expected = None
    for _ in range(samples):
        start = time.perf_counter()
        result = run(count)
        elapsed = (time.perf_counter() - start) * 1000
        if expected is not None and result != expected:
            raise RuntimeError(f'Result changed between samples: {expected} -> {result}')
        expected = result
        checksum += result
        times.append(elapsed)
    ordered = sorted(times)
    middle = median(ordered)
    print(f'{name} median_ms={middle:.3f} '
          f'min_ms={ordered[0]:.3f} max_ms={ordered[-1]:.3f} '
          f'ns/{unit}={middle * 1000000 / count:.2f} '
          f'raw_ms={",".join(f"{value:.3f}" for value in times)}')
    print(f'checksum={checksum}')
