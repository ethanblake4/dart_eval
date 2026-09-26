from support.comparison import run_comparison


class LogCursor:
    def __init__(self) -> None:
        self.offset = 0
        self.line = 1
        self.column = 0
        self.field_start = 0
        self.record_start = 0
        self.fields_in_record = 0
        self.records = 0
        self.errors = 0
        self.field_bytes = 0
        self.record_bytes = 0

    def feed(self, chunk: str) -> None:
        i = 0
        while i < len(chunk):
            code = ord(chunk[i])
            self.offset += 1
            if code == 124:
                self.field_bytes += self.offset - self.field_start - 1
                self.field_start = self.offset
                self.fields_in_record += 1
                self.column += 1
            elif code == 10:
                self.field_bytes += self.offset - self.field_start - 1
                self.record_bytes += self.offset - self.record_start - 1
                if self.fields_in_record != 3:
                    self.errors += 1
                self.records += 1
                self.line += 1
                self.column = 0
                self.fields_in_record = 0
                self.field_start = self.offset
                self.record_start = self.offset
            else:
                self.column += 1
            i += 1

    @property
    def checksum(self) -> int:
        return (self.offset * 3 + self.line * 11 + self.column * 17 +
                self.records * 19 + self.errors * 23 + self.field_bytes * 29 +
                self.record_bytes * 31)


def main(batches: int) -> int:
    chunks = [
        '2026-09-26|INFO|api|ready\n2026-09-26|WARN|',
        'cache|slow\n2026-09-26|ERROR|db|timeout\n',
        '2026-09-26|INFO|auth|',
        'accepted\n2026-09-26|WARN|missing\n',
    ]
    cursor = LogCursor()
    batch = 0
    while batch < batches:
        for chunk in chunks:
            cursor.feed(chunk)
        batch += 1
    return cursor.checksum


if __name__ == '__main__':
    run_comparison('int_fields', main, unit='batch', iterations=5000,
                   warmup_iterations=50, default_samples=15)
