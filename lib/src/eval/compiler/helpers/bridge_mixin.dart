import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/ast/token.dart' show StringToken;
// ignore: implementation_imports
import 'package:analyzer/src/dart/ast/ast.dart' as ast;
import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/dart_eval_bridge.dart';

import '../backend/representation.dart';
import '../context.dart';
import '../errors.dart';
import '../member/call_signature.dart';
import '../member/member.dart';
import '../member/member_name.dart';
import '../type.dart';
import 'extension.dart' show positionalArityOf;
import 'field_storage.dart';
import '../../ir/bridge.dart';
import '../../ir/closures.dart';
import '../../ir/flow.dart';
import '../../ir/function.dart';
import '../../ir/objects.dart';

final _fields = Expando<TypeRef>('bridge mixin storage');
final _methods = Expando<BridgeMixinMethod>('bridge mixin methods');
final _sequences = Expando<int>('bridge mixin sequence');

class BridgeMixinMethod {
  BridgeMixinMethod(this.field, this.member, this.signature);
  final FieldDeclaration field;
  final BridgeMember member;
  final CallSignature signature;
}

BridgeMixinMethod? bridgeMixinMethod(AstNode node) => _methods[node];
bool isBridgeMixinField(FieldDeclaration field) => _fields[field] != null;

/// Native mixin bodies keep separate adapters instead of replacing the
/// application's real superclass. The adapter dispatches virtual calls back
/// to the guest instance; its shim selects the SDK implementation itself.
(List<FieldDeclaration>, List<MethodDeclaration>) lowerBridgeMixin(
  CompilerContext ctx,
  TypeRef type,
) {
  final declaration = nominalDeclOf(type);
  final bridge = declaration is BridgeTypeDecl ? declaration.classDef : null;
  if (bridge == null || !bridge.bridge || !bridge.type.isMixinClass) {
    throw CompileError('${type.name} is not a mixin (used in a with clause)');
  }
  if (!bridge.constructors.containsKey('')) {
    throw CompileError('Bridged mixin ${type.name} needs an unnamed adapter');
  }
  final sequence = _sequences[ctx] ?? 0;
  _sequences[ctx] = sequence + 1;
  final field = ast.FieldDeclarationImpl(
    comment: null,
    metadata: [],
    augmentKeyword: null,
    externalKeyword: null,
    staticKeyword: null,
    abstractKeyword: null,
    covariantKeyword: null,
    fields: ast.VariableDeclarationListImpl(
      comment: null,
      metadata: [],
      lateKeyword: null,
      keyword: Token(Keyword.VAR, 0),
      type: null,
      variables: [
        ast.VariableDeclarationImpl(
          comment: null,
          metadata: [],
          name: StringToken(TokenType.IDENTIFIER, '#bridgeMixin$sequence', 0),
          equals: null,
          initializer: null,
        ),
      ],
    ),
    semicolon: Token(TokenType.SEMICOLON, 0),
  );
  _fields[field] = type;
  final methods = <MethodDeclaration>[];
  void add(String name, MemberKind kind, BridgeMethodDef definition) {
    if (definition.isStatic || definition.isAbstract) return;
    final member = BridgeMember(
      owner: TypeDeclMemberOwner(declaration!),
      name: MemberName(name, kind),
      def: definition,
    );
    final signature = member.signature.substitute(
      Substitution.forInterface(type),
    );
    String parameter(BridgeParameter p) =>
        '${p.optional ? '' : 'required '}dynamic ${p.name}'
        '${p.optional ? ' = ${p.defaultValueSource ?? 'null'}' : ''}';
    final function = definition.functionDescriptor;
    final required = function.params.where((p) => !p.optional);
    final optional = function.params.where((p) => p.optional);
    final parameters = [
      for (final p in required) 'dynamic ${p.name}',
      if (optional.isNotEmpty)
        '[${optional.map((p) => 'dynamic ${p.name} = ${p.defaultValueSource ?? 'null'}').join(',')}]',
      if (function.namedParams.isNotEmpty)
        '{${function.namedParams.map(parameter).join(',')}}',
    ].join(',');
    final generics = function.generics.isEmpty
        ? ''
        : '<${function.generics.keys.join(',')}>';
    final declarationSource = switch (kind) {
      MemberKind.getter => 'get $name => null;',
      MemberKind.setter => 'set $name($parameters) {}',
      _ => '${_operatorName(name)}$generics($parameters) => null;',
    };
    final host =
        parseString(
              content: 'class ${type.name} { $declarationSource }',
              throwIfDiagnostics: false,
            ).unit.declarations.single
            as ClassDeclaration;
    final method = host.body.members.single as MethodDeclaration;
    final nodes = method.parameters?.parameters.toList() ?? <FormalParameter>[];
    var parameterIndex = 0;
    ParameterSpec bindParameter(ParameterSpec spec) {
      final node = nodes[parameterIndex++];
      final value = node.defaultClause?.value;
      return ParameterSpec(
        spec.name,
        spec.type,
        isRequired: spec.isRequired,
        erased: spec.erased,
        node: node,
        defaultValue: value == null ? null : SourceDefault(value, type.file),
      );
    }

    final bound = CallSignature(
      typeParameters: signature.typeParameters,
      typeParameterRefs: signature.typeParameterRefs,
      positional: signature.positional.map(bindParameter).toList(),
      requiredPositional: signature.requiredPositional,
      named: signature.named.map(bindParameter).toList(),
      returnType: signature.returnType,
      returnAnnotated: signature.returnAnnotated,
      returnOverride: signature.returnOverride,
    );
    _methods[method] = BridgeMixinMethod(field, member, bound);
    methods.add(method);
  }

  bridge.methods.forEach(
    (name, definition) => add(name, MemberKind.method, definition),
  );
  bridge.getters.forEach(
    (name, definition) => add(name, MemberKind.getter, definition),
  );
  bridge.setters.forEach(
    (name, definition) => add(name, MemberKind.setter, definition),
  );
  return ([field], methods);
}

