# Second improvement loop, September 25, 2026

Starting revisions: dart_eval `9e8d99e` on `xv2`, control_flow_graph
`bd9c394` on `main`. Windows x64, Dart 3.13.4, CPython 3.12.9.
The sibling path dependency is intentional.

## Step 1: constructor formals and dynamic list indexes

A fresh survey of operator, if_null, parameter, getter and assert tests found
59 passes and nine failures among 68 runnable SDK tests. After the dynamic
index fix below, the same set has 60 passes and eight failures.

`parameter/initializer_test.dart` exposed inconsistent constructor signatures.
An explicitly typed field formal, such as `int this.value` on a `num` field,
used the field type at the call site but its annotation in the callee. The
caller boxed a value that the callee expected in an integer register. Formal
resolution now honors annotations before inherited types, including super
formals. Super forwarding uses the same resolved type as its incoming parameter.
Regression coverage exercises direct, named, defaulted and forwarded parameters
in fresh and serialized programs. The SDK test now compiles but still fails
because superclass constructor bodies cannot dispatch to subclass setters before
the subclass instance exists. Its expected-failure entry remains.

`parameter/named_with_dollars_test.dart` exposed a separate bug in its dynamic
list index expression. `n % 3` had object representation, while `IndexList`
requires an integer. List reads now apply the existing assignment conversion
to the index. Typed integer indexes need no additional instruction; dynamic
indexes receive the required type check and conversion. The SDK test passes
and its expected-failure entry is removed. Regression coverage checks successful
dynamic indexes and rejection of a string index, fresh and serialized.

The full core run also found seven stale expected-failure entries:
`super/bound_closure_test.dart` and `super/operator_index3_test.dart` through
`operator_index8_test.dart`. All seven now pass as ordinary SDK tests, so their
entries were removed. They use super method calls and operator dispatch, not
the dynamic list index conversion above.

Focused constructor and index regressions and the original named-parameter SDK
test pass. Changed-file analysis is clean. No runtime or standard-library
changes were required.

## Step 2: appointment overlap

`benchmark/interval_overlap.dart` and `.py` generate sorted appointments, measure
booked time and count pairwise overlaps within the preceding six appointments.
The ports use the same comparisons, integer masks, loops and checksum. Guest
compilation is outside the timer, and the dart_eval host is AOT compiled.

Conditional expressions boxed every branch result, including integer min/max
choices in the inner loop. The compiler now waits for both arm types, then
replaces the result conversions at their original positions with scalar copies
or unboxing. This preserves branch evaluation order and local representations.
Mixed and nullable results keep the existing object representation. A wider SDK
survey caught nominal common-ancestor selection dropping a nullable arm;
the conditional join now preserves nullability from both arms explicitly.

Initial sequential comparison without concurrent test runs, 100,000 appointments
and 15 samples. These runs were unpinned: a later audit found that the ctypes
affinity call had the wrong Windows handle width and silently failed. Corrected,
verified-affinity comparisons are recorded in the final review below.

| Version | Median ms | Minimum ms | Maximum ms |
| --- | ---: | ---: | ---: |
| Baseline | 203.945 | 193.644 | 560.092 |
| Scalar joins | 150.320 | 142.289 | 191.602 |
| CPython | 93.507 | 86.714 | 118.696 |

All checksums are `6224594498`. The candidate takes 26% less time; the ratio to
CPython falls from 2.18 to 1.61. Python remains faster. The baseline's high first
sample is included; medians and all raw samples are retained in
`.dart_tool/interval-isolated.log`. An earlier comparison overlapped the test
suite and is excluded from the reported measurements.

The full default suite passed 1,597 tests with 62 skips before the nullable-arm
regression was added. All 11 focused condition tests and the SDK null-shortening
case pass after the fix. Bytecode regression coverage confirms that nested
integer conditionals contain no boxing or object-to-scalar moves. Other cases
cover mixed types, local mutation, throwing arms and nullable scalar arms in
both orders. Changed-file analysis is clean. No runtime, opcode, standard-library
or serialization changes.

## Step 3a: promotions after throwing guards

A second SDK survey covered 53 runnable tests in nnbd/never, flow_analysis and
type_promotion: 37 passed and 16 failed before the nullable-conditional repair
and guard fixes. Two tests failed to compile because `x is String || throw ...`
did not promote `x` after the expression.

Short-circuit compilation now marks a Never-typed RHS as terminating before
emitting result conversions. At the join, the left operand's surviving condition
supplies its promotions. Conditional expressions no longer restore the then
branch's state unconditionally. Branch joins retain a promoted type only when
both continuing paths agree, so a guard on just one arm cannot affect the other.

`nnbd/type_promotion/logical_or_throw_test.dart` and `conditional_both_test.dart`
pass and their expected-failure entries are removed. The type_promotion survey
now passes seven of ten runnable tests. Regression coverage runs both conditional
arms, direct throws, Never-returning calls, AND null guards and rejects a
promotion present on only one arm. Fresh and serialized runtimes agree. All
12 condition tests and changed-file analysis pass. No runtime changes or
additional checks on ordinary boolean expressions were introduced.

Full default suite: 1,599 passed, 62 skipped. Generated typed-machine check passed.

## Step 3b: access-policy decisions

`benchmark/access_policy.dart` and `.py` classify packed request records using
tenant, ownership, role, expiry, suspension, verification and risk conditions.
The 200,000-request dataset includes 50,000 tenant mismatches, 26,405 allows,
7,969 reviews and 165,626 denials. Both ports use identical decision logic.
The initial tenant check used constant low bits of the alternating generator;
both ports were corrected before rebuilding the comparison binaries.

Boolean-valued `&&` and `||` now keep their results in the boolean register bank.
Chains consisting solely of non-nullable boolean locals and constants use the
existing condition compiler and materialize one final result. Expressions with
calls, mutations, type tests or other operands keep the general short-circuit
path, including its type checks and promotions. Regression coverage verifies
all truth-table combinations, captures, skipped invalid dynamic operands and
required runtime type checks when the result is unused.

Verified affinity mask `4`, 200,000 requests and 15 samples:

| Version | Median ms | Minimum ms | Maximum ms |
| --- | ---: | ---: | ---: |
| Baseline | 257.466 | 224.886 | 600.237 |
| Boolean registers and direct chains | 165.367 | 152.556 | 195.001 |
| CPython | 141.598 | 138.270 | 151.558 |
| Candidate repeat | 163.081 | 152.499 | 204.550 |

All checksums are `396413532770`. The candidate is within 17% of Python, down
from 82% in this comparison. The baseline is noisy; a preceding pinned run
measured 201.775 ms for the same baseline and 184.841 ms with boolean registers
alone. Do not interpret the full 36% median reduction as a stable speedup.
Raw logs are `.dart_tool/access-chain-comparison.log` and
`.dart_tool/loop2-pinned-comparisons.log`. No runtime or standard-library changes.

The user requested more varied language-feature coverage at this point. The
next workloads therefore focus on polymorphic template rendering and an event
bus using closures, captures and bound methods, rather than scalar loops.

Validation: full default suite passes 1,601 tests with 62 skipped; changed-file analysis is clean.

## Conditional review repair

The review found a second termination issue in conditional expressions. A
Never-typed arm still contributed to the result join and hid promotions from
the sole continuing arm. Such arms now terminate before result conversion;
only continuing arms determine the result type and storage representation.
Two terminating arms produce an unreachable Never result. Focused regressions
cover both arm orders, direct throws, Never-returning calls and the inferred
integer result in fresh and serialized execution. All 16 condition tests pass;
changed-file analysis is clean.
