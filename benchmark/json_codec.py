import sys
import time

# Faithful port of benchmark/json_codec.dart's guest program — same
# recursive-descent JSON parser and serializer over generated docs.

class Parser:
    __slots__ = ('s', 'pos')

    def __init__(self, s):
        self.s = s
        self.pos = 0

    def ws(self):
        s = self.s
        n = len(s)
        while self.pos < n:
            c = ord(s[self.pos])
            if c == 32 or c == 9 or c == 10 or c == 13:
                self.pos += 1
            else:
                break

    def value(self):
        self.ws()
        c = ord(self.s[self.pos])
        if c == 123:
            return self.object()
        if c == 91:
            return self.array()
        if c == 34:
            return self.string()
        if c == 116:
            self.pos += 4
            return True
        if c == 102:
            self.pos += 5
            return False
        if c == 110:
            self.pos += 4
            return None
        return self.number()

    def object(self):
        self.pos += 1
        m = {}
        self.ws()
        if ord(self.s[self.pos]) == 125:
            self.pos += 1
            return m
        while True:
            self.ws()
            key = self.string()
            self.ws()
            self.pos += 1
            m[key] = self.value()
            self.ws()
            c = ord(self.s[self.pos])
            if c == 44:
                self.pos += 1
                continue
            self.pos += 1
            return m

    def array(self):
        self.pos += 1
        l = []
        self.ws()
        if ord(self.s[self.pos]) == 93:
            self.pos += 1
            return l
        while True:
            l.append(self.value())
            self.ws()
            c = ord(self.s[self.pos])
            if c == 44:
                self.pos += 1
                continue
            self.pos += 1
            return l

    def string(self):
        self.pos += 1
        start = self.pos
        buf = None
        s = self.s
        while self.pos < len(s):
            c = ord(s[self.pos])
            if c == 34:
                break
            if c == 92:
                if buf is None:
                    buf = []
                buf.append(s[start:self.pos])
                self.pos += 1
                e = ord(s[self.pos])
                if e == 110:
                    buf.append('\n')
                elif e == 116:
                    buf.append('\t')
                elif e == 117:
                    buf.append(chr(self.hex4()))
                else:
                    buf.append(chr(e))
                self.pos += 1
                start = self.pos
                continue
            self.pos += 1
        tail = s[start:self.pos]
        self.pos += 1
        if buf is None:
            return tail
        buf.append(tail)
        return ''.join(buf)

    def hex4(self):
        v = 0
        s = self.s
        for i in range(4):
            c = ord(s[self.pos])
            d = c - 48
            if d > 9:
                d = (c | 32) - 87
            v = v * 16 + d
            self.pos += 1
        return v

    def number(self):
        s = self.s
        neg = False
        if ord(s[self.pos]) == 45:
            neg = True
            self.pos += 1
        n = 0
        while self.pos < len(s):
            c = ord(s[self.pos])
            if c < 48 or c > 57:
                break
            n = n * 10 + c - 48
            self.pos += 1
        if self.pos < len(s) and ord(s[self.pos]) == 46:
            self.pos += 1
            scale = 0.1
            frac = 0.0
            while self.pos < len(s):
                c = ord(s[self.pos])
                if c < 48 or c > 57:
                    break
                frac += (c - 48) * scale
                scale *= 0.1
                self.pos += 1
            v = n + frac
            return -v if neg else v
        return -n if neg else n


def write_string(v, b):
    b.append('"')
    start = 0
    for i in range(len(v)):
        c = ord(v[i])
        if c == 34 or c == 92:
            if i > start:
                b.append(v[start:i])
            b.append('\\')
            b.append(chr(c))
            start = i + 1
        elif c == 10:
            if i > start:
                b.append(v[start:i])
            b.append('\\n')
            start = i + 1
    if len(v) > start:
        b.append(v[start:])
    b.append('"')


def write_value(v, b):
    if v is None:
        b.append('null')
        return
    if isinstance(v, bool):
        b.append('true' if v else 'false')
        return
    if isinstance(v, (int, float)):
        b.append(str(v))
        return
    if isinstance(v, str):
        write_string(v, b)
        return
    if isinstance(v, list):
        b.append('[')
        for i in range(len(v)):
            if i > 0:
                b.append(',')
            write_value(v[i], b)
        b.append(']')
        return
    b.append('{')
    first = True
    for key, val in v.items():
        if not first:
            b.append(',')
        first = False
        write_string(key, b)
        b.append(':')
        write_value(val, b)
    b.append('}')


def make_doc(seed):
    x = seed

    def nxt():
        nonlocal x
        x = (x * 1103515245 + 12345) & 0x7fffffff
        return x

    b = []
    b.append('{"items":[')
    for i in range(40):
        if i > 0:
            b.append(',')
        b.append('{"id":')
        b.append(str(nxt() % 100000))
        b.append(',"name":"user_')
        b.append(str(nxt() % 9999))
        b.append('","tags":["alpha","b')
        b.append(str(nxt() % 999))
        b.append('","g"],"score":')
        b.append(str((nxt() % 10000) / 100))
        b.append(',"ok":')
        b.append('true' if nxt() % 3 == 0 else 'false')
        b.append(',"meta":null}')
    b.append('],"count":40}')
    return ''.join(b)


def checksum(v):
    if isinstance(v, list):
        n = len(v)
        for e in v:
            n += checksum(e)
        return n
    if isinstance(v, dict):
        n = len(v)
        for k, e in v.items():
            n += len(k) + checksum(e)
        return n
    if isinstance(v, str):
        return len(v)
    if isinstance(v, bool):
        return 1
    if isinstance(v, int):
        return v & 0xff
    if isinstance(v, float):
        return int(v) & 0xff
    return 0 if v is None else 1


def main(n):
    total = 0
    for i in range(n):
        doc = make_doc(123456789 + i * 2654435761)
        parsed = Parser(doc).value()
        out = []
        write_value(parsed, out)
        total += len(''.join(out)) + checksum(parsed)
    return total


if __name__ == '__main__':
    iterations = int(sys.argv[1]) if len(sys.argv) > 1 else 4000
    samples = int(sys.argv[2]) if len(sys.argv) > 2 else 7
    for _ in range(2):
        main(50)
    times = []
    for _ in range(samples):
        t0 = time.perf_counter()
        result = main(iterations)
        times.append((time.perf_counter() - t0) * 1000)
    times.sort()
    median = times[len(times) // 2]
    print(f'json_codec median_ms={median:.3f} '
          f'min_ms={times[0]:.3f} '
          f'max_ms={times[-1]:.3f} '
          f'ns/iteration={median * 1000000 / iterations:.2f}')
    print(f'checksum={result}')
