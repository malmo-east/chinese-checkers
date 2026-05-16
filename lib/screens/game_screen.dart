import 'dart:async';

import 'package:flutter/material.dart';

import '../ai/bot.dart';
import '../models/board.dart';
import '../models/game_state.dart';
import '../models/hex_coord.dart';
import '../models/move.dart';
import '../models/player.dart';
import '../theme/colors.dart';
import '../widgets/board_view.dart';
import 'home_screen.dart';

class GameScreen extends StatefulWidget {
  final int botCount;
  final Difficulty difficulty;
  final int humanColor;

  const GameScreen({
    super.key,
    required this.botCount,
    required this.difficulty,
    required this.humanColor,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late GameState _game;
  late List<Bot?> _bots; // null = human
  int _humanId = 0;

  HexCoord? _selected;
  Map<HexCoord, Move> _destinations = <HexCoord, Move>{};

  late final AnimationController _anim;
  Move? _animatingMove;
  Timer? _botTimer;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this)
      ..addListener(() => setState(() {}))
      ..addStatusListener(_onAnimStatus);
    _initGame();
    _maybeStartBot();
  }

  @override
  void dispose() {
    _botTimer?.cancel();
    _anim.dispose();
    super.dispose();
  }

  void _initGame() {
    final assignment = _triangleAssignmentFor(widget.botCount + 1);
    // Human is always at triangle 3 (bottom of the screen).
    const humanTri = 3;
    assert(assignment.contains(humanTri));
    final botTris = assignment.where((t) => t != humanTri).toList();

    final availColors = [for (int i = 0; i < AppColors.piece.length; i++) i]
      ..remove(widget.humanColor);

    final players = <Player>[
      Player(
        id: 0,
        startTriangle: humanTri,
        goalTriangle: Board.oppositeTriangle(humanTri),
        colorIndex: widget.humanColor,
        isHuman: true,
        name: 'Вы',
      ),
    ];

    for (int i = 0; i < botTris.length; i++) {
      players.add(
        Player(
          id: i + 1,
          startTriangle: botTris[i],
          goalTriangle: Board.oppositeTriangle(botTris[i]),
          colorIndex: availColors[i],
          isHuman: false,
          name: 'Бот ${i + 1}',
        ),
      );
    }

    _humanId = 0;
    _game = GameState.initial(players);
    _bots = players
        .map<Bot?>((p) => p.isHuman ? null : Bot(widget.difficulty))
        .toList();
  }

  List<int> _triangleAssignmentFor(int playerCount) {
    switch (playerCount) {
      case 2:
        return const [3, 0];
      case 3:
        return const [3, 1, 5];
      case 4:
        return const [3, 0, 1, 4];
      case 6:
        return const [3, 0, 1, 2, 4, 5];
      default:
        throw ArgumentError('Unsupported player count $playerCount');
    }
  }

  void _maybeStartBot() {
    if (_game.gameOver) return;
    final current = _game.currentPlayer;
    if (current < 0) return;
    final bot = _bots[current];
    if (bot == null) return;
    _botTimer?.cancel();
    _botTimer = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      final move = bot.chooseMove(_game, current);
      if (move == null) {
        _game.advanceTurn();
        setState(() {});
        _maybeStartBot();
      } else {
        _startAnimation(move);
      }
    });
  }

  void _startAnimation(Move m) {
    if (_animatingMove != null) return;
    final segments = m.path.length - 1;
    _animatingMove = m;
    _anim.duration = Duration(milliseconds: 220 * segments);
    _anim.forward(from: 0);
  }

  void _onAnimStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    final m = _animatingMove;
    if (m == null) return;
    setState(() {
      _animatingMove = null;
      _game.applyMove(m);
      _game.recordIfFinished(_game.currentPlayer);
      _selected = null;
      _destinations = <HexCoord, Move>{};
      if (!_game.gameOver) {
        _game.advanceTurn();
      }
    });
    if (!_game.gameOver) _maybeStartBot();
  }

  void _onCellTap(HexCoord cell) {
    if (_animatingMove != null) return;
    if (_game.gameOver) return;
    if (_game.currentPlayer != _humanId) return;

    final ownerId = _game.pieces[cell];
    if (ownerId == _humanId) {
      setState(() {
        if (_selected == cell) {
          _selected = null;
          _destinations = <HexCoord, Move>{};
        } else {
          _selected = cell;
          _destinations = _buildDestinations(cell);
        }
      });
      return;
    }

    if (_destinations.containsKey(cell)) {
      final m = _destinations[cell]!;
      _selected = null;
      _destinations = <HexCoord, Move>{};
      _startAnimation(m);
      return;
    }

    // Tap on empty / opponent piece without a selection clears.
    if (_selected != null) {
      setState(() {
        _selected = null;
        _destinations = <HexCoord, Move>{};
      });
    }
  }

  Map<HexCoord, Move> _buildDestinations(HexCoord from) {
    final result = <HexCoord, Move>{};
    for (final m in _game.legalMoves(_humanId)) {
      if (m.from != from) continue;
      final existing = result[m.to];
      // Prefer longer jump chains visually (more satisfying).
      if (existing == null || m.path.length > existing.path.length) {
        result[m.to] = m;
      }
    }
    return result;
  }

  void _restart() {
    _botTimer?.cancel();
    _anim.stop();
    setState(() {
      _animatingMove = null;
      _selected = null;
      _destinations = <HexCoord, Move>{};
      _initGame();
    });
    _maybeStartBot();
  }

  @override
  Widget build(BuildContext context) {
    final currentPlayer = _game.currentPlayer >= 0
        ? _game.players[_game.currentPlayer]
        : _game.players[_humanId];
    final isHumanTurn = _game.currentPlayer == _humanId && !_game.gameOver;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _TopBar(
                  current: currentPlayer,
                  isHumanTurn: isHumanTurn,
                  onMenu: _confirmExit,
                  onRestart: _restart,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: AspectRatio(
                      aspectRatio: 13 * 1.732 / 26, // width / height
                      child: BoardView(
                        game: _game,
                        humanId: _humanId,
                        selected: _selected,
                        validDestinations: _destinations.keys.toSet(),
                        activePlayer: _game.currentPlayer,
                        animatingMove: _animatingMove,
                        animationValue: _anim.value,
                        onTap: _onCellTap,
                      ),
                    ),
                  ),
                ),
                _StatusFooter(
                  game: _game,
                  humanId: _humanId,
                  isHumanTurn: isHumanTurn,
                  hasSelection: _selected != null,
                ),
                const SizedBox(height: 8),
              ],
            ),
            if (_game.gameOver) _GameOverOverlay(
              game: _game,
              humanId: _humanId,
              onPlayAgain: _restart,
              onMenu: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (_) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmExit() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Выйти в меню?', style: TextStyle(color: AppColors.text)),
        content: const Text(
          'Текущая партия будет потеряна.',
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Остаться'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
    if (shouldExit == true && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    }
  }
}

