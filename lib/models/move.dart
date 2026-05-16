import 'hex_coord.dart';

/// A single move: starting position followed by 1+ landing positions.
/// Length 2 with adjacent cells = single step.
/// Length 2 with non-adjacent cells, or length > 2 = jump chain.
class Move {
  final List<HexCoord> path;

  const Move(this.path);

  HexCoord get from => path.first;
  HexCoord get to => path.last;

  bool get isJump => path.first.distanceTo(path[1]) > 1 || path.length > 2;

  @override
  String toString() => path.join(' -> ');
}
