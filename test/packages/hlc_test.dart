import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/base.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

/// A test of the [hlc](https://pub.dev/packages/hlc) package
void main() {
  test('package:hlc', () {
    final compiler = Compiler();
    final runtime = compiler.compileWriteAndLoad({
      'hlc': {
        'hlc.dart': r'''
  import 'dart:math';

/// A hybrid logical clock implementation with string-based nodes.
class HLC implements Comparable<HLC> {
  /// The delimiter used for [pack]ing and [unpack]ing this HLC in a string.
  ///
  /// Useful if you have an existing HLC that doesn't use the default, a colon (:).
  static String delimiter = ':';

  /// The clock's timestamp.
  final int timestamp;

  /// The clock's event count, which breaks ties in the case of identical clocks.
  final int count;

  /// This node's name (or ID), which breaks ties in the case of identical counts.
  final String node;

  /// Constructs an HLC from the given parameters.
  HLC({
    required this.timestamp,
    required this.count,
    required this.node,
  });

  /// Constructs a copy of this HLC with the given parameters.
  HLC copy({
    int? timestamp,
    int? count,
    String? node,
  }) {
    return HLC(
      timestamp: timestamp ?? this.timestamp,
      count: count ?? this.count,
      node: node ?? this.node,
    );
  }

  /// Constructs an initial HLC using the current wall clock.
  static HLC now(String node) {
    return HLC(
      timestamp: DateTime.now().millisecondsSinceEpoch,
      count: 0,
      node: node,
    );
  }

  /// Produces the next, local clock.
  HLC increment() {
    return copy(count: count + 1);
  }

  /// Synchronizes with a given [remote] clock.
  ///
  /// If a [maximumDrift] is configured and the remote clock is sufficiently in
  /// the future, a [TimeDriftException] will be thrown.
  ///
  /// The [now] parameter indicates the wall clock in milliseconds. It is primarily
  /// used for testing.
  HLC receive(
    HLC remote, {
    Duration? maximumDrift,
    int? now,
  }) {
    now ??= DateTime.now().millisecondsSinceEpoch;
    final local = this;

    if (maximumDrift != null) {
      final drift = Duration(milliseconds: remote.timestamp - now);

      if (drift > maximumDrift) {
        throw TimeDriftException(
          drift: drift,
          maximumDrift: maximumDrift,
        );
      }
    }

    if (now > local.timestamp && now > remote.timestamp) {
      return copy(timestamp: now, count: 0);
    }

    if (local.timestamp < remote.timestamp) {
      return copy(timestamp: remote.timestamp, count: remote.count + 1);
    } else if (local.timestamp > remote.timestamp) {
      return copy(count: count + 1);
    } else {
      return copy(count: max(local.count, remote.count) + 1);
    }
  }

  @override
  int compareTo(HLC other) {
    var result = timestamp.compareTo(other.timestamp);

    if (result != 0) {
      return result;
    }

    result = count.compareTo(other.count);

    if (result != 0) {
      return result;
    }

    return node.compareTo(other.node);
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (
            other is HLC &&
            timestamp == other.timestamp &&
            count == other.count &&
            node == other.node);
  }

  @override
  int get hashCode => Object.hash(
        timestamp.hashCode,
        count.hashCode,
        node.hashCode,
      );

  @override
  String toString() {
    return pack();
  }

  /// Encodes this HLC into a string representation whose topological ordering
  /// is equivalent to that of the original HLC.
  String pack() {
    final buffer = StringBuffer();
    buffer.write(timestamp.toString().padLeft(15, '0'));
    buffer.write(delimiter);
    buffer.write(count.toRadixString(36).padLeft(5, '0'));
    buffer.write(delimiter);
    buffer.write(node);
    return buffer.toString();
  }

  /// Decodes an HLC previously packed with [pack], else fails with a [FormatException].
  static HLC unpack(String packed) {
    final parts = packed.split(delimiter);

    return HLC(
      timestamp: int.parse(parts[0]),
      count: int.parse(parts[1], radix: 36),
      node: parts.sublist(2).join(delimiter),
    );
  }
}

class TimeDriftException implements Exception {
  final Duration drift;

  final Duration maximumDrift;

  const TimeDriftException({
    required this.drift,
    required this.maximumDrift,
  });

  String get message => 'TimeDriftException: The received clock\'s time drift exceeds the maximum.';
}
          '''
      },
      'eval_test': {
        'main.dart': '''
          import 'package:hlc/hlc.dart';
          String main() {
            final hlc = HLC.unpack('001697431030337:00001:time');
            return hlc.increment().pack();
          }
        '''
      }
    });

    expect(runtime.executeLib('package:eval_test/main.dart', 'main'),
        $String('001697431030337:00002:time'));
  });
}
