import 'package:dart_eval/dart_eval_bridge.dart';
import 'dart:io';
import 'package:dart_eval/stdlib/core.dart';
import 'package:dart_eval/stdlib/async.dart';
import 'package:dart_eval/stdlib/io.dart';
import 'dart:core';

/// dart_eval wrapper binding for [ProcessInfo]
class $ProcessInfo implements $Instance {
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFunc(
        'dart:io', 'ProcessInfo.currentRss*g', $ProcessInfo.$currentRss);

    runtime.registerBridgeFunc(
        'dart:io', 'ProcessInfo.maxRss*g', $ProcessInfo.$maxRss);
  }

  /// Compile-time type specification of [$ProcessInfo]
  static const $spec = BridgeTypeSpec(
    'dart:io',
    'ProcessInfo',
  );

  /// Compile-time type declaration of [$ProcessInfo]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$ProcessInfo]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,
      isAbstract: true,
    ),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [],
        ),
        isFactory: false,
      ),
    },
    methods: {},
    getters: {
      'currentRss': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
          namedParams: [],
          params: [],
        ),
        isStatic: true,
      ),
      'maxRss': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
          namedParams: [],
          params: [],
        ),
        isStatic: true,
      ),
    },
    setters: {},
    fields: {},
    wrap: true,
  );

  /// Wrapper for the [ProcessInfo.currentRss] getter
  static $Value? $currentRss(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final value = ProcessInfo.currentRss;
    return $int(value);
  }

  /// Wrapper for the [ProcessInfo.maxRss] getter
  static $Value? $maxRss(Runtime runtime, $Value? target, List<$Value?> args) {
    final value = ProcessInfo.maxRss;
    return $int(value);
  }

  final $Instance _superclass;

  @override
  final ProcessInfo $value;

  @override
  ProcessInfo get $reified => $value;

  /// Wrap a [ProcessInfo] in a [$ProcessInfo]
  $ProcessInfo.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    return _superclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}

/// dart_eval wrapper binding for [ProcessStartMode]
class $ProcessStartMode implements $Instance {
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFunc(
        'dart:io', 'ProcessStartMode.normal*g', $ProcessStartMode.$normal);

    runtime.registerBridgeFunc('dart:io', 'ProcessStartMode.inheritStdio*g',
        $ProcessStartMode.$inheritStdio);

    runtime.registerBridgeFunc(
        'dart:io', 'ProcessStartMode.detached*g', $ProcessStartMode.$detached);

    runtime.registerBridgeFunc(
        'dart:io',
        'ProcessStartMode.detachedWithStdio*g',
        $ProcessStartMode.$detachedWithStdio);

    runtime.registerBridgeFunc(
        'dart:io', 'ProcessStartMode.values*g', $ProcessStartMode.$values);
  }

  /// Compile-time type specification of [$ProcessStartMode]
  static const $spec = BridgeTypeSpec(
    'dart:io',
    'ProcessStartMode',
  );

  /// Compile-time type declaration of [$ProcessStartMode]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$ProcessStartMode]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,
      isAbstract: false,
    ),
    constructors: {
      '_internal': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              '_mode',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
              false,
            ),
          ],
        ),
        isFactory: false,
      ),
    },
    methods: {
      'toString': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
          namedParams: [],
          params: [],
        ),
      ),
    },
    getters: {
      'values': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.list)),
          namedParams: [],
          params: [],
        ),
        isStatic: true,
      ),
    },
    setters: {},
    fields: {
      'normal': BridgeFieldDef(
        BridgeTypeAnnotation(
            BridgeTypeRef(BridgeTypeSpec('dart:io', 'ProcessStartMode'))),
        isStatic: true,
      ),
      'inheritStdio': BridgeFieldDef(
        BridgeTypeAnnotation(
            BridgeTypeRef(BridgeTypeSpec('dart:io', 'ProcessStartMode'))),
        isStatic: true,
      ),
      'detached': BridgeFieldDef(
        BridgeTypeAnnotation(
            BridgeTypeRef(BridgeTypeSpec('dart:io', 'ProcessStartMode'))),
        isStatic: true,
      ),
      'detachedWithStdio': BridgeFieldDef(
        BridgeTypeAnnotation(
            BridgeTypeRef(BridgeTypeSpec('dart:io', 'ProcessStartMode'))),
        isStatic: true,
      ),
      '_mode': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
        isStatic: false,
      ),
    },
    wrap: true,
  );

  /// Wrapper for the [ProcessStartMode.normal] getter
  static $Value? $normal(Runtime runtime, $Value? target, List<$Value?> args) {
    final value = ProcessStartMode.normal;
    return $ProcessStartMode.wrap(value);
  }

  /// Wrapper for the [ProcessStartMode.inheritStdio] getter
  static $Value? $inheritStdio(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final value = ProcessStartMode.inheritStdio;
    return $ProcessStartMode.wrap(value);
  }

  /// Wrapper for the [ProcessStartMode.detached] getter
  static $Value? $detached(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final value = ProcessStartMode.detached;
    return $ProcessStartMode.wrap(value);
  }

  /// Wrapper for the [ProcessStartMode.detachedWithStdio] getter
  static $Value? $detachedWithStdio(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final value = ProcessStartMode.detachedWithStdio;
    return $ProcessStartMode.wrap(value);
  }

  /// Wrapper for the [ProcessStartMode.values] getter
  static $Value? $values(Runtime runtime, $Value? target, List<$Value?> args) {
    final value = ProcessStartMode.values;
    return $List.view(value, (e) => $ProcessStartMode.wrap(e));
  }

  final $Instance _superclass;

  @override
  final ProcessStartMode $value;

  @override
  ProcessStartMode get $reified => $value;

  /// Wrap a [ProcessStartMode] in a [$ProcessStartMode]
  $ProcessStartMode.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'toString':
        return __toString;
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __toString = $Function(_toString);
  static $Value? _toString(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target as $ProcessStartMode;
    final result = self.$value.toString();
    return $String(result);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}

