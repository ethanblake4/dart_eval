import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:dart_eval/src/eval/bindgen/bindgen.dart';
import 'package:dart_eval/src/eval/bindgen/config.dart';
import 'package:dart_eval/src/eval/bindgen/errors.dart';
import 'package:test/test.dart';

const _widgetYaml = '''
version: 1
defaults:
  mode: wrap
libraries:
  - uri: package:bindcfg/widget.dart
    hooks: widget_hooks.dart
    classes:
      Widget:
        include: true
        constructors:
          "":
            permissions:
              - name: math.scale
                paramData: count
        excludeMembers: [describe]
        methods:
          scale:
            rename: scaled
            permissions:
              - name: math.scale
                paramData: factor
            returns:
              dependsOn:
                index: 0
                cases:
                  int: int
                  double: double
                fallback: num
        getters:
          size:
            hook: widgetSize
        statics:
          zero:
            expr: '\$Widget.wrap(Widget.zero())'
            permissions:
              - name: math.scale
                constData: static
        synthetic:
          - kind: method
            name: bump
            returns: int
            hook: widgetBump
          - kind: getter
            name: tripleSize
            expr: '\$int(\$value.size * 3)'
    functions:
      makeWidget:
        include: true
        hook: makeWidget
        permissions:
          - name: math.scale
            paramData: count
      ignored:
        include: false
''';

const _widgetSource = '''
class Widget {
  const Widget(this.count);
  final int count;
  int scale(num factor, [int extra = 0]) =>
      (count * factor).round() + extra;
  String describe() => 'widget-\$count';
  int get size => count;
  static Widget zero() => const Widget(0);
}
Widget makeWidget(int count) => Widget(count);
Widget ignored(int count) => Widget(count);
''';

