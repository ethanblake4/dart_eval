# Dynamic performance regressions — analysis and improvement plan

Date: 2026-09-19 (UTC-7, AC power, High performance scheme).
Baseline commit: `8ad26b3757891abb1381bface225fae6bc763dfa` (branch `xv2`).
Candidate: same commit + working-tree dynamic-support changes (uncommitted),
plus the `isTypedValueType` boundary fix described in §2.
Script: `tool/run_dynamic_performance.ps1` (note: repo path is `tool/`, not `tools/`).
Summary: `tool/summarize_dynamic_performance.ps1`.
Dart SDK: 3.10.7 stable on windows_x64, AMD Ryzen AI Max Pro 390, affinity `4`,
15 samples/sweep, two rotated sweeps.
Evidence:
`.dart_tool/dynamic-performance/2026-09-19-paired2/` (pre-optimization run,
§3) and `.dart_tool/dynamic-performance/2026-09-19-paired-opt/`
(post-optimization run, §4).

## 1. What was executed

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File D:\Projects\dart_eval\tool\run_dynamic_performance.ps1 `
  -BaselineRoot D:\Projects\dart_eval_dynamic_baseline `
  -CandidateRoot D:\Projects\dart_eval `
  -EvidenceRoot D:\Projects\dart_eval\.dart_tool\dynamic-performance\2026-09-19-paired2
```

This run **completed end to end**: 9+9 benchmark builds, both `audit` and
`affinity` auxiliaries built and passed their `prepare`/`check 257` gates
(11/11 allocator checksums on the candidate, zero `auxiliary-skips` entries),
and both rotated sweeps produced timing logs for every benchmark.
`-ReuseBaselineEvidence` was **not** used: its
`Copy-Item (Join-Path $ReuseBaselineEvidence 'baseline/auxiliary')` step throws
`DirectoryExist` when the destination already exists — rebuild baseline fresh
or delete `baseline/auxiliary` in the new evidence dir first.

## 2. Correctness blockers — all fixed

| blocker | status |
| --- | --- |
| `audit` `word_count`: `num -> int` rejected at compile time | fixed earlier — `prepare` now emits 11 checksums |
| `audit` `events`: `void Function(int)` closure fails `assertTypedTypeArgument` | fixed earlier — same |
| `external_calls.exe` exit 255 at sweep start | fixed this pass, see below |

`external_calls` crashed in `TypedExportAdapter._validate`
(`typed_export_adapter.dart:184`): the new `runtimeTypeId` path called
`isTypedValueType`, which unconditionally called
`(value as $Value).$getRuntimeType(this)`. The benchmark's `_Token` is a
deliberately opaque `$Instance` (`$getRuntimeType` throws) passed to an
`Object` parameter. Fix in `lib/src/eval/runtime/typed_interop_runtime.dart`:

- `isTypedValueType` returns `true` for `dynamic`/`void` nominals before the
  null check and for `Object` after it — every non-null value satisfies these
  without reifying the value's type. Also treats `value is $null` as null.
- Same short-circuits in `isTypedValueTypeInClassEnvironment` and
  `isTypedValueTypeInCallableEnvironment`, gated on `descriptor.length == 2`
  so type-parameter rows (whose slot `[0]` is the `dynamic` nominal) still get
  environment resolution.
- `isTypedExternalAssignable` short-circuits `dart:core` `dynamic`/`void`/`Object`
  before `$getRuntimeType`.

This also fixes a latent bug: `x is void` previously returned `false` for
non-`void` values instead of `true`. Verified: `dart analyze` clean,
`test/language/dynamic_*` 83/83, `test/interop/` 77/77, all benchmark
checksums correct in-sweep.

## 3. Measured timing regressions (median of 30 samples, 2 sweeps)

Sanity anchors: every `*/native*` row and `dispatch/* typed|native` is flat
(±5%), so harness affinity/ordering is sound. `load/*/runtime_ctor_lazy` rows
show NaN/garbage percent from 0.000→0.000 ms medians — ignore.