/// dart_eval wrapper binding for [Process]
class $Process implements $Instance {
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFunc('dart:io', 'Process.start', $Process.$start);

    runtime.registerBridgeFunc('dart:io', 'Process.run', $Process.$run);

    runtime.registerBridgeFunc('dart:io', 'Process.runSync', $Process.$runSync);

    runtime.registerBridgeFunc('dart:io', 'Process.killPid', $Process.$killPid);
  }

  /// Compile-time type specification of [$Process]
  static const $spec = BridgeTypeSpec(
    'dart:io',
    'Process',
  );

  /// Compile-time type declaration of [$Process]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$Process]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,
      isAbstract: true,
    ),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [],
        ),
        isFactory: false,
      ),
    },
    methods: {
      'start': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future)),
          namedParams: [
            BridgeParameter(
              'workingDirectory',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string),
                  nullable: true),
              true,
            ),
            BridgeParameter(
              'environment',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.map),
                  nullable: true),
              true,
            ),
            BridgeParameter(
              'includeParentEnvironment',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
              true,
            ),
            BridgeParameter(
              'runInShell',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
              true,
            ),
            BridgeParameter(
              'mode',
              BridgeTypeAnnotation(
                  BridgeTypeRef(BridgeTypeSpec('dart:io', 'ProcessStartMode'))),
              true,
            ),
          ],
          params: [
            BridgeParameter(
              'executable',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
              false,
            ),
            BridgeParameter(
              'arguments',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.list)),
              false,
            ),
          ],
        ),
        isStatic: true,
      ),
      'run': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future)),
          namedParams: [
            BridgeParameter(
              'workingDirectory',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string),
                  nullable: true),
              true,
            ),
            BridgeParameter(
              'environment',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.map),
                  nullable: true),
              true,
            ),
            BridgeParameter(
              'includeParentEnvironment',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
              true,
            ),
            BridgeParameter(
              'runInShell',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
              true,
            ),
            BridgeParameter(
              'stdoutEncoding',
              BridgeTypeAnnotation(BridgeTypeRef(ConvertTypes.encoding),
                  nullable: true),
              true,
            ),
            BridgeParameter(
              'stderrEncoding',
              BridgeTypeAnnotation(BridgeTypeRef(ConvertTypes.encoding),
                  nullable: true),
              true,
            ),
          ],
          params: [
            BridgeParameter(
              'executable',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
              false,
            ),
            BridgeParameter(
              'arguments',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.list)),
              false,
            ),
          ],
        ),
        isStatic: true,
      ),
      'runSync': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(BridgeTypeSpec(
              'package:debug_test/process.dart', 'ProcessResult'))),
          namedParams: [
            BridgeParameter(
              'workingDirectory',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string),
                  nullable: true),
              true,
            ),
            BridgeParameter(
              'environment',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.map),
                  nullable: true),
              true,
            ),
            BridgeParameter(
              'includeParentEnvironment',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
              true,
            ),
            BridgeParameter(
              'runInShell',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
              true,
            ),
            BridgeParameter(
              'stdoutEncoding',
              BridgeTypeAnnotation(BridgeTypeRef(ConvertTypes.encoding),
                  nullable: true),
              true,
            ),
            BridgeParameter(
              'stderrEncoding',
              BridgeTypeAnnotation(BridgeTypeRef(ConvertTypes.encoding),
                  nullable: true),
              true,
            ),
          ],
          params: [
            BridgeParameter(
              'executable',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
              false,
            ),
            BridgeParameter(
              'arguments',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.list)),
              false,
            ),
          ],
        ),
        isStatic: true,
      ),
      'killPid': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
          namedParams: [],
          params: [
            BridgeParameter(
              'pid',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
              false,
            ),
            BridgeParameter(
              'signal',
              BridgeTypeAnnotation(BridgeTypeRef(BridgeTypeSpec(
                  'package:debug_test/process.dart', 'ProcessSignal'))),
              true,
            ),
          ],
        ),
        isStatic: true,
      ),
      'kill': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
          namedParams: [],
          params: [
            BridgeParameter(
              'signal',
              BridgeTypeAnnotation(BridgeTypeRef(BridgeTypeSpec(
                  'package:debug_test/process.dart', 'ProcessSignal'))),
              true,
            ),
          ],
        ),
      ),
    },
    getters: {
      'exitCode': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future)),
          namedParams: [],
          params: [],
        ),
      ),
      'stdout': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.stream)),
          namedParams: [],
          params: [],
        ),
      ),
      'stderr': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.stream)),
          namedParams: [],
          params: [],
        ),
      ),
      'stdin': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(IoTypes.ioSink)),
          namedParams: [],
          params: [],
        ),
      ),
      'pid': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
          namedParams: [],
          params: [],
        ),
      ),
    },
    setters: {},
    fields: {},
    wrap: true,
  );

  /// Wrapper for the [Process.start] method
  static $Value? $start(Runtime runtime, $Value? target, List<$Value?> args) {
    runtime.assertPermission('process:run', args[0]!.$value);
    final value = Process.start(
        args[0]!.$value, (args[1]!.$reified as List).cast(),
        workingDirectory: args[2]?.$value,
        environment: (args[3]?.$reified as Map?)?.cast(),
        includeParentEnvironment: args[4]?.$value ?? true,
        runInShell: args[5]?.$value ?? false,
        mode: args[6]?.$value ?? ProcessStartMode.normal);
    return $Future.wrap(value.then((e) => $Process.wrap(e)));
  }

  /// Wrapper for the [Process.run] method
  static $Value? $run(Runtime runtime, $Value? target, List<$Value?> args) {
    runtime.assertPermission('process:run', args[0]!.$value);
    final value = Process.run(
        args[0]!.$value, (args[1]!.$reified as List).cast(),
        workingDirectory: args[2]?.$value,
        environment: (args[3]?.$reified as Map?)?.cast(),
        includeParentEnvironment: args[4]?.$value ?? true,
        runInShell: args[5]?.$value ?? false,
        stdoutEncoding: args[6]?.$value ?? systemEncoding,
        stderrEncoding: args[7]?.$value ?? systemEncoding);
    return $Future.wrap(value.then((e) => $ProcessResult.wrap(e)));
  }

  /// Wrapper for the [Process.runSync] method
  static $Value? $runSync(Runtime runtime, $Value? target, List<$Value?> args) {
    runtime.assertPermission('process:run', args[0]!.$value);
    final value = Process.runSync(
        args[0]!.$value, (args[1]!.$reified as List).cast(),
        workingDirectory: args[2]?.$value,
        environment: (args[3]?.$reified as Map?)?.cast(),
        includeParentEnvironment: args[4]?.$value ?? true,
        runInShell: args[5]?.$value ?? false,
        stdoutEncoding: args[6]?.$value ?? systemEncoding,
        stderrEncoding: args[7]?.$value ?? systemEncoding);
    return $ProcessResult.wrap(value);
  }

  /// Wrapper for the [Process.killPid] method
  static $Value? $killPid(Runtime runtime, $Value? target, List<$Value?> args) {
    runtime.assertPermission('process:kill', args[0]!.$value);
    final value = Process.killPid(
        args[0]!.$value, args[1]?.$value ?? ProcessSignal.sigterm);
    return $bool(value);
  }

  final $Instance _superclass;

  @override
  final Process $value;

  @override
  Process get $reified => $value;

  /// Wrap a [Process] in a [$Process]
  $Process.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'exitCode':
        final exitCode = $value.exitCode;
        return $Future.wrap(exitCode.then((e) => $int(e)));

      case 'stdout':
        final stdout = $value.stdout;
        return $Stream.wrap(stdout.map((e) => $List.view(e, (e) => $int(e))));

      case 'stderr':
        final stderr = $value.stderr;
        return $Stream.wrap(stderr.map((e) => $List.view(e, (e) => $int(e))));

      case 'stdin':
        final stdin = $value.stdin;
        return $IOSink.wrap(stdin);

      case 'pid':
        final pid = $value.pid;
        return $int(pid);
      case 'kill':
        return __kill;
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __kill = $Function(_kill);
  static $Value? _kill(Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target as $Process;
    final result = self.$value.kill(args[0]?.$value ?? ProcessSignal.sigterm);
    return $bool(result);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}