class _TopBar extends StatelessWidget {
  final Player current;
  final bool isHumanTurn;
  final VoidCallback onMenu;
  final VoidCallback onRestart;

  const _TopBar({
    required this.current,
    required this.isHumanTurn,
    required this.onMenu,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            color: AppColors.text,
            onPressed: onMenu,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.outline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.piece[current.colorIndex],
                    shape: BoxShape.circle,
                    boxShadow: isHumanTurn
                        ? [
                            BoxShadow(
                              color: AppColors.piece[current.colorIndex]
                                  .withOpacity(0.55),
                              blurRadius: 8,
                              spreadRadius: 1.5,
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${current.name} · ходит',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.restart_alt, size: 20),
            color: AppColors.text,
            tooltip: 'Заново',
            onPressed: onRestart,
          ),
        ],
      ),
    );
  }
}

class _StatusFooter extends StatelessWidget {
  final GameState game;
  final int humanId;
  final bool isHumanTurn;
  final bool hasSelection;

  const _StatusFooter({
    required this.game,
    required this.humanId,
    required this.isHumanTurn,
    required this.hasSelection,
  });

  String _hint() {
    if (game.gameOver) return '';
    if (!isHumanTurn) return 'Соперник обдумывает ход…';
    if (hasSelection) return 'Коснитесь подсвеченной точки, чтобы пойти';
    return 'Выберите свою фишку';
  }

  @override
  Widget build(BuildContext context) {
    final hint = _hint();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 18,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final p in game.players)
                _PlayerChip(
                  player: p,
                  isYou: p.id == humanId,
                  isActive: game.currentPlayer == p.id,
                  finished: game.finishOrder.contains(p.id),
                ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 32,
            child: Center(
              child: Text(
                hint,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerChip extends StatelessWidget {
  final Player player;
  final bool isYou;
  final bool isActive;
  final bool finished;

  const _PlayerChip({
    required this.player,
    required this.isYou,
    required this.isActive,
    required this.finished,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.piece[player.colorIndex];
    return Opacity(
      opacity: finished ? 0.45 : (isActive ? 1.0 : 0.7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? AppColors.text : Colors.transparent,
                width: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isYou ? 'Вы' : '#${player.id}',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  final GameState game;
  final int humanId;
  final VoidCallback onPlayAgain;
  final VoidCallback onMenu;

  const _GameOverOverlay({
    required this.game,
    required this.humanId,
    required this.onPlayAgain,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final winner = game.winner;
    final humanWon = winner == humanId;
    final winnerName = winner != null ? game.players[winner].name : '—';
    final winnerColor = winner != null
        ? AppColors.piece[game.players[winner].colorIndex]
        : AppColors.text;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.78),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.outline),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: winnerColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  humanWon ? 'Победа!' : 'Партия окончена',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  humanWon
                      ? 'Все ваши фишки в цели.'
                      : 'Первым финишировал: $winnerName',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onMenu,
                        child: const Text('Меню'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: onPlayAgain,
                        child: const Text('Ещё'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
