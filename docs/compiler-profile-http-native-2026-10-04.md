# Native HTTP compiler profile

This profile uses the source workload from `test/packages/http_native_test.dart`.
The test and profiler share `benchmark/support/http_native.dart`, including
the same eleven dependency packages and guest `http.get` entrypoint. The
profiler uses a fixed URL but never executes guest code or opens a connection.

The current resolved dependencies contribute 348 Dart files plus the guest
entrypoint. Compilation builds 1095 frontend function graphs and prepares and
emits 692 functions. Serialized output is 293565 bytes. `http` is version 1.6.0.

## Broad measurements

AOT measurements used Dart 3.13.4 on Windows x64, an AMD Ryzen AI Max Pro 390,
one logical CPU, three discarded warmups, and no competing tests or agent
compilations. Fresh mode constructs a new compiler each sample; cached mode
reuses its parsed-source cache. Each mode ran three rounds of 21 samples,
with mode order reversed in the middle round. Plain and profiled compilations
alternate within each process. The table pools 63 samples per mode.

Directory enumeration happens before timing. File reads and parsing happen
inside fresh compilation, matching the integration test. Cached compilation
reuses the same source objects. Guest execution, HTTP server startup, test
isolate startup, and AOT executable startup are excluded.

| Phase | Fresh median ms | Cached median ms |
| --- | ---: | ---: |
| Whole compile, profiling disabled | 567.691 | 432.954 |
| Whole compile, profiling enabled | 603.654 | 425.378 |
| Plugins, file reads, parsing | 172.094 | 0.075 |
| Library and type resolution | 40.140 | 20.392 |
| Declaration compilation | 96.466 | 131.124 |
| Graph cleanup and inlining | 15.285 | 16.401 |
| Eager SSA construction | 0.041 | 0.041 |
| Reachability, lazy SSA, class metadata | 85.987 | 84.737 |
| Function lowering, allocation, emission | 137.418 | 135.467 |
| Program assembly | 5.413 | 5.442 |
| Program metadata | 1.735 | 1.755 |
| Serialization | 1.788 | 1.777 |
| Decode and validation | 4.565 | 3.221 |
| Runtime setup from decoded program | 0.209 | 0.215 |
| Runtime setup directly from bytes | 3.224 | 3.330 |

Loading directly from bytes is an alternative to decoding then initializing,
not another cost to add. Phase medians do not sum to the whole-compile median.
GC and host CPU variation affect the plain/profiled comparison and even move
declaration costs between fresh and cached modes. These measurements locate
costs; they do not establish a precise profiler overhead or suite-wide speedup.
All six runs produced the same complete serialized-program SHA-256:
`9fdd9e2b0195543331347ff445f2c7fd36cab1c05e111faac0bc9b9b3e2d5dca`.

## Cold JIT compilation

Three independent JIT processes each compiled this workload once, with no
compiler warmup. Timing started after source enumeration and excluded process
startup and guest execution. These runs were not CPU-pinned. Median first
compilation took 2688.366 ms, with a range of 2611.396 to 2935.883 ms.

| Phase | Cold JIT median ms |
| --- | ---: |
| Plugins, file reads, parsing | 643.071 |
| Library and type resolution | 180.433 |
| Declaration compilation | 768.038 |
| Graph cleanup and inlining | 79.676 |
| Reachability, lazy SSA, class metadata | 257.916 |
| Function lowering, allocation, emission | 690.775 |
| Program assembly | 80.073 |
| Program metadata | 19.760 |

The JIT compiles host compiler code during this first guest compilation.
This is closer to a fresh test isolate than warmed AOT measurements, and
changes the priorities: declaration compilation and lowering are at least
as important as input parsing. Process/test-isolate startup adds further
iteration cost outside these numbers. The profiling tool now preserves the
first profiled compilation's total and broad phases under
`first_compilation_us`, separately from warmed median samples.
The final profiling tool reproduced this first-compile result at 2729.590 ms
and retained the same full-workload serialized hash.

## Drill-down

Temporary timers split the large phases, then the expensive SSA and lowering
graph work. The following medians are from a separate cached run with 21
samples, so compare their ordering rather than subtracting them from the
broad table. The temporary timers were removed after the investigation.

| Work | Median ms |
| --- | ---: |
| Compile functions and classes | 100.798 |
| Compile static initializers | 1.477 |
| Remaining declaration work, including extensions | 2.582 |
| SSA specialization and frontend validation | 7.315 |
| SSA graph clone | 16.065 |
| SSA phi insertion | 19.224 |
| SSA renaming | 22.601 |
| SSA dead-code removal and validation | 17.615 |
| Reachability traversal between preparations | 0.608 |
| Remaining reachability/class metadata | 0.650 |
| Lowering graph clone | 18.766 |
| Primitive optimization | 30.544 |
| Representation analysis | 6.881 |
| Remaining lowering graph setup | 0.908 |
| Instruction selection and comparison fusion | 17.310 |
| Phi removal and register allocation | 46.340 |
| Local layout, relaxation, and emission | 10.775 |