/// dart_eval wrapper binding for [ProcessResult]
class $ProcessResult implements $Instance {
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFunc(
        'dart:io', 'ProcessResult.', $ProcessResult.$new);
  }

  /// Compile-time type specification of [$ProcessResult]
  static const $spec = BridgeTypeSpec(
    'dart:io',
    'ProcessResult',
  );

  /// Compile-time type declaration of [$ProcessResult]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$ProcessResult]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,
      isAbstract: false,
    ),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'pid',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
              false,
            ),
            BridgeParameter(
              'exitCode',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
              false,
            ),
            BridgeParameter(
              'stdout',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
              false,
            ),
            BridgeParameter(
              'stderr',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
              false,
            ),
          ],
        ),
        isFactory: false,
      ),
    },
    methods: {},
    getters: {},
    setters: {},
    fields: {
      'exitCode': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
        isStatic: false,
      ),
      'stdout': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
        isStatic: false,
      ),
      'stderr': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
        isStatic: false,
      ),
      'pid': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
        isStatic: false,
      ),
    },
    wrap: true,
  );

  /// Wrapper for the [ProcessResult.new] constructor
  static $Value? $new(Runtime runtime, $Value? thisValue, List<$Value?> args) {
    return $ProcessResult.wrap(
      ProcessResult(
          args[0]!.$value, args[1]!.$value, args[2]!.$value, args[3]!.$value),
    );
  }

  final $Instance _superclass;

  @override
  final ProcessResult $value;

  @override
  ProcessResult get $reified => $value;

  /// Wrap a [ProcessResult] in a [$ProcessResult]
  $ProcessResult.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'exitCode':
        final exitCode = $value.exitCode;
        return $int(exitCode);

      case 'stdout':
        final stdout = $value.stdout;
        return stdout is String
            ? $String(stdout)
            : stdout is List<int>
                ? $List.view(stdout, (e) => $int(e))
                : $Object(stdout);

      case 'stderr':
        final stderr = $value.stderr;
        return stderr is String
            ? $String(stderr)
            : stderr is List<int>
                ? $List.view(stderr, (e) => $int(e))
                : $Object(stderr);

      case 'pid':
        final pid = $value.pid;
        return $int(pid);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}

