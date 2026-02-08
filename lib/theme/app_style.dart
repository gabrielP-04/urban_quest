import 'package:flutter/material.dart';

class AppStyles {
  static BorderRadius cardRadius = BorderRadius.circular(16);

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];
}