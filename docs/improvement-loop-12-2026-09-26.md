# Improvement loop 12

## Step 1: preserve nested generic environments

Runtime callable parameters previously resolved against one positional vector.
An outer T and inner U both occupied slot zero; entering the inner callable
lost the outer binding. Exact calls with omitted arguments could additionally
replace captured outer arguments with the inner defaults.

Functions now record the owner of each type parameter, and codec version 128
preserves this metadata. An immutable environment links each invocation's
bindings to its captured scopes. Frames create it lazily when type operations
or closure capture need it. Nongeneric frames reuse their captured environment.
Resolution matches both owner and parameter index, including extension and
method parameters sharing an argument vector. The obsolete extension-method
index offset is removed.

Closure defaults, bound checks, argument checks, runtime signatures, allocations,
type tests, and type literals use the captured environment. Exact calls pass
resolved defaults as their own arguments while retaining the outer bindings.
Async frames retain their environment; generator iterators copy the captured
scope from their template. The interpreter source is regenerated from its tool.

Eleven fresh/serialized language regressions cover three escaping generic scopes,
composite omitted bounds, invalid explicit bounds before body execution, generic
signatures, named/default calls, async and generator suspension, and mixed generic
extension/method parameters. Constructor closures recognize the captured integer
class descriptor, and factories record their class-parameter owners. Three
constructor regressions cover defaults and rejection before body execution.
Codec tests check repeated/mixed owner IDs and reject malformed metadata.

SDK function/type2_test now passes: a callback created in a super-constructor
argument checks its captured class type. Its expected-failure entry is removed.
The final 151-test generic SDK survey passes 114, with three compile errors and
34 runtime errors, all expected. Results are in
`.dart_tool/loop12-step1-verified-sdk.jsonl`.

The constructor-complete full run passed 1,760 tests and exposed only the stale
type2 expected-failure entry; the focused SDK test passes after removing it.
The next full run again passed 1,760 tests, but a binding-generator child process
exited with no diagnostic output. Its isolated retry passes. Both runs skipped
62 tests. Targeted analysis is clean. Logs are
`.dart_tool/loop12-step1-verified-tests.log`, `loop12-step1-green-tests.log`,
`loop12-step1-sdk-type2.log`, and `loop12-step1-bindgen-isolated.log`.

Performance testing caught a 5-7% exact-closure slowdown in the first version.
Calls without explicit type arguments now skip caller-environment resolution,
and the small closure entry helpers inline. Restoring the indexed parameter scan
in the constructor-owner helper also removed a host-callback slowdown. The final
36 focused generic/default/machine tests pass, including generated-code checks;
analysis of runtime and changed compiler sources is clean.

The final 22-driver AOT sweep matches all 21 execution checksums. Compilation
measures 11.011 -> 11.145 ms (+1.2%), with 1,225 code bytes unchanged. Exact
closure repeats improve by 1.2-3.8%. Reversed 101-sample callback repeats range
from -2.2% to +2.0%; async cases are unchanged or faster. String fields retain
a 3.1% increase on the reversed 101-sample run (earlier measurements were
+5.2% and +7.5%), so that cost remains a performance follow-up rather than a
claim of no regression.

Baseline is edeaaa7 with control_flow_graph a0c339a. Final executable is
`.dart_tool/loop12-callback-sweep.exe`; sweep and repeat logs are in
`.dart_tool/loop12-step1-final-sweep/`, `loop12-final-repeat-*`, and
`loop12-reverse-*`. Generic checked calls can also avoid repeated environment
snapshots across parameter checks in a later performance pass.

## Step 2: contextual types for indexed operations

Thirteen alias-usage SDK failures shared one cause: an empty `{}` used as a
`Map<Set<T>, Set<T>>` assignment key was compiled without the setter's key
context, creating a map instead of a set. Index compilation now obtains the
instantiated operator parameter type before compiling the key. Simple writes
use `[]=`, while reads and compound writes use `[]`, matching native Dart.
Null-aware operations keep key evaluation inside the existing null guard.

The same signature lookup supplies assignment-value context for bridged and
inherited operators, replacing source-only annotation resolution. Generic
extension operators retain their extension bindings. This is a compiler-only
change with no added runtime checks or interpreter changes.

Six regressions exercise fresh and serialized programs: alias map keys and
values, inherited generic operators, extension cascades and increments,
null-aware side effects, null-coalescing assignments, and different getter and
setter key contexts. All pass. Targeted compiler analysis is clean.

The 151-test SDK survey improves from 114 to 127 passes, with three compile
errors and 21 runtime errors remaining, no regressions or timeouts. Removed
all 13 newly passing expected-failure entries. Survey results are in
`.dart_tool/loop12-step2-sdk.jsonl`.

The full suite passes: 1,767 tests, 62 skipped. The SDK core runner still records
34 expected runtime failures and 26 expected compile failures; the improvement
loop remains active. Full log: `.dart_tool/loop12-step2-full-tests.log`.
