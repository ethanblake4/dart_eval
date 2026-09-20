Implement correct `dynamic` semantics on `xv2` by extending the existing typed backend with checked conversions, runtime type descriptors, and complete dynamic invocation metadata. Keep the scalar register ABI and canonical boxed values. A new interpreter or a separate dynamic value representation is unnecessary.

This plan is based on `8ad26b3`, inspected on September 18, 2026, with Dart 3.10.7. It is a plan only; no compiler or runtime implementation has changed.

The correctness target is observable agreement with native Dart for dynamic operations in the language features dart_eval supports: successful results, side effects and their order, runtime type checks, and guest-visible exception categories. Generic values, function signatures, null behavior, and `noSuchMethod` are part of that target. Partial milestones should be described as partial support. Existing unrelated limitations, such as native host Record construction, do not need to be solved in this work.

Dart permits implicit downcasts from `dynamic`, but checks them at runtime. Accepting an assignment at compile time does not establish that its value has the destination type. See [Dart's type-system documentation](https://dart.dev/language/type-system#implicit-downcasts-from-dynamic). Generic type arguments are retained at runtime, so erased class identity cannot implement parameterized type tests. See [Dart generics](https://dart.dev/language/generics). Use the installed SDK as the executable reference, with the [language specification and feature specifications](https://dart.dev/resources/language/spec) to resolve edge cases.

The existing suite passes all 868 tests. The generated runtime check passes with 231 instructions. Analysis reports only the existing `invalid_dependency` warning for the local control_flow_graph path dependency. Twelve small programs were also compared against native Dart, running dart_eval both from a fresh Program and after serialization. Both dart_eval modes produced the same outcomes:

| Case | Native Dart | Current branch |
| --- | --- | --- |
| `dynamic x = 'bad'; A a = x; return 1;` | TypeError | Returns 1 |
| Assign that value to an existing `A` local | TypeError | Returns 1 |
| Dynamic call of `int f(A x)` with a String | TypeError before entering the body | Returns 1 |
| Dynamic `a.f(x: 9)` with a named parameter | Returns 9 | CompileError |
| Dynamic `a.f()` with optional `int x = 7` | Returns 7 | Argument-count error |
| `dynamic x = <int>[1]; x is List<String>` | false | true |
| `dynamic x = <int>[1]; x.add('bad')` | TypeError | Adds the String |
| `dynamic x = null; x.toString()` | String `"null"` | Internal `$Instance` cast fails |
| Missing method on an ordinary guest instance | NoSuchMethodError | EvalUnknownPropertyException |
| `dynamic x = 1; if (x) ...` | TypeError at runtime | Compiler representation-conflict StateError |
| Reassign a dynamic int local to `'abc'`, read `length` | 3 | 3 |
| `dynamic x = 2; x + 3` | 5 | 5 |

The source explains these failures. `TypeRef.isAssignableTo` accepts dynamic on either side, while declaration, argument, and return compilation generally only changes boxing afterward. `IdentifierReference` widens local types on assignment instead of retaining a separate declared type. `TypeRef` equality uses library and name, ignoring nullability and type arguments; runtime type tests similarly use class IDs and ancestor IDs. Dynamic method call sites carry only member name, kind, and argument count. Closure descriptors already carry names and defaults and should be reused where possible. These are separate problems that need a coordinated fix.

Implement the work in this order, keeping each stage independently reviewable.

1. Establish the semantic regression suite and preserve passing behavior.

   Add `test/language/dynamic_test.dart` and a small shared fixture helper under `test/support`. Turn the cases above into focused assertions, including catch-and-return checks inside guest code. Compare successful values, side-effect traces, and public error categories, rather than native private class names or exact error text. Compile each fixture once and execute both fresh and serialized forms. Keep a reproducible native-Dart comparison command for the same fixtures.

   Expand the matrix as each stage lands. Include dynamic parameters whose values come from the host, branches assigning different runtime types, captured locals, globals, field initializers, inherited members, callable objects, tear-offs, records, bridge values, and async suspension. Test an invalid argument that the callee never uses and an invalid assignment whose destination is never read. These prevent deferred checks from appearing correct by accident. Each implementation commit must make its own regression cases pass; do not leave skipped tests as the completion criterion.

   Capture the performance baseline before implementation, using the protocol below. Add shared benchmark fixtures before changing semantics where possible, so both revisions execute the same workload. Record unsupported or incorrect baseline cases explicitly instead of treating their timings as valid comparisons.

2. Separate declared types, flow facts, and machine representations.

   Start in `compiler/type.dart`, `variable.dart`, `context.dart`, `reference.dart`, and the branch/promotion helpers. Give bindings a stable declared or inferred type, separate from their current promoted type and the SSA value's representation. Assignments must be checked against that binding type; joins must combine flow facts without widening an explicitly typed binding or accidentally making a dynamic binding permanently concrete. Writes invalidate promotions where Dart requires it, including captures.

   Introduce explicit operations for nominal declaration identity, semantic type equality, subtype checks, and assignment compatibility. Replace `forceAllowDynamic` at semantic decision points with a conversion decision: already valid, requires a runtime check, or statically invalid. Do not globally change `TypeRef.operator ==` without migrating the caches and builtin maps that currently use nominal identity. Correct the generic comparison loop, which currently skips the last type argument, and account for nullability and function signatures.

   Preserve static distinctions among `dynamic`, `Object?`, `Object`, `void`, `Null`, and `Never`. Dynamic member access is permitted without a statically known member; ordinary `Object?` access is not. Audit `is` folding, promotion, and intrinsic selection so they require a real subtype or value proof. A value stored in a dynamic variable may still be optimized when that proof preserves runtime behavior.

3. Add one runtime type model and explicit checked conversion lowering.

   Introduce interned runtime type descriptors for special types, nullable types, nominal types with arguments, function signatures, record shapes, and type parameters with substitutions. Start with nongeneric nominal and nullable checks, then extend the same model in stage 5. Keep nominal class IDs for dispatch. Give type descriptors their own identity so `List<int>` and `List<String>` can share a class without sharing a type.

   Route `is`, `as`, implicit downcasts, and dynamic entry checks through one runtime subtype/check service. Extend `ir/types.dart`, `runtime/typed_interop_runtime.dart`, backend lowering, and codec metadata. `TypedExportParameter` already distinguishes declared types from machine kinds; replace its limited name-based checks with the shared descriptors while preserving the documented host API policy.

   Add a shared compiler conversion helper and use it for local declarations and writes, fields and globals, direct-call arguments, returns, collection elements, conditions, and async payloads. Convert from the source representation to a checked target value, then unbox to the exact target bank. An unbox operation must state its target representation. Inspect `backend/representation.dart` and `primitive_optimization.dart`, which currently infer or remove unboxing from its producer. A boxed int followed by a checked bool conversion must throw, even if its producer is known.

   Reuse `AssertType` where appropriate and add only the IR/bytecode forms that make checked outputs and effects explicit. Mark checks as potentially throwing, retain unused checks, and preserve their order across calls, mutation, catch/finally, phi edges, and suspension. Checks must run before an invalid write or callee body. Use `tool/generate_typed_machine.dart` for generated changes. Preserve raw null and existing `$Value`/`TypedInstance` identity, including cross-program type identity translation at bridges.

4. Complete dynamic invocation and guest error behavior.

   Extend `InvokeDynamic`, `TypedCallSite`, member metadata, and serialization with positional count, named argument names, caller library identity for private selectors, and explicit type arguments. Carry values in source evaluation order. Resolve the receiver's actual member first, then bind arguments to its signature, apply defaults, and validate required arguments and types. Reuse the closure argument-binding metadata and logic instead of implementing another incompatible binder. A call's valid arity does not prove its argument types.

   Cover methods, getters, setters, callable fields/getters, closures, method tear-offs, and callable instances through consistent lookup and binding rules. Update `typed_dispatch.dart`, `typed_instance.dart`, `typed_closure.dart`, `typed_interop.dart`, and bridge invocation adapters. Exact same-program calls should still enter the current VM loop using existing registers; they must pass the required checks. Calls requiring defaults or reordering can use an adapter without forcing every call to allocate an argument list.

   Implement supported Object operations on null explicitly. Implement `Invocation` and `noSuchMethod` dispatch for unresolved members and invalid invocation shapes, including named/type arguments and library-private names. Argument type mismatches produce TypeError. Preserve user-defined `noSuchMethod` behavior and ordinary default NoSuchMethodError behavior. See [Object.noSuchMethod](https://api.dart.dev/dart-core/Object/noSuchMethod.html).

   Register guest-visible TypeError and NoSuchMethodError support in the core wrappers and exception normalization; today general Error wrapping loses these specific categories. Assert that guest `on TypeError`, `on NoSuchMethodError`, and finally blocks behave correctly. Preserve any existing outer RuntimeException contract at the host boundary. Do not turn errors thrown by a successfully resolved user method into lookup failures.

5. Reify generic and callable types, and enforce checked writes.

   Retain instantiated type arguments on guest objects, List/Map/Set values, closures, records, and Future values where needed for language type checks. Replace `loadTemporaryTypes` substitution of a type parameter with its bound or dynamic by a real parameter identity and runtime substitution. Apply substitutions through generic inheritance, member signatures, and generic function invocation. Handle explicit type arguments, omitted-argument instantiation rules, and bound checks against native Dart fixtures.

   Enforce collection element/key/value constraints on every mutating path, including intrinsics, indexed stores, bulk methods, and aliases viewed through `dynamic`, `Object`, or a wider generic type. A failed `as List<int>` must check the list's runtime type; it must not copy the list or inspect only its current contents. Preserve identity and existing lazy host collection adapters. Raw host generic types and functions need explicit bridge type metadata or generated type witnesses where AOT Dart cannot recover arbitrary type arguments/signatures. Do not guess them from contents or `runtimeType.toString()`.

   Implement structural function checks with positional/named requirements, return types, parameter variance, and generic bounds. Runtime dispatch must enforce covariant parameter checks where required, including calls through a base type. Apply record shape/field checks and Future/FutureOr payload rules through the same type service. This is a necessary part of full dynamic correctness; passing scalar and nominal tests alone is an intermediate milestone.

6. Audit every dynamic expression path and finish integration.

   Cover arithmetic, comparisons, equality and null equality, unary operators, `[]`/`[]=`, compound assignment, prefix/postfix updates, boolean conditions, `!`, `&&`, `||`, `??`, null-aware access, `!` null assertion, interpolation, dynamic iteration, and await. Make boolean conversion explicit without introducing truthiness. Dynamic operator calls must respect user overrides. Dynamic access must not select extension methods statically. Invalid runtime operand types must compile where Dart permits them and fail at the correct execution point.

   Use side-effecting receivers, indexes, getters, and arguments to verify single evaluation and ordering, especially compound writes and null-aware chains. Exercise success and failure across closures, exception handlers, recursion, register spills, and suspension. Add static rejection fixtures to ensure the changes do not simply make all types behave as dynamic.

   Bump typed payload/envelope versions when their layouts change, reject older incompatible bytecode, and validate descriptor references, signatures, call-site shapes, and generic metadata during decoding. Keep runtime-only caches out of serialized data. Update the current compiler checkpoint and public documentation only after their corresponding tests pass.

Stages 2 and 3 establish the checks needed by stage 4; stage 5 completes their type information. Stage 6 starts as regression coverage alongside those stages and ends with the full integration gate. The largest uncertainty is reification across existing bridge collections/functions, followed by generic substitution and flow promotion. Resolve these with small working examples before migrating every producer or consumer.

Completion requires all conformance fixtures to agree with native Dart in fresh and serialized execution, all existing tests to pass, no new analyzer errors or warnings, and a passing generated-runtime check. Run `dart test`, `dart analyze`, and `dart run tool/generate_typed_machine.dart --check`. Where allocator constraints change, also run the adjacent control_flow_graph tests. Run the sibling flutter_eval suite after bridge metadata changes.

Performance work is part of stages 2 through 5. Typed scalar arithmetic and proven direct calls should require no additional checks or boxing. Dynamic calls and generic writes may become slower because the current implementation omits required checks. Type descriptors and adapters also increase metadata size and compilation work. Do not predict percentage changes before measurement.

Move work into the compiler wherever it has sufficient proof:

- Track SSA value facts independently of declared types. Remove proven-successful checks and redundant checks dominated by a successful check of the same value. Keep `dynamic x = 42; int y = x;` in integer registers when the value does not escape. Do not move a potentially failing check across observable effects or onto a path that previously skipped it.
- Generate checked entry adapters around shared function bodies. Proven direct calls use the existing typed ABI; unknown dynamic calls validate and convert their arguments before entering the body. Avoid checking at both boundaries. Covariant parameters still need validation unless the actual target's requirements are proven.
- Precompute argument placement, defaults, selector identity, and constant type substitutions. For a known target and call shape, emit register moves directly. For an unknown target, select a precomputed binding plan after lookup or cache the resolved plan. Avoid per-call name maps and argument lists on exact same-program calls. Do not eagerly generate every possible target/call-shape combination.
- Fuse primitive checking and unboxing so a dynamic-to-int conversion checks the wrapper and extracts its value in one operation. Use the general subtype service only when necessary. Eliminate collection write checks only when both the actual collection type and inserted value justify it; a declared `List<num>` can contain a `List<int>` instance.
- Intern constant type descriptors, precompute nominal subtype relationships and generic substitution recipes, and share metadata across instances. Keep general type checking and binding helpers outside the main dispatch loop. Add caches only after their correctness tests pass, keyed by the relevant program/runtime, instantiated types, and call shape. Lookup caches must not retain another instance's bound receiver or a mutable getter's previous result.

Defer speculative specialization and broad function cloning until profiles justify their complexity. Measure compile time, memory, and code size alongside runtime gains.

Run the following measurement protocol before implementation, after changes to checks/calls/generic storage, and at the final integration gate:

1. Preserve a baseline build from `8ad26b3` and a candidate build in separate checkouts/output directories. Record the exact commit and any benchmark-only patch, Dart SDK, dependency lockfile and adjacent control_flow_graph revision, OS, CPU, build flags, and LLVM versions. Keep SDK, dependencies, workload source, and input data identical unless the change explicitly requires otherwise. Compile each revision's own bytecode; do not reuse incompatible serialized programs across versions.

2. Run correctness-checked AOT workloads from `benchmark/dispatch.dart`, `calls.dart`, `closures.dart`, `callbacks.dart`, `external_calls.dart`, `globals.dart`, `exceptions.dart`, and `async.dart`. The existing call benchmark covers primitive, object, mixed, polymorphic, and overflow calls. Add `benchmark/dynamic.dart` for known versus unknown conversions, stable versus alternating receiver types, named/default binding, cold versus cached generic/function type checks, and collection writes with proven versus unknown element types. Include host-originated values so constant propagation cannot erase all checks. Measure failure paths separately from successful steady-state execution. Unsupported baseline features get an initial candidate measurement, not a claimed before/after speedup.

3. Compile outside timed execution, warm up each executable, and run at least two paired sweeps with baseline/candidate order reversed. Use at least 15 samples per steady-state case and fixed iteration counts long enough to exceed timer noise. Keep CPU affinity and power settings consistent and run no builds or tests concurrently. Verify every sample's result or checksum. Report raw samples, medians, spread, ns/operation, and percentage changes; separate cold-start and JIT measurements from AOT steady-state results. Repeat noisy or conflicting cases. Measure source compilation, bytecode loading, serialized size, AOT code size, and allocation/retained memory separately with the collection method recorded. Do not infer allocation counts from elapsed time or process RSS.

4. Cross-compile and inspect the full production ARM64 dispatch before and after using `tool/inspect_typed_arm64.ps1` and its file-driven `benchmark/runtime_probe.dart`. Preserve snapshots, symbol tables, disassembly, and exact commands under distinct baseline/candidate output directories. Use the same probe and keep the relevant dynamic, bridge, and type-check helpers reachable. Extend inspection to those helper symbols when they move out of `_dispatch`, so a smaller dispatch function does not hide larger total code.

Example commands, run in each revision's checkout with its own output label and available LLVM tools:

```powershell
$measurementLabel = 'baseline' # Use 'candidate' in the implementation checkout.
$measurementDir = ".dart_tool/dynamic-performance/$measurementLabel"
New-Item -ItemType Directory -Force -Path $measurementDir | Out-Null
dart compile exe benchmark/dispatch.dart -o "$measurementDir/dispatch.exe"
dart compile exe benchmark/calls.dart -o "$measurementDir/calls.exe"
& "$measurementDir/dispatch.exe" 5000000 15
& "$measurementDir/calls.exe" 1000000 15
./tool/inspect_typed_arm64.ps1 -Output "$measurementDir/arm64" -Objdump llvm-objdump -Objcopy llvm-objcopy
```

Apply the same paired protocol to the remaining benchmarks. Save warmup and raw timing logs rather than retaining only the summary output; extend the benchmark harness where it currently prints only aggregates.

Include the existing benchmarks under `.dart_tool` in the before/after suite. The `benchmark/` directory is not the complete performance inventory:

| Existing benchmark source | Required coverage |
| --- | --- |
| `.dart_tool/allocator_swaps_20260916/audit.dart`, its `before/cases.json` and `after/cases.json`, and `workloads/` | Integer sum, double arithmetic, integer mixing, particles, checkout, events, word count, and recursive tree traversal. Reuse the native checksum functions and workload inputs. |
| `.dart_tool/register_affinity_20260916/production/probes/affinity.dart` | Field access, maps, boolean calls, and comparisons, including fresh/serialized execution and boolean argument-boundary checks. |
| `.dart_tool/performance_audit_20260916/audit.dart` | Loading and first-call measurements using the `loadprepare`, `branchprepare`, and `load` modes. Keep file reading, lazy Runtime construction, Program/typed-payload validation, and first execution separate. |

Use `.dart_tool/allocator_swaps_20260916/compare.ps1` and `.dart_tool/register_affinity_20260916/run.ps1` as references for affinity, warmup, case rotation, paired execution, and JSONL evidence. Adapt their paths and build steps in a new measurement directory. The allocator comparison uses one executable for two payload sets because its runtime was unchanged; this dynamic implementation requires separate baseline/candidate executables whenever the runtime or codec changes. Rebuild all payloads with their matching compiler and dependencies.

The register-affinity `experiment.py` and `inspect.py` also provide ARM64 inspection and separate opcode-counting runs. Retain dispatch counts for the audit and affinity workloads to distinguish extra VM instructions from changes in native instruction cost. Never time the instrumented executables. Historical variant snapshots and results in `.dart_tool/performance_optimization_20260916`, `.dart_tool/performance_evidence_check`, and archive-check directories are reference evidence, not additional independent workload samples.

These local files may be absent from a fresh checkout. Preserve the selected harnesses, workload sources, inputs, and any API adaptations in the new reproducible evidence bundle, or promote reusable sources into `benchmark/`. Existing recovery material includes [allocator-swap-evidence.zip](allocator-swap-evidence.zip), [register-affinity-evidence.zip](register-affinity-evidence.zip), and the local `.dart_tool/performance_audit_20260916/performance-audit-evidence.zip`. Preserve historical results and source snapshots; write new builds and measurements elsewhere. Do not silently omit these workloads if a local harness needs updating for the current API.

The ARM64 comparison must report dispatch and helper code bytes, native stack-frame size, common-loop loads/stores, and consistently counted paths for integer/double arithmetic, fused branches, direct calls, dynamic calls, and checked unboxing. Record path assumptions and helper calls separately from instruction counts. Look specifically for type tables or other new state becoming live across the entire loop, extra scalar spills, and new allocations on exact calls. Cross-compiled assembly provides static code measurements only. If ARM64 hardware is available, run the same paired AOT workloads there and identify the device; otherwise label ARM64 timings unmeasured.

The performance acceptance target is no new executed checks, boxes, or allocations on proven scalar/direct paths. Investigate reproducible timing regressions beyond observed noise and any new common-loop stack traffic before accepting the change. For genuinely dynamic paths, report the measured correctness cost and the savings from compiler elimination or binding plans. Compare optimizations against a correct implementation as well as the original branch, so omitting checks cannot appear to be a valid optimization. Do not set an unsupported universal slowdown allowance.

Store commands, revision/environment metadata, raw results, ARM64 evidence, and a per-workload before/after table in a reproducible report under `docs/`. Link it from the current compiler checkpoint and explain unresolved regressions or unavailable measurements. Publish remaining unsupported cases rather than claiming complete `dynamic` support prematurely.
