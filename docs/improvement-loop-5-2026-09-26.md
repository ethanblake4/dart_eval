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
