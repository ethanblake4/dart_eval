import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
// The analyzer's public AST does not expose member replacement.
// ignore: implementation_imports
import 'package:analyzer/src/dart/ast/ast.dart' as ast;

/// The value-class experiment expresses generated members as ordinary Dart.
/// Keep explicit constructors and operators, and let normal compilation handle
/// field initialization, argument checks, dispatch and serialization.
void lowerValueClass(ClassDeclaration declaration) {
  if (!declaration.metadata.any(
    (annotation) => annotation.name.name == 'valueClass',
  )) {
    return;
  }
  final body = declaration.body;
  if (body is! BlockClassBody) return;
  final members = body.members;
  final fields = [
    for (final field in members.whereType<FieldDeclaration>())
      if (!field.isStatic)
        for (final variable in field.fields.variables) variable,
  ];
  final methods = members.whereType<MethodDeclaration>();
  final name = declaration.namePart.typeName.lexeme;
  final parameters = declaration.namePart.typeParameters;
  final type =
      '$name${parameters == null ? '' : '<${parameters.typeParameters.map((parameter) => parameter.name.lexeme).join(', ')}>'}';
  final generated = StringBuffer();
  if (!members.any((member) => member is ConstructorDeclaration)) {
    final requiredFields = fields.where((field) => field.initializer == null);
    final formals = requiredFields.map(
      (field) => 'required this.${field.name.lexeme}',
    );
    generated.writeln(
      'const $name(${requiredFields.isEmpty ? '' : '{${formals.join(', ')}}'});',
    );
  }
  if (!methods.any(
    (method) => method.isOperator && method.name.lexeme == '==',
  )) {
    final equalFields = fields.map(
      (field) => '${field.name.lexeme} == other.${field.name.lexeme}',
    );
    generated.writeln(
      'bool operator ==(Object other) => identical(this, other) || '
      'other is $type && runtimeType == other.runtimeType'
      '${fields.isEmpty ? '' : ' && ${equalFields.join(' && ')}'};',
    );
  }
  if (!methods.any(
    (method) => method.isGetter && method.name.lexeme == 'hashCode',
  )) {
    generated.writeln('int get hashCode { var hash = runtimeType.hashCode;');
    for (final field in fields) {
      final fieldName = field.name.lexeme;
      generated.writeln(
        'hash = ((hash * 31) ^ ($fieldName == null ? 0 : $fieldName.hashCode)) '
        '& 0x1fffffff;',
      );
    }
    generated.writeln('return hash; }');
  }
  if (generated.isEmpty) return;
  final synthetic =
      parseString(
            content: 'class $name${parameters?.toSource() ?? ''} {$generated}',
            throwIfDiagnostics: false,
          ).unit.declarations.single
          as ClassDeclaration;
  (declaration as ast.ClassDeclarationImpl).body = ast.BlockClassBodyImpl(
    leftBracket: body.leftBracket,
    members: [
      ...members.cast<ast.ClassMemberImpl>(),
      ...synthetic.body.members.cast<ast.ClassMemberImpl>(),
    ],
    rightBracket: body.rightBracket,
  );
}