String _operatorName(String name) =>
    const {
      '+',
      '-',
      '*',
      '/',
      '~/',
      '%',
      '==',
      '<',
      '>',
      '<=',
      '>=',
      '&',
      '|',
      '^',
      '<<',
      '>>',
      '>>>',
      '~',
      '[]',
      '[]=',
    }.contains(name)
    ? 'operator $name'
    : name;

/// Registers folded declarations in order while retaining the host's members.
void registerBridgeMixinMethods(
  CompilerContext ctx,
  Declaration host,
  List<MethodDeclaration> folded,
) {
  if (!folded.any((m) => bridgeMixinMethod(m) != null)) return;
  final members =
      ctx.instanceDeclarationsMap[ctx.library]![declarationName(host)]!;
  final original = Map<String, Declaration>.of(members);
  for (final method in folded) {
    final kind = memberKind(method);
    final key = kind == MemberKind.method
        ? MemberName.method(method.name.lexeme, positionalArityOf(method)).key
        : MemberName(method.name.lexeme, kind).key;
    final own = original[key];
    if (own?.parent?.parent == host) continue;
    members[key] = method;
  }
}

void initializeBridgeMixins(
  CompilerContext ctx,
  List<FieldDeclaration> fields,
  SSA receiver, {
  int firstFieldIndex = 0,
}) {
  var index = firstFieldIndex;
  for (final field in fields) {
    if (!hasInstanceFieldStorage(field)) continue;
    final type = _fields[field];
    if (type != null) {
      final adapter = ctx.svar('mixin_adapter');
      final shim = ctx.svar('mixin_shim');
      final external =
          ctx.bridgeStaticFunctionIndices[type.file]?['${type.name}.'];
      if (external == null) {
        throw CompileError('No bridge adapter for ${type.name}');
      }
      ctx.pushOp(NewBridgeSuperShim(shim));
      ctx.pushOp(
        BridgeInstantiate(
          adapter,
          external,
          receiver,
          const [],
          runtimeTypeId: ctx.runtimeTypes.idOf(type),
        ),
      );
      ctx.pushOp(ParentBridgeSuperShim(shim, adapter));
      ctx.pushOp(SetPropertyStatic(receiver, index, shim));
    }
    index += field.fields.variables.length;
  }
}

int compileBridgeMixinMethod(
  CompilerContext ctx,
  Declaration host,
  MethodDeclaration method,
  List<FieldDeclaration> fields,
  int firstFieldIndex,
) {
  final body = bridgeMixinMethod(method)!;
  final signature = body.signature;
  final kind = memberKind(method);
  final function = ctx.beginFunction(
    '${declarationName(host)}.${method.name.lexeme} (bridge mixin)',
  );
  final receiver = SSA('arg_0');
  final parameters =
      method.parameters?.parameters.toList() ?? <FormalParameter>[];
  final types = [
    for (final p in signature.positional) p.type,
    for (final p in signature.named) p.type,
  ];
  ctx.functionParameters[function] = parameters;
  ctx.functionParameterTypes[function] = types;
  ctx.functionTypeParameters[function] = signature.typeParameters;
  ctx.functionRuntimeTypes[function] = signature.toFunctionType(ctx);
  ctx.functionSignatures[function] = MachineFunctionSignature(
    List.filled(types.length + 1, MachineRepresentation.object),
    MachineRepresentation.object,
  );
  ctx.pushOp(Parameter(receiver, 0));
  final arguments = <SSA>[];
  for (var i = 0; i < types.length; i++) {
    final argument = SSA('arg_${i + 1}');
    ctx.pushOp(Parameter(argument, i + 1));
    final prepared = ctx.svar('bridge_argument');
    ctx.pushOp(PrepareBridgeArgument(prepared, argument));
    arguments.add(prepared);
  }
  var index = firstFieldIndex;
  for (final field in fields) {
    if (!hasInstanceFieldStorage(field)) continue;
    if (identical(field, body.field)) break;
    index += field.fields.variables.length;
  }
  final shim = ctx.svar('mixin_shim');
  final result = ctx.svar('mixin_result');
  ctx.pushOp(LoadPropertyStatic(shim, receiver, index));
  if (kind == MemberKind.setter) {
    ctx.pushOp(SetPropertyDynamic(shim, method.name.lexeme, arguments.single));
    ctx.pushOp(Return(null));
  } else {
    final callable = kind == MemberKind.getter
        ? result
        : ctx.svar('mixin_method');
    ctx.pushOp(LoadPropertyDynamic(callable, shim, method.name.lexeme));
    if (kind == MemberKind.method) {
      ctx.pushOp(InvokeClosure(result, callable, arguments, const {}));
    }
    ctx.pushOp(Return(result));
  }
  final library = ctx.enclosingLibrary ?? ctx.library;
  ctx.instanceDeclarationPositions[library]![declarationName(host)]![kind]![ctx
          .instanceMethodKey(method.name.lexeme, positionalArityOf(method))] =
      function;
  return function;
}
