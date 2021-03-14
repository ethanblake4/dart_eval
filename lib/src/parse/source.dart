/// Represents a node in Dart source code
abstract class DartSourceNode {
  final int offset;
  final int length;

  const DartSourceNode(this.offset, this.length);
}