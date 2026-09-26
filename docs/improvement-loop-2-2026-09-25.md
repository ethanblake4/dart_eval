# Second improvement loop, September 25, 2026

Starting revisions: dart_eval `9e8d99e` on `xv2`, control_flow_graph
`bd9c394` on `main`. Windows x64, Dart 3.13.4, CPython 3.12.9.
The sibling path dependency is intentional.

## Step 1: constructor formals and dynamic list indexes

A fresh survey of operator, if_null, parameter, getter and assert tests found
59 passes and nine failures among 68 runnable SDK tests.

`parameter/initializer_test.dart` exposed inconsistent constructor signatures.
An explicitly typed field formal, such as `int this.value` on a `num` field,
used the field type at the call site but its annotation in the callee. The
caller boxed a value that the callee expected in an integer register. Formal
resolution now honors annotations before inherited types, including super
formals. Super forwarding uses the same resolved type as its incoming parameter.
Regression coverage exercises direct, named, defaulted and forwarded parameters
in fresh and serialized programs. The SDK test now compiles but still fails
because superclass constructor bodies cannot dispatch to subclass setters before
the subclass instance exists. Its expected-failure entry remains.

`parameter/named_with_dollars_test.dart` exposed a separate bug in its dynamic
list index expression. `n % 3` had object representation, while `IndexList`
requires an integer. List reads now apply the existing assignment conversion
to the index. Typed integer indexes need no additional instruction; dynamic
indexes receive the required type check and conversion. The SDK test passes
and its expected-failure entry is removed. Regression coverage checks successful
dynamic indexes and rejection of a string index, fresh and serialized.

Focused constructor and index regressions and the original named-parameter SDK
test pass. Changed-file analysis is clean. No runtime or standard-library
changes were required.
