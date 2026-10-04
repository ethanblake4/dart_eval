import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('explicit extensions retain unpromoted cast receiver types', () {
    final program = Compiler().compile({
      'cast_receiver': {
        'values.dart': '''
          import 'nodes.dart';
          import 'extensions.dart';
          mixin Values {
            int get text => NodeString(this as Node).text;
          }
        ''',
        'nodes.dart': '''
          import 'values.dart';
          class Node with Values {
            final int value;
            Node(this.value);
          }
          class Other with Values {}
        ''',
        'extensions.dart': '''
          import 'nodes.dart';
          extension NodeString on Node {
            int get text => value;
          }
        ''',
        'main.dart': '''
          import 'nodes.dart';
          import 'extensions.dart';
          int main() {
            final node = Node(7);
            if (node.text != 7) return -1;
            var wrongMixinThrew = false;
            try { Other().text; } on TypeError { wrongMixinThrew = true; }
            if (!wrongMixinThrew) return -2;
            Object captured = Node(8);
            void replace() { captured = Other(); }
            final first = NodeString(captured as Node).text;
            replace();
            var wrongLocalThrew = false;
            try {
              NodeString(captured as Node).text;
            } on TypeError { wrongLocalThrew = true; }
            if (!wrongLocalThrew) return -3;
            Object number = 5;
            void replaceNumber() { number = 6; }
            final scalar = number as int;
            replaceNumber();
            return node.text + first + scalar + (number as int);
          }
        ''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:cast_receiver/main.dart', 'main'), 26);
    }
  });
}
