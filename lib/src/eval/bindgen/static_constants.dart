import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:dart_eval/src/eval/bindgen/context.dart';
import 'package:dart_eval/src/eval/bindgen/config.dart';
import 'package:dart_eval/src/eval/bindgen/type.dart';

/// Generated pieces for static const fields with ordinary getter semantics.
///
/// A group shares its type annotation and registration callback. The field
/// names still appear individually in the bridge declaration and runtime.
class CompactStaticConstants {
  const CompactStaticConstants({
    required this.fieldNames,
    required this.typeDeclarations,
    required this.fieldDeclarations,
    required this.runtimeRegistrations,
    required this.wrapperMembers,
  });

  final Set<String> fieldNames;
  final String typeDeclarations;
  final String fieldDeclarations;
  final String runtimeRegistrations;
  final String wrapperMembers;
}

final _cache = Expando<Map<InterfaceElement, CompactStaticConstants?>>();

/// Return compact source for eligible fields when the class opts in.
CompactStaticConstants? compactStaticConstants(
  BindgenContext ctx,
  InterfaceElement element,
) {
  if (ctx.classConfig?.compactStaticConstants != true) return null;
  final classCache = _cache[ctx] ??= {};
  if (classCache.containsKey(element)) return classCache[element];
  return classCache[element] = _build(ctx, element);
}

CompactStaticConstants? _build(BindgenContext ctx, InterfaceElement element) {
  final groups = <DartType, _ConstantGroup>{};
  final names = <String>{};
  for (final field in element.fields) {
    final name = field.name;
    if (name == null ||
        field.isPrivate ||
        !field.isStatic ||
        !field.isConst ||
        field.isEnumConstant ||
        field.isOriginGetterSetter ||
        !ctx.memberIncluded(name, 'field') ||
        !ctx.memberIncluded(name, 'static')) {
      continue;
    }
    final fieldConfig = ctx.memberConfig(name, 'field');
    final getterConfig = ctx.memberConfig(name, 'static');
    if (_customized(fieldConfig) || _customized(getterConfig)) continue;
    final type = field.type;
    // A type's bridge metadata and wrapper conversion are emitted once for
    // the group, even for classes with thousands of constants.
    final group = groups.putIfAbsent(type, () {
      final annotation = bridgeTypeAnnotationFrom(ctx, type);
      final wrapped = wrapVar(ctx, type, 'entry.value');
      return _ConstantGroup(
        groups.length,
        type.getDisplayString(),
        annotation,
        wrapped ?? 'runtime.wrapAlways(entry.value)',
      );
    });
    group.fields.add(field);
    names.add(name);
  }
  if (groups.isEmpty) return null;

  final types = StringBuffer();
  final fields = StringBuffer();
  final registrations = StringBuffer();
  final members = StringBuffer();
  final uri = ctx.libOverrides[element.name] ?? ctx.uri;
  for (final group in groups.values) {
    final index = group.index;
    final typeName = '_compactConstantType$index';
    final mapName = '_compactConstants$index';
    types.writeln('  static const $typeName = ${group.annotation};');
    members.writeln('  static const $mapName = <String, ${group.typeSource}>{');
    for (final field in group.fields) {
      final name = field.name!;
      members.writeln("    '$name': ${element.name}.$name,");
      fields.writeln(
        "      '$name': BridgeFieldDef($typeName, isStatic: true),",
      );
    }
    members.writeln('  };');
    registrations.writeln('''
    for (final entry in $mapName.entries) {
      runtime.registerBridgeFuncRegisters(
        '$uri',
        '${element.name}.\${entry.key}*g',
        (runtime, r, s, c) => ${group.wrapped},
      );
    }
''');
  }
  return CompactStaticConstants(
    fieldNames: names,
    typeDeclarations: types.toString(),
    fieldDeclarations: fields.toString(),
    runtimeRegistrations: registrations.toString(),
    wrapperMembers: members.toString(),
  );
}

bool _customized(BindgenMemberConfig? member) =>
    member != null &&
    (member.rename != null ||
        member.returns != null ||
        member.hook != null ||
        member.expr != null ||
        member.type != null ||
        member.isStatic != null ||
        member.permissions.isNotEmpty ||
        member.params.isNotEmpty);

class _ConstantGroup {
  _ConstantGroup(this.index, this.typeSource, this.annotation, this.wrapped);

  final int index;
  final String typeSource;
  final String annotation;
  final String wrapped;
  final List<FieldElement> fields = [];
}
