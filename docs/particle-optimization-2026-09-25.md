# Particle field updates, September 25, 2026

Starting revisions: dart_eval `137812a` on `xv2`, control_flow_graph
`bd9c394` on `main`. Windows x64, Dart 3.13.4, CPython 3.12.9.

## Workload

`benchmark/particles.dart` preserves the supplied Particle program: 64 mutable
objects, indexed loops, two position updates per tick, conditional velocity
reversals, and a final energy reduction. The Python port uses ordinary instance
attributes and equivalent indexed loops. Neither port uses vectorization or
changes the update order.

Compile the dart_eval host to AOT before timing:

```powershell
dart compile exe benchmark/particles.dart -o .dart_tool/particles.exe
& .dart_tool/particles.exe 10000 15
python benchmark/particles.py 10000 15
```

Both drivers compile or prepare the program outside the timed region, perform
two 100-tick warmups, then report 15 execution samples. The common comparison
driver now accepts floating-point results as well as integer results. Existing
benchmarks retain their seven-sample default.

## Changes

The compiler knew Particle's exact class but emitted dynamic setter calls for
all four field assignments in `tick`. Field declarations live under their bare
names, whereas the implementation lookup intentionally requires explicit
accessor declarations. Applying that lookup to a compiled synthetic setter
incorrectly rejected the direct storage slot.

Field writes now use the storage index and compiled setter position together.
Explicit setters still require their concrete declaration. Inherited storage
uses the declaring superclass link. Generic fields and narrowed receiver views
retain checked setter dispatch: a `Box<Object>` view of `Box<String>` cannot
write an integer into its field. Final and late-final behavior is preserved.

Double stores retain the native double instead of allocating a `$double`
wrapper on each update. Numeric field loads accept either representation,
including boxed constructor and dynamic-setter writes. Object and late-field
reads supply canonical boxed values. The machine generator produces every
affected opcode implementation; no generated stdlib source was edited.
Opcode numbers and bytecode format are unchanged.

An intermediate experiment kept boxed storage and only inlined double field
loads. It was slower than deferred boxing in the comparable steady samples,
although host timing varied enough that the small incremental difference should
not be treated as a precise percentage. Native method ABIs were also surveyed;
virtual dispatch currently enters boxed argument registers directly, so changing
that convention would require a separate dispatch and override design.

## Validation and measurements

The final 20-driver AOT sweep used a shared host, 15 samples, CPU affinity mask
4, alternating baseline/candidate order, and no concurrent test or build jobs.
All 19 execution checksums matched. The compilation driver completed with
1,221 code bytes on both revisions. Logs are under
`.dart_tool/particles/final-sweep/`.

| Workload | Baseline median | Final median | Reduction |
| --- | ---: | ---: | ---: |
| Particle, 10,000 ticks | 271.362 ms | 118.994 ms | 56.1% |
| JSON codec, 200 iterations | 368.875 ms | 282.646 ms | 23.4% |
| Event bus, 60,000 events | 89.497 ms | 73.541 ms | 17.8% |

Timing varied substantially at process startup, including the native control
loops. A longer Particle comparison used 50,000 ticks, 15 samples, and affinity
mask 256 to check the result on another core:

| Implementation | Median |
| --- | ---: |
| Baseline dart_eval AOT host | 1,419.180 ms |
| Final dart_eval AOT host | 608.272 ms |
| CPython | 441.384 ms |

This repeat cuts dart_eval time by 57.1%, from 3.22 times Python's time to
1.38 times. All three checksums are exactly `975517083.0548853`.
The 10,000-tick checksum is `12468123.056000791`. Early exploratory runs were
noisier; the raw samples are retained rather than interpreting every apparent
sweep gain as a compiler improvement.

Longer follow-ups checked the apparent regressions. At 500,000 iterations,
boxed-argument calls measured 77.129 to 78.942 ms and overflow calls 110.032 to
110.653 ms. At 20,000 appointments, interval overlap measured 25.317 to
26.082 ms. A 31-sample compiler repeat measured 13.963 to 14.244 ms.
These remaining increases are about 0.6% to 3.0%; the larger initial sweep
regressions did not repeat. Deferred double boxing adds a type check to object
field reads, so small costs elsewhere remain a tradeoff of this change.

The default root suite passes 1,659 tests with 62 skips. Its SDK core run reports
418 passes, 38 expected failures, and 32 expected compile errors. Focused tests
cover direct and inherited writes, real setter overrides, generic covariance,
narrowed fields, late initialization and final guards, mixed boxed/native
storage, dynamic reads, and method tear-offs. They execute fresh and serialized
programs. Scoped analysis is clean, and rerunning the machine generator leaves
its output unchanged. The graph library was not modified.
