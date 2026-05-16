import 'dart:math' as math;

/// Cube coordinate on a hexagonal grid. Invariant: x + y + z == 0.
class HexCoord {
  final int x;
  final int y;
  final int z;

  const HexCoord(int x, int y) : this._(x, y, -x - y);
  const HexCoord._(this.x, this.y, this.z);

  /// 6 unit direction vectors around a hex.
  static const List<HexCoord> directions = [
    HexCoord._(1, 0, -1),
    HexCoord._(1, -1, 0),
    HexCoord._(0, -1, 1),
    HexCoord._(-1, 0, 1),
    HexCoord._(-1, 1, 0),
    HexCoord._(0, 1, -1),
  ];

  HexCoord neighbor(int direction) {
    final d = directions[direction];
    return HexCoord._(x + d.x, y + d.y, z + d.z);
  }

  HexCoord step(HexCoord d, int k) =>
      HexCoord._(x + d.x * k, y + d.y * k, z + d.z * k);

  /// Hex (cube) distance between two coordinates.
  int distanceTo(HexCoord other) {
    final dx = (x - other.x).abs();
    final dy = (y - other.y).abs();
    final dz = (z - other.z).abs();
    return math.max(dx, math.max(dy, dz));
  }

  @override
  bool operator ==(Object other) =>
      other is HexCoord && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => '($x,$y,$z)';
}