### 3.1 Biggest regressions — call-path type checks

| case | baseline | candidate | delta |
| --- | --- | --- | --- |
| closures/overflow-four | 205.0 | 1282.5 | **+525.6%** |
| closures/noncapturing-exact | 84.6 | 477.7 | **+464.5%** |
| closures/shared-mutable-capture | 158.7 | 808.3 | **+409.3%** |
| closures/default-adapter | 358.2 | 1362.0 | **+280.2%** |
| calls/polymorphic | 105.0 | 307.2 | **+192.5%** |
| calls/overflow-arguments | 215.1 | 426.5 | +98.3% |
| calls/boxed-arguments | 130.0 | 197.0 | +51.5% |
| calls/method | 197.0 | 247.2 | +25.5% |
| closures/direct | 32.7 | 35.2 | +7.6% |
| calls/primitive / mixed | 33.2 / 70.9 | 35.6 / 74.4 | +7.1% / +4.9% |

Mechanism: `TypedClosure.checkExactArguments` → `_checkArgument` runs
`isTypedValueTypeInCallableEnvironment` **per parameter per call**
(`typed_closure.dart:156-227`), plus `_checkTypeArguments` →
`assertTypedTypeArguments` for generic calls. `TypedClosure.invokeAt`
additionally allocates a `values` list, a `named` map (even when empty), and
`sublist` copies per invocation (`typed_closure.dart:242-289`).

### 3.2 Collection element checks

| case | baseline | candidate | delta |
| --- | --- | --- | --- |
| dynamic/collection-write-proven | 13.2 | 34.0 | +157.2% |
| dynamic/collection-write-unknown-value | 10.8 | 27.2 | +152.4% |
| dynamic/collection-write-dynamic-receiver | 14.2 | 33.9 | +139.4% |
| allocator/word_count eval_aot | 28.1 | 66.7 | +137.8% |
| allocator/events eval_aot | 6.1 | 13.1 | +115.8% |

Mechanism: `$List._checkElement` / `$Map._checkEntry` / `$Set` call
`assertTypedTypeArgument` **per write** (`list.dart:1222`, `map.dart:331-333`,
`set.dart:391`), and each call recomputes the *collection's own*
`$getRuntimeType` (→ `importRuntimeType` → two `_setup` calls + possible
linear `_findRuntimeTypeDescriptor` scan) before checking the value.

### 3.3 Boundary / adapter validation

| case | baseline | candidate | delta |
| --- | --- | --- | --- |
| callbacks/default-adapter | 10.0 | 28.4 | +184.3% |
| callbacks/one-argument | 12.1 | 32.3 | +167.9% |
| callbacks/bound-member | 60.6 | 126.8 | +109.2% |
| external_calls/arity=6 legacy | 163.8 | 321.3 | +96.1% |
| external_calls/arity=6 registers | 133.8 | 248.5 | +85.6% |
| async/awaitCallback | 35.4 | 63.4 | +79.1% |
| async/awaitNativeFuture | 31.3 | 55.2 | +76.4% |
| external_calls/arity=3 registers | 49.0 | 82.6 | +68.8% |
| callbacks/captured-value / -void | 23.8 / 19.2 | 38.6 / 32.2 | +61.8% / +67.2% |
| async/asyncWithoutAwait | 1.8 | 2.7 | +46.4% |
| affinity/maps fresh / serialized | 69.2 / 69.1 | 164.7 / 163.6 | +138.1% / +136.8% |
| affinity/fields fresh / serialized | 76.8 / 77.8 | 152.9 / 157.2 | +99.1% / +102.0% |
| affinity/comparisons fresh / serialized | 77.8 / 88.3 | 130.2 / 130.6 | +67.3% / +47.8% |
| affinity/booleans fresh / serialized | 169.7 / 168.1 | 223.4 / 218.5 | +31.6% / +30.0% |

