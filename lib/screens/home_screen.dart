import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/colors.dart';
import 'setup_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const _Logo(),
              const SizedBox(height: 24),
              Text(
                'КИТАЙСКИЕ\nШАШКИ',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 12),
              Text(
                'Тихая партия для двоих, троих,\nчетверых или шестерых',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textMuted, height: 1.4),
              ),
              const Spacer(flex: 2),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SetupScreen()),
                  );
                },
                child: const Text('ИГРАТЬ'),
              ),
              const SizedBox(height: 24),
              Text(
                'v1.0 · оффлайн · без рекламы',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 120,
        height: 120,
        child: CustomPaint(painter: _StarPainter()),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide * 0.42;

    final stroke = Paint()
      ..color = AppColors.outline
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // Faint hexagon outline.
    final hex = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * math.pi / 180;
      final dx = center.dx + r * math.cos(angle);
      final dy = center.dy + r * math.sin(angle);
      if (i == 0) {
        hex.moveTo(dx, dy);
      } else {
        hex.lineTo(dx, dy);
      }
    }
    hex.close();
    canvas.drawPath(hex, stroke);

    // Colored peg per triangle.
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 90) * math.pi / 180;
      final dx = center.dx + r * 0.95 * math.cos(angle);
      final dy = center.dy + r * 0.95 * math.sin(angle);
      canvas.drawCircle(
        Offset(dx, dy),
        r * 0.18,
        Paint()..color = AppColors.piece[i],
      );
    }

    // Soft central dot for the accent.
    canvas.drawCircle(
      center,
      r * 0.14,
      Paint()..color = AppColors.accent.withOpacity(0.9),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