The near-zero broad eager-SSA phase does not mean SSA is cheap. Ordinary
programs build it lazily during backend reachability. Call traversal itself
is small. No single SSA pass accounts for most of SSA construction.

## Input experiment

`package:web` supplies 190 files and 2706733 bytes, about 77% of dependency
source bytes. The HTTP client selects `io_client.dart` through its conditional
import for this native workload, while compilation still parses all supplied
sources before discovering reachable libraries.

A temporary experiment omitted only the web sources. A 21-sample fresh run
reduced the parsing/plugin phase to 31.923 ms, compared with the full workload's
172.094 ms pooled median. It retained 1095 frontend functions, 692 emitted
functions, and the same serialized length. Typed instruction bytes matched
exactly. Serialized hashes differed; the probe library's numeric index moved
from 355 to 165. Both full and reduced programs decoded and made the local
HTTP request successfully. This supports testing lazy input parsing, but is
not a proof that arbitrarily omitting dependencies preserves all programs.
The checked-in test and `http-native` benchmark retain every original package.

A separate final AOT comparison ran three rounds of 11 samples each for the
file-backed and preloaded-memory variants, reversing their order in the middle
round. Pooled unprofiled medians were 568.704 and 503.770 ms; parsing/plugin
phase medians were 193.135 and 127.856 ms. Preloading removed about 65 ms in
this comparison, but substantial parsing cost remained. GC and host variation
still affect exact deltas. All six complete serialized hashes matched the
full-workload baseline.

## Optimization targets

1. Avoid parsing inactive dependency libraries for explicitly selected
   entrypoints. Index supplied source URIs, then load selected imports, exports,
   and parts on demand. Preserve conditional-import rules, bridge merging,
   runtime-override discovery, and the existing entrypoint contract. The web
   experiment is the strongest measured opportunity for fresh test compilation.
2. Investigate compiling frontend bodies on demand. This workload creates 403
   more frontend graphs than it emits, and declaration compilation is a large
   cached cost. Some graphs are needed for inlining, so the count is not an
   estimate of removable time. Separate required class/member signatures and
   layouts from bodies; retain constructor defaults, extensions, closures,
   global initializers, and weak-reference behavior.
3. Reduce graph copying and repeated SSA indexing. SSA and lowering clones
   together cost about 35 ms here. Compare a cheaper clone or transfer of an
   owned graph with current SSA inspection and escape-analysis requirements.
   SSA renaming and phi insertion also warrant experiments that share existing
   dominance information. Keep validation meaningful when composing passes.
4. Split allocation's 46 ms into liveness, phi removal, and actual allocation
   before choosing an algorithm change. The constrained allocator currently
   rescans each block's instructions during liveness iteration. Precomputed
   block uses/definitions are a candidate, but preserve exceptional edges and
   ordering that can affect spills and generated code.

Serialization, program metadata, and loading are small compared with these
compiler phases. They are lower priorities for this workload.

## Reproduction and verification

Run from the repository root so the workload finds `.dart_tool/package_config.json`:

```powershell
dart compile exe tool/profile_compiler.dart -o "$env:TEMP/profile_compiler.exe"
& "$env:TEMP/profile_compiler.exe" http-native 21 fresh "$env:TEMP/http-fresh.json"
& "$env:TEMP/profile_compiler.exe" http-native 21 cached "$env:TEMP/http-cached.json"
& "$env:TEMP/profile_compiler.exe" http-native-memory 21 fresh "$env:TEMP/http-memory.json"
# Run as JIT to inspect first_compilation_us as well as warmed medians.
dart run tool/profile_compiler.dart http-native 1 fresh "$env:TEMP/http-jit.json"
```

`http-native-memory` reads the same files before compilation timing to help
separate file loading from parsing. Neither workload runs the guest entrypoint.
The tool records input, frontend, prepared, and emitted counts, phase samples,
and the complete serialized hash. The integration test still exercises guest
execution, permission denial, permission granting, and the local response.

Changed-source analysis passed. The HTTP integration test and the existing
profiling/loading controls passed all three tests. No compiler, runtime, or
stdlib changes remain from the temporary instrumentation.
The rebuilt AOT tool also verified valid first-compile reports, bounded sample
counts, and unchanged serialized hashes for small, mixed, pipeline, full HTTP
fresh/cached, and preloaded HTTP workloads.
