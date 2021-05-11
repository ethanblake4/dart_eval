/// Represents a node in Dart source code
abstract class DartSourceNode {
  /// The character offset into the source file
  final int offset;

  /// The length of this node in characters
  final int length;

  /// Create a [DartSourceNode]
  const DartSourceNode(this.offset, this.length);
}
