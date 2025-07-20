# Contributing

Thank you for deciding to help out! It's really important for this project.

## Getting started

Clone the project, open it in your favorite IDE or editor and make sure everything's working by running the project's tests via `dart test`.

## Project structure

The project structure is as follows:

- dart_eval.dart - the main exported library for users of dart_eval
- dart_eval_bridge.dart - the main exported library for users creating custom interop classes and methods
- stdlib - Exported libraries for builtin 'dart:' library mappings
- src/eval - contains the main project source
  - eval.dart - The eval() function
  - bindgen - Source for the bindgen functionality, which generates Dart code to bridge from
    source code
  - bridge - Source for bridge functionality, both runtime and compile-time
  - cli - Source for the command line interface
  - compiler - Source for the dart_eval compiler
    - collection - functionality for compiling lists, maps, etc
    - declaration - functionality for compiling top-level declarations like functions and classes
    - expression - functionality for compiling Dart expressions (this is most Dart code)
    - helpers - shared functionality for compiling unclassified Dart syntax like argument lists
    - macros - compiler functions that allow reuse of common, complex structures like branches and loops
    - optimizer - for specific optimizations that can be enabled or disabled for a compiler speed tradeoff
    - statement - functionality for compiling statements like if, for, and return
  - runtime - Source for the dart_eval runtime VM
    - ops - The various op code implementations for the dart_eval bytecode
  - shared - shared code between the runtime and compiler
    - stdlib - builtin mappings for the 'dart:' standard libraries

## Overview of how it works

First, the compiler takes a map of source files (as strings) and passes them to the Dart analyzer's `parseString` function.
This returns an analyzer [AST](https://en.wikipedia.org/wiki/Abstract_syntax_tree) which contains a tree representation of the code.
However, we don't use the Analyzer to 'resolve' the code (even though it is capable), which would fill in type references, etc.,
because this is very slow. Resolving is mainly used by IDEs to support code navigation and refactoring.

After we have the analyzer ASTs, we need to compile them to a linear bytecode format which can be executed efficiently. The compiler
groups top-level declarations in each file and resolves basic information about them that it can use to store them in efficient data
structures for fast access when compiling. It also resolves imports and parts at this stage, determining which declarations are
visible from each file.

Next, we go through each declaration in no particular order and actually compile it into code. There are many steps to this that vary.
Classes will be compiled into a 1) a metadata structure referencing all of their methods and fields, 2) functions for each of the methods
and fields, and 3) 'static' functions (although all functions are technically static in bytecode) for their static functions and constructors.
For functions, local variables need to be tracked by the compiler as the bytecode only references them by their absolute index into the
current stack frame.

Finally, the resultant bytecode along with all necessary metadata is written to a file.

The runtime loads this file and maps each bytecode back to a class, storing it in a List that represents the entire program. In a loop,
the runtime steps through and executes each bytecode op in order. Most bytecode ops do things like push and pop values from the stack
of different types. In some cases, the bridgeCall() function will be used to create a 'sub-invocation' of the dart_eval VM, such as
when bridging (since we no longer control the program flow once we have made a call to a bridge function).

Eventually, the program will throw an exception signaling termination, which the runtime will catch and return a value (or not, if the
called function is void).

## Making a contribution

Making a contribution follows standard procedure: fork the repository, make the change, write a test, and create a pull request. 
This applies whether you are fixing a bug or contributing a new feature. Please refrain from making sweeping, large changes without
getting in touch with me first or filing an issue and getting a go-ahead.

## Adding a new feature

If you're adding a new feature, the best place to start is by writing a test. 
The error you get when running a failed test will often point you to the right place to start!
