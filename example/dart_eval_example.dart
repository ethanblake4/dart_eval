import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/bridge/declaration/class.dart';
import 'package:dart_eval/src/eval/bridge/declaration/type.dart';
import 'package:dart_eval/src/eval/runtime/stdlib/core/future.dart';

class X {
  const X(this.q);

  final int q;

  int doThing() {
    return q + q;
  }
}

void main(List<String> args) {
  final source = '''
    void main (Future future) {
      future.then((dynamic _) {
        print('This message will print 2 seconds later');
      });
      print('This message will print immediately');
    }
  ''';
  final timestamp = DateTime.now().millisecondsSinceEpoch;

  final result = eval(source, args: [$Future.wrap(Future.delayed(const Duration(seconds: 2)), (_) => $null())]);

  print('Output: $result');
  print('Execution time: ${DateTime.now().millisecondsSinceEpoch - timestamp} ms');
}

class $X extends X with $Bridge {
  const $X(int q) : super(q);

  $X._construct(List<Object?> args) : this(args[0] as int);

  static const $type = BridgeClassTypeDeclaration('package:flutter/src/main.dart', 'X');

  static const BridgeClassDeclaration $classDef = BridgeClassDeclaration(
      BridgeTypeReference.unresolved(BridgeUnresolvedTypeReference('package:flutter/src/main.dart', 'X'), []),
      isAbstract: false,
      constructors: {},
      methods: {},
      getters: {},
      setters: {},
      fields: {});

  @override
  $Value? $bridgeGet(String identifier) {
    switch (identifier) {
      case 'q':
        return $int(super.q);
      case 'doThing':
        return $Function((runtime, target, args) => $int(super.doThing()));
    }
    throw UnimplementedError();
  }

  @override
  void $bridgeSet(String identifier, $Value value) {
    throw UnimplementedError();
  }

  @override
  int get q => $_get('q');

  @override
  int doThing() => $_invoke('doThing', []);

  @override
  int get $runtimeType => throw UnimplementedError();
}
