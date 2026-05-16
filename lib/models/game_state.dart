import 'board.dart';
import 'hex_coord.dart';
import 'move.dart';
import 'player.dart';

/// Mutable game state. All "logic" lives here (move generation, win check).
class GameState {
  final List<Player> players;
  final Map<HexCoord, int> pieces; // cell -> player id
  int currentPlayer;
  final List<int> finishOrder; // player ids in finishing order

  GameState({
    required this.players,
    required this.pieces,
    required this.currentPlayer,
    List<int>? finishOrder,
  }) : finishOrder = finishOrder ?? <int>[];

  factory GameState.initial(List<Player> players) {
    final pieces = <HexCoord, int>{};
    for (final p in players) {
      for (final cell in Board.triangles[p.startTriangle]) {
        pieces[cell] = p.id;
      }
    }
    return GameState(
      players: players,
      pieces: pieces,
      currentPlayer: 0,
    );
  }

  GameState clone() => GameState(
        players: players,
        pieces: Map<HexCoord, int>.from(pieces),
        currentPlayer: currentPlayer,
        finishOrder: List<int>.from(finishOrder),
      );

  Iterable<HexCoord> piecesOf(int playerId) =>
      pieces.entries.where((e) => e.value == playerId).map((e) => e.key);

  /// Returns all legal moves for [playerId]. Each move is either a single step
  /// to an adjacent empty cell, or a chain of one or more jumps.
  ///
  /// House rule (to keep the game ending well): a piece that already sits in
  /// its goal triangle may not leave it. This avoids "wandering home" pieces
  /// and the classic "block your own goal" tactic.
  List<Move> legalMoves(int playerId) {
    final player = players[playerId];
    final goalCells = Board.triangleSets[player.goalTriangle];
    final out = <Move>[];

    for (final piece in piecesOf(playerId).toList(growable: false)) {
      final inGoal = goalCells.contains(piece);

      // Single steps.
      for (int dir = 0; dir < 6; dir++) {
        final n = piece.neighbor(dir);
        if (!Board.cellSet.contains(n)) continue;
        if (pieces.containsKey(n)) continue;
        if (inGoal && !goalCells.contains(n)) continue;
        out.add(Move(<HexCoord>[piece, n]));
      }

      // Jump chains.
      final visited = <HexCoord>{piece};
      _collectJumps(
        origin: piece,
        position: piece,
        path: <HexCoord>[piece],
        visited: visited,
        goalCells: goalCells,
        mustStayInGoal: inGoal,
        out: out,
      );
    }
    return out;
  }

  void _collectJumps({
    required HexCoord origin,
    required HexCoord position,
    required List<HexCoord> path,
    required Set<HexCoord> visited,
    required Set<HexCoord> goalCells,
    required bool mustStayInGoal,
    required List<Move> out,
  }) {
    for (int dir = 0; dir < 6; dir++) {
      final d = HexCoord.directions[dir];
      final mid = HexCoord(position.x + d.x, position.y + d.y);
      final landing = HexCoord(position.x + 2 * d.x, position.y + 2 * d.y);

      if (!Board.cellSet.contains(mid)) continue;
      if (!Board.cellSet.contains(landing)) continue;

      // Mid must be occupied. The moving piece's origin is "empty" for jumps.
      final midOccupied = pieces.containsKey(mid) && mid != origin;
      if (!midOccupied) continue;

      // Landing must be empty (origin is empty as the piece is moving).
      final landingEmpty = !pieces.containsKey(landing) || landing == origin;
      if (!landingEmpty) continue;

      if (visited.contains(landing)) continue;
      if (mustStayInGoal && !goalCells.contains(landing)) continue;

      visited.add(landing);
      final newPath = List<HexCoord>.from(path)..add(landing);
      out.add(Move(newPath));
      _collectJumps(
        origin: origin,
        position: landing,
        path: newPath,
        visited: visited,
        goalCells: goalCells,
        mustStayInGoal: mustStayInGoal,
        out: out,
      );
      visited.remove(landing);
    }
  }

  /// Applies a move (does not advance the turn).
  void applyMove(Move m) {
    final piece = pieces.remove(m.from);
    if (piece == null) {
      throw StateError('No piece at ${m.from}');
    }
    pieces[m.to] = piece;
  }

  /// Advances to the next player who has not finished yet.
  void advanceTurn() {
    final n = players.length;
    for (int i = 1; i <= n; i++) {
      final next = (currentPlayer + i) % n;
      if (!finishOrder.contains(next)) {
        currentPlayer = next;
        return;
      }
    }
    // Everyone finished.
    currentPlayer = -1;
  }

  /// True if [playerId]'s pieces fill their goal triangle.
  bool hasFinished(int playerId) {
    final goal = Board.triangleSets[players[playerId].goalTriangle];
    for (final c in goal) {
      if (pieces[c] != playerId) return false;
    }
    return true;
  }

  /// Records a finish for [playerId] if newly finished.
  void recordIfFinished(int playerId) {
    if (!finishOrder.contains(playerId) && hasFinished(playerId)) {
      finishOrder.add(playerId);
    }
  }

  bool get gameOver => finishOrder.length >= players.length - 1;

  int? get winner => finishOrder.isEmpty ? null : finishOrder.first;
}
