# Contributing

Thank you for deciding to help out! It's really important for this project.

## Getting started

Clone the project, open it in your favorite IDE or editor and make sure everything's working by running the project's tests via `dart test`.

## Project structure

Each file in the project under `eval` is named with the type of code it corresponds to:

- `class.dart` - Static class reference objects
- `collections.dart` - Special classes related to collections
- `declarations.dart` - Declaration objects
- `expressions.dart` - All of the Dart expressions except literals
- `functions.dart` - Function interfaces, parameters, and function classes
- `generics.dart` - Generic lists, generic parameter classes
- `literals.dart` - Literal expressions such as String, int, and List literals
- `object.dart` - Objects within Eval, Bridge object mixins
- `primitives.dart` - The dart:core built in base types
- `reference.dart` - The Reference interface
- `scope.dart` - Different types of Scopes, references for those Scopes
- `statements.dart` - Evaluable statements such as if and for
- `type.dart` - The Eval type system
- `unit.dart` - Defines a Dart compilation unit (collection of libraries)
- `value.dart` - The base value interfaces, allowing Eval objects to be backed by real Dart values

## Understanding how it works

First, `parse/parse.dart` takes a String and passes it to the Dart analyzer's `parseString` function.
This returns an analyzer [AST](https://en.wikipedia.org/wiki/Abstract_syntax_tree) which contains a tree representation of the code.
However, we don't use the Analyzer to 'resolve' the code (even though it is capable), which would fill in type references, etc.,
because this is both very slow and unneccessary for an interpreter. Resolving is mainly used by IDEs to support code navigation
and refactoring.

After we have the analyzer AST, we need to convert it to our own AST which can be executed and actually run. In order to do this,
`parse` loops over all of the declarations in the returned compilation unit and calls `_parseDeclaration`. Parsing now occurs 
recursively, with each parse function calling another until we have mapped an entire declaration.

Next, we declare the top-level declarations onto a scope. Declaring a declaration creates one or more `EvalField`s each consisting 
of at least one of a value, getter, and setter. The most important reason we use declarations instead of creating fields directly
is that the fields need a reference to the lexical scope they're declared in so they can lookup other fields. For example, a class
needs to be able to instantiate other classes in the same file, so when we declare it we pass in the very scope that we then add it
to. (Yes, a circular reference, but it's the best solution.)

Aside: In dart_eval, classes, methods, functions, and values can all be stored in an EvalField because they are all `EvalValue`s. EvalValue
is the base type of anything that can 'exist' within Eval. It has an optional real backing value as well as a way to get and set fields.
Functions indeed 'exist' in Dart - in fact they are objects, which is why you can create tearoffs!

At this point, we're effectively 'done' with building an Eval environment and the scope is returned to the user, even though we
really haven't run any code yet! (Even top-level variable declarations that are initialized to a value are 'lazy' in Dart, so
they don't initialize until you first access them. Neat!)

To call a method, we now can obtain a reference to an EvalField in the scope which contains an EvalFunction, call its getter to get it,
and then call the EvalFunction. This quite simply executes whatever it contains, usually a `EvalBlockStatement`, using a newly created
scope which it injects the result of evaluating each of its parameters into. Many statements create their own scope.

Constructing a class is somewhat unique as it still has undeclared declarations. When we declare those declarations, we pass in
an `EvalObjectLexicalScope` - a special scope that forwards fields of an `EvalObject`. Therefore, a variable declaration on
this scope is actually a declaration on the Object.

## Making a contribution

Making a contribution follows standard procedure: fork the repository, make the change, write a test, and create a pull request. 
This applies whether you are fixing a bug or contributing a new feature. Please refrain from making sweeping, large changes without
getting in touch with me first or filing an issue and getting a go-ahead.

## Adding a new feature

If you're adding a new feature, the best place to start is by writing a test in `dart_eval_test.dart`. 
This is because, in this project, the error you get when running a failed test will often point you to the right place to start!