Mechanism: `TypedCheckedFunction.call` runs
`assertTypedFunctionAdapterArguments` + `validateTypedFunctionAdapterResult`
**every invocation** (`typed_interop.dart:264-266`); `TypedInstance.invoke`/
`_dispatchTypedObject` funnel into the same `checkExactArguments` per-arg
checks (affinity probes); `invokeTypedExternal` materializes an argument list
for the >3-arity path (`typed_interop_runtime.dart:809-824`); `executeLib`
`_validate` now runs the `runtimeTypeId` block per argument.

### 3.4 Conversion / type-assert ops

| case | baseline | candidate | delta |
| --- | --- | --- | --- |
| dynamic/conversion-stable | 2.3 | 15.9 | +578.5% |
| dynamic/conversion-host | 2.3 | 14.1 | +503.2% |
| dynamic/receiver-stable | 25.4 | 52.7 | +107.6% |
| dynamic/receiver-alternating | 37.2 | 68.6 | +84.6% |

New candidate-only coverage (no baseline): `failed-conversion`,
`function-type-check`, `generic-type-check`, `named-default-binding`.

Mechanism: `rAssertType`/`eIsTypeR` dispatch to
`isTypedValueTypeInCallableEnvironment` per executed op
(`typed_machine.g.dart:754-798`), and compute
`typeReceiver.dispatchRoot.$getRuntimeType(runtime)` for `actualOwnerType`
**even when the expected descriptor contains no type parameters**.

### 3.5 Allocation paths

| case | baseline | candidate | delta |
| --- | --- | --- | --- |
| allocator/particles eval_aot | 33.0 | 85.5 | +159.0% |
| allocator/checkout eval_aot | 33.9 | 52.4 | +54.8% |
| allocator/double_calls / object_calls | 16.0 / 22.7 | 21.5 / 30.0 | +34.2% / +32.3% |
| allocator/recursive_tree eval_aot | 100.4 | 133.0 | +32.5% |
| allocator/int_calls eval_aot | 4.7 | 5.2 | +11.2% |
| allocator/int_sum / int_mix / double_math | 37.5 / 31.8 / 24.6 | 38.5 / 32.6 / 25.5 | +2.9% / +2.5% / +3.7% |

Mechanism: `rCreateClassRA`/`rBoxListTyped` resolve descriptors at runtime via
`resolveTypedEnvironmentType`/`resolveTypedCallTypeArguments`
(`typed_machine.g.dart:585-1006`); when a type environment is required this
allocates a `Map<int,int>` and interns through the **linear**
`_findRuntimeTypeDescriptor` scan + `_typeTypes` set copies
(`runtime.dart:443-478`). Pure scalar loops stay flat (+2.5-3.7% ≈ noise) —
`code_bytes` unchanged there.

### 3.6 Load / startup path