void main() {
  group('BindgenConfig', () {
    test('parses YAML sidecar', () {
      final config = BindgenConfig.parse(_widgetYaml)..resolveDefaults();
      final lib = config.libraries.single;
      expect(lib.uri, 'package:bindcfg/widget.dart');
      expect(lib.hooks, 'widget_hooks.dart');
      expect(lib.defaults.mode, 'wrap');

      final widget = lib.classes['Widget']!;
      expect(widget.include, isTrue);
      expect(widget.excludeMembers, contains('describe'));

      final scale = widget.methods['scale']!;
      expect(scale.rename, 'scaled');
      expect(scale.permissions.single.name, 'math.scale');
      expect(scale.permissions.single.paramData, 'factor');
      final dep = scale.returns!.dependsOn!;
      expect(dep.index, 0);
      expect(dep.cases, {'int': 'int', 'double': 'double'});
      expect(dep.fallback, 'num');

      expect(widget.getters['size']!.hook, 'widgetSize');
      expect(widget.synthetic, hasLength(2));
      expect(widget.synthetic.first.name, 'bump');
      expect(lib.functions['makeWidget']!.hook, 'makeWidget');
      expect(lib.functions['ignored']!.include, isFalse);
    });

    test('unnamed constructor aliases do not configure named constructors', () {
      for (final name in ['', 'new']) {
        final config = BindgenConfig.parse(
          _widgetYaml.replaceFirst('"":', '"$name":'),
        )..resolveDefaults();
        final widget = config.libraries.single.classes['Widget']!;
        expect(widget.memberConfig('constructor', ''), isNotNull);
        expect(widget.memberConfig('constructor', 'new'), isNotNull);
        expect(widget.memberConfig('constructor', 'named'), isNull);
      }
    });
  });

  group('config-driven generation', () {
    test('applies shaping, hooks, permissions and synthetics', () async {
      final directory = Directory(
        'test',
      ).absolute.createTempSync('bindgen_config_');
      addTearDown(() => directory.deleteSync(recursive: true));
      final source = File(p.join(directory.path, 'widget.dart'))
        ..writeAsStringSync(_widgetSource);

      final config = BindgenConfig.parse(_widgetYaml)..resolveDefaults();
      final generated = (await Bindgen().parse(
        source,
        'widget.dart',
        'package:bindcfg/widget.dart',
        false,
        config: config,
        libraryConfig: config.libraries.single,
      ))!;

      // hooks file import
      expect(generated, contains("import 'widget_hooks.dart' as hooks;"));

      // member rename applies to declaration and dispatch
      expect(generated, contains("'scaled': BridgeMethodDef"));
      expect(generated, isNot(contains("'scale'")));

      // excluded member absent
      expect(generated, isNot(contains('describe')));

      // permission assertion with param data
      expect(
        generated,
        contains(
          "runtime.assertPermission('math.scale', Runtime.permissionData(",
        ),
      );

      // parameter-dependent return type emitted into the declaration
      expect(
        generated,
        contains('returnTypeDependency: BridgeReturnTypeDependency('),
      );
      expect(generated, contains('paramIndex: 0'));

      // getter hook delegation
      expect(generated, contains('hooks.widgetSize(runtime, this)'));

      // synthetic method declaration + hooked body
      expect(generated, contains("'bump': BridgeMethodDef"));
      expect(generated, contains('hooks.widgetBump(runtime, target, r, s, c)'));

      // synthetic getter dispatch + expr
      expect(generated, contains("case 'tripleSize':"));

      // top-level function hook and include filtering
      expect(
        generated,
        contains('hooks.makeWidget(runtime, null, [r as \$Value?])'),
      );
      expect(generated, isNot(contains('\$ignoredFn')));

      // generated code uses the register ABI for bridge functions
      expect(generated, contains('registerBridgeFuncRegisters'));
      expect(generated, contains('callRegisters'));
    });

    test('rejects invalid permission parameter references', () async {
      final directory = Directory(
        'test',
      ).absolute.createTempSync('bindgen_perm_invalid_');
      addTearDown(() => directory.deleteSync(recursive: true));
      final source = File(p.join(directory.path, 'widget.dart'))
        ..writeAsStringSync(_widgetSource);
      for (final invalid in ['missing', 'factor..path']) {
        final config = BindgenConfig.parse(
          _widgetYaml.replaceFirst('paramData: factor', 'paramData: $invalid'),
        )..resolveDefaults();
        expect(
          () => Bindgen().parse(
            source,
            'widget.dart',
            'package:bindcfg/widget.dart',
            false,
            config: config,
            libraryConfig: config.libraries.single,
          ),
          throwsA(isA<BindingGenerationError>()),
        );
      }
    });

    test('receiver permission reads the typed host instance', () async {
      final directory = Directory(
        'test',
      ).absolute.createTempSync('bindgen_receiver_');
      addTearDown(() => directory.deleteSync(recursive: true));
      final source = File(p.join(directory.path, 'widget.dart'))
        ..writeAsStringSync(_widgetSource);
      final config = BindgenConfig.parse(
        _widgetYaml.replaceFirst('paramData: factor', 'receiverData: count'),
      )..resolveDefaults();
      expect(
        config
            .libraries
            .single
            .classes['Widget']!
            .methods['scale']!
            .permissions
            .single
            .receiverData,
        'count',
      );
      final generated = (await Bindgen().parse(
        source,
        'widget.dart',
        'package:bindcfg/widget.dart',
        false,
        config: config,
        libraryConfig: config.libraries.single,
      ))!;
      expect(
        generated,
        contains(
          r"runtime.assertPermission('math.scale', (target! as $Widget).$value.count);",
        ),
      );
    });

    test('rejects malformed or unavailable receiver permission data', () async {
      final directory = Directory(
        'test',
      ).absolute.createTempSync('bindgen_receiver_invalid_');
      addTearDown(() => directory.deleteSync(recursive: true));
      final source = File(p.join(directory.path, 'widget.dart'))
        ..writeAsStringSync(_widgetSource);
      final invalidConfigs = [
        for (final path in ['', 'count..path', 'count()'])
          _widgetYaml.replaceFirst(
            'paramData: factor',
            'receiverData: "$path"',
          ),
        _widgetYaml.replaceFirst('paramData: count', 'receiverData: count'),
        _widgetYaml.replaceFirst('constData: static', 'receiverData: count'),
        _widgetYaml.replaceFirst(
          'paramData: factor',
          'paramData: factor\n                receiverData: count',
        ),
      ];
      for (final yaml in invalidConfigs) {
        final config = BindgenConfig.parse(yaml)..resolveDefaults();
        expect(
          () => Bindgen().parse(
            source,
            'widget.dart',
            'package:bindcfg/widget.dart',
            false,
            config: config,
            libraryConfig: config.libraries.single,
          ),
          throwsA(isA<BindingGenerationError>()),
        );
      }
    });

    test('unnamed constructor permission accepts the empty YAML key', () async {
      final directory = Directory(
        'test',
      ).absolute.createTempSync('bindgen_perm_ctor_');
      addTearDown(() => directory.deleteSync(recursive: true));
      final source = File(p.join(directory.path, 'api.dart'))
        ..writeAsStringSync('class Api { Api(String url); }');
      final config = BindgenConfig.parse('''
libraries:
  - uri: package:bindcfg/api.dart
    classes:
      Api:
        constructors:
          "":
            permissions:
              - name: network
                paramData: url
''')..resolveDefaults();
      final generated = (await Bindgen().parse(
        source,
        'api.dart',
        'package:bindcfg/api.dart',
        false,
        config: config,
        libraryConfig: config.libraries.single,
      ))!;
      expect(
        generated,
        contains("runtime.assertPermission('network', Runtime.permissionData("),
      );
    });

    test('generated bindings run hooks and permissions', () async {
      final directory = Directory(
        'test',
      ).absolute.createTempSync('bindgen_config_rt_');
      addTearDown(() => directory.deleteSync(recursive: true));
      final source = File(p.join(directory.path, 'widget.dart'))
        ..writeAsStringSync(_widgetSource);
      File(p.join(directory.path, 'widget_hooks.dart')).writeAsStringSync(r'''
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'widget.dart';
import 'widget.eval.dart';

$Value? widgetSize(Runtime runtime, $Value? target) =>
    $int((target!.$value as Widget).size + 1);

$Value? widgetBump(
  Runtime runtime,
  $Value? target,
  Object? r,
  Object? s,
  Object? c,
) => $int((target!.$value as Widget).count + 10);

$Value? makeWidget(Runtime runtime, $Value? target, List<$Value?> args) =>
    $Widget.wrap(Widget(99));
''');

      final config = BindgenConfig.parse(_widgetYaml)..resolveDefaults();
      final generated = (await Bindgen().parse(
        source,
        'widget.dart',
        'package:bindcfg/widget.dart',
        false,
        config: config,
        libraryConfig: config.libraries.single,
      ))!;

      File(p.join(directory.path, 'widget.eval.dart')).writeAsStringSync('''
import 'widget.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
$generated
''');

      File(p.join(directory.path, 'run.dart')).writeAsStringSync(r'''
import 'widget.dart';
import 'widget.eval.dart';
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:dart_eval/src/eval/runtime/security/permission.dart';
class AllowScale implements Permission {
  @override List<String> get domains => const ['math.scale'];
  @override bool match([Object? data]) => true;
}
void check(bool condition) { if (!condition) throw StateError('Bridge assertion failed'); }
void main() {
  final runtime = Runtime.ofProgram(Compiler().compile({'main': {'main.dart': 'int main() => 0;'}}));
  $Widget.configureForRuntime(runtime);
  $makeWidgetFn.configureForRuntime(runtime);

  // Unnamed constructor and hook-backed function both enforce permissions.
  var constructorDenied = false;
  try { $Widget.$new(runtime, $int(4), null, null); } catch (_) { constructorDenied = true; }
  check(constructorDenied);
  var functionDenied = false;
  try { $makeWidgetFn.callRegisters(runtime, $int(1), null, null); } catch (_) { functionDenied = true; }
  check(functionDenied);
  var staticDenied = false;
  try { $Widget.$zero(runtime, null, null, null); } catch (_) { staticDenied = true; }
  check(staticDenied);
  final w = $Widget.wrap(const Widget(4));

  // renamed + permission-asserted method
  var denied = false;
  try {
    (w.$getProperty(runtime, 'scaled') as EvalCallable)
        .call(runtime, w, $int(3), $int(0), 2);
  } catch (_) {
    denied = true;
  }
  check(denied);

  runtime.grant(AllowScale());
  final created = $Widget.$new(runtime, $int(4), null, null)! as $Widget;
  check(created.$value.count == 4);
  final zero = $Widget.$zero(runtime, null, null, null)! as $Widget;
  check(zero.$value.count == 0);
  final scaled = (w.$getProperty(runtime, 'scaled') as EvalCallable)
      .call(runtime, w, $int(3), $int(0), 2)!;
  check(scaled.$value == 12);

  // hooked getter
  final size = w.$getProperty(runtime, 'size')!;
  check(size.$value == 5);

  // synthetic hooked method + synthetic expr getter
  final bump = (w.$getProperty(runtime, 'bump') as EvalCallable)
      .call(runtime, w, null, null, 0)!;
  check(bump.$value == 14);
  final triple = w.$getProperty(runtime, 'tripleSize')!;
  check(triple.$value == 12);

  // hooked top-level function
  final made = $makeWidgetFn.callRegisters(runtime, $int(1), null, null)!;
  check(made is $Widget && made.$value.count == 99);
}
''');
      final result = await Process.run(Platform.resolvedExecutable, [
        'run',
        p.join(directory.path, 'run.dart'),
      ]);
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}
