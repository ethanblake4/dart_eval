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
survey caught TypeRef's nullability-insensitive equality dropping a nullable
arm; the join now preserves nullability independently of type-set deduplication.

Pinned affinity mask `4`, sequential processes without concurrent test runs,
100,000 appointments and 15 samples:

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
