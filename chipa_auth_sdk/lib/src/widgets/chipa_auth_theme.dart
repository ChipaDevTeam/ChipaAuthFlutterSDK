import 'package:flutter/material.dart';

/// Controls the look of ChipaAuthWidget. All fields have sensible defaults
/// matching the web template's glassmorphism palette.
class ChipaAuthTheme {
  final Color primaryColor;
  final Color accentColor;
  final Color backgroundColor;
  final Color textColor;
  final Color errorColor;
  final double cardElevation;
  final double borderRadius;
  final String? fontFamily;

  const ChipaAuthTheme({
    this.primaryColor = const Color(0xFF667EEA),
    this.accentColor = const Color(0xFF764BA2),
    this.backgroundColor = Colors.white,
    this.textColor = const Color(0xFF1A1A2E),
    this.errorColor = const Color(0xFFE53E3E),
    this.cardElevation = 8,
    this.borderRadius = 16,
    this.fontFamily,
  });
}
