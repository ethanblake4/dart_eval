# Compilation and iteration time

The [native HTTP profile](compiler-profile-http-native-2026-10-04.md) covers
the larger, multi-package workload from `http_native_test` and the resulting
compiler optimization targets.

## Measurement

Start with broad phases, then subdivide the expensive phases. The first AOT
run separated frontend work, graph preparation, bytecode generation, and
program metadata. Bytecode generation and graph preparation justified a
second split. The final instrumentation has seven sequential phase boundaries,
one optional callback, and one stopwatch per compilation. It does not collect
per-operation or per-function timings. An unprofiled compiler starts no clock.

`Compiler(onPhase: (name, microseconds) { ... })` reports completed phases.
`Runtime.initialize()` allows loading and bridge registration to be measured
without running guest code or guest global initializers. The interpreter loop
is unchanged.

Reproduce on Windows with:

```powershell
dart compile exe tool/profile_compiler.dart -o "$env:TEMP/profile_compiler.exe"
& "$env:TEMP/profile_compiler.exe" small 101 fresh "$env:TEMP/small.json"
& "$env:TEMP/profile_compiler.exe" mixed 101 fresh "$env:TEMP/mixed.json"
& "$env:TEMP/profile_compiler.exe" pipeline 101 fresh "$env:TEMP/pipeline.json"
# Repeat with cached instead of fresh.
```

The tool also accepts a single Dart source file containing a `main` entrypoint.
File I/O happens outside the measured compilation. `mixed` and `pipeline`
reuse the existing compilation benchmarks; the latter generates 64 middleware
stages. `small` is `int main() => 42;`.

These measurements use Dart 3.13.4 on Windows x64, three discarded warmups,
and 101 samples per workload/mode. Fresh mode constructs a compiler for each
sample. Cached mode reuses a compiler and its parsed-source/plugin caches.
Plain and profiled compilation alternate order. Their serialized outputs are
compared, and the focused regression checks fresh, cached, and typed output.
No other agent compiled or tested during the timing window. Editor services
were left running; timings varied between sweeps, so absolute improvements
must be verified with paired comparisons. Cold process startup is not measured.

Median milliseconds from the final sweep:

| Phase | Small fresh | Mixed fresh | Pipeline fresh | Small cached | Mixed cached | Pipeline cached |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Whole compilation, profiling disabled | 7.565 | 19.208 | 27.223 | 6.806 | 18.984 | 24.976 |
| Whole compilation, profiling enabled | 7.347 | 18.738 | 27.940 | 6.709 | 19.306 | 25.936 |
| Frontend | 3.593 | 5.901 | 8.704 | 2.631 | 5.109 | 5.764 |
| Graph cleanup and inlining | 0.434 | 0.820 | 1.238 | 0.420 | 0.866 | 1.292 |
| SSA construction | 2.470 | 4.159 | 6.695 | 2.006 | 4.776 | 5.766 |
| Backend reachability and class metadata | 0.021 | 0.076 | 0.141 | 0.018 | 0.084 | 0.143 |
| Function lowering, allocation, and local emission | 0.099 | 5.439 | 10.878 | 0.094 | 5.439 | 10.762 |
| Program bytecode assembly and validation | 0.025 | 0.227 | 0.275 | 0.023 | 0.239 | 0.297 |
| Program metadata | 0.767 | 0.718 | 0.674 | 0.754 | 0.733 | 0.682 |
| Serialization | 0.397 | 0.366 | 0.474 | 0.368 | 0.370 | 0.454 |
| Decode and validation | 0.358 | 0.403 | 0.534 | 0.349 | 0.420 | 0.522 |
| Runtime setup from decoded program | 0.175 | 0.164 | 0.185 | 0.181 | 0.176 | 0.154 |
| Runtime setup directly from bytes | 0.495 | 0.420 | 0.578 | 0.421 | 0.443 | 0.561 |

