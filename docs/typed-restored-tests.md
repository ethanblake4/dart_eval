# Restored test coverage

The six tests disabled before the typed-backend migration are enabled again.
Three fixtures needed corrections: a quoted map key, the result of `1 + 1`,
and the changed element after an indexed write.

Custom and dynamic indexed assignments now use operator dispatch instead of
assuming a List. Known Lists keep direct bytecodes with explicit scalar
conversions. Finding an assignment's contextual type no longer executes its
indexed getter. A fresh/serialized regression checks setter-only execution and
single evaluation of the index and assigned value.

Late instance fields without initializers use a private uninitialized marker.
Their getters and late-final setters use dedicated checked operations. An
assigned null counts as initialized. Ordinary field reads and writes keep their
existing instructions and do not pay for initialization checks. This does not
add lazy evaluation of late field initializer expressions.

`$List.view` exposes canonical guest elements through an explicit mapped List
adapter. Mapping remains lazy and mutations reach the native backing list.
The VM's direct List instructions need no new wrapper checks or conversions.
`view` is now a generic static method returning `$List<$Value?>`, rather than
a factory whose element type described native values despite exposing wrappers.
Use `$List.view<T>(values, mapper)` when an explicit host element type is needed.

The final 243-opcode ARM64 snapshot (Dart 3.10.7, Linux ARM64 cross-compiled
from Windows x64) retains the 41-instruction integer/double addition path:
31 dispatch-header instructions, five operation instructions and five tail
instructions, with eleven stack stores and three stack loads. The native frame
remains 176 bytes. Dispatch occupies 25,656 bytes and the recovery driver 428
bytes. These are generated-code measurements, not ARM hardware timings; the
three late-field operations do not alter the ordinary field instructions.
