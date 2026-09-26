# Native integer field experiment, September 26, 2026

Starting revision: dart_eval `238a88f` on `xv2`. The sibling
control_flow_graph checkout was unchanged.

## Workloads and candidates

`benchmark/int_fields.dart` and `.py` process delimited log chunks. A cursor
keeps offsets, record boundaries, field counts, and error counts as mutable
integer fields. Most values quickly exceed `$int`'s −128 to 127 wrapper cache.
`benchmark/string_fields.dart` and `.py` apply name/value patches to long-lived
records and repeatedly replace several string fields. Both Python ports use
ordinary class instances, preserve update order, and match their Dart checksums.

Three AOT hosts were built from the same finalized benchmark sources:

- Baseline at `238a88f`.
- Native integer field writes and reads.
- Native integer and String field writes and reads.

The integer change stores native ints from typed field stores and the fused
increment instruction. Numeric loads accept boxed constructor and dynamic
setter values as well as native values. Object reads box the stored int on
demand. This uses existing opcodes and preserves the bytecode version.

The String candidate reused object-register stores to retain native strings.
It kept the same behavior in tests, but the longer patch-record benchmark was
about 3% slower than the integer-only host. String fields therefore keep their
boxed storage convention. The String benchmark remains as a regression check.

## Results

The final 22-driver AOT sweep used 15 samples per driver and CPU affinity mask
4. All 21 execution checksums matched between baseline and the retained
integer-only build. The compiler driver produced the same 1,221 code bytes.
The complete paired logs are under `.dart_tool/native-fields/final-sweep/`.

| Workload | Baseline median | Integer-only median |
| --- | ---: | ---: |
| Log cursor, 5,000 batches | 70.220 ms | 65.813 ms |
| Patch records, 15,000 batches | 116.495 ms | 110.595 ms |
| JSON codec, 200 iterations | 311.250 ms | 300.476 ms |
| Particle, 10,000 ticks | 127.051 ms | 132.804 ms |

The machine's timing varied sharply during the sweep. Even native dispatch
controls changed by more than 50% between paired runs. Longer repeats were used
to check the apparent regressions and the integer gain:

| Workload | Baseline medians | Integer-only medians |
| --- | ---: | ---: |
| Log cursor, 20,000 batches | 341.825, 274.869 ms | 240.332, 244.587 ms |
| Particle, 50,000 ticks | 632.647, 643.147 ms | 625.047, 634.726 ms |
| Boxed calls, 500,000 iterations | 81.740, 81.971 ms | 82.002, 84.140 ms |
| Overflow calls, 500,000 iterations | 114.906, 115.433 ms | 115.770, 116.223 ms |

The first log-cursor baseline includes slow startup samples; its later samples
and second run settle near 275 ms. Against that stable baseline, the integer
change saves about 11–13%. The large call regressions and the Particle slowdown
in the sweep did not repeat. A separate CPython run of the 5,000-batch cursor
measured 96.208 ms; its checksum matched both AOT hosts.

For the String candidate, the 60,000-batch patch workload measured 439.863 ms
with integer-only storage and 452.426 and 457.446 ms with native String storage.
The baseline measured 442.836 ms. That is a repeatable cost near 3% for native
String storage on this workload, so the String candidate was removed.

The default root suite passed 1,664 tests with 62 skips after both candidates
were applied. After removing native String storage, the 19 focused field tests
passed and scoped analysis found no issues. Integer tests cover mixed boxed and
native writes, dynamic reads, inherited storage, late fields, and generic
covariance in fresh and serialized programs. The machine generator still emits
220 instructions, and the graph library was not modified.
