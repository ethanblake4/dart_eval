from support.comparison import run_comparison


class Patch:
    def __init__(self, target: int, line: str) -> None:
        self.target = target
        self.line = line


class TokenRecord:
    def __init__(self) -> None:
        self.name = 'unknown'
        self.state = 'idle'
        self.region = 'none'
        self.last_key = ''
        self.last_value = ''

    def apply(self, line: str) -> None:
        separator = line.find('=')
        key = line[:separator]
        value = line[separator + 1:]
        self.last_key = key
        self.last_value = value
        if key == 'name':
            self.name = value
        elif key == 'state':
            self.state = value
        elif key == 'region':
            self.region = value

    @property
    def score(self) -> int:
        return (len(self.name) * 3 + len(self.state) * 5 +
                len(self.region) * 7 + len(self.last_key) * 11 +
                len(self.last_value) * 13 + ord(self.name[0]) +
                ord(self.state[0]) + ord(self.region[0]))


def main(batches: int) -> int:
    records = [TokenRecord(), TokenRecord(), TokenRecord(), TokenRecord()]
    patches = [
        Patch(0, 'name=alpha'),
        Patch(1, 'name=bravo'),
        Patch(2, 'state=active'),
        Patch(0, 'region=us-west'),
        Patch(3, 'name=delta'),
        Patch(1, 'state=paused'),
        Patch(2, 'region=eu-central'),
        Patch(0, 'state=active'),
        Patch(3, 'region=ap-south'),
        Patch(1, 'region=us-east'),
        Patch(2, 'name=charlie'),
        Patch(3, 'state=ready'),
    ]
    checksum = 0
    batch = 0
    while batch < batches:
        i = 0
        while i < len(patches):
            patch = patches[i]
            record = records[patch.target]
            record.apply(patch.line)
            checksum += len(record.last_value)
            i += 1
        i = 0
        while i < len(records):
            checksum += records[i].score
            i += 1
        batch += 1
    return checksum


if __name__ == '__main__':
    run_comparison('string_fields', main, unit='batch', iterations=15000,
                   warmup_iterations=100, default_samples=15)
