import 'hex_coord.dart';

/// Static information about the 121-cell Chinese Checkers star board.
///
/// Cube coordinates with x + y + z == 0. The central hexagon has radius 4
/// (61 cells). Six triangles of 10 cells each extend outward in 6 directions.
///
/// Triangle indices (clockwise from top, opposite of i is (i + 3) % 6):
///   0 - top         (direction -y, apex (4, -8, 4))
///   1 - upper-right (direction +x, apex (8, -4, -4))
///   2 - lower-right (direction -z, apex (4, 4, -8))
///   3 - bottom      (direction +y, apex (-4, 8, -4))
///   4 - lower-left  (direction -x, apex (-8, 4, 4))
///   5 - upper-left  (direction +z, apex (-4, -4, 8))
class Board {
  static const int radius = 4;
  static const int triangleSize = 4;

  /// All 121 board cells.
  static final List<HexCoord> cells = _generateCells();
  static final Set<HexCoord> cellSet = cells.toSet();

  /// Cells belonging to each of the 6 outer triangles (10 cells each).
  static final List<List<HexCoord>> triangles = _generateTriangles();
  static final List<Set<HexCoord>> triangleSets =
      triangles.map((t) => t.toSet()).toList(growable: false);

  /// Apex of each triangle (the deepest single cell).
  static final List<HexCoord> apex = _generateApex();

  static int oppositeTriangle(int i) => (i + 3) % 6;

  static List<HexCoord> _generateCells() {
    final result = <HexCoord>{};
    // Central hexagon: max(|x|, |y|, |z|) <= 4.
    for (int x = -radius; x <= radius; x++) {
      for (int y = -radius; y <= radius; y++) {
        final z = -x - y;
        if (z.abs() <= radius) result.add(HexCoord(x, y));
      }
    }
    // Six triangles, each row has (5 - row) cells, row in 1..4.
    for (int d = 1; d <= triangleSize; d++) {
      // Triangle 0: -y direction (top), y = -(radius + d).
      for (int x = d; x <= radius; x++) {
        final yv = -(radius + d);
        result.add(HexCoord(x, yv));
      }
      // Triangle 3: +y direction (bottom).
      for (int x = -radius; x <= -d; x++) {
        final yv = radius + d;
        result.add(HexCoord(x, yv));
      }
      // Triangle 1: +x direction (upper-right), x = radius + d.
      for (int y = -radius; y <= -d; y++) {
        result.add(HexCoord(radius + d, y));
      }
      // Triangle 4: -x direction (lower-left).
      for (int y = d; y <= radius; y++) {
        result.add(HexCoord(-(radius + d), y));
      }
      // Triangle 2: -z direction (lower-right), z = -(radius + d), so x + y = radius + d.
      for (int x = d; x <= radius; x++) {
        final yv = radius + d - x;
        result.add(HexCoord(x, yv));
      }
      // Triangle 5: +z direction (upper-left), z = radius + d, so x + y = -(radius + d).
      for (int x = -radius; x <= -d; x++) {
        final yv = -(radius + d) - x;
        result.add(HexCoord(x, yv));
      }
    }
    return result.toList(growable: false);
  }

  static List<List<HexCoord>> _generateTriangles() {
    final tris = List.generate(6, (_) => <HexCoord>[]);
    for (final c in cells) {
      if (c.y < -radius) {
        tris[0].add(c);
      } else if (c.x > radius) {
        tris[1].add(c);
      } else if (c.z < -radius) {
        tris[2].add(c);
      } else if (c.y > radius) {
        tris[3].add(c);
      } else if (c.x < -radius) {
        tris[4].add(c);
      } else if (c.z > radius) {
        tris[5].add(c);
      }
    }
    return tris.map((l) => List<HexCoord>.unmodifiable(l)).toList();
  }

  static List<HexCoord> _generateApex() => const [
        HexCoord(4, -8),   // 0 top
        HexCoord(8, -4),   // 1 upper-right
        HexCoord(4, 4),    // 2 lower-right
        HexCoord(-4, 8),   // 3 bottom
        HexCoord(-8, 4),   // 4 lower-left
        HexCoord(-4, -4),  // 5 upper-left
      ];
}
