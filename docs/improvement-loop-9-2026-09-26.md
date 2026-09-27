# Improvement loop 9 — 2026-09-26

Starting revision: dart_eval `77c78f3` on `xv2`; control_flow_graph remains
`b901e65` on `main`.

## Step 1: lazy synchronous generators

The survey found 39 runnable SDK tests blocked directly by missing yield
statements. This checkpoint implements `sync*` with ordinary `yield`; delegated
`yield*` and asynchronous generators remain separate work.

A generator returns an iterable before entering its body. The existing register
allocator spills live values at its entry and yield boundaries. Each iterator
copies the initial typed spills into a separate frame, then resumes after each
yield. Captured parameters allocate their cells after the initial suspension,
so iterators share outer captures but have independent parameter/local state.
Exception handlers remain attached to the suspended frame. New opcodes are
appended to the generated instruction set; existing opcode numbers are stable.

Nine previously expected failures pass in a fresh AOT survey and their status
entries are removed: anonymous-method break/continue, generic sync*, five
sync_star tests, and both yield type-promotion soundness tests. Of 20 selected
tests, the other eleven require yield*, Iterable superclass/mixin support, or
async*. Seven focused regressions exercise fresh and serialized runtimes,
including laziness, captures, overflow parameters, generic types, closure return
inference, finally, exceptions, and reentrant iteration.

Validation: 1,220 non-SDK tests plus all 488 SDK-core cases pass (62 skips).
The SDK-core breakdown remains 426 passes, 34 expected failures, and 28 expected
compile errors. The first full run caught a status-file editing error; after
repairing the YAML, the entire SDK-core suite passed. Changed-file analysis,
generated-machine verification, and an independent code review pass.

The full 22-driver AOT comparison against `77c78f3` completed with all 21
execution checksums equal and the compiler output unchanged at 1,225 bytes.
Most execution medians were within about 5%. Initial interval-overlap (+8.5%)
and callback default-adapter (+13.9%) outliers did not persist in 51-sample
reverse-order repeats: interval overlap was 7.609 vs 7.655 ms (+0.6%), and the
callback case was 2.059 vs 1.907 ms (-7.4%). The compiler repeat was 16.928 vs
17.363 ms (+2.6%). This is a feature checkpoint, with no performance gain
claimed. Logs are in `.dart_tool/goal-generator-sweep` and
`.dart_tool/goal-generator-repeat-*`.

## Step 2: synchronous yield* delegation

`yield*` now uses the existing iterator protocol and loop lowering. The iterable
expression is evaluated once, then each `moveNext`/`current` pair supplies the
next suspended yield. This preserves lazy evaluation, iterator exceptions, and
the enclosing generator's catch/finally handlers without adding runtime
instructions. Closure inference collects the delegated iterable's element type,
and contextual typing supplies `Iterable<T>` to delegated expressions.

A fresh AOT survey passes 14 of the same 20 selected SDK tests, up from nine.
All five yield* blockers pass: move-past-end, nested subtype, regression 62319,
nested exceptions, and yieldstar. Their expected-failure entries are removed.
The six remaining tests need Iterable superclass/mixin support or async*.
Focused fresh/serialized tests cover lazy delegation, closure inference, empty
iterables, and iterator failure reaching the delegating catch/finally.
All 1,217 compiler/language/interop/runtime/stdlib/security tests pass, and
changed-file analysis is clean. This step changes only compiler lowering.
