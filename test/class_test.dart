import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

void main() {
  group('Class tests', () {
    late Compiler compiler;

    setUp(() {
      compiler = Compiler();
    });

    test('Default constructor, basic method', () {
      final runtime = compiler.compileWriteAndLoad({
        'dbc_test': {
          'main.dart': '''
            class MyClass {
              MyClass();
              
              int someMethod() {
                return 4 + 4;
              }
            }
            int main() {
              final cls = MyClass();
              return cls.someMethod() + 2;
            }
          '''
        }
      });

      expect(runtime.executeLib('package:dbc_test/main.dart', 'main'), 10);
    });

    test('Field formal parameters, external field access', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            import 'package:example/x.dart';
            num main() {
              var i = Vib(z: 5);
              var m = Vib();
              return i.z + m.z + i.h();
            }
          ''',
          'x.dart': '''
            class Vib {
              Vib({this.z = 3});
              
              int z;
              
              int h() {
                return 11;
              }
            }
          '''
        }
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), $int(19));
    });

    test('Trying to access nonexistent method throws error', () {
      final packages = {
        'example': {
          'main.dart': '''
            class MyClass {
              MyClass();
              
              int someMethod() {
                return 4 + 4;
              }
            }
            int main() {
              final cls = MyClass();
              return cls.someMethod() + cls.someOtherMethod();
            }
          '''
        }
      };

      expect(() => compiler.compileWriteAndLoad(packages),
          throwsA(isA<CompileError>()));
      expect(() => compiler.compileWriteAndLoad(packages),
          throwsA(predicate((CompileError e) {
        return e.toString().contains('someOtherMethod') &&
            e.toString().contains('file package:example/main.dart');
      })));
    });

    test('"this" keyword', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main () {
              return M(2).load();
            }
            
            class M {
              M(this.number);
              final int number;
              
              int load() {
                return this._loadInternal(4);
              }
              
              _loadInternal(int times) {
                return this.number * times;
              }
            }
          '''
        }
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), 8);
    });

    test('Implicit and "this" field access from closure', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main () {
              return M(2).load();
            }
                    
            class M {
              M(this.number);
              int number;
              
              int load() {
                return this._loadInternal(4);
              }
              
              _loadInternal(int times) {
                final f = (t) {
                  number++;
                  return this.number * t;
                };
                return f(times);
              }
            }
          '''
        }
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), 12);
    });

    test('Simple static method', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main () {
              return M.getNum(4) + 2;
            }
            
            class M {
              static int getNum(int b) {
                return 12 - b;
              }
            }
          '''
        }
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), 10);
    });

    test('Implicit static method scoping', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
          int main () {
            return M(4).load();
          }
          
          class M {
            M(this.x);
            
            final int x;
            
            static int getNum(int b) {
              return 12 - b;
            }
            
            int load() {
              return getNum(5 + x);
            }
          }
          '''
        }
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), 3);
    });

    test('"new" keyword', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main () {
              return new M(4).load();
            }
            
            class M {
              M(this.x);
              
              final int x;
              
              int load() {
                return 5 + x;
              }
            }
            
          '''
        }
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), 9);
    });

    test('Getters and setters', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main () {
              final m = M();
              m.x = 5;
              return m.x + 1;
            }
            
            class M {
              int _x = 0;
              
              int get x => _x;
              set x(int value) => _x = value;
            }
            
          '''
        }
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), 6);
    });

    test('New-style super constructor parameters', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main () {
              final c = OldCat('Julian');
              return c.age + c.name.length;
            }
            
            class Cat {
              Cat(this.name, {required this.age});
              final String name;
              final int age;
            }

            class OldCat extends Cat {
              OldCat(super.name) : super(age: 10);
            }
          '''
        }
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), 16);
    });

    test('Accessing list element from instance method', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main () {
              final c = Cat();
              return c.load();
            }
            
            class Cat {
              final _list = [1, 2, 3];
              List<int> _list2 = [4, 5, 6];
              
              int load() {
                return _list[1] + _list2[1];
              }
            }
          '''
        }
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), 7);
    });

    test('Method call on field with inferred type from closure', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            String main () {
              final c = Cat();
              c.load()();
              return c.list[3];
            }
            
            class Cat {
              final list = ['a', 'b', 'c'];
              
              Function load() {
                return () {
                  list.add('d');
                };
              }
            }
          '''
        }
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'),
          $String('d'));
    });

    test('Accessing methods and fields on super', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            class Animal {
              Animal(this.name);
              final String name;
              
              String getLabel() {
                return name + ' the animal';
              }
            }

            class Cat extends Animal {
              Cat(String name) : super(name);
              
              String getLabel() {
                return super.getLabel() + ' (cat)';
              }
            }

            String main () {
              final c = Cat('Julian');
              return c.getLabel();
            }
          '''
        }
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'),
          $String('Julian the animal (cat)'));
    });

    test('Constructor field initializers', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            void main() {
              var x = X("Hi");
              x.printValues();
            }

            class X {
              X(String s) : _a = 1, this._b = s + "!";
              final int _a;
              final String _b;
              void printValues() => print(_a + _b.length);
            }
          '''
        }
      });

      expect(() {
        runtime.executeLib('package:example/main.dart', 'main');
      }, prints('4\n'));
    });

    test('Factory constructor', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            void main() {
              var x = X("Hi");
              x.printValues();
            }

            class X {
              factory X(String s) {
                return X._(s + "!");
              }
              X._(this._b) : _a = 1;
              final int _a;
              final String _b;
              void printValues() => print(_a + _b.length);
            }
          '''
        }
      });

      expect(() {
        runtime.executeLib('package:example/main.dart', 'main');
      }, prints('4\n'));
    });

    test('runtimeType', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            void main() {
              var x = X();
              var x2 = X();

              print(x.runtimeType == x2.runtimeType);
              print(x.runtimeType == 1.runtimeType);
              print(1.runtimeType == 2.runtimeType);
            }

            class X {
              X();
            }
          '''
        }
      });

      expect(() {
        runtime.executeLib('package:example/main.dart', 'main');
      }, prints('true\nfalse\ntrue\n'));
    });

    test('Modifying static class field', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            class TestA {
              static int value = 11;
            }      
      
            int main() {
              TestA.value = 22;
              return TestA.value;
            }
          '''
        }
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), 22);
    });

    test('Modifying field value in constructor block', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            class TestA {
              int value = 11;
              TestA() {
                value = 22;
                this.value++;
              }
            }      
      
            int main() {
              var a = TestA();
              return a.value;
            }
          '''
        }
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), 23);
    });

    test('Simple redirecting constructor', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            class TestA {
              int value;
              int value2;
              TestA(int b) : this._(11, b);
              TestA._(this.value, this.value2);
            }      
      
            int main() {
              var a = TestA(4);
              return a.value + a.value2;
            }
          '''
        }
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), 15);
    });

    test('Nullable static value', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
              class TestA {
                static int? value;
              }      
        
              int? main() {
                TestA.value = 22;
                return TestA.value;
              }
        '''
        }
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), $int(22));
    });

    test('Using set value', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            class TestClass {
              int tempValue = 0;
            }  
         
            bool main() {
              final testClass = TestClass();
              testClass.tempValue = testClass.hashCode;
              print('hashCode \${testClass.tempValue}');
              return true;
            }
          '''
        }
      });

      expect(() {
        runtime.executeLib('package:example/main.dart', 'main');
      }, prints(startsWith('hashCode ')));
    });

/*    test('Super parameter multi-level indirection', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            abstract class BaseRequest {
              BaseRequest(String method, this.url)
                : this._method = method;
              String _method;
              String get method => _method;
              final Uri url;
            }

            class Request extends BaseRequest {
              Request(super.method, super.url);
            }

            void main() {
              var r = Request("GET", Uri.parse("http://example.com"));
              print(r.method);
              print(r.url);
            }
          '''
        }
      });

      expect(() {
        runtime.executeLib('package:example/main.dart', 'main');
      }, prints('GET\nhttp://example.com\n'));
    });*/

    test('Generic class with type parameter field', () {
      final runtime = compiler.compileWriteAndLoad({
        'generic_test': {
          'main.dart': '''
            class OrderItenModel {
              String name;
              OrderItenModel({required this.name});
            }
            
            class OrderModel extends OrderItenModel {
              OrderModel({required String name}) : super(name: name);
            }
            
            class BudgetModel extends OrderItenModel {
              BudgetModel({required String name}) : super(name: name);
            }
            
            class CustomOrderItenModel<T extends OrderItenModel> {
              final T model;
              
              CustomOrderItenModel({
                required this.model,
              });
              
              String getModelName() {
                return model.name;
              }
            }
            
            class CustomOrderModel extends CustomOrderItenModel<OrderModel> {
              CustomOrderModel({
                required OrderModel model,
              }) : super(
                      model: model,
                    );
            }
            
            class CustomBudgetModel extends CustomOrderItenModel<BudgetModel> {
              CustomBudgetModel({
                required BudgetModel model,
              }) : super(
                      model: model,
                    );
            }
            
            String main() {
              final orderModel = OrderModel(name: 'Test Order');
              final customOrder = CustomOrderModel(model: orderModel);
              
              final budgetModel = BudgetModel(name: 'Test Budget');
              final customBudget = CustomBudgetModel(model: budgetModel);
              
              return customOrder.getModelName() + '|' + customBudget.getModelName();
            }
          '''
        }
      });

      final result =
          runtime.executeLib('package:generic_test/main.dart', 'main');
      expect(result.toString(), '\$"Test Order|Test Budget"');
    });

    test('Generic class with field formal parameters', () {
      final runtime = compiler.compileWriteAndLoad({
        'generic_test': {
          'main.dart': '''
            class OrderItenModel {
              String name;
              OrderItenModel({required this.name});
            }
            
            class OrderModel extends OrderItenModel {
              OrderModel({required String name}) : super(name: name);
            }
            
            class BudgetModel extends OrderItenModel {
              BudgetModel({required String name}) : super(name: name);
            }
            
            class CustomOrderItenModel<T extends OrderItenModel> {
              final T model;
              
              CustomOrderItenModel({
                required this.model,
              });
              
              String getModelName() {
                return model.name;
              }
            }
            
            class CustomOrderModel extends CustomOrderItenModel<OrderModel> {
              CustomOrderModel({
                required OrderModel model,
              }) : super(
                      model: model,
                    );
            }
            
            class CustomBudgetModel extends CustomOrderItenModel<BudgetModel> {
              CustomBudgetModel({
                required BudgetModel model,
              }) : super(
                      model: model,
                    );
            }
            
            String main() {
              final orderModel = OrderModel(name: 'Test Order');
              final customOrder = CustomOrderModel(model: orderModel);
              
              final budgetModel = BudgetModel(name: 'Test Budget');
              final customBudget = CustomBudgetModel(model: budgetModel);
              
              return customOrder.getModelName() + '|' + customBudget.getModelName();
            }
          '''
        }
      });

      final result =
          runtime.executeLib('package:generic_test/main.dart', 'main');
      expect(result.toString(), '\$"Test Order|Test Budget"');
    });

    test('Generic class with multiple type parameters and bounds', () {
      final runtime = compiler.compileWriteAndLoad({
        'generic_test': {
          'main.dart': '''
            class BaseModel {
              String id;
              BaseModel({required this.id});
            }
            
            class CustomContainer<T extends BaseModel, U extends BaseModel> {
              final T first;
              final U second;
              
              CustomContainer({
                required this.first,
                required this.second,
              });
              
              String getFirstId() {
                return first.id;
              }
              
              String getSecondId() {
                return second.id;
              }
            }
            
            String main() {
              final base1 = BaseModel(id: 'base123');
              final base2 = BaseModel(id: 'base456');
              final container = CustomContainer<BaseModel, BaseModel>(first: base1, second: base2);
              
              return container.getFirstId() + '|' + container.getSecondId();
            }
          '''
        }
      });

      final result =
          runtime.executeLib('package:generic_test/main.dart', 'main');
      expect(result.toString(), '\$"base123|base456"');
    });

    test('Generic class with field formal parameters - exact real scenario',
        () {
      final runtime = compiler.compileWriteAndLoad({
        'altforce_test': {
          'main.dart': '''
            class OrderItenModel {
              String name;
              OrderItenModel({required this.name});
            }
            
            class OrderModel extends OrderItenModel {
              OrderModel({required String name}) : super(name: name);
            }
            
            class CustomUserModel {
              String name;
              CustomUserModel({required this.name});
            }
            
            class CustomOrderItenModel<T extends OrderItenModel> {
              final T model;
              final CustomUserModel user;
              
              CustomOrderItenModel({
                required this.model,
                required this.user,
              });
            }
            
            class CustomOrderModel extends CustomOrderItenModel<OrderModel> {
              CustomOrderModel({
                required OrderModel model,
                required CustomUserModel user,
              }) : super(
                model: model,
                user: user,
              );
            }
            
            String main() {
              final order = OrderModel(name: "Test Order");
              final user = CustomUserModel(name: "Test User");
              
              final customOrder = CustomOrderModel(
                model: order,
                user: user,
              );
              
              return customOrder.model.name + "|" + customOrder.user.name;
            }
          ''',
        },
      });

      final result =
          runtime.executeLib('package:altforce_test/main.dart', 'main');
      expect(result.toString(), '\$"Test Order|Test User"');
    });

    test('Generic field access with type inference', () {
      final runtime = compiler.compileWriteAndLoad({
        'generic_test': {
          'main.dart': '''
            class OrderItenModel {
              String name;
              OrderItenModel({required this.name});
            }
            
            class BudgetModel extends OrderItenModel {
              double budget;
              BudgetModel({required String name, required this.budget}) : super(name: name);
            }
            
            class CustomOrderItenModel<T extends OrderItenModel> {
              final T model;
              
              CustomOrderItenModel({
                required this.model,
              });
            }
            
            String main() {
              final customBudget = CustomOrderItenModel<BudgetModel>(
                model: BudgetModel(name: "Test", budget: 100.0),
              );
              
              // Este é o problema - o compilador não está inferindo o tipo corretamente
              BudgetModel extractedModel = customBudget.model;
              
              return extractedModel.name;
            }
          ''',
        },
      });

      final result =
          runtime.executeLib('package:generic_test/main.dart', 'main');
      expect(result.toString(), '\$"Test"');
    });

    test('Generic field access debug', () {
      final runtime = compiler.compileWriteAndLoad({
        'generic_test': {
          'main.dart': '''
            class BaseModel {
              String name;
              BaseModel({required this.name});
            }
            
            class SpecificModel extends BaseModel {
              SpecificModel({required String name}) : super(name: name);
            }
            
            class Container<T extends BaseModel> {
              final T item;
              Container({required this.item});
            }
            
            String main() {
              final container = Container<SpecificModel>(
                item: SpecificModel(name: "Test"),
              );
              
              // Tentar acessar o item sem declarar uma variável tipada
              return container.item.name;
            }
          ''',
        },
      });

      final result =
          runtime.executeLib('package:generic_test/main.dart', 'main');
      expect(result.toString(), '\$"Test"');
    });

    test('Generic field access - direct vs typed assignment', () {
      final runtime = compiler.compileWriteAndLoad({
        'generic_test': {
          'main.dart': '''
            class BaseModel {
              String name;
              BaseModel({required this.name});
            }
            
            class SpecificModel extends BaseModel {
              SpecificModel({required String name}) : super(name: name);
            }
            
            class Container<T extends BaseModel> {
              final T item;
              Container({required this.item});
            }
            
            String main() {
              final container = Container<SpecificModel>(
                item: SpecificModel(name: "Test"),
              );
              
              // Acesso direto funciona
              final directAccess = container.item.name;
              
              // Atribuição a variável sem tipo específico também funciona
              final inferredType = container.item;
              
              return directAccess + "|" + inferredType.name;
            }
          ''',
        },
      });

      final result =
          runtime.executeLib('package:generic_test/main.dart', 'main');
      expect(result.toString(), '\$"Test|Test"');
    });

    test('Generic field access - typed assignment problem', () {
      final runtime = compiler.compileWriteAndLoad({
        'generic_test': {
          'main.dart': '''
            class BaseModel {
              String name;
              BaseModel({required this.name});
            }
            
            class SpecificModel extends BaseModel {
              SpecificModel({required String name}) : super(name: name);
            }
            
            class Container<T extends BaseModel> {
              final T item;
              Container({required this.item});
            }
            
            String main() {
              final container = Container<SpecificModel>(
                item: SpecificModel(name: "Test"),
              );
              
              // Aqui está o problema - atribuição tipada
              SpecificModel typedAssignment = container.item;
              
              return typedAssignment.name;
            }
          ''',
        },
      });

      final result =
          runtime.executeLib('package:generic_test/main.dart', 'main');
      expect(result.toString(), '\$"Test"');
    });

    test('Generic instance creation debug', () {
      final runtime = compiler.compileWriteAndLoad({
        'generic_test': {
          'main.dart': '''
            class BaseModel {
              String name;
              BaseModel({required this.name});
            }
            
            class SpecificModel extends BaseModel {
              SpecificModel({required String name}) : super(name: name);
            }
            
            class Container<T extends BaseModel> {
              final T item;
              Container({required this.item});
            }
            
            String main() {
              final container = Container<SpecificModel>(
                item: SpecificModel(name: "Test"),
              );
              
              // Verificar se o tipo está sendo inferido corretamente
              return container.item.runtimeType.toString();
            }
          ''',
        },
      });

      final result =
          runtime.executeLib('package:generic_test/main.dart', 'main');
      print('Result: $result');
      expect(result.toString(), contains('SpecificModel'));
    });

    test('Simple instance creation debug', () {
      final runtime = compiler.compileWriteAndLoad({
        'generic_test': {
          'main.dart': '''
            class Container<T> {
              final T item;
              Container({required this.item});
            }
            
            String main() {
              Container<String> container = Container<String>(item: "test");
              return container.item;
            }
          ''',
        },
      });

      final result =
          runtime.executeLib('package:generic_test/main.dart', 'main');
      print('Result: $result');
      expect(result.toString(), '\$"test"');
    });

    test('Simple positional args debug', () {
      final runtime = compiler.compileWriteAndLoad({
        'generic_test': {
          'main.dart': '''
            class Container<T> {
              final T item;
              Container(this.item);
            }
            
            String main() {
              Container<String> container = Container<String>("test");
              return container.item;
            }
          ''',
        },
      });

      final result =
          runtime.executeLib('package:generic_test/main.dart', 'main');
      print('Result: $result');
      expect(result.toString(), '\$"test"');
    });
  });

  group('Super constructor generic type resolution', () {
    test('Super constructor with generic inheritance chain', () {
      eval(r'''
        class OrderModel {
          String name;
          OrderModel(this.name);
        }
        
        class BudgetModel {
          String title;
          BudgetModel(this.title);
        }
        
        class BaseModel<T> {
          T model;
          BaseModel(this.model);
        }
        
        class CustomOrderItenModel<T> extends BaseModel<T> {
          CustomOrderItenModel(T model) : super(model);
        }
        
        class SpecificOrderModel extends CustomOrderItenModel<OrderModel> {
          SpecificOrderModel(OrderModel model) : super(model);
        }
        
        class SpecificBudgetModel extends CustomOrderItenModel<BudgetModel> {
          SpecificBudgetModel(BudgetModel model) : super(model);
        }
        
        void main() {
          final order = OrderModel("test order");
          final budget = BudgetModel("test budget");
          
          final specificOrder = SpecificOrderModel(order);
          final specificBudget = SpecificBudgetModel(budget);
          
          print("Order: ${specificOrder.model.name}");
          print("Budget: ${specificBudget.model.title}");
        }
      ''');
    });
  });

  group('Real world generic constructor problem', () {
    test('CustomOrderItenModel with OrderModel and BudgetModel', () {
      eval(r'''
        class OrderItenModel {
          String name;
          OrderItenModel(this.name);
        }
        
        class OrderModel extends OrderItenModel {
          OrderModel(String name) : super(name);
        }
        
        class BudgetModel extends OrderItenModel {
          BudgetModel(String name) : super(name);
        }
        
        class CustomOrderItenModel<T extends OrderItenModel> {
          final T model;
          final String user;
          final String state;
          final String city;
          final String? region;
          final String? dealer;
          final String? coordination;

          CustomOrderItenModel({
            required this.model,
            required this.user,
            required this.state,
            required this.city,
            this.region,
            this.dealer,
            this.coordination,
          });
        }
        
        class CustomOrderModel extends CustomOrderItenModel<OrderModel> {
          CustomOrderModel({
            required OrderModel model,
            required String user,
            required String state,
            required String city,
            String? region,
            String? dealer,
            String? coordination,
          }) : super(
                model: model,
                user: user,
                state: state,
                city: city,
                region: region,
                dealer: dealer,
                coordination: coordination,
              );
        }
        
        class CustomBudgetModel extends CustomOrderItenModel<BudgetModel> {
          CustomBudgetModel({
            required BudgetModel model,
            required String user,
            required String state,
            required String city,
            String? region,
            String? dealer,
            String? coordination,
          }) : super(
                model: model,
                user: user,
                state: state,
                city: city,
                region: region,
                dealer: dealer,
                coordination: coordination,
              );
        }
        
        void main() {
          final order = OrderModel("test order");
          final budget = BudgetModel("test budget");
          
          final customOrder = CustomOrderModel(
            model: order,
            user: "user1",
            state: "state1",
            city: "city1",
          );
          
          final customBudget = CustomBudgetModel(
            model: budget,
            user: "user2",
            state: "state2",
            city: "city2",
          );
          
          print("Order: ${customOrder.model.name}");
          print("Budget: ${customBudget.model.name}");
        }
      ''');
    });
  });
}
