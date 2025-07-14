import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/src/eval/runtime/ops/all_ops.dart';

class OffsetTracker {
  OffsetTracker(this.context);

  final Map<int, DeferredOrOffset> _deferredOffsets = {};
  CompilerContext context;

  void setOffset(int location, DeferredOrOffset offset) {
    _deferredOffsets[location] = offset;
  }

  /// Resolve method offset in inheritance hierarchy
  int? _resolveInheritedMethodOffset(
      int file, String className, String methodName) {
    // Verificações null-safe para instanceDeclarationPositions
    final instanceDeclarations = context.instanceDeclarationPositions;

    final fileDeclarations = instanceDeclarations[file];
    if (fileDeclarations == null) {
      return null;
    }

    final classDeclarations = fileDeclarations[className];
    if (classDeclarations == null) {
      return null;
    }

    final methodTypeDeclarations = classDeclarations[2];
    if (methodTypeDeclarations == null) {
      return null;
    }

    // Primeiro, procura na classe atual
    final methodOffset = methodTypeDeclarations[methodName];
    if (methodOffset != null) {
      return methodOffset;
    }

    // Se não encontrou, procura na hierarquia de herança
    final classDec = context.topLevelDeclarationsMap[file]?[className];
    if (classDec == null || classDec.isBridge) {
      return null;
    }

    final classDeclaration = classDec.declaration;
    if (classDeclaration is! ClassDeclaration) {
      return null;
    }

    final extendsClause = classDeclaration.extendsClause;
    if (extendsClause == null) {
      // Se não tem herança, procura em Object
      return _resolveInheritedMethodOffset(file, 'Object', methodName);
    }

    // Procura na superclasse
    final superClassName = extendsClause.superclass.name2.value();
    final superType = context.visibleTypes[file]?[superClassName];
    if (superType == null) {
      return null;
    }

    return _resolveInheritedMethodOffset(
        superType.file, superType.name, methodName);
  }

  List<EvcOp> apply(List<EvcOp> source) {
    _deferredOffsets.forEach((pos, offset) {
      final op = source[pos];
      if (op is Call) {
        int resolvedOffset;
        if (offset.methodType == 2) {
          // Tentar resolver primeiro com busca hierárquica
          final inheritedOffset = _resolveInheritedMethodOffset(
              offset.file!, offset.className!, offset.name!);

          if (inheritedOffset != null) {
            resolvedOffset = inheritedOffset;
          } else {
            // Fallback para verificações explícitas (código original)
            final instanceDeclarations = context.instanceDeclarationPositions;

            final fileDeclarations = instanceDeclarations[offset.file!];
            if (fileDeclarations == null) {
              throw CompileError(
                  'No declarations found for file ${offset.file}');
            }

            final classDeclarations = fileDeclarations[offset.className!];
            if (classDeclarations == null) {
              throw CompileError(
                  'No declarations found for class ${offset.className} in file ${offset.file}');
            }

            final methodTypeDeclarations = classDeclarations[2];
            if (methodTypeDeclarations == null) {
              throw CompileError(
                  'No method type declarations found for class ${offset.className} in file ${offset.file}');
            }

            final methodOffset = methodTypeDeclarations[offset.name!];
            if (methodOffset == null) {
              throw CompileError(
                  'No method offset found for ${offset.className}.${offset.name} in file ${offset.file}');
            }

            resolvedOffset = methodOffset;
          }
        } else {
          // Verificações null-safe para topLevelDeclarationPositions
          final topLevelDeclarations = context.topLevelDeclarationPositions;

          final fileDeclarations = topLevelDeclarations[offset.file!];
          if (fileDeclarations == null) {
            throw CompileError(
                'No top level declarations found for file ${offset.file}');
          }

          final methodOffset = fileDeclarations[offset.name!];
          if (methodOffset == null) {
            throw CompileError(
                'No top level method offset found for ${offset.name} in file ${offset.file}');
          }

          resolvedOffset = methodOffset;
        }
        final newOp = Call.make(resolvedOffset);
        source[pos] = newOp;
      } else if (op is PushObjectPropertyImpl) {
        // Verificações null-safe para instanceGetterIndices
        final instanceGetters = context.instanceGetterIndices;

        final fileGetters = instanceGetters[offset.file!];
        if (fileGetters == null) {
          throw CompileError('No getter indices found for file ${offset.file}');
        }

        final classGetters = fileGetters[offset.className!];
        if (classGetters == null) {
          throw CompileError(
              'No getter indices found for class ${offset.className} in file ${offset.file}');
        }

        final getterOffset = classGetters[offset.name!];
        if (getterOffset == null) {
          throw CompileError(
              'No getter offset found for ${offset.className}.${offset.name} in file ${offset.file}');
        }

        final resolvedOffset = getterOffset;
        final newOp =
            PushObjectPropertyImpl.make(op.objectOffset, resolvedOffset);
        source[pos] = newOp;
      }
    });
    return source;
  }
}

/// An structure pointing to a function that may or may not have been generated already. If it hasn't, the exact program
/// offset will be resolved later by the [OffsetTracker]
class DeferredOrOffset {
  DeferredOrOffset(
      {this.offset,
      this.file,
      this.name,
      this.className,
      this.methodType,
      this.targetScopeFrameOffset})
      : assert(offset != null || name != null);

  final int? offset;
  final int? file;
  final String? className;
  final int? methodType;
  final String? name;
  final int? targetScopeFrameOffset;

  factory DeferredOrOffset.lookupStatic(
      CompilerContext ctx, int library, String parent, String name) {
    if (ctx.topLevelDeclarationPositions[library]
            ?.containsKey('$parent.$name') ??
        false) {
      return DeferredOrOffset(
          file: library,
          offset: ctx.topLevelDeclarationPositions[library]!['$parent.$name'],
          name: '$parent.$name');
    } else {
      return DeferredOrOffset(file: library, name: '$parent.$name');
    }
  }

  @override
  String toString() {
    return 'DeferredOrOffset{offset: $offset, file: $file, name: $name}';
  }

  @override
  bool operator ==(Object other) =>
      other is DeferredOrOffset &&
      other.offset == offset &&
      other.file == file &&
      other.className == className &&
      other.name == name;

  @override
  int get hashCode =>
      offset.hashCode ^ className.hashCode ^ file.hashCode ^ name.hashCode;
}
