# Map, Set and expression checkpoint

Seven instructions add Map/Set construction, insertion, map indexing and explicit
wrapping. Backing collections store canonical guest values. Their hash and equality
callbacks support evaluated object keys with custom operators and preserve native
insertion order. Host views retain identity and mutation in both directions.
Boxed collections remain boxed when their interfaces can serve direct indexing,
avoiding repeated wrapper allocation. Set.add now returns its insertion result,
and Set reports its correct runtime type.

Switch evaluates its subject once and uses a distinct comparison operand for each
case. Comparisons no longer rewrite the subject used by later cases. Dynamic
arguments are boxed by the compiler, including strings and collections. Global
constructor inference retains static class types, allowing optional bridge
arguments to use their declared layout.

Validation: 781 tests pass, 45 fail, six are skipped. Fifty previously failing
tests now pass with no regressions. An old test expecting unsupported map
construction now checks successful fresh and serialized execution. Analysis has
zero errors. The remaining failures are recorded in the migration report.

Codec version 112, 229 opcodes, 27 unused byte values. ARM64 dispatch remains
41 instructions for integer/double addition with 11 stack stores and three loads.
The switch is 23,696 bytes at `0x14fe50..0x155ae0`, versus 22,856 previously.
These static counts do not measure hashing, guest equality calls or allocation.
Those operations have separate costs, particularly custom guest hash/equality
callbacks. Future specialization can use statically known key representations;
it must preserve custom equality, numeric equivalence and null semantics.

Async suspension is the next integration milestone. Its separate unused helper
and frame groundwork are excluded from this commit.