Medians of separate phases need not sum to the median of the whole compile.
The seven compiler phases do not overlap within a sample. Loading from bytes
is an alternative to decode followed by setup, so do not add that row again.
Loading measurements include validation and bridge registration, and exclude
guest execution. Function lowering includes register allocation and local
byte emission; the assembly row covers the remaining program-level work.

| Workload | SSA functions prepared | Functions emitted | Serialized bytes |
| --- | ---: | ---: | ---: |
| Small | 105 | 1 | 27,611 |
| Mixed | 133 | 24 | 37,050 |
| Pipeline | 234 | 130 | 60,349 |

## Target plan

1. **Avoid preparing unused functions.** `_compileSources` currently cleans,
   validates, inlines, specializes, and constructs SSA for every frontend
   function. `TypedBackend.compileEntrypoints` discovers reachable functions
   afterward. For the tiny fixture, 104 prepared functions are not emitted.
   Move a conservative strong-reachability walk ahead of SSA, or build SSA
   on demand during the backend walk. Reuse the existing reachability rules
   rather than maintaining a second independent root definition. Include
   global initializers, default thunks, class members, closures, and overrides.
   Initially retain the existing preparation path for weak-reference programs;
   weak escape analysis consumes SSA and needs separate handling. Measure
   preparation counts and small/mixed compilation first. SSA alone is about
   34% of the small fresh compile, an upper bound rather than a promised gain.
   Preserve output and diagnostics, then run bounded reachability/default/
   override controls and the complete SDK gate before accepting the change.

2. **Bisect function lowering for larger programs.** It takes about 29% of
   mixed and 39% of pipeline fresh compilation, rising to about 41% of cached
   pipeline compilation. The next temporary split should separate
   `_LoweringSession` construction plus instruction selection from `emit()`.
   If construction/selection wins, split graph cloning and primitive/
   representation analysis. If emission wins, split phi removal, register
   allocation, and block emission. Optimize only the winning branch, starting
   with repeated graph scans, SSA refreshes, or repeated construction of fixed
   register/opcode metadata. Current data does not identify which of these
   dominates. Require a paired AOT compile benchmark improvement with identical
   bytecode when semantics permit; if allocation changes bytecode, verify
   checksums and run the execution benchmark sweep.

3. **Bisect frontend costs after eliminating unused preparation.** It is
   approximately 31% of mixed/pipeline fresh compilation and 49% of the tiny
   fixture. Split plugin setup/parsing from library/type resolution and
   declaration compilation. Cached runs already avoid parsing and initial
   plugin registration, but still rebuild substantial frontend state. If
   library/type setup dominates, investigate immutable SDK declaration/index
   reuse with compilation-local type and bridge identities. If declaration
   compilation dominates, extend reachability to avoid unnecessary bodies.
   Check changed sources, compiler reuse, bridge overrides, and diagnostic
   mode before introducing caches. Merely reusing a compiler is not a proven
   universal speedup: the mixed cached result barely changes in this sweep.

Serialization, loading, and final assembly are lower priorities for the
complex workloads. Avoid changing the codec or interpreter for their small
shares. For tests that do not exercise serialization, consider `Runtime.ofProgram`
only after checking that doing so preserves the intended contract; retain
serialized coverage for codecs, security, type metadata, and loading behavior.

Measure iteration time separately from compiler throughput. AOT timings find
compiler costs, but the test runner uses JIT and spends time compiling/loading
host test isolates and generated bindings. Establish a paired default-suite
baseline before promising a suite-wide gain from any compiler optimization.

## Test cleanup

The parallel survey removed 25 tests across 11 paths, including two files:

- Basic loop, enum, exception, unary-minus, and integer-division examples
  covered by retained SDK originals or stronger compiler regressions.
- Exact duplicate async-exception and RegExp cases.
- A superseded list-view smoke test; dual-mode mapping and mutation remain.
- Two self-equality checks and a purported relative-path filesystem case that
  repeated absolute-path checks.
