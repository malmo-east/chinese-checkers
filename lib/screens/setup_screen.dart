import 'package:flutter/material.dart';

import '../ai/bot.dart';
import '../theme/colors.dart';
import 'game_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  int _botCount = 1; // 1, 2, 3 or 5 bots (= 2, 3, 4 or 6 players)
  Difficulty _difficulty = Difficulty.medium;
  int _humanColor = 3; // gold

  static const _botOptions = <int>[1, 2, 3, 5];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Новая партия'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: theme.textTheme.titleLarge,
        iconTheme: const IconThemeData(color: AppColors.text),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SectionLabel(text: 'Соперники'),
              const SizedBox(height: 10),
              _SegmentedRow<int>(
                values: _botOptions,
                labels: _botOptions.map((b) => '$b').toList(),
                selected: _botCount,
                onChanged: (v) => setState(() => _botCount = v),
              ),
              const SizedBox(height: 6),
              Text(
                'Игроков всего: ${_botCount + 1} · все, кроме вас — боты',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 28),

              const _SectionLabel(text: 'Сложность'),
              const SizedBox(height: 10),
              _SegmentedRow<Difficulty>(
                values: Difficulty.values,
                labels: Difficulty.values.map((d) => d.label).toList(),
                selected: _difficulty,
                onChanged: (v) => setState(() => _difficulty = v),
              ),
              const SizedBox(height: 6),
              Text(
                _difficultyHint(_difficulty),
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 28),

              const _SectionLabel(text: 'Цвет фишек'),
              const SizedBox(height: 10),
              _ColorPicker(
                selected: _humanColor,
                onChanged: (c) => setState(() => _humanColor = c),
              ),
              const SizedBox(height: 6),
              Text(
                AppColors.pieceName[_humanColor],
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textMuted),
              ),

              const Spacer(),
              FilledButton(
                onPressed: _start,
                child: const Text('НАЧАТЬ ИГРУ'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _difficultyHint(Difficulty d) {
    switch (d) {
      case Difficulty.easy:
        return 'Боты часто играют расслабленно.';
      case Difficulty.medium:
        return 'Уверенный темп, без хитростей.';
      case Difficulty.hard:
        return 'Боты ведут свои фишки чётко к цели.';
    }
  }

  void _start() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          botCount: _botCount,
          difficulty: _difficulty,
          humanColor: _humanColor,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 12,
        letterSpacing: 1.4,
      ),
    );
  }
}

class _SegmentedRow<T> extends StatelessWidget {
  final List<T> values;
  final List<String> labels;
  final T selected;
  final ValueChanged<T> onChanged;

  const _SegmentedRow({
    required this.values,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline, width: 1),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          for (int i = 0; i < values.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(values[i]),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: values[i] == selected
                        ? AppColors.accent
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      color: values[i] == selected
                          ? Colors.black
                          : AppColors.text,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _ColorPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (int i = 0; i < AppColors.piece.length; i++)
          GestureDetector(
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.piece[i],
                shape: BoxShape.circle,
                border: Border.all(
                  color: i == selected ? AppColors.text : Colors.transparent,
                  width: 2.5,
                ),
                boxShadow: i == selected
                    ? [
                        BoxShadow(
                          color: AppColors.piece[i].withOpacity(0.35),
                          blurRadius: 14,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}
