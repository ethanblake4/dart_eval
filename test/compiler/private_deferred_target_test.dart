import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/invocation/deferred.dart';
import 'package:dart_eval/src/eval/compiler/member/member_name.dart';
import 'package:test/test.dart';

void main() {
  test(
    'private direct targets preserve origin and prefer qualified entries',
    () {
      final ctx = CompilerContext()
        ..libraryMap = {'package:own/main.dart': 0}
        ..instanceDeclarationPositions = {
          0: {
            'Host': {
              MemberKind.getter: {'_value': 1},
              MemberKind.setter: {
                'package:own/main.dart::_value': 2,
                'package:foreign/mixin.dart::_value': 3,
              },
            },
          },
        };
      int? resolve(String name, [MemberKind? kind]) => DeferredOrOffset(
        file: 0,
        className: 'Host',
        name: name,
        methodType: kind,
      ).resolveFunctionId(ctx);

      expect(resolve('package:own/main.dart::_value', MemberKind.getter), 1);
      expect(resolve('package:own/main.dart::_value'), 2);
      expect(
        resolve('package:foreign/mixin.dart::_value', MemberKind.setter),
        3,
      );
      expect(
        resolve('package:foreign/mixin.dart::_value', MemberKind.getter),
        null,
      );
      expect(resolve('package:unknown/main.dart::_value'), null);
    },
  );
}
