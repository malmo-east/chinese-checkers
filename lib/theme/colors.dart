import 'package:flutter/material.dart';

/// Minimalist palette: soft "2000s board game" colors on a near-black canvas.
class AppColors {
  static const Color background = Color(0xFF111114);
  static const Color surface = Color(0xFF1A1A1F);
  static const Color surfaceMuted = Color(0xFF22232A);
  static const Color outline = Color(0xFF34353D);
  static const Color text = Color(0xFFE9EAEE);
  static const Color textMuted = Color(0xFF8A8C95);
  static const Color accent = Color(0xFFE8B664);

  /// Six checker colors, in a triangle index order. Players choose freely.
  static const List<Color> piece = <Color>[
    Color(0xFFE15F5F), // 0 - coral red
    Color(0xFF6FAFE0), // 1 - sky blue
    Color(0xFF9ED36A), // 2 - moss green
    Color(0xFFE8B664), // 3 - warm gold
    Color(0xFFB58FE0), // 4 - lavender
    Color(0xFF6FD3D3), // 5 - aqua
  ];

  static const List<String> pieceName = <String>[
    'Коралл',
    'Небо',
    'Мох',
    'Золото',
    'Лаванда',
    'Аква',
  ];

  static Color emptyCell = const Color(0xFF2A2B33);
}
