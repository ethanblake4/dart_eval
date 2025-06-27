import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  group('Static access tests', () {
    late Compiler compiler;

    setUp(() {
      compiler = Compiler();
    });

    test('fromString deve retornar valores corretos para chaves válidas', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            enum MyEnum {
              bug,
              suggestion,
              code,
            }

            class MyEnumHelper {
              static MyEnum? fromString(
                String? value,
              ) {
                return map[value];
              }

              static Map<String, MyEnum> get map => {
                    "1731511068440": MyEnum.bug,
                    "1731511077738": MyEnum.suggestion,
                    "1739906454585": MyEnum.code,
                  };
            }
            
            void main() {
              var bug = MyEnumHelper.fromString("1731511068440");
              var suggestion = MyEnumHelper.fromString("1731511077738");
              var code = MyEnumHelper.fromString("1739906454585");
              
              print(bug == MyEnum.bug);
              print(suggestion == MyEnum.suggestion);
              print(code == MyEnum.code);
            }
          '''
        }
      });

      expect(() => runtime.executeLib('package:example/main.dart', 'main'),
          prints('true\ntrue\ntrue\n'));
    });

    test('fromString deve retornar null para chaves inválidas', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            enum MyEnum {
              bug,
              suggestion,
              code,
            }

            class MyEnumHelper {
              static MyEnum? fromString(
                String? value,
              ) {
                return map[value];
              }

              static Map<String, MyEnum> get map => {
                    "1731511068440": MyEnum.bug,
                    "1731511077738": MyEnum.suggestion,
                    "1739906454585": MyEnum.code,
                  };
            }
            
            void main() {
              var inexistente = MyEnumHelper.fromString("chave_inexistente");
              var vazio = MyEnumHelper.fromString("");
              var nulo = MyEnumHelper.fromString(null);
              
              print(inexistente == null);
              print(vazio == null);
              print(nulo == null);
            }
          '''
        }
      });

      expect(() => runtime.executeLib('package:example/main.dart', 'main'),
          prints('true\ntrue\ntrue\n'));
    });

    test('Map deve conter todas as chaves esperadas', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            enum MyEnum {
              bug,
              suggestion,
              code,
            }

            class MyEnumHelper {
              static Map<String, MyEnum> get map => {
                    "1731511068440": MyEnum.bug,
                    "1731511077738": MyEnum.suggestion,
                    "1739906454585": MyEnum.code,
                  };
            }
            
            int main() {
              var mapa = MyEnumHelper.map;
              return mapa.length;
            }
          '''
        }
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), 3);
    });
  });
}
