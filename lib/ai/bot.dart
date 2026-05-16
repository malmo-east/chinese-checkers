import 'dart:math' as math;

import '../models/board.dart';
import '../models/game_state.dart';
import '../models/move.dart';

enum Difficulty { easy, medium, hard }

extension DifficultyLabel on Difficulty {
  String get label => switch (this) {
        Difficulty.easy => 'Лёгкий',
        Difficulty.medium => 'Средний',
        Difficulty.hard => 'Сложный',
      };
}

/// "Human-like" AI in the spirit of 2000s casual games.
///
/// Design notes:
///   * Each bot scores positions using ONLY its own pieces. It has no concept
///     of other players, so it never blocks, gangs up, or singles out the
///     human. Bots simply race their own checkers home.
///   * One-ply enumeration is enough thanks to a "distance-to-own-apex"
///     heuristic plus small shaping terms for the home/goal triangles.
///   * Difficulty changes how greedily the bot picks among the top moves and
///     whether it cares about stragglers (the classic "leave no checker
///     behind" rule of thumb that human players use).
class Bot {
  final Difficulty difficulty;
  final math.Random _rng;

  Bot(this.difficulty, {math.Random? rng}) : _rng = rng ?? math.Random();

  /// Picks a move for [playerId] given the current [state].
  /// Returns null if the player has no legal moves.
  Move? chooseMove(GameState state, int playerId) {
    final moves = state.legalMoves(playerId);
    if (moves.isEmpty) return null;

    final scored = <_ScoredMove>[];
    for (final m in moves) {
      scored.add(_ScoredMove(m, _scoreMove(state, m, playerId)));
    }
    scored.sort((a, b) => b.score.compareTo(a.score));

    switch (difficulty) {
      case Difficulty.easy:
        // Pick a random move from the top half - sometimes silly, never hostile.
        final cutoff = math.max(1, (scored.length * 0.5).ceil());
        final pool = scored.take(cutoff).toList();
        // 30% chance to pick from anywhere in pool (more "lazy"),
        // 70% chance to pick from top third.
        if (_rng.nextDouble() < 0.7) {
          final topThird = math.max(1, (pool.length / 3).ceil());
          return pool[_rng.nextInt(topThird)].move;
        }
        return pool[_rng.nextInt(pool.length)].move;

      case Difficulty.medium:
        // Pick from top 3, weighted toward the best.
        final pool = scored.take(math.min(3, scored.length)).toList();
        final weights = <double>[for (int i = 0; i < pool.length; i++) 1.0 / (i + 1)];
        return _weightedPick(pool, weights).move;

      case Difficulty.hard:
        // Take the best; if there is a tie, randomize to avoid loops.
        final best = scored.first.score;
        final ties = scored.takeWhile((s) => s.score == best).toList();
        return ties[_rng.nextInt(ties.length)].move;
    }
  }

  _ScoredMove _weightedPick(List<_ScoredMove> pool, List<double> weights) {
    final total = weights.fold<double>(0, (a, b) => a + b);
    double r = _rng.nextDouble() * total;
    for (int i = 0; i < pool.length; i++) {
      r -= weights[i];
      if (r <= 0) return pool[i];
    }
    return pool.last;
  }

  int _scoreMove(GameState state, Move m, int playerId) {
    final player = state.players[playerId];
    final goalApex = Board.apex[player.goalTriangle];
    final goalCells = Board.triangleSets[player.goalTriangle];
    final startCells = Board.triangleSets[player.startTriangle];

    final dFrom = m.from.distanceTo(goalApex);
    final dTo = m.to.distanceTo(goalApex);

    // Primary: distance progress toward goal apex.
    int score = (dFrom - dTo) * 10;

    // Bonus for landing inside the goal triangle.
    final wasInGoal = goalCells.contains(m.from);
    final nowInGoal = goalCells.contains(m.to);
    if (!wasInGoal && nowInGoal) score += 6;
    if (wasInGoal && !nowInGoal) score -= 20; // never leave goal voluntarily

    // Reward for finally leaving the start triangle.
    final wasInStart = startCells.contains(m.from);
    final nowInStart = startCells.contains(m.to);
    if (wasInStart && !nowInStart) score += 4;

    // Multi-jump bonus: long chains feel exciting and usually mean progress.
    if (m.path.length > 2) {
      score += (m.path.length - 2) * 2;
    }

    if (difficulty == Difficulty.hard) {
      // Discourage leaving a lone "straggler" behind: check the worst piece
      // distance after the move and compare with before.
      score += _stragglerDelta(state, m, playerId);
    }

    return score;
  }

  int _stragglerDelta(GameState state, Move m, int playerId) {
    int maxBefore = 0;
    int maxAfter = 0;
    final goalApex = Board.apex[state.players[playerId].goalTriangle];
    for (final entry in state.pieces.entries) {
      if (entry.value != playerId) continue;
      final p = entry.key;
      final pos = p == m.from ? m.to : p;
      final dBefore = p.distanceTo(goalApex);
      final dAfter = pos.distanceTo(goalApex);
      if (dBefore > maxBefore) maxBefore = dBefore;
      if (dAfter > maxAfter) maxAfter = dAfter;
    }
    return (maxBefore - maxAfter) * 3;
  }
}

class _ScoredMove {
  final Move move;
  final int score;
  _ScoredMove(this.move, this.score);
}
