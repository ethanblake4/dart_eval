# Fifth improvement loop, September 26, 2026

Starting revisions: dart_eval `807f48b` on `xv2`; sibling control_flow_graph
on `main`. Validation runs on Windows with the local Dart SDK.

## Step 1: constructor capture scopes

A fresh SDK sample passed 103 of 125 runnable tests across assert, closure,
constructor, and operator. The core suite passed its status expectations,
with 425 actual passes, 33 runtime failures, and 30 compile errors.

Capture analysis kept initializing formal parameters in scope while scanning
constructor bodies. A closure reading `a` inside `C(this.a) { ... }` therefore
captured a parameter that code generation had already removed. In the body,
that name denotes the field and the closure must capture `this`.

The capture scan now removes initializing formals after visiting the
initializer list. Initializer closures still capture the parameter. No runtime
code or bytecode checks were added.

Validation: the complete SDK `constructor_contexts_test.dart` now passes and
its expected-failure entry is removed. All 44 closure tests pass, including a
new regression that distinguishes the initializer's captured parameter from
the body's captured field, both directly and after serialization.

The separate `constructor_test.dart` and `closure/in_initializer2_test.dart`
failures need construction-order changes: superclass bodies currently run
before the subclass instance and fields exist. They remain open.

## Step 2: call typing and void closure returns

Direct `Object.new()` and source `C.new()` calls now normalize the unnamed
constructor selector before looking up bridge and source targets. The SDK
unnamed-constructor fixture proceeds to a separate, still unsupported
constructor tear-off. Thirteen constructor-entrypoint tests pass.

`remainder` and `clamp` now use Dart's operand-dependent numeric result types
and pass the result context down to their arguments. This changes compiler
type information without adding runtime checks or adapters. Two focused
tests cover integer/double results and generic argument inference. The large
SDK numeric fixtures still encounter separate binary-operator typing and
context-inference failures, so their status entries remain.

An intrinsic such as `List.add` emits no result register. The resolver erased
its `void` type to `dynamic`, causing an arrow closure to return an undefined
SSA value. Intrinsic void results now retain their type, and arrow closures
emit a void return for them. The new regression and all 52 closure tests pass.

The existing late-field test added a nullable public field directly to an
integer. The host Dart analyzer rejects that expression. Its read now uses
`!`, keeping the original late-field state checks; all three tests pass.

Analysis of the changed files reports only the existing local-name lint in
the binder. No runtime or generated standard-library code changed.
The default suite passes 1,679 tests with 62 skips, including the pending
capture optimization. SDK core now has 426 actual passes, 33 runtime failures,
and 29 compile errors under its existing status list.

## Step 3: capture initialized final objects directly

Closure environments already support object values as well as shared cells.
An initialized final object binding cannot be reassigned, so allocating a
mutable cell for it wastes an allocation and a read on each access. Such
bindings now use the existing direct-capture path. Scalars keep typed cells;
uninitialized finals keep cells so closures observe later initialization.

The configured-callback benchmark creates escaping processors with per-batch
configuration and mutable output, then processes 32 records per batch. It
exercises object identity and repeated field access through captured objects.
AOT executables were pinned to CPU affinity mask 4 and run with 15 samples.

| Workload | Baseline median | Candidate median |
| --- | ---: | ---: |
| Configured callbacks, 20,000 batches, first pair | 181.292 ms | 165.973 ms |
| Configured callbacks, reverse-order repeat | 195.060 ms | 166.009 ms |
| Event bus, 60,000 events | 108.288 ms | 106.626 ms |
| Final rebuilt configured callbacks | 208.939 ms | 162.360 ms |
| Final rebuilt event bus | 72.626 ms | 71.711 ms |

The first two callback pairs improve by 8.5% and 14.9%; event-bus results are
roughly unchanged. Timing has substantial system noise, especially in the
final callback pair, so the larger final median difference is not a reliable
speedup estimate. Every baseline/candidate checksum matches: `7522092512`
for configured callbacks and `907679289586` for the event bus.

The default suite passes with this change. Additional tests cover nested
captures sharing object mutation, deferred initialization of finals, promoted
scalar and nullable string captures, serialization, and absence of mutable
capture-cell operations for an initialized final list. No runtime changes.

## Step 4: review and cleanup

Reviewed the constructor capture, call typing, void-result, and direct-capture
changes. Numeric method context selection now checks the method name before
testing receiver subtyping, avoiding that work for unrelated bridge calls.
The result helper is named for `remainder`, its actual caller, and the touched
binder's local-name lint is fixed. Formatting needs no further changes and
analysis of all changed compiler files is clean.

The focused numeric, void-closure, constructor-entrypoint, and closure suites
pass after cleanup. The full SDK survey still has hundreds of real failures;
the next loop starts with inherited `noSuchMethod` conformance and async test
completion. No control_flow_graph changes were needed in this loop.
