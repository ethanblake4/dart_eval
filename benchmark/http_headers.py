import sys
import time


def make_request(seed):
    names = [
        'Host', 'content-type', 'X-Request-Id', 'Cache-Control',
        'Authorization', 'Content-Length', 'ACCEPT', 'X-Trace',
    ]
    parts = []
    state = seed
    for line in range(32):
        state = (state * 1103515245 + 12345) & 0x7fffffff
        kind = line & 7
        parts.append(names[kind])
        parts.append(': ')
        if kind == 0:
            parts.extend(('node', str(state % 97), '.example'))
        elif kind == 1:
            parts.append('application/json')
        elif kind == 3:
            parts.extend(('max-age=', str(state % 180)))
        elif kind == 4:
            parts.extend(('Bearer ', str(state % 1000000)))
        elif kind == 6:
            parts.append('text/plain')
        elif kind == 7:
            parts.extend(('a', str(state % 10000)))
        else:
            parts.append(str(state % 100000))
        parts.append('\r\n')
    parts.append('\r\n')
    return ''.join(parts)


def scan(request):
    pos = 0
    score = 0
    hosts = 0
    authorization = 0
    body_bytes = 0
    while pos < len(request):
        if ord(request[pos]) == 13:
            break
        name_hash = 0
        while ord(request[pos]) != 58:
            c = ord(request[pos])
            pos += 1
            if 65 <= c <= 90:
                c += 32
            name_hash = (name_hash * 33 + c) & 0x7fffffff
        pos += 1
        while ord(request[pos]) == 32 or ord(request[pos]) == 9:
            pos += 1
        value_hash = 0
        length = 0
        while ord(request[pos]) != 13:
            c = ord(request[pos])
            pos += 1
            value_hash = (value_hash * 33 + c) & 0x7fffffff
            if name_hash == 157516714:
                length = length * 10 + c - 48
        pos += 2
        if name_hash == 3862238:
            hosts += 1
        if name_hash == 1914971089:
            authorization += 1
        if name_hash == 157516714:
            body_bytes += length
        score = (score + (name_hash ^ value_hash)) & 0x7fffffff
    return (score + hosts * 31 + authorization * 131 + body_bytes) & 0x7fffffff


def main(requests):
    checksum = 0
    for i in range(requests):
        checksum += scan(make_request(123456789 + i * 2654435761))
    return checksum


if __name__ == '__main__':
    requests = int(sys.argv[1]) if len(sys.argv) > 1 else 1000
    samples = int(sys.argv[2]) if len(sys.argv) > 2 else 7
    if requests < 1 or samples < 7:
        raise ValueError('Positive requests and at least seven samples required')

    checksum = 0
    for _ in range(2):
        checksum += main(10)
    times = []
    for _ in range(samples):
        start = time.perf_counter()
        checksum += main(requests)
        times.append((time.perf_counter() - start) * 1000)
    times.sort()
    median = times[len(times) // 2]
    print(f'http_headers median_ms={median:.3f} '
          f'min_ms={times[0]:.3f} max_ms={times[-1]:.3f} '
          f'ns/request={median * 1000000 / requests:.2f}')
    print(f'checksum={checksum}')
