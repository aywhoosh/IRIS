import 'package:flutter/material.dart';

class IrisColors {
  // Primary and secondary colors
  static const Color primary = Color(0xFF1E88E5); // Medical Blue
  static const Color secondary = Color(0xFF42A5F5); // Lighter Blue
  static const Color tertiary = Color(0xFF64B5F6); // Even Lighter Blue

  // Accent colors
  static const Color accent = Color(0xFF26A69A); // Teal

  // Background colors
  static const Color background =
      Color(0xFFF5F7FA); // Light Grey with blue undertone
  static final Color backgroundAlt =
      const Color(0xFFE3F2FD); // Light Blue Background

  // Text colors
  static const Color textPrimary = Color(0xFF263238); // Dark Grey for text
  static const Color textSecondary =
      Color(0xFF546E7A); // Medium Grey for secondary text
  static const Color textLight =
      Color(0xFF78909C); // Light Grey for tertiary text
  static const Color textOnDark =
      Color(0xFFFFFFFF); // White text for dark backgrounds

  // Status colors
  static const Color success = Color(0xFF66BB6A); // Green for success states
  static const Color warning = Color(0xFFFFB74D); // Orange for warning states
  static const Color error = Color(0xFFEF5350); // Red for error states
  static const Color info = Color(0xFF42A5F5); // Blue for info states

  // Health status colors (for scan history and diagnostic results)
  static const Color healthNormal = Color(0xFF4CAF50); // Green for healthy
  static const Color healthWarning =
      Color(0xFFFFC107); // Amber for mild conditions
  static const Color healthAlert =
      Color(0xFFE53935); // Red for serious conditions
  static const Color healthUnknown =
      Color(0xFF9E9E9E); // Grey for unknown status

  // Aurora color schemes
  static final auroraStandard = AuroraColorScheme(
    primary: const Color(0xFF42A5F5),
    secondary: const Color(0xFF26C6DA),
    background: const Color(0xFFE3F2FD),
  );

  static final auroraWarning = AuroraColorScheme(
    primary: const Color(0xFFFFB74D),
    secondary: const Color(0xFFFFD54F),
    background: const Color(0xFFFFF8E1),
  );

  static final auroraAlert = AuroraColorScheme(
    primary: const Color(0xFFEF5350),
    secondary: const Color(0xFFE57373),
    background: const Color(0xFFFFEBEE),
  );

  static final auroraSuccess = AuroraColorScheme(
    primary: const Color(0xFF66BB6A),
    secondary: const Color(0xFF81C784),
    background: const Color(0xFFE8F5E9),
  );

  // Get aurora color scheme based on health status
  static AuroraColorScheme getAuroraForHealthStatus(String condition) {
    // Default to standard scheme
    if (condition.isEmpty) return auroraStandard;

    // Convert condition to lowercase for case-insensitive comparison
    final lowerCondition = condition.toLowerCase();

    // Check for keywords indicating severity
    if (lowerCondition.contains('healthy') ||
        lowerCondition.contains('normal')) {
      return auroraSuccess;
    } else if (lowerCondition.contains('mild') ||
        lowerCondition.contains('moderate') ||
        lowerCondition.contains('cataract')) {
      return auroraWarning;
    } else if (lowerCondition.contains('severe') ||
        lowerCondition.contains('advanced') ||
        lowerCondition.contains('glaucoma') ||
        lowerCondition.contains('diabetic retinopathy')) {
      return auroraAlert;
    }

    // Default to standard
    return auroraStandard;
  }
}

class AuroraColorScheme {
  final Color primary;
  final Color secondary;
  final Color background;

  AuroraColorScheme({
    required this.primary,
    required this.secondary,
    required this.background,
  });
}
