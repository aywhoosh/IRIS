import 'package:flutter/material.dart';
import '../screens/enhanced_camera_screen.dart';
import '../screens/processing_screen.dart';
import '../screens/results_screen.dart';
import '../screens/history_screen.dart';
import '../screens/profile_screen.dart';

/// This class manages all navigation in the app to ensure
/// enhanced screens are used consistently throughout the app.
class AppRouter {
  // Main app routes
  static const String home = '/';
  static const String camera = '/camera';
  static const String processing = '/processing';
  static const String results = '/results';
  static const String history = '/history';
  static const String profile = '/profile';

  // Generate route factory method
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case camera:
        return MaterialPageRoute(
          builder: (_) => const EnhancedCameraScreen(),
        );

      case processing:
        final args = settings.arguments as ProcessingScreenArguments;
        return MaterialPageRoute(
          builder: (_) => ProcessingScreen(
            imagePath: args.imagePath,
            eyeSide: args.eyeSide,
          ),
        );

      case results:
        final args = settings.arguments as ResultsScreenArguments;
        return MaterialPageRoute(
          builder: (_) => ResultsScreen(
            scanId: args.scanId,
          ),
        );

      case history:
        return MaterialPageRoute(
          builder: (_) => const HistoryScreen(),
        );

      case profile:
        return MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
        );

      default:
        // Default to the camera screen as home
        return MaterialPageRoute(
          builder: (_) => const EnhancedCameraScreen(),
        );
    }
  }

  // Navigator helpers
  static void navigateToCamera(BuildContext context) {
    Navigator.pushNamed(context, camera);
  }

  static void navigateToProcessing(
      BuildContext context, String imagePath, String eyeSide) {
    Navigator.pushNamed(
      context,
      processing,
      arguments: ProcessingScreenArguments(imagePath, eyeSide),
    );
  }

  static void navigateToResults(BuildContext context, String scanId) {
    Navigator.pushNamed(
      context,
      results,
      arguments: ResultsScreenArguments(scanId),
    );
  }

  static void navigateToHistory(BuildContext context) {
    Navigator.pushNamed(context, history);
  }

  static void navigateToProfile(BuildContext context) {
    Navigator.pushNamed(context, profile);
  }
}

// Arguments classes for routes that need parameters
class ProcessingScreenArguments {
  final String imagePath;
  final String eyeSide;

  ProcessingScreenArguments(this.imagePath, this.eyeSide);
}

class ResultsScreenArguments {
  final String scanId;

  ResultsScreenArguments(this.scanId);
}
