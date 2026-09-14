/// Register-bank IDs used by typed machine lowering.
enum MachineRepresentation { integer, doublePrecision, boolean, string, object }

/// The machine ABI of a compiled function, in formal parameter order.
class MachineFunctionSignature {
  const MachineFunctionSignature(this.parameters, this.result);

  final List<MachineRepresentation> parameters;
  final MachineRepresentation? result;
}