/// dart_eval wrapper binding for [ProcessSignal]
class $ProcessSignal implements $Instance {
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFunc(
        'dart:io', 'ProcessSignal.sighup*g', $ProcessSignal.$sighup);

    runtime.registerBridgeFunc(
        'dart:io', 'ProcessSignal.sigint*g', $ProcessSignal.$sigint);

    runtime.registerBridgeFunc(
        'dart:io', 'ProcessSignal.sigquit*g', $ProcessSignal.$sigquit);

    runtime.registerBridgeFunc(
        'dart:io', 'ProcessSignal.sigill*g', $ProcessSignal.$sigill);

    runtime.registerBridgeFunc(
        'dart:io', 'ProcessSignal.sigtrap*g', $ProcessSignal.$sigtrap);

    runtime.registerBridgeFunc(
        'dart:io', 'ProcessSignal.sigabrt*g', $ProcessSignal.$sigabrt);

    runtime.registerBridgeFunc(
        'dart:io', 'ProcessSignal.sigbus*g', $ProcessSignal.$sigbus);

    runtime.registerBridgeFunc(
        'dart:io', 'ProcessSignal.sigfpe*g', $ProcessSignal.$sigfpe);

    runtime.registerBridgeFunc(
        'dart:io', 'ProcessSignal.sigkill*g', $ProcessSignal.$sigkill);

    runtime.registerBridgeFunc(
        'dart:io', 'ProcessSignal.sigusr1*g', $ProcessSignal.$sigusr1);

    runtime.registerBridgeFunc(
        'dart:io', 'ProcessSignal.sigsegv*g', $ProcessSignal.$sigsegv);

