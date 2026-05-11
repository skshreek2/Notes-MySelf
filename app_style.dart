import 'package:flutter/material.dart';

class AppStyles {

  // Base Gradient (135deg)
  static const LinearGradient baseGradient =
      LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFEFF6FF),
      Color(0xFFFAF5FF),
    ],
  );

  // Overlay Gradient (90deg)
  static const LinearGradient overlayGradient =
      LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color.fromRGBO(230, 237, 255, 0.60),
      Color.fromRGBO(157, 183, 249, 0.60),
    ],
    stops: [0.5244, 0.9723],
  );

  static const BorderRadius screenRadius =
      BorderRadius.only(
    topLeft: Radius.circular(24),
    topRight: Radius.circular(24),
  );

  static const EdgeInsets screenPadding =
      EdgeInsets.all(48);

  static const double screenGap = 24;
}
