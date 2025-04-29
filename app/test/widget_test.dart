import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:iris_app/screens/home_screen.dart';
import 'package:iris_app/screens/camera_screen.dart';
import 'package:iris_app/screens/processing_screen.dart';
import 'package:iris_app/screens/results_screen.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    final fontLoader = FontLoader('Inter');
    fontLoader.addFont(Future.value(ByteData(0))); // Mock empty font data
  });

  setUpAll(() async {
    // Create mock assets
    const manifestJson =
        '{"packages/google_fonts/fonts/Inter-Regular.ttf":["packages/google_fonts/fonts/Inter-Regular.ttf"]}';
    final ByteData manifestData =
        ByteData.sublistView(Uint8List.fromList(manifestJson.codeUnits));

    // Create a mock shader that mimics the real GLSL shader structure
    const String mockShader = '''#version 460 core
    #include <flutter/runtime_effect.glsl>
    
    layout(location = 0) uniform float iWidth;
    layout(location = 1) uniform float iHeight;
    layout(location = 2) uniform float iTime;
    
    out vec4 fragColor;
    
    void main() {
      fragColor = vec4(1.0, 1.0, 1.0, 1.0);
    }
    ''';

    final ByteData shaderData = ByteData(mockShader.length)
      ..buffer.asUint8List().setAll(0, mockShader.codeUnits);

    // Create a simple valid SVG for testing
    const String mockSvg = '''
      <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
        <circle cx="12" cy="12" r="10" fill="currentColor"/>
      </svg>
    ''';
    final ByteData svgData =
        ByteData.sublistView(Uint8List.fromList(mockSvg.codeUnits));

    // Set up asset loading
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
      'flutter/assets',
      (ByteData? message) async {
        if (message == null) return null;
        final String key = utf8.decode(message.buffer.asUint8List());

        // Return appropriate mock data based on asset type
        switch (key) {
          case 'AssetManifest.json':
          case 'FontManifest.json':
            return manifestData;
          case 'shaders/mesh_gradient.glsl':
            return shaderData;
          default:
            if (key.endsWith('.svg')) {
              return svgData;
            }
            // Return empty data for other assets
            return ByteData(0);
        }
      },
    );
  });

  testWidgets('IRIS App Flow Test', (WidgetTester tester) async {
    // Create a test app with GoRouter for navigation
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeScreen(),
            ),
            GoRoute(
              path: '/camera',
              builder: (context, state) => const CameraScreen(),
            ),
            GoRoute(
              path: '/processing',
              builder: (context, state) => ProcessingScreen(
                imagePath: state.extra as String? ?? '',
                eyeSide: 'unknown', // Default for testing
              ),
            ),
            GoRoute(
              path: '/results',
              builder: (context, state) => ResultsScreen(scanId: 'test-id'),
            ),
          ],
        ),
      ),
    );

    // Wait for any animations to complete
    await tester.pumpAndSettle();

    // Verify that we start on the home screen
    expect(find.byType(HomeScreen), findsOneWidget);

    // Verify home screen elements are present
    expect(find.text('IRIS'), findsOneWidget);
    expect(find.text('AI-Powered Eye Disease Detection'), findsOneWidget);

    // Verify navigation elements exist
    expect(find.byIcon(Icons.camera_alt), findsOneWidget);
  });
}
