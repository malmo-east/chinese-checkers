import 'package:flutter_test/flutter_test.dart';

import 'package:chinese_checkers/ai/bot.dart';
import 'package:chinese_checkers/models/board.dart';
import 'package:chinese_checkers/models/game_state.dart';
import 'package:chinese_checkers/models/hex_coord.dart';
import 'package:chinese_checkers/models/player.dart';

void main() {
  group('Board geometry', () {
    test('star has 121 cells', () {
      expect(Board.cells.length, 121);
    });

    test('each triangle holds 10 cells', () {
      for (final t in Board.triangles) {
        expect(t.length, 10);
      }
    });

    test('apexes belong to their triangle', () {
      for (int i = 0; i < 6; i++) {
        expect(Board.triangleSets[i].contains(Board.apex[i]), isTrue);
      }
    });

    test('opposite triangles are at distance 16', () {
      for (int i = 0; i < 6; i++) {
        final opp = Board.oppositeTriangle(i);
        expect(Board.apex[i].distanceTo(Board.apex[opp]), 16);
      }
    });
  });

  group('Hex math', () {
    test('cube coords sum to zero', () {
      for (final c in Board.cells) {
        expect(c.x + c.y + c.z, 0);
      }
    });

    test('distance to self is zero', () {
      const c = HexCoord(2, -3);
      expect(c.distanceTo(c), 0);
    });

    test('distance to neighbor is one', () {
      const c = HexCoord(0, 0);
      for (int i = 0; i < 6; i++) {
        expect(c.distanceTo(c.neighbor(i)), 1);
      }
    });
  });

  group('Game logic', () {
    GameState twoPlayerGame() {
      return GameState.initial([
        const Player(
          id: 0,
          startTriangle: 3,
          goalTriangle: 0,
          colorIndex: 0,
          isHuman: true,
          name: 'Вы',
        ),
        const Player(
          id: 1,
          startTriangle: 0,
          goalTriangle: 3,
          colorIndex: 1,
          isHuman: false,
          name: 'Бот',
        ),
      ]);
    }

    test('initial board has 20 pieces (2 players)', () {
      final g = twoPlayerGame();
      expect(g.pieces.length, 20);
    });

    test('player has legal moves from start', () {
      final g = twoPlayerGame();
      final moves = g.legalMoves(0);
      expect(moves, isNotEmpty);
    });

    test('initial moves include single steps', () {
      final g = twoPlayerGame();
      final moves = g.legalMoves(0);
      // A piece can step into the empty central hex.
      expect(moves.any((m) => m.path.length == 2 &&
              m.path[0].distanceTo(m.path[1]) == 1), isTrue);
    });

    test('jumps are detected when possible', () {
      // Set up a contrived board with a clear single-jump opportunity.
      final g = twoPlayerGame();
      // Move a player-0 piece next to another so it can hop over.
      g.pieces.clear();
      g.pieces[const HexCoord(0, 0)] = 0;     // jumper
      g.pieces[const HexCoord(1, 0)] = 1;     // jumped over (any color)
      // Landing at (2, 0) is empty.
      final moves = g.legalMoves(0);
      expect(moves.any((m) => m.isJump), isTrue);
    });

    test('apply move updates pieces map', () {
      final g = twoPlayerGame();
      final moves = g.legalMoves(0);
      final m = moves.first;
      g.applyMove(m);
      expect(g.pieces.containsKey(m.from), isFalse);
      expect(g.pieces[m.to], 0);
    });

    test('hasFinished detects a winning position', () {
      final g = twoPlayerGame();
      // Wipe player 0 pieces and fill goal triangle 0 with them.
      g.pieces.removeWhere((_, v) => v == 0);
      for (final c in Board.triangles[0]) {
        g.pieces[c] = 0;
      }
      expect(g.hasFinished(0), isTrue);
    });
  });

  group('Bot', () {
    test('bot returns a legal move from initial state', () {
      final g = GameState.initial([
        const Player(
          id: 0,
          startTriangle: 3,
          goalTriangle: 0,
          colorIndex: 0,
          isHuman: true,
          name: 'Вы',
        ),
        const Player(
          id: 1,
          startTriangle: 0,
          goalTriangle: 3,
          colorIndex: 1,
          isHuman: false,
          name: 'Бот',
        ),
      ]);
      final bot = Bot(Difficulty.hard);
      final move = bot.chooseMove(g, 1);
      expect(move, isNotNull);
      final legal = g.legalMoves(1);
      expect(legal.any((m) => identical(m, move) ||
              (m.from == move!.from && m.to == move.to)),
          isTrue);
    });

    test('a self-play game terminates within 500 plies', () {
      final game = GameState.initial([
        const Player(
          id: 0,
          startTriangle: 3,
          goalTriangle: 0,
          colorIndex: 0,
          isHuman: false,
          name: 'A',
        ),
        const Player(
          id: 1,
          startTriangle: 0,
          goalTriangle: 3,
          colorIndex: 1,
          isHuman: false,
          name: 'B',
        ),
      ]);
      final bots = [Bot(Difficulty.hard), Bot(Difficulty.hard)];
      int turns = 0;
      while (!game.gameOver && turns < 500) {
        final current = game.currentPlayer;
        final move = bots[current].chooseMove(game, current);
        if (move == null) {
          game.advanceTurn();
          continue;
        }
        game.applyMove(move);
        game.recordIfFinished(current);
        if (!game.gameOver) game.advanceTurn();
        turns++;
      }
      expect(game.gameOver, isTrue,
          reason: 'Bots looped without finishing after $turns plies');
      expect(game.winner, isNotNull);
    });
  });
}
