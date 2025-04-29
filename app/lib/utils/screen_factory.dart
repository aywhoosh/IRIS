// This file centralizes access to screens to make it easy to toggle between
// old and new UI implementations throughout the app
import 'package:flutter/material.dart';

// Import both versions of screens
import '../screens/camera_screen.dart';
import '../screens/enhanced_camera_screen.dart';
import '../screens/processing_screen.dart';

// Set this to true to use enhanced UI screens
const bool useEnhancedUI = true;

// Camera screen factory
Widget getCameraScreen() {
  return useEnhancedUI ? const EnhancedCameraScreen() : const CameraScreen();
}

// Processing screen factory
Widget getProcessingScreen(
    {required String imagePath, required String eyeSide}) {
  return useEnhancedUI
      ? ProcessingScreen(
          imagePath: imagePath,
          eyeSide: eyeSide,
        )
      : ProcessingScreen(
          imagePath: imagePath,
          eyeSide: eyeSide,
        );
}
