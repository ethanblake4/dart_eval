# Improvement loop 11 — 2026-09-26

## Step 1: omitted generic function arguments

Dynamic invocation previously skipped type-argument bound validation when no
arguments were supplied. Runtime fallback followed raw bounds, so recursive
bounds such as `T extends Iterable<T>` entered the function instead of throwing.

Closure descriptors now carry finite instantiate-to-bound defaults computed by
the compiler's existing type-system helper, in declaration order. The compiler
retains parameter definitions instead of a duplicate list of their bounds.
Bytecode version 127 serializes and validates the new defaults. The interpreter
source generator supplies the callee's resolved defaults through its existing
fallback type environment; checked invocation and parameter checks use the same
arguments. Defaults resolve once per closure/runtime against the captured class
and callable environment. Nongeneric calls do not allocate type arguments.

An initial implementation repeated default resolution checks at frame entry and
regressed closure benchmarks by 7–8%. Reusing the resolved entry environment
removed that regression: a 31-sample AOT repeat measured closure cases from
-2.2% to +1.3% against the untouched baseline. The final 22-driver AOT sweep matches all 21 execution checksums. The
largest positive execution delta after repeating the lone >5% outlier is +4.2%;
compile time is 14.391 -> 14.632 ms (+1.7%) with 1,225 code bytes unchanged. Baseline was built at dart_eval
fae56c7 and control_flow_graph 291b1f4 before editing. Logs are in
`.dart_tool/loop11-verified-sweep/`; the final binary is
`.dart_tool/loop11-sweep-final.exe`. A 51-sample interval-overlap repeat
resolves the initial +7.1% outlier at 7.788 -> 7.697 ms (-1.2%), with the
same checksum.

The SDK generic/function_bounds_test now passes its instantiate-to-bounds and
argument-checking sections. Its type-formatting section still fails the first
signature pattern, and its subtype section accepts a G<double> cast that should
fail. The test remains expected-failing. A separate existing issue confuses
outer and inner callable parameter owners by position; composite captured bounds
such as `U extends List<T>` need owner-aware environments in a later step.

The default suite passes 1,737 tests with 62 skipped, including seven new
fresh/serialized regressions. Final review added a low-level cache-lifetime
regression: a runtime-free closure discards cached type IDs before a context-free
call. That test and all seven language regressions pass after the correction.
Analyzer is clean for changed source and tests; generated interpreter output is
verified by the runtime suite. Expected-failure SDK statuses remain unchanged.

