import 'package:flutter/material.dart';

enum RainbowColor { red, blue, green, yellow, purple }

extension RainbowColorExt on RainbowColor {
  String get displayName {
    switch (this) {
      case RainbowColor.red:
        return 'Red';
      case RainbowColor.blue:
        return 'Blue';
      case RainbowColor.green:
        return 'Green';
      case RainbowColor.yellow:
        return 'Yellow';
      case RainbowColor.purple:
        return 'Purple';
    }
  }

  Color get color {
    switch (this) {
      case RainbowColor.red:
        return const Color(0xFFFF4444);
      case RainbowColor.blue:
        return const Color(0xFF4AA8FF);
      case RainbowColor.green:
        return const Color(0xFF6BE35F);
      case RainbowColor.yellow:
        return const Color(0xFFFFD84D);
      case RainbowColor.purple:
        return const Color(0xFF9B59FF);
    }
  }

  Color get darkColor {
    switch (this) {
      case RainbowColor.red:
        return const Color(0xFFCC2222);
      case RainbowColor.blue:
        return const Color(0xFF2277CC);
      case RainbowColor.green:
        return const Color(0xFF3CAB31);
      case RainbowColor.yellow:
        return const Color(0xFFE6A800);
      case RainbowColor.purple:
        return const Color(0xFF6C4DFF);
    }
  }

  int get missionNumber => index + 1;

  String get missionTitle => 'FIND ${displayName.toUpperCase()}';

  String get missionInstruction => 'Find something ${displayName.toLowerCase()}.';

  String get successMessage =>
      'Wow! You found something ${displayName.toLowerCase()}!';

  String get retryMessage =>
      "Oops! Let's keep looking for something ${displayName.toLowerCase()}!";

  List<String> get examples {
    switch (this) {
      case RainbowColor.red:
        return ['Apple', 'Book', 'Balloon', 'Shirt'];
      case RainbowColor.blue:
        return ['Bottle', 'Book', 'Cap', 'Pillow'];
      case RainbowColor.green:
        return ['Leaf', 'Toy', 'Notebook', 'Vegetable'];
      case RainbowColor.yellow:
        return ['Banana', 'Ball', 'Star', 'Notebook'];
      case RainbowColor.purple:
        return ['Crayon', 'Toy', 'Bag', 'Cloth'];
    }
  }

  String get emoji {
    switch (this) {
      case RainbowColor.red:
        return '🍎';
      case RainbowColor.blue:
        return '💧';
      case RainbowColor.green:
        return '🌿';
      case RainbowColor.yellow:
        return '⭐';
      case RainbowColor.purple:
        return '🔮';
    }
  }
}

class Discovery {
  final String imagePath;
  final String objectLabel;
  final String detectedColor;
  final RainbowColor targetColor;
  final DateTime discoveredAt;

  Discovery({
    required this.imagePath,
    required this.objectLabel,
    required this.detectedColor,
    required this.targetColor,
    required this.discoveredAt,
  });
}
