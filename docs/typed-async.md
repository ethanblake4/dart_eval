# Async invocation and suspension

Async functions enter through the ordinary typed call ABI. Their synchronous
prefix runs in the same dispatch loop as the caller. Arguments keep their
compiler-selected representations, including native scalar registers and the
existing overflow convention.

`rBeginAsync` creates invocation state on the frame. It replaces the previous
bridge call to construct a Completer. A body that finishes without suspending
returns a completed or failed Future directly; a Completer is allocated only
when the first await needs a pending result. The Future payload uses the existing
boxed guest ABI. Exporting that Future does not recursively unwrap its payload.

The backend treats `rAwait` as clobbering every register bank. Register allocation
therefore stores live values in typed spills before suspension. The await helper
retains the frame, its lexical environment, handlers and pending completions.
It removes the frame from its caller's reusable child cache and clears its parent
link. Another invocation at the same call site gets independent storage.

The caller immediately receives the pending Future and continues. When the
awaited value completes, a callback reenters the dispatch loop at the saved PC
with its boxed result in R. Other registers start empty and the generated reloads
restore live values. A non-Future await still schedules a continuation. Native
Future values are normalized at this asynchronous host boundary, not by guessing
representations at ordinary calls.

Exceptions recover outside the hot dispatch loop. Unwinding stops at the nearest
async frame after its own catch/finally chain is exhausted, completes that
invocation's Future with the original error and trace, and returns the Future
to its caller. An error before the first await follows the same rule. An error
delivered by an awaited Future resumes the saved handler chain directly.

Protected async returns save the evaluated result in an object spill, then use
the existing completion jump to run finally blocks. `rReturnAsync` or
`returnAsyncNull` completes the invocation afterward. Returning a Future adopts
it after finally; it does not implicitly await inside the returning try block.
An explicit `return await expression` still awaits before leaving that block.

Focused tests cover fresh and serialized execution, synchronous prefixes,
overlapping child invocations, scalar awaits, captures, errors, async void and
fallthrough, and pending return/throw completions across await in finally.

## Performance evidence

Dart 3.10.7 cross-compiled the current 236-opcode interpreter from Windows x64
for Linux ARM64. `tool/inspect_typed_arm64.ps1` used LLVM's ARM64 disassembler;
these are instruction counts, not ARM hardware timings.

The steady integer-add and double-add paths remain 41 instructions: 31 in the
dispatch header, five in the operation, and five in the common tail. They have
11 stack stores and three stack loads, matching the Map/Set checkpoint. The
native dispatch frame remains 176 bytes. The dispatch body is 24,660 bytes;
the outer recovery driver is 428 bytes. Async continuation closures are created
inside the cold suspension helper. The dispatch entry does not allocate a
closure context, and ordinary frame entry/return has no async-state check.

Windows x64 AOT measurements below use 100,001 iterations and three samples.
Each row reports the median; asynchronous cases include scheduling and Future
completion. They characterize different workloads, not equivalent operations.

| Workload | Median ms | ns/iteration |
| --- | ---: | ---: |
| Synchronous function | 3.602 | 36.02 |
| Async body without await | 3.991 | 39.91 |
| Await completed scalar | 15.934 | 159.34 |
| Await native Future | 34.075 | 340.75 |
| Await host callback Future | 39.562 | 395.62 |

`benchmark/async.dart` produced checksum `75013262500`. A separate,
concurrently loaded run of `benchmark/calls.dart` exercised primitive,
mixed, instance, polymorphic, boxed and overflow arguments and produced checksum
`30010480045`. Its medians ranged from 166 to 388 ns/iteration; this noisy run is
not evidence of a speedup or regression. The generated ordinary call path keeps
the existing typed register and spill convention without per-call argument
boxing. Repeat both benchmarks on an idle machine when comparing checkpoints.

The nine focused async tests pass in fresh and serialized forms, including
errors thrown from guest callbacks invoked by native Future.then. That bridge
boundary removes the internal exception wrapper while preserving the original
error and stack trace.