- Copied SDK juxtaposition and private-mixin fixtures, and a missing-main case
  covered by the contract matrix.

The forwarding-constructor fixture retains its materialization/variant checks
and drops four repeated compilation/execution runs. Numeric edge cases,
metadata-corruption controls, long-branch controls, async launcher contracts,
and fresh-versus-serialized regressions remain. Full-SDK originals still run
in the full suite. Focused verification passed 188 affected/retained tests,
30 SDK loop/enum tests with one existing skip, three pinned SDK originals,
and 16 exception tests after the final duplicate removal.

The survey reduced the existing inventory from 305 to 303 test files. This
task adds one file with two focused profiling/loading controls, for a net
reduction of one file and 23 cases. Final default verification passed 2313
tests with 86 existing skips and no failures: runner elapsed 2:14, external
wall time 139.326 seconds. Changed-source analysis and focused profiling/
loading controls also pass. The cleanup saves work, but no causal suite-time
percentage is claimed against the unpaired historical 2:29 run.

## Implemented: prepare SSA on demand

The existing backend reachability walk now calls `prepareFunctionSSA` when
it visits a function. That helper specializes indexed loops, validates the
frontend graph, builds SSA, and caches it in the compilation context. Calls
resolve against frontend function graphs, so a callee need not already have
SSA to be discovered. Class members, global initializers, closures, and
default thunks continue to use the same walk, including thunks minted during
backend metadata construction.

Weak-reference programs retain eager SSA preparation. Their escape analysis
follows inlined and escaped callees beyond ordinary backend reachability.
Frontend declaration compilation, cleanup, validation, and inlining are
unchanged; skipping their unused work remains a separate followup.

The `ssaFunctionGraphs` inspection API now contains prepared reachable
functions for ordinary programs, rather than every frontend function. All
frontend functions remain available through `functionGraphs`. Profiling
reports lazy SSA work under `bytecode reachability, SSA and class metadata`;
the earlier `SSA construction` phase covers eager weak-reference preparation.

Paired AOT comparison used separate executables built before and after the
change, three rounds of 31 samples per workload/mode, three discarded warmups
per process, and reversed executable order in the middle round. No tests or
other agent compilations ran during these rounds. The following medians pool
the 93 unprofiled compile samples for each executable:

| Workload | Mode | Before ms | After ms | Reduction |
| --- | --- | ---: | ---: | ---: |
| Small | Fresh | 6.498 | 3.696 | 43.1% |
| Small | Cached | 5.881 | 4.046 | 31.2% |
| Mixed | Fresh | 21.410 | 19.688 | 8.0% |
| Mixed | Cached | 19.340 | 18.257 | 5.6% |
| Pipeline | Fresh | 31.682 | 31.117 | 1.8% |
| Pipeline | Cached | 30.792 | 27.816 | 9.7% |

Individual rounds were noisy, including occasional complex-workload
regressions. The small fixture improved in every round. SSA preparation
counts fell from 105 to 1, 133 to 24, and 234 to 130 respectively. SHA-256 of
the complete serialized program matched before and after in all 36 runs,
with unchanged serialized lengths. The profiling tool now records this hash
to make future comparisons reproducible. No runtime, stdlib, opcode, or
register-allocation changes were made in this optimization.

A bounded regression adds one case to the existing SSA test file. It checks
that an unused frontend function receives no SSA while a global closure and
constructor default remain callable, including compiler reuse and fresh/
serialized loading. Existing compiler, weak-reference, inherited-default,
contextual-default, and closure-default controls passed 376 tests before
that new case; the complete SSA file then passed 14 tests. Changed-source
analysis is clean.

Final gates:

- `dart test --concurrency=4`: 2314 passed, 86 existing skips, no failures;
  runner elapsed 3:25, external wall time 209.538 seconds.
