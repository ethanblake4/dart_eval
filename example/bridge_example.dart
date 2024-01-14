import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/dart_eval_extensions.dart';
import 'package:dart_eval/stdlib/core.dart';

/// An example class we want to bridge
class Book {
  Book(this.pages);

  final List<String> pages;

  String getPage(int index) => pages[index];
}

/// This is our bridge class
class $Book$bridge extends Book with $Bridge<Book> {
  static final $type = BridgeTypeSpec('package:hello/book.dart', 'Book').ref;

  /// Create a class declaration for the dart_eval compiler
  static final $declaration = BridgeClassDef(BridgeClassType($type),
      constructors: {
        // Define the default constructor with an empty string
        '': BridgeFunctionDef(
            returns: $type.annotate,
            params: ['pages'.param(CoreTypes.list.ref.annotate)]).asConstructor
      },
      fields: {'pages': BridgeFieldDef(CoreTypes.list.ref.annotate)},
      methods: {
        'getPage': BridgeFunctionDef(
          returns: CoreTypes.string.ref.annotate,
          params: ['index'.param(CoreTypes.int.ref.annotate)],
        ).asMethod,
      },
      bridge: true);

  /// Recreate the original constructor
  $Book$bridge(super.pages);

  static $Value? $new(Runtime runtime, $Value? target, List<$Value?> args) {
    return $Book$bridge((args[0]!.$reified as List).cast());
  }

  @override
  $Value? $bridgeGet(String identifier) {
    if (identifier == 'getPage') {
      return $Function((_, target, args) {
        return $String(getPage(args[0]!.$value));
      });
    }
    throw UnimplementedError('Unknown property $identifier');
  }

  @override
  $Value? $bridgeSet(String identifier, $Value value) =>
      throw UnimplementedError('Unknown property $identifier');

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'pages':
        // TODO: Now we just pass along the bridged/parent class' property, so values don't change...
        return $List<$String>(identifier,
            $List<$String>.wrap(pages.map((e) => $String(e)).toList()));
      default:
        return super.$getProperty(runtime, identifier);
    }
  }

  /// Override the original class' properties and methods
  @override
  String getPage(int index) => $_invoke('getPage', [$int(index)]);

  // @override
  // List<String> get pages => $_get('pages');

}

void main() {
  final compiler = Compiler();
  compiler.defineBridgeClass($Book$bridge.$declaration);

  final program = compiler.compile({
    'hello': {
      'main.dart': '''
      import 'book.dart';
      class MyBook extends Book {
        MyBook(List<String> pages) : super(pages);
        String getPage(int index) => 'Hello world!';
      }

      Book main() {
        final book = MyBook(['Hi world!', 'Hello again!']);
        book.pages.add('Next Chapter');
        book.pages.add('Final Chapter');
        return book;
      }
    '''
    }
  });

  final runtime = Runtime.ofProgram(program);
  runtime.registerBridgeFunc(
      'package:hello/book.dart', 'Book.', $Book$bridge.$new,
      isBridge: true);

  // Now we can use the new book class outside dart_eval!
  final book = runtime.executeLib('package:hello/main.dart', 'main') as Book;
  print(book.getPage(1)); // -> 'Hello world!'
  print(book is Book);
  print(book is $Book$bridge);
  // TODO: I'd expect the "Next Chapter" and "Final Chapter" here as well...
  print(book.pages);
}
