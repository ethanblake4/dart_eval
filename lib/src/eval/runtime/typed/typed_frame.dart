import 'dart:typed_data';

import 'typed_function.dart';

/// Allocated per call, never per arithmetic instruction. Argument storage is
/// copied from the caller, so recursive calls cannot overwrite live arguments.
class TypedFrame {
  TypedFrame(
    TypedFunction function,
    List<int> integers,
    List<double> doubles,
    List<int> booleans, {
    this.parent,
    this.returnPc = 0,
    this.returnBank = -1,
  }) : intArguments = Int64List.fromList(integers),
       doubleArguments = Float64List.fromList(doubles),
       boolArguments = Uint8List.fromList(booleans),
       intSpills = Int64List(function.intSpillCount),
       doubleSpills = Float64List(function.doubleSpillCount),
       boolSpills = Uint8List(function.boolSpillCount),
       intOutgoing = Int64List(function.intOutgoingCount),
       doubleOutgoing = Float64List(function.doubleOutgoingCount),
       boolOutgoing = Uint8List(function.boolOutgoingCount);

  final TypedFrame? parent;
  final int returnPc;
  final int returnBank;
  final Int64List intArguments, intSpills, intOutgoing;
  final Float64List doubleArguments, doubleSpills, doubleOutgoing;
  final Uint8List boolArguments, boolSpills, boolOutgoing;
}