    runtime.registerBridgeFunc(
        'dart:io', 'ProcessSignal.sigusr2*g', $ProcessSignal.$sigusr2);

    runtime.registerBridgeFunc(
        'dart:io', 'ProcessSignal.sigpipe*g', $ProcessSignal.$sigpipe);

    runtime.registerBridgeFunc(
        'dart:io', 'ProcessSignal.sigalrm*g', $ProcessSignal.$sigalrm);

    runtime.registerBridgeFunc(
        'dart:io', 'ProcessSignal.sigterm*g', $ProcessSignal.$sigterm);

    runtime.registerBridgeFunc(
        'dart:io', 'ProcessSignal.sigchld*g', $ProcessSignal.$sigchld);

    runtime.registerBridgeFunc(
        'dart:io', 'ProcessSignal.sigcont*g', $ProcessSignal.$sigcont);

    runtime.registerBridgeFunc(
        'dart:io', 'ProcessSignal.sigstop*g', $ProcessSignal.$sigstop);

    runtime.registerBridgeFunc(
        'dart:io', 'ProcessSignal.sigtstp*g', $ProcessSignal.$sigtstp);

    runtime.registerBridgeFunc(
        'dart:io', 'ProcessSignal.sigttin*g', $ProcessSignal.$sigttin);

    runtime.registerBridgeFunc(
        'dart:io', 'ProcessSignal.sigttou*g', $ProcessSignal.$sigttou);

    runtime.registerBridgeFunc(
        'dart:io', 'ProcessSignal.sigurg*g', $ProcessSignal.$sigurg);

    runtime.registerBridgeFunc(
        'dart:io', 'ProcessSignal.sigxcpu*g', $ProcessSignal.$sigxcpu);

    runtime.registerBridgeFunc(
        'dart:io', 'ProcessSignal.sigxfsz*g', $ProcessSignal.$sigxfsz);

    runtime.registerBridgeFunc(
        'dart:io', 'ProcessSignal.sigvtalrm*g', $ProcessSignal.$sigvtalrm);

    runtime.registerBridgeFunc(
        'dart:io', 'ProcessSignal.sigprof*g', $ProcessSignal.$sigprof);

    runtime.registerBridgeFunc(
        'dart:io', 'ProcessSignal.sigwinch*g', $ProcessSignal.$sigwinch);

    runtime.registerBridgeFunc(
        'dart:io', 'ProcessSignal.sigpoll*g', $ProcessSignal.$sigpoll);

    runtime.registerBridgeFunc(
        'dart:io', 'ProcessSignal.sigsys*g', $ProcessSignal.$sigsys);
  }

  /// Compile-time type specification of [$ProcessSignal]
  static const $spec = BridgeTypeSpec(
    'dart:io',
    'ProcessSignal',
  );

  /// Compile-time type declaration of [$ProcessSignal]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$ProcessSignal]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,
      isAbstract: false,
    ),
    constructors: {
      '_': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'signalNumber',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
              false,
            ),
            BridgeParameter(
              'name',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
              false,
            ),
          ],
        ),
        isFactory: false,
      ),
    },
    methods: {
      'toString': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
          namedParams: [],
          params: [],
        ),
      ),
      'watch': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.stream)),
          namedParams: [],
          params: [],
        ),
      ),
    },
    getters: {},
    setters: {},
    fields: {
      'sighup': BridgeFieldDef(
        BridgeTypeAnnotation(
            BridgeTypeRef(BridgeTypeSpec('dart:io', 'ProcessSignal'))),
        isStatic: true,
      ),
      'sigint': BridgeFieldDef(
        BridgeTypeAnnotation(
            BridgeTypeRef(BridgeTypeSpec('dart:io', 'ProcessSignal'))),
        isStatic: true,
      ),
      'sigquit': BridgeFieldDef(
        BridgeTypeAnnotation(
            BridgeTypeRef(BridgeTypeSpec('dart:io', 'ProcessSignal'))),
        isStatic: true,
      ),
      'sigill': BridgeFieldDef(
        BridgeTypeAnnotation(
            BridgeTypeRef(BridgeTypeSpec('dart:io', 'ProcessSignal'))),
        isStatic: true,
      ),
      'sigtrap': BridgeFieldDef(
        BridgeTypeAnnotation(
            BridgeTypeRef(BridgeTypeSpec('dart:io', 'ProcessSignal'))),
        isStatic: true,
      ),
      'sigabrt': BridgeFieldDef(
        BridgeTypeAnnotation(
            BridgeTypeRef(BridgeTypeSpec('dart:io', 'ProcessSignal'))),
        isStatic: true,
      ),
      'sigbus': BridgeFieldDef(
        BridgeTypeAnnotation(
            BridgeTypeRef(BridgeTypeSpec('dart:io', 'ProcessSignal'))),
        isStatic: true,
      ),
      'sigfpe': BridgeFieldDef(
        BridgeTypeAnnotation(
            BridgeTypeRef(BridgeTypeSpec('dart:io', 'ProcessSignal'))),
        isStatic: true,
      ),
      'sigkill': BridgeFieldDef(
        BridgeTypeAnnotation(
            BridgeTypeRef(BridgeTypeSpec('dart:io', 'ProcessSignal'))),
        isStatic: true,
      ),
      'sigusr1': BridgeFieldDef(
        BridgeTypeAnnotation(
            BridgeTypeRef(BridgeTypeSpec('dart:io', 'ProcessSignal'))),
        isStatic: true,
      ),
      'sigsegv': BridgeFieldDef(
        BridgeTypeAnnotation(
            BridgeTypeRef(BridgeTypeSpec('dart:io', 'ProcessSignal'))),
        isStatic: true,
      ),
      'sigusr2': BridgeFieldDef(
        BridgeTypeAnnotation(
            BridgeTypeRef(BridgeTypeSpec('dart:io', 'ProcessSignal'))),
        isStatic: true,
      ),
      'sigpipe': BridgeFieldDef(
        BridgeTypeAnnotation(
            BridgeTypeRef(BridgeTypeSpec('dart:io', 'ProcessSignal'))),
        isStatic: true,
      ),
      'sigalrm': BridgeFieldDef(
        BridgeTypeAnnotation(
            BridgeTypeRef(BridgeTypeSpec('dart:io', 'ProcessSignal'))),
        isStatic: true,
      ),
      'sigterm': BridgeFieldDef(
        BridgeTypeAnnotation(
            BridgeTypeRef(BridgeTypeSpec('dart:io', 'ProcessSignal'))),
        isStatic: true,
      ),
      'sigchld': BridgeFieldDef(
        BridgeTypeAnnotation(
            BridgeTypeRef(BridgeTypeSpec('dart:io', 'ProcessSignal'))),
        isStatic: true,
      ),
      'sigcont': BridgeFieldDef(
        BridgeTypeAnnotation(
            BridgeTypeRef(BridgeTypeSpec('dart:io', 'ProcessSignal'))),
        isStatic: true,
      ),
      'sigstop': BridgeFieldDef(
        BridgeTypeAnnotation(
            BridgeTypeRef(BridgeTypeSpec('dart:io', 'ProcessSignal'))),
        isStatic: true,
      ),
      'sigtstp': BridgeFieldDef(
        BridgeTypeAnnotation(
            BridgeTypeRef(BridgeTypeSpec('dart:io', 'ProcessSignal'))),
        isStatic: true,
      ),
      'sigttin': BridgeFieldDef(
        BridgeTypeAnnotation(
            BridgeTypeRef(BridgeTypeSpec('dart:io', 'ProcessSignal'))),
        isStatic: true,
      ),
      'sigttou': BridgeFieldDef(
        BridgeTypeAnnotation(
            BridgeTypeRef(BridgeTypeSpec('dart:io', 'ProcessSignal'))),
        isStatic: true,
      ),
      'sigurg': BridgeFieldDef(
        BridgeTypeAnnotation(
            BridgeTypeRef(BridgeTypeSpec('dart:io', 'ProcessSignal'))),
        isStatic: true,
      ),
      'sigxcpu': BridgeFieldDef(
        BridgeTypeAnnotation(
            BridgeTypeRef(BridgeTypeSpec('dart:io', 'ProcessSignal'))),
        isStatic: true,
      ),
      'sigxfsz': BridgeFieldDef(
        BridgeTypeAnnotation(
            BridgeTypeRef(BridgeTypeSpec('dart:io', 'ProcessSignal'))),
        isStatic: true,
      ),
      'sigvtalrm': BridgeFieldDef(
        BridgeTypeAnnotation(
            BridgeTypeRef(BridgeTypeSpec('dart:io', 'ProcessSignal'))),
        isStatic: true,
      ),
      'sigprof': BridgeFieldDef(
        BridgeTypeAnnotation(
            BridgeTypeRef(BridgeTypeSpec('dart:io', 'ProcessSignal'))),
        isStatic: true,
      ),
      'sigwinch': BridgeFieldDef(
        BridgeTypeAnnotation(
            BridgeTypeRef(BridgeTypeSpec('dart:io', 'ProcessSignal'))),
        isStatic: true,
      ),
      'sigpoll': BridgeFieldDef(
        BridgeTypeAnnotation(
            BridgeTypeRef(BridgeTypeSpec('dart:io', 'ProcessSignal'))),
        isStatic: true,
      ),
      'sigsys': BridgeFieldDef(
        BridgeTypeAnnotation(
            BridgeTypeRef(BridgeTypeSpec('dart:io', 'ProcessSignal'))),
        isStatic: true,
      ),
      'signalNumber': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
        isStatic: false,
      ),
      'name': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
        isStatic: false,
      ),
    },
    wrap: true,
  );

  /// Wrapper for the [ProcessSignal.sighup] getter
  static $Value? $sighup(Runtime runtime, $Value? target, List<$Value?> args) {
    final value = ProcessSignal.sighup;
    return $ProcessSignal.wrap(value);
  }

  /// Wrapper for the [ProcessSignal.sigint] getter
  static $Value? $sigint(Runtime runtime, $Value? target, List<$Value?> args) {
    final value = ProcessSignal.sigint;
    return $ProcessSignal.wrap(value);
  }

  /// Wrapper for the [ProcessSignal.sigquit] getter
  static $Value? $sigquit(Runtime runtime, $Value? target, List<$Value?> args) {
    final value = ProcessSignal.sigquit;
    return $ProcessSignal.wrap(value);
  }

  /// Wrapper for the [ProcessSignal.sigill] getter
  static $Value? $sigill(Runtime runtime, $Value? target, List<$Value?> args) {
    final value = ProcessSignal.sigill;
    return $ProcessSignal.wrap(value);
  }

  /// Wrapper for the [ProcessSignal.sigtrap] getter
  static $Value? $sigtrap(Runtime runtime, $Value? target, List<$Value?> args) {
    final value = ProcessSignal.sigtrap;
    return $ProcessSignal.wrap(value);
  }

  /// Wrapper for the [ProcessSignal.sigabrt] getter
  static $Value? $sigabrt(Runtime runtime, $Value? target, List<$Value?> args) {
    final value = ProcessSignal.sigabrt;
    return $ProcessSignal.wrap(value);
  }

  /// Wrapper for the [ProcessSignal.sigbus] getter
  static $Value? $sigbus(Runtime runtime, $Value? target, List<$Value?> args) {
    final value = ProcessSignal.sigbus;
    return $ProcessSignal.wrap(value);
  }

  /// Wrapper for the [ProcessSignal.sigfpe] getter
  static $Value? $sigfpe(Runtime runtime, $Value? target, List<$Value?> args) {
    final value = ProcessSignal.sigfpe;
    return $ProcessSignal.wrap(value);
  }

  /// Wrapper for the [ProcessSignal.sigkill] getter
  static $Value? $sigkill(Runtime runtime, $Value? target, List<$Value?> args) {
    final value = ProcessSignal.sigkill;
    return $ProcessSignal.wrap(value);
  }

  /// Wrapper for the [ProcessSignal.sigusr1] getter
  static $Value? $sigusr1(Runtime runtime, $Value? target, List<$Value?> args) {
    final value = ProcessSignal.sigusr1;
    return $ProcessSignal.wrap(value);
  }

  /// Wrapper for the [ProcessSignal.sigsegv] getter
  static $Value? $sigsegv(Runtime runtime, $Value? target, List<$Value?> args) {
    final value = ProcessSignal.sigsegv;
    return $ProcessSignal.wrap(value);
  }

  /// Wrapper for the [ProcessSignal.sigusr2] getter
  static $Value? $sigusr2(Runtime runtime, $Value? target, List<$Value?> args) {
    final value = ProcessSignal.sigusr2;
    return $ProcessSignal.wrap(value);
  }

  /// Wrapper for the [ProcessSignal.sigpipe] getter
  static $Value? $sigpipe(Runtime runtime, $Value? target, List<$Value?> args) {
    final value = ProcessSignal.sigpipe;
    return $ProcessSignal.wrap(value);
  }

  /// Wrapper for the [ProcessSignal.sigalrm] getter
  static $Value? $sigalrm(Runtime runtime, $Value? target, List<$Value?> args) {
    final value = ProcessSignal.sigalrm;
    return $ProcessSignal.wrap(value);
  }

  /// Wrapper for the [ProcessSignal.sigterm] getter
  static $Value? $sigterm(Runtime runtime, $Value? target, List<$Value?> args) {
    final value = ProcessSignal.sigterm;
    return $ProcessSignal.wrap(value);
  }

  /// Wrapper for the [ProcessSignal.sigchld] getter
  static $Value? $sigchld(Runtime runtime, $Value? target, List<$Value?> args) {
    final value = ProcessSignal.sigchld;
    return $ProcessSignal.wrap(value);
  }

  /// Wrapper for the [ProcessSignal.sigcont] getter
  static $Value? $sigcont(Runtime runtime, $Value? target, List<$Value?> args) {
    final value = ProcessSignal.sigcont;
    return $ProcessSignal.wrap(value);
  }

  /// Wrapper for the [ProcessSignal.sigstop] getter
  static $Value? $sigstop(Runtime runtime, $Value? target, List<$Value?> args) {
    final value = ProcessSignal.sigstop;
    return $ProcessSignal.wrap(value);
  }

  /// Wrapper for the [ProcessSignal.sigtstp] getter
  static $Value? $sigtstp(Runtime runtime, $Value? target, List<$Value?> args) {
    final value = ProcessSignal.sigtstp;
    return $ProcessSignal.wrap(value);
  }

  /// Wrapper for the [ProcessSignal.sigttin] getter
  static $Value? $sigttin(Runtime runtime, $Value? target, List<$Value?> args) {
    final value = ProcessSignal.sigttin;
    return $ProcessSignal.wrap(value);
  }

  /// Wrapper for the [ProcessSignal.sigttou] getter
  static $Value? $sigttou(Runtime runtime, $Value? target, List<$Value?> args) {
    final value = ProcessSignal.sigttou;
    return $ProcessSignal.wrap(value);
  }

  /// Wrapper for the [ProcessSignal.sigurg] getter
  static $Value? $sigurg(Runtime runtime, $Value? target, List<$Value?> args) {
    final value = ProcessSignal.sigurg;
    return $ProcessSignal.wrap(value);
  }

  /// Wrapper for the [ProcessSignal.sigxcpu] getter
  static $Value? $sigxcpu(Runtime runtime, $Value? target, List<$Value?> args) {
    final value = ProcessSignal.sigxcpu;
    return $ProcessSignal.wrap(value);
  }

  /// Wrapper for the [ProcessSignal.sigxfsz] getter
  static $Value? $sigxfsz(Runtime runtime, $Value? target, List<$Value?> args) {
    final value = ProcessSignal.sigxfsz;
    return $ProcessSignal.wrap(value);
  }

  /// Wrapper for the [ProcessSignal.sigvtalrm] getter
  static $Value? $sigvtalrm(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final value = ProcessSignal.sigvtalrm;
    return $ProcessSignal.wrap(value);
  }

  /// Wrapper for the [ProcessSignal.sigprof] getter
  static $Value? $sigprof(Runtime runtime, $Value? target, List<$Value?> args) {
    final value = ProcessSignal.sigprof;
    return $ProcessSignal.wrap(value);
  }

  /// Wrapper for the [ProcessSignal.sigwinch] getter
  static $Value? $sigwinch(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final value = ProcessSignal.sigwinch;
    return $ProcessSignal.wrap(value);
  }

  /// Wrapper for the [ProcessSignal.sigpoll] getter
  static $Value? $sigpoll(Runtime runtime, $Value? target, List<$Value?> args) {
    final value = ProcessSignal.sigpoll;
    return $ProcessSignal.wrap(value);
  }

  /// Wrapper for the [ProcessSignal.sigsys] getter
  static $Value? $sigsys(Runtime runtime, $Value? target, List<$Value?> args) {
    final value = ProcessSignal.sigsys;
    return $ProcessSignal.wrap(value);
  }

  final $Instance _superclass;

  @override
  final ProcessSignal $value;

  @override
  ProcessSignal get $reified => $value;

  /// Wrap a [ProcessSignal] in a [$ProcessSignal]
  $ProcessSignal.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'signalNumber':
        final signalNumber = $value.signalNumber;
        return $int(signalNumber);

      case 'name':
        final name = $value.name;
        return $String(name);
      case 'toString':
        return __toString;

      case 'watch':
        return __watch;
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __toString = $Function(_toString);
  static $Value? _toString(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target as $ProcessSignal;
    final result = self.$value.toString();
    return $String(result);
  }

  static const $Function __watch = $Function(_watch);
  static $Value? _watch(Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target as $ProcessSignal;
    final result = self.$value.watch();
    return $Stream.wrap(result.map((e) => $ProcessSignal.wrap(e)));
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
