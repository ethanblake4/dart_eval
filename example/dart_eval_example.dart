import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';

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
      final m = {'h': 'wow', 'b': 'oh!'};
      future.then((dynamic _) {
        print('This message will print 2 seconds later');
      });
      func(m['b']).then((dynamic _) {
        print('did suspend');
      });
      print('This message will print immediately');
    }
    
    Future func(String str) async {
      await Future.delayed(Duration(seconds: 1));
      print(str);
      print(await l());
    }
    
    Future l() async {
      await Future.delayed(Duration(milliseconds: 400));
      return "K";
    }
  ''';

  eval(source, args: [
    $Future.wrap(Future.delayed(const Duration(seconds: 2)), (_) => $null())
  ]);
}

class $X extends X with $Bridge {
  const $X(int q) : super(q);

  $X._construct(List<Object?> args) : this(args[0] as int);

  static const $type =
      BridgeClassTypeDeclaration('package:flutter/src/main.dart', 'X');

  static const BridgeClassDeclaration $classDef = BridgeClassDeclaration(
      BridgeTypeReference.unresolved(
          BridgeUnresolvedTypeReference('package:flutter/src/main.dart', 'X'),
          []),
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