| case | baseline | candidate | delta |
| --- | --- | --- | --- |
| load1/program_read_validate | 0.072 | 2.733 | +3701% (+2.66ms) |
| load1/runtime_of_program | 0.003 | 0.284 | +9884% (+0.28ms) |
| load1/typed_payload_read_validate | 0.004 | 0.067 | +1586% |
| load1/first_call_from_bytes / _from_program | 0.087 / 0.016 | 0.699 / 0.110 | +705% / +595% |
| load100/first_call_from_bytes | 0.252 | 2.953 | +1074% |
| load100/program_read_validate | 0.229 | 2.446 | +969% |
| load100/typed_payload_read_validate | 0.165 | 0.558 | +239% |
| load1000/* | — | — | +3-40% |
| branch3000/first_call_from_bytes | 6.758 | 9.600 | +42.1% |
| branch3000/typed_payload_read_validate | 5.144 | 6.361 | +23.7% |
| branch100-1000 first_call / validate | — | — | +6-63% |

Mechanism: `_loadProgram` eagerly deep-copies `_typeTypes` (one `Set<int>`
per type), `_typeDescriptors`, and rebuilds `_typeIdentities`/
`_nominalTypeIds` per `Runtime` (`runtime.dart:96-117`); evc decode
(`program_read_validate`) now also reads the descriptor block (+1 KB fixed,
+11-22% per case, §3.8). `runtime_of_program` shows a **~0.28 ms fixed**
descriptor-table cost on `load1` — dominant for small programs.

### 3.7 Wins and noise

- `dispatch/double object-reference`: **−92.9%** (657.5→46.4 ms);
  `dispatch/mixed object-reference`: **−85.1%**. The descriptor-based dispatch
  replaced a much slower object-reference path — keep, and report honestly.
- `exceptions/handledThrow`: **−23.8%** (211.8→161.5 ms).
- `load1000/first_call_from_bytes` −15.6% — likely ordering/cache artifact;
  do not claim.
- `globals/local` −2.6%, `global` +3.3% — noise.
- `exceptions` others +1.8-7.4%, `globals/object` +13.2%, `calls/mixed`
  +4.9% — minor.

### 3.8 Static regressions (re-measured this run)

Host AOT binary: `dispatch` +0.38%, `calls` +1.90%, all others +2.60% —
unchanged from the prior measurement; growth is the generated runtime
(`typed_machine.g.dart`/`typed_ops.g.dart`) plus descriptor machinery, not
guest payload. Guest `evc_bytes`: +1 KB fixed even for `int_sum`, +3.8-22.1%
scaling with declared types (unchanged from prior run; `code_bytes` still
identical everywhere — scalar/direct paths emit no extra VM instructions).

## 4. Optimization pass — implemented and re-measured

Re-run: `2026-09-19-paired-opt` (same command shape as §1, fresh evidence dir,
full audit + affinity gates green, 2 rotated sweeps × 15 samples).
Absolute numbers are not directly comparable across runs (baseline medians
moved up to ~2x on some rows, e.g. `closures/default-adapter` 358→195 ms —
machine boost/thermal variance); compare **delta percentages** and the
candidate-side reductions.

### 4.1 What was implemented

- **Trusted closure call sites** (plan item 1, partial — closure sites only).
  `invokeClosure` (`compiler/helpers/closure.dart`) now proves each supplied
  argument against the callee's static signature via
  `assignmentConversionTo == none` and stamps `InvokeClosure.trusted`.
  `TypedClosureCall` carries the flag through the codec (version 123→124) to
  `TypedClosure.resolve`/`invoke`, which skip the per-arg loop while keeping
  `_checkTypeArguments` and `accepts`. Function literals without a context
  type now carry their declared signature
  (`compiler/expression/function.dart`) — previously `var f = (int x) => x`
  typed as bare `Function`, which would have left every literal call site
  unprovable.
- **Owner-type caching** (item 5a): `TypedFrame.typeEnvironmentOwnerType`
  memoizes the receiver's dispatch-root runtime type per frame; regenerated
  `typed_machine.g.dart` uses it at the 11 prior
  `dispatchRoot.$getRuntimeType` sites.
- **Subtype/resolution memoization** (items 5b, 6): `_isSubtypeMemoized`
  caches `(actual, expected, ownerType, typeArgs)` verdicts;
  `_resolvedEnvironmentTypes` caches `resolveTypedEnvironmentType` results
  keyed `(type, actualOwnerType)` when callable type args are empty;
  `actual == expected` hoisted before type-parameter resolution; shared
  `_typeTypes`/`_typeDescriptors` tables with copy-on-write + version
  counter replace the eager per-Runtime deep copies; `_findRuntimeTypeDescriptor`
  is a hash map.
- **Alloc-free hot paths** (item 2): `invokeAt`/`TypedDispatch.invoke` no
  longer materialize `named` maps or `sublist` copies for positional-only
  calls; `TypedCheckedFunction` caches a monomorphic arg-shape verdict.
- **Owner caches on values** (items 3, 4): `TypedInstance.$getRuntimeType`
  single-entry memo keyed on runtime + dispatch-root identity;
  `$List`/`$Map`/`$Set` wrappers cache runtime/owner type for repeated
  element checks.

### 4.2 Re-measured results (median of 30 samples)

| case | base | cand | Δ now | Δ before |
| --- | --- | --- | --- | --- |
| calls/polymorphic | 100.9 | 125.7 | +24.6% | +192.5% |
| calls/overflow-arguments | 201.9 | 216.9 | +7.5% | +98.3% |
| calls/boxed-arguments | 131.9 | 141.1 | +6.9% | +51.5% |
| calls/method | 199.5 | 249.3 | +25.0% | +25.5% |
| calls/primitive / mixed | 35.8 / 72.4 | 36.0 / 76.3 | +0.5% / +5.5% | ~flat |
| closures/noncapturing-exact | 86.4 | 224.3 | +159.6% | +464.5% |
| closures/shared-mutable-capture | 161.2 | 319.3 | +98.1% | +409.3% |
| closures/default-adapter | 195.0 | 403.0 | +106.7% | +280.2% |
| closures/overflow-four | 210.4 | 353.5 | +68.1% | +525.6% |
| closures/direct | 34.1 | 36.9 | +8.2% | +7.6% |
| external_calls arity=3/6 legacy | 64.1 / 169.6 | 67.1 / 178.5 | +4.6% / +5.3% | +8.0% / +96.1% |
| external_calls arity=3/6 registers | 50.8 / 134.5 | 55.6 / 139.9 | +9.4% / +4.0% | +68.8% / +85.6% |
| dynamic/collection-write-* | 10.3-12.4 | 25.0-27.6 | +118-143% | +139-157% |
| dynamic/conversion-stable/host | 2.3 / 2.3 | 16.0 / 15.0 | +593% / +550% | +578% / +503% |
| dynamic/receiver-stable/alternating | 14.2 / 20.7 | 43.8 / 53.3 | +209% / +158% | +108% / +85% |
| callbacks/one-argument | 13.0 | 32.8 | +153.4% | +167.9% |
| callbacks/default-adapter | 10.4 | 29.8 | +186.8% | +184.3% |
| callbacks/bound-member | 59.7 | 138.9 | +132.7% | +109.2% |
| callbacks/captured-value/-void | 24.4 / 19.3 | 44.5 / 37.3 | +82.5% / +93.6% | +61.8% / +67.2% |
| affinity/fields fresh/serialized | 77.1 / 77.0 | 152.4 / 153.6 | +97.6% / +99.6% | +99.1% / +102.0% |
| affinity/maps fresh/serialized | 40.8 / 40.8 | 70.2 / 71.4 | +71.9% / +74.9% | +138.1% / +136.8% |
| async/awaitCallback / awaitNativeFuture | 36.4 / 32.5 | 58.4 / 51.7 | +60.6% / +59.3% | +79.1% / +76.4% |
| allocator/particles / word_count | 34.0 / 27.9 | 74.1 / 58.3 | +118.2% / +109.0% | +159.0% / +137.8% |
| exceptions/handledThrow | 160.0 | 167.8 | +4.9% | −23.8% |
| dispatch/integer object-reference | 73.4 | 43.1 | −41.2% | −85-93%* |
| dispatch/integer typed | 55.1 | 31.7 | −42.4% | win retained |
| load1/runtime_of_program | 0.003 | 0.010 | +257.7% | +9884% |
| load1/program_read_validate | 0.072 | 0.114 | +57.6% | +3701% |
| load100/program_read_validate | 0.224 | 0.286 | +27.4% | +969% |
| branch3000/typed_payload_read_validate | 5.7 | 7.2 | +25.2% | +23.7% |

`*` first run measured the same win on double/mixed rows (−85.1%, −92.9%);
integer rows still show a real −41% improvement.

All candidate `audit` checksums passed in-sweep; `dart analyze lib` clean;
`dart test` 961/961 (codec test updated for version 124).

### 4.3 What remains — next steps, ordered by impact

1. **Callbacks / adapter paths** (+82-187%): `callbacks/*` rows moved least.
   `default-adapter`/`one-argument` still materialize named-arg maps and
   defaults per invocation and re-run adapter validation on the bridge side.
   Extend the alloc-free/`trusted` treatment to `invokeBridgeArguments` and
   the named/default binding path; the per-invocation
   `assertTypedFunctionAdapterArguments` re-validation is still per-arg.
2. **Conversion/assert ops** (+550-593%): `dynamic → int` assignment now
   executes a real check per iteration where baseline skipped it — this is
   semantics-required cost, not an implementation bug. Remaining slack: the
   check still enters `isTypedValueType` + `$getRuntimeType` before the
   `actual == expected` hit; a per-value or per-descriptor single-entry
   memo at the op level could shave the fixed ~13 ns/iter further. Diminishing
   returns — document as expected cost of correct dynamic semantics.
3. **Dynamic receiver dispatch** (+158-209%, `calls/polymorphic` +24.6%):
   `callVirtual` on `dynamic` receivers must check args — no static
   signature exists. A per-callsite monomorphic cache
   `(receiverTypeId, member) → checked member` would collapse
   `receiver-stable`-class loops; alternating receivers still pay full
   resolve+check (legitimate).
4. **Collection element writes** (+118-143%): `assertTypedTypeArgument` per
   write remains ~15 ns after owner-type caching; a last-checked
   `(valueRuntimeTypeId → bool)` memo on the wrapper would hit ~100% in
   loops like `values.add(i)`.
5. **Affinity field/map ops** (+72-100%): same per-write check mechanism as
   (4) through typed field stores and map/set entry validation.
6. **Load path** (load1 `runtime_of_program` +257% / ~7 µs fixed, validate
   +14-58%): copy-on-write tables removed the per-Runtime deep copies (the
   ~0.28 ms `runtime_of_program` cost dropped to ~7 µs), but evc decode still
   reads the descriptor block eagerly and every program pays ~+1 KB
   `evc_bytes`. Next: lazy `_typeTypes`/`_typeIdentities` construction and
   compile-time gating of descriptor emission on dynamic/structural use
   (items 7a-7c of the original plan, still open).
7. **Host binary** (+2.6% unchanged): outline shared slow paths in generated
   code (item 8, still open).

Re-measurement protocol after each step: rerun the paired script exactly as in
§1 (fresh `EvidenceRoot`, no `ReuseBaselineEvidence` unless its Copy-Item bug
is fixed), then `summarize_dynamic_performance.ps1`, and compare medians —
do not hand-run exes for numbers.

## 5. Acceptance

- Candidate `audit prepare` + `affinity check` green (done — both runs,
  11/11 checksums).
- Full paired evidence with `summary.json` (done — `2026-09-19-paired2`
  pre-optimization, `2026-09-19-paired-opt` post-optimization).
- Status vs. goals:
  - `external_calls` — met (+4-9%).
  - `calls` static paths — met (+0.5-7.5%); `method` +25% and `polymorphic`
    +24.6% are per-call dispatch overhead, tracked in §4.3 item 3.
  - `closures` — improved 2-5x but still +68-160%; remaining gap is frame/
    snapshot machinery per call (§4.3 items 1, 3).
  - `conversion-*`, `collection-write-*`, `callbacks`, `affinity/*` —
    regressions named and bounded in §4.3 items 1, 2, 4, 5.
  - Load path — `runtime_of_program` fixed cost reduced ~40x; remaining
    +7 µs fixed + eager descriptor decode (§4.3 item 6).
  - `evc_bytes` +1 KB — not yet eliminated (§4.3 item 6).
  - Scalar loops check-free — `code_bytes` parity still holds; native rows
    flat.
- Wins preserved: `dispatch` object-reference −41% (integer) / +4-7%
  (double/mixed), `dispatch typed` −42%; `handledThrow` now +4.9% — the
  earlier −23.8% did not reproduce under different machine conditions,
  treat as noise not a lost win.