- `dart test -P sdk-full test/sdk_language/full_test.dart`: 2737 passed,
  557 registered skips, no failures; the eligible-fixture summary reports
  three existing unsupported skips. Runner elapsed 3:39, external wall time
  229.832 seconds.
- Two earlier default-concurrency runs each hit one subprocess deadline:
  the CLI network test at 30 seconds and a binding-generator analyzer test
  at 60 seconds. The CLI file passed independently in 14 seconds, and both
  cases passed in the four-isolate complete run. No timeout limits or test
  configuration were changed. Suite-wide speedup is not inferred from these
  runs with differing contention and concurrency.

## Frontend and lowering followup

The next investigation split frontend work into parsing/plugin setup,
library/type resolution, and declaration compilation. Temporary lowering
timers first separated graph analysis and instruction selection from
allocation/emission, then separated graph construction, primitive
optimization, and allocation. Primitive optimization and register allocation
were the largest lowering costs. Declaration compilation was the largest
frontend cost. The detailed timers have been removed; the permanent profiler
retains the broad frontend phases and aggregates repeated callbacks per compile.

Implemented changes:

- Cache expanded declarations within import resolution, remove its write-only
  map, and use the existing set of used declarations during tree shaking.
- Reuse bridge declaration lists and resolve each bridge type wrapper once
  after nominal registration, instead of copying it for each visible namespace.
- Reuse ordered formal parameters and skip contextual default-type resolution
  for parameters that cannot have explicit or inherited defaults.
- Cache immutable opcode-family register constraints across functions and
  compiler invocations. Operation-specific fixed variants retain their own path.
- Leave native-list rewrite blocks untouched unless a rewrite is needed.
- Let common-expression elimination defer SSA metadata refresh to the
  immediately following dead-code pass. The CFG API defaults to refreshing,
  preserving existing callers; a composition regression covers the deferred path.

The final AOT comparison used three rounds of 51 unprofiled samples per
workload/mode, three discarded warmups, reversed executable order in the
middle round, and both executables pinned to the same logical CPU. No other
tests or agent compilations ran during timing. These medians pool 153 samples
per executable and compare against the prior lazy-SSA implementation:

| Workload | Mode | Before ms | After ms | Reduction |
| --- | --- | ---: | ---: | ---: |
| Small | Fresh | 3.251 | 2.916 | 10.3% |
| Small | Cached | 3.026 | 2.771 | 8.4% |
| Mixed | Fresh | 15.859 | 15.084 | 4.9% |
| Mixed | Cached | 14.414 | 13.745 | 4.6% |
| Pipeline | Fresh | 28.450 | 25.041 | 12.0% |
| Pipeline | Cached | 26.856 | 25.243 | 6.0% |

CPU affinity reduced scheduling variation but did not control CPU frequency.
Individual rounds remained noisy, including one small candidate process
roughly twice as slow across compilation and loading. The pooled results
show further compiler improvements, not a measured test-suite speedup.
All 36 comparisons preserved the complete serialized program's SHA-256 and
length. Runtime dispatch, opcodes, stdlib, and allocation algorithms are unchanged.

Focused compiler/default/profiling verification passed 372 tests. CFG's
complete suite passed 110 tests. Changed-source analysis was clean. The final
code review found no correctness blockers and suggested making reversed
cached argument lists explicitly unmodifiable.

Final complete gates passed 2314 default tests with 86 existing skips and
2737 SDK tests with 557 registered skips. The SDK eligible-fixture summary
reports three existing unsupported skips. External wall times were 183.276
seconds for the default suite at concurrency four and 202.292 seconds for
the full SDK suite. These are verification runs, not paired suite benchmarks.
After the cache immutability cleanup, all 363 compiler tests and analysis
passed again. A rebuilt AOT executable completed a final 31-sample sweep of
all six workload/mode combinations with unchanged serialized hashes and lengths.
