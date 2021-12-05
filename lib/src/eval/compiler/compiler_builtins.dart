part of 'compiler.dart';

class BuiltinValue {
  BuiltinValue({this.intval, this.doubleval, this.stringval}) {
    if (intval != null) {
      type = BuiltinValueType.intType;
    } else if (stringval != null) {
      type = BuiltinValueType.stringType;
    } else if (doubleval != null) {
      type = BuiltinValueType.doubleType;
    } else {
      type = BuiltinValueType.nullType;
    }
  }

  late BuiltinValueType type;
  final int? intval;
  final double? doubleval;
  final String? stringval;
}

enum BuiltinValueType { intType, stringType, doubleType, nullType }

class KnownMethod {
  const KnownMethod(this.returnType, this.args, this.namedArgs);

  final ReturnType? returnType;
  final List<KnownMethodArg> args;
  final Map<String, KnownMethodArg> namedArgs;
}

class KnownMethodArg {
  const KnownMethodArg(this.name, this.type, this.optional, this.nullable);

  final String name;
  final TypeRef? type;
  final bool optional;
  final bool nullable;
}

const TypeRef _dynamicType = TypeRef(_dartCoreFile, 'dynamic');
const TypeRef _nullType = TypeRef(_dartCoreFile, 'Null', extendsType: _dynamicType);
const TypeRef _objectType = TypeRef(_dartCoreFile, 'Object', extendsType: _dynamicType);
const TypeRef _numType = TypeRef(_dartCoreFile, 'num', extendsType: _objectType);
final TypeRef _intType = TypeRef(_dartCoreFile, 'int', extendsType: _numType);
final TypeRef _doubleType = TypeRef(_dartCoreFile, 'double', extendsType: _numType);
const TypeRef _stringType = TypeRef(_dartCoreFile, 'String', extendsType: _objectType);
const TypeRef _mapType = TypeRef(_dartCoreFile, 'Map', extendsType: _objectType);
const TypeRef _listType = TypeRef(_dartCoreFile, 'List', extendsType: _objectType);
const TypeRef _functionType = TypeRef(_dartCoreFile, 'Function', extendsType: _objectType);

final Map<String, TypeRef> _coreDeclarations = {
  'dynamic': _dynamicType,
  'Null': _nullType,
  'Object': _objectType,
  'num': _numType,
  'String': _stringType,
  'int': _intType,
  'double': _doubleType,
  'Map': _mapType,
  'List': _listType,
  'Function': _functionType
};

final _intBinaryOp = KnownMethod(
    ParameterTypeDependentReturnType({
      _doubleType: AlwaysReturnType(_doubleType, false),
      _intType: AlwaysReturnType(_intType, false),
      _numType: AlwaysReturnType(_numType, false)
    }, paramIndex: 0, fallback: AlwaysReturnType(_numType, false)),
    [KnownMethodArg('other', _numType, false, false)],
    {});

final _doubleBinaryOp =
KnownMethod(AlwaysReturnType(_doubleType, false), [KnownMethodArg('other', _numType, false, false)], {});

final _numBinaryOp = KnownMethod(
    ParameterTypeDependentReturnType({
      _doubleType: AlwaysReturnType(_doubleType, false),
    }, paramIndex: 0, fallback: AlwaysReturnType(_numType, false)),
    [KnownMethodArg('other', _numType, false, false)],
    {});

final Map<TypeRef, Map<String, KnownMethod>> _knownMethods = {
  _intType: {
    '+': _intBinaryOp,
    '-': _intBinaryOp,
    '/': _intBinaryOp,
    '%': _intBinaryOp,
  },
  _doubleType: {
    '+': _doubleBinaryOp,
    '-': _doubleBinaryOp,
    '/': _doubleBinaryOp,
    '%': _doubleBinaryOp,
  },
  _numType: {
    '+': _numBinaryOp,
    '-': _numBinaryOp,
    '/': _numBinaryOp,
    '%': _numBinaryOp,
  }
};

final Set<TypeRef> _unboxedAcrossFunctionBoundaries = {_intType, _doubleType};