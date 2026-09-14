# Typed backend implementation

The user approved implementation on 2026-09-13. This supersedes the pause and
generic-runtime-first order in backend-checkpoint.md. Commit and push each
verified stage in both repositories. Preserve the adjacent package's unrelated
working-tree fixture edits.

## Requirements

The production dispatch loop uses a dense integer switch over bytecode and named,
non-nullable typed scalar registers. Arithmetic handlers must not decode register
arrays, recover operand types, allocate instruction objects, or call generic
arithmetic helpers. Fixed operand and destination combinations are encoded in
the opcode. The existing general-object register machine is a semantic reference
while the typed backend reaches parity.

The initial register bank has two integer, two double, and two boolean registers.
Object/string banks, restricted loop registers, and instruction fusion follow
measured requirements. Spills use typed backing storage. Language types, wrapper
objects, and machine representations must remain distinct. Representation changes
are explicit at SSA definitions, phi edges, calls, and suspension boundaries.

## Stages

1. Generate a scalar runtime, opcode metadata, and encodings from one instruction
   description. Verify arithmetic, comparisons, branches, and typed spills with
   execution tests. Establish native Dart and object-register baselines, compile
   AOT, inspect native output, and record reproducible commands and limitations.
2. Make constrained allocation preserve ordered duplicate operands, respect
   register groups and clobbers, and spill live values instead of dropping them
   when destructive instructions need an occupied register. Verify with execution
   tests under two-register pressure and across control-flow edges.
3. Connect frontend SSA representations to the compact backend. Start with explicit
   primitive signatures, arithmetic, branches, loops, and direct calls. Reject
   unsupported operations explicitly. Test source-to-execution and serialization,
   including recursion, spills, and reverse operand order.
4. Add remaining representations and runtime operations with explicit call,
   exception, closure, bridge, and suspension conventions. Resolve the existing
   semantic failures against the typed backend before declaring parity.
5. Tune instruction selection, register counts, spill placement, compact branch
   encodings, and fused instructions using measured workloads. Preserve generated
   assembly and benchmark evidence when changing the hot loop.

## Validation principles

Run AOT performance tests separately from JIT. On Dart 3.10.7 the switch selection
code explicitly limits optimized jump-table selection to AOT. Small synthetic
switches do not reproduce the deployment dispatch function. Record SDK, target,
iterations, timing spread, code size, and benchmark checksums. A zero-allocation
claim must distinguish arithmetic dispatch from run entry, spilling, calls, and
return boxing. An unavailable platform is an unmeasured platform.

New package allocation tests must check executed results and live-value survival.
Do not refresh the preexisting package golden strings merely to silence failures.

## Implemented checkpoints

- `c074333`: generated scalar switch and reproducible AOT baseline. Results and
  native-code limitations are in typed-dispatch-baseline.md.
- Package `8afe791`: ordered duplicate operands, operation-specific variants and
  clobbers, constrained spilling, graph cloning, and SSA metadata rebuilding.
- Package `0436280`: carry resident registers across linear block boundaries.
- Package `104c802`: execution stress tests for clobbers, phi swaps, and joins.

The compiler now exposes `compileTyped` and selects reachable direct callees.
It preserves per-version representations, assigns fixed scalar register variants,
and emits bytecode with separate argument/spill banks. Calls execute in the same
dispatch loop. Caller values survive in typed spills; callee argument buffers are
independent, including under recursion. The format-102 typed codec preserves
signed 64-bit integers and floating-point bit patterns.

```dart
final program = Compiler().compileTyped({
  'example': {'main.dart': '''
    int fib(int n) {
      if (n < 2) return n;
      return fib(n - 1) + fib(n - 2);
    }
    int main(int n) => fib(n);
  '''},
}, entrypoint: 'package:example/main.dart');
final result = TypedMachine.run(program, intArguments: [10]); // 55
final restored = TypedProgram.read(program.write().buffer);
```

Supported source operations include integer addition/subtraction/multiplication,
truncating division/modulo, homogeneous double arithmetic, numeric comparisons,
boolean negation, branches, loops, break/continue, and direct primitive calls.
The generated runtime has 161 instruction forms. Compiler and runtime tests cover
register pressure, duplicate operands, mixed banks, recursion, more arguments
than registers, IEEE edge cases, codec validation, and serialization round trips.

`compile` still uses the reference backend while the typed backend reaches parity.
Unsupported typed operations fail during compilation. Optional-argument presence,
nullable values, objects, strings, dynamic dispatch, exceptions, closures, and
async remain unfinished on this path. Linear edges retain registers; loop/join
edges currently spill conservatively. Primitive source semantics and the existing
30 reference-backend failures remain the correctness baseline, not a claim of
completed runtime parity. Analysis has zero errors; inherited warnings remain.

## Pause and resume

The user requested a pause after this checkpoint on 2026-09-13. Stop after commit
and push; resume only when asked. All 51 focused typed machine, codec, compiler,
numeric, and representation tests pass. The latest full suite before the final
six codec/call tests were added had 530 passes, 30 known failures, and six skips.
The added tests pass separately. Full analysis reports zero errors.

Next work is stage 4 representation/runtime coverage above. Before tuning loop
performance, preserve the measured baseline: the compiled integer sum loop's hot
cycle currently has 20 instructions, including seven reloads and four spills.
Choosing the register for constant 1 more carefully in the update could avoid
spilling/reloading the constant and reloading the counter. Increment-immediate
selection or a restricted third integer loop register may offer more value than
complex global register-map reconciliation. No speculative allocator change was
kept; the package is committed through 104c802 with only the original fixture
edits remaining dirty.

The 161-opcode runtime now has call frames, so the earlier 152-opcode assembly
and timings describe the baseline checkpoint, not a remeasurement of the current
loop. Recompile and inspect the current AOT output before drawing new performance
conclusions. Local benchmark/disassembly artifacts are under .dart_tool/.
