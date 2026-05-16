import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/board.dart';
import '../models/game_state.dart';
import '../models/hex_coord.dart';
import '../models/move.dart';
import '../theme/colors.dart';

/// Pure layout math for placing the star board inside a [Size].
class BoardLayout {
  final Size size;
  final double cellRadius;
  final double pegRadius;
  final Offset center;

  BoardLayout._(this.size, this.cellRadius, this.pegRadius, this.center);

  factory BoardLayout.from(Size size) {
    final cellRadius = math.min(
      size.width / (math.sqrt(3) * 13),
      size.height / 26,
    );
    return BoardLayout._(
      size,
      cellRadius,
      cellRadius * 0.68,
      Offset(size.width / 2, size.height / 2),
    );
  }

  Offset hexToPixel(HexCoord c) {
    final x = cellRadius * math.sqrt(3) * (c.x + c.y / 2);
    final y = cellRadius * 1.5 * c.y;
    return Offset(center.dx + x, center.dy + y);
  }

  HexCoord? cellAt(Offset pos, {double slack = 1.0}) {
    HexCoord? best;
    double bestDist = double.infinity;
    for (final c in Board.cells) {
      final d = (hexToPixel(c) - pos).distanceSquared;
      if (d < bestDist) {
        bestDist = d;
        best = c;
      }
    }
    final threshold = (cellRadius * slack);
    return bestDist <= threshold * threshold ? best : null;
  }
}

/// The visual board: cells, pieces, highlights, and tap routing.
class BoardView extends StatelessWidget {
  final GameState game;
  final int humanId;
  final HexCoord? selected;
  final Set<HexCoord> validDestinations;
  final int? activePlayer;
  final Move? animatingMove;
  final double animationValue;
  final void Function(HexCoord) onTap;

  const BoardView({
    super.key,
    required this.game,
    required this.humanId,
    required this.selected,
    required this.validDestinations,
    required this.activePlayer,
    required this.animatingMove,
    required this.animationValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = BoardLayout.from(constraints.biggest);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            final cell = layout.cellAt(details.localPosition);
            if (cell != null) onTap(cell);
          },
          child: CustomPaint(
            size: constraints.biggest,
            painter: _BoardPainter(
              layout: layout,
              game: game,
              humanId: humanId,
              selected: selected,
              validDestinations: validDestinations,
              activePlayer: activePlayer,
              animatingMove: animatingMove,
              animationValue: animationValue,
            ),
          ),
        );
      },
    );
  }
}

class _BoardPainter extends CustomPainter {
  final BoardLayout layout;
  final GameState game;
  final int humanId;
  final HexCoord? selected;
  final Set<HexCoord> validDestinations;
  final int? activePlayer;
  final Move? animatingMove;
  final double animationValue;

  _BoardPainter({
    required this.layout,
    required this.game,
    required this.humanId,
    required this.selected,
    required this.validDestinations,
    required this.activePlayer,
    required this.animatingMove,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _paintTriangleTints(canvas);
    _paintEmptyCells(canvas);
    _paintDestinations(canvas);
    _paintPieces(canvas);
    _paintSelectionRing(canvas);
    _paintMovingPiece(canvas);
  }

  void _paintTriangleTints(Canvas canvas) {
    for (int t = 0; t < 6; t++) {
      int? colorOwner;
      for (final p in game.players) {
        if (p.goalTriangle == t) {
          colorOwner = p.colorIndex;
          break;
        }
      }
      if (colorOwner == null) continue;
      final paint = Paint()
        ..color = AppColors.piece[colorOwner].withOpacity(0.06);
      for (final c in Board.triangles[t]) {
        canvas.drawCircle(
            layout.hexToPixel(c), layout.cellRadius * 1.05, paint);
      }
    }
  }

  void _paintEmptyCells(Canvas canvas) {
    final paint = Paint()
      ..color = AppColors.emptyCell
      ..style = PaintingStyle.fill;
    for (final c in Board.cells) {
      final p = layout.hexToPixel(c);
      canvas.drawCircle(p, layout.pegRadius * 0.35, paint);
    }
  }

  void _paintDestinations(Canvas canvas) {
    if (validDestinations.isEmpty) return;
    final ring = Paint()
      ..color = AppColors.accent.withOpacity(0.85)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    for (final c in validDestinations) {
      final p = layout.hexToPixel(c);
      canvas.drawCircle(p, layout.pegRadius * 0.85, ring);
    }
  }

  void _paintPieces(Canvas canvas) {
    for (final entry in game.pieces.entries) {
      final cell = entry.key;
      final playerId = entry.value;
      if (animatingMove != null && cell == animatingMove!.from) {
        // Skip: the moving piece is drawn at the animated overlay.
        continue;
      }
      final colorIdx = game.players[playerId].colorIndex;
      final color = AppColors.piece[colorIdx];
      _drawPeg(canvas, layout.hexToPixel(cell), color, playerId == humanId);
    }
  }

  void _drawPeg(Canvas canvas, Offset center, Color color, bool isHuman) {
    final shadow = Paint()
      ..color = Colors.black.withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawCircle(center.translate(0, 1.5), layout.pegRadius, shadow);

    final fill = Paint()..color = color;
    canvas.drawCircle(center, layout.pegRadius, fill);

    // Soft inner ring for depth.
    final inner = Paint()
      ..color = Colors.black.withOpacity(0.12)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, layout.pegRadius * 0.85, inner);

    // Tiny indicator dot for the human's pieces.
    if (isHuman) {
      final dot = Paint()..color = Colors.white.withOpacity(0.55);
      canvas.drawCircle(
        center.translate(-layout.pegRadius * 0.35, -layout.pegRadius * 0.35),
        layout.pegRadius * 0.15,
        dot,
      );
    }
  }

  void _paintSelectionRing(Canvas canvas) {
    final sel = selected;
    if (sel == null) return;
    final p = layout.hexToPixel(sel);
    final ring = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(p, layout.pegRadius * 1.25, ring);
  }

  void _paintMovingPiece(Canvas canvas) {
    final m = animatingMove;
    if (m == null) return;
    final segCount = m.path.length - 1;
    if (segCount <= 0) return;
    final t = (animationValue * segCount).clamp(0.0, segCount.toDouble());
    int segIdx = t.floor();
    if (segIdx >= segCount) segIdx = segCount - 1;
    final segProgress = t - segIdx;
    final start = layout.hexToPixel(m.path[segIdx]);
    final end = layout.hexToPixel(m.path[segIdx + 1]);
    final eased = Curves.easeInOut.transform(segProgress);
    var pos = Offset.lerp(start, end, eased)!;

    // Tiny vertical hop for jump segments to make them feel like jumps.
    final isJump = m.path[segIdx].distanceTo(m.path[segIdx + 1]) > 1;
    if (isJump) {
      final hop = math.sin(segProgress * math.pi) * layout.cellRadius * 0.55;
      pos = pos.translate(0, -hop);
    }

    final playerId = game.pieces[m.from];
    if (playerId == null) return;
    final colorIdx = game.players[playerId].colorIndex;
    _drawPeg(canvas, pos, AppColors.piece[colorIdx], playerId == humanId);
  }

  @override
  bool shouldRepaint(covariant _BoardPainter old) =>
      old.game != game ||
      old.selected != selected ||
      old.validDestinations != validDestinations ||
      old.activePlayer != activePlayer ||
      old.animatingMove != animatingMove ||
      old.animationValue != animationValue;
}
