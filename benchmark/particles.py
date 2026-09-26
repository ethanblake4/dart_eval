from support.comparison import run_comparison


class Particle:
    def __init__(self, x: float, y: float, vx: float, vy: float) -> None:
        self.x = x
        self.y = y
        self.vx = vx
        self.vy = vy

    def tick(self, dt: float) -> None:
        self.x += self.vx * dt
        self.y += self.vy * dt
        if self.x > 100.0:
            self.vx = -self.vx
        if self.y > 100.0:
            self.vy = -self.vy

    def energy(self) -> float:
        return self.x * self.x + self.y * self.y


def run(n: int) -> float:
    items = []
    j = 0
    while j < 64:
        items.append(Particle(j * 0.5, j * 0.25, 1.25, -0.75))
        j += 1
    i = 0
    while i < n:
        j = 0
        while j < len(items):
            items[j].tick(0.016)
            j += 1
        i += 1
    sum = 0.0
    j = 0
    while j < len(items):
        sum += items[j].energy()
        j += 1
    return sum


if __name__ == '__main__':
    run_comparison('particles', run, unit='tick', iterations=10000,
                   warmup_iterations=100, default_samples=15)
