import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/bridge/declaration/class.dart';
import 'package:dart_eval/src/eval/bridge/declaration/type.dart';

class X {
  const X(this.q);

  final int q;

  int doThing() {
    return q + q;
  }
}

void main(List<String> args) {
  final source = '''
    Function r() {
      return () {
        return 2;
      };
    }
    
    int main () {
      return r()();
    }
    
    /*
    int main() {
      final target = ['index', 'sequence'];
      final targetTypes = [{1,3,6,9}, {5,4,0}];
      final call = ['prop', 'index'];
    
      var i = 0;
      var j = 0;
      var cl = call.length;
      var tl = target.length - 1;
    
      while(j < cl) {
        if (i > tl) {
          return 4;
        }
        if (target[i] == call[j]) {
          j++;
        }
        i++;
      }
      return 7;
    }*/
    
    /*int main () {
      return fib(1);
    }
    
    int fib(int n) {
      if (n <= 1) return 1;
      return fib(n - 1) + fib(n - 2);
    }*/
  ''';
  final timestamp = DateTime.now().millisecondsSinceEpoch;

  final result = eval(source);
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
