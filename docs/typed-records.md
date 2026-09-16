# Records and type operations

`NewRecord` lowers to a three-byte opcode. The compiler stores its field-layout
constant and runtime type ID in the program constant pool. The runtime decodes
that layout once and shares it across record instances. Each construction
transfers the field list built by the compiler without copying its elements.
Fields contain canonical guest values, including native null.

Synthetic record types are registered before program emission. Their hash code
now agrees with the existing cross-library type equality rule. Record literals
receive their contextual type, and positional patterns start at `$1`.

Constant type values and checked casts have dedicated operations. The compiler
boxes the cast operand explicitly, checks it, then narrows its type before
selecting any scalar unbox instruction.

The existing record, pattern, expression and class tests pass. A focused test
checks nullable and collection fields across calls in both fresh and serialized
programs. Exported records retain a `$Record` handle rather than silently
returning null. Native host Record construction and multi-register record
returns are not implemented.
