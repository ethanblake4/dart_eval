# Global storage checkpoint

Globals now use runtime-owned storage with lazy initialization. The compiler
links initializer functions when reachable code loads or stores their slot;
initializers execute only on the first read. An assignment before that read
suppresses initialization. Multiple Runtime instances can share one immutable
Program while keeping independent global values and initialization flags.

## Storage and calls

The frontend chooses a stable representation before compiling an initializer,
including forward references. Integer, double, boolean and String globals retain
native values. Nullable and other object globals use the object bank. Initializer
functions take no arguments and return that selected representation. The compiler
emits required conversions for initializers, reads and assignments. Global
storage never guesses whether to unwrap a `$Value`.

Eight load/store instructions cover the integer, double, boolean and object
banks. Each uses a two-byte global index. Non-inlined typed helpers access the
runtime's storage without keeping another table pointer live in the switch loop.
Initialized reads check a byte flag and read the value; no signature lookup or
bridge conversion occurs. Native values reside in one Object? list, so Dart may
still box native doubles or large integers in that heap storage. This is separate
from dart_eval wrapper allocation.

Inference covers declared types and common scalar expressions. More complex
unannotated initializers can use boxed dynamic storage until fuller expression
type inference is available. An explicit declaration preserves the intended
storage type for those cases.

A first read enters its initializer through a separate VM invocation. This cold
path preserves the caller's registers without changing the register ABI. The
ordinary call loop and C overflow convention remain unchanged. VM host entry
prepares a serialized Runtime and its bridge registrations before accessing
globals. Source closures and instances retain their originating runtime, and
cross-runtime callbacks use that runtime's globals rather than the caller's.
Instances now retain a runtime reference, and member resolution checks runtime
identity before taking the direct call path. This adds an object field and a
dispatch check in exchange for correct ownership when objects escape the VM.

The runtime allocates exactly the global slot count in the program, replacing
the former fixed allocation of 20,000 values. Bridge enum registration writes
through the same state mechanism and marks those slots initialized.

## Initialization semantics

Each slot is unread, initializing or ready. An initialized null is ready. Cyclic
reads and reads of unassigned late globals throw a StateError with the global
name. Failed initialization can be retried. If the initializer explicitly writes
its own slot before throwing, that assignment survives; a successful initializer
return supplies the final value. Tests compare these write/throw rules with
native Dart behavior.

Late final globals without initializers permit one assignment. The frontend
rejects writes to other final or const globals, and the runtime rejects repeated
late-final writes. These errors currently use StateError; precise Dart
LateInitializationError compatibility remains part of exception work.

Source enum constant initializers use the same lazy storage. Enum names are
explicitly boxed for their constructor ABI, and synthetic enum constructors are
excluded from public exports. Global initialization does not make them callable
as ordinary exported functions.

A bridge initializer regression also exposed cross-compilation cache leakage.
Resolved types and built-in method tables previously reused numeric library IDs
from a different compiler context. Both caches now belong to their compiler
context, including when compilers with different bridge libraries are interleaved.

## Encoding and verification

Typed payload version 110 has a 68-byte header and global descriptors containing
the initializer function, storage kind, late/final flags and name. The Program
envelope remains at version 102. Validation checks indices, initializer argument
and result signatures, and the register bank used by each global operation.
The opcode table has 212 entries, leaving 44 byte values for future intrinsics.

Tests cover lazy execution, dependencies, forward references, write-before-read,
initialized null, cycles, retries, explicit writes during initialization,
late-final assignment, statics, enums, primitive conversions, runtime isolation,
callbacks and serialized execution. The current complete suite is recorded in
[the migration report](typed-migration-failures.md). Native code measurements and
repeatable profiling workloads are in [the ARM64 report](typed-arm64-optimization.md).

Final validation: 665 passes, 128 failures and six skips, with zero analyzer
errors. Twenty-three formerly failing tests now pass, and no previously passing
test regressed. The remaining failures include 127 unfinished-feature errors and
the existing Future.delayed timing assertion, which passes in isolation. Generated
files are current and the ARM64 arithmetic path remains at 38 instructions.

## Next checkpoint

Implement exception handling and finally blocks before suspension. Define handler
metadata and frame unwinding, preserve values used by catch/finally blocks in
spills, and ensure return, break, continue and rethrow retain their pending
completion through finally. Reuse the frontend's existing exception IR. Check
nested calls, closure frames and failed global initialization across unwinding,
then rerun the existing exception tests and full suite. Keep handler metadata out
of the arithmetic loop's live registers and reinspect the full ARM64 probe.

Remaining representation and bridge-method argument failures stay in the migration
report. Default/tearoff call adapters, frame cache behavior and multiple-register
record results remain separate performance work. Future Map/Set intrinsics can
still use existing object registers and the shared instruction generator.
