import 'package:flutter/material.dart';

/// A single player slot in a game.
@immutable
class Player {
  final int id;
  final int startTriangle;
  final int goalTriangle;
  final int colorIndex;
  final bool isHuman;
  final String name;

  const Player({
    required this.id,
    required this.startTriangle,
    required this.goalTriangle,
    required this.colorIndex,
    required this.isHuman,
    required this.name,
  });
}
