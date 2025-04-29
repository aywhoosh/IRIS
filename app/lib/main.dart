import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io' show Platform;
import 'providers/auth_provider.dart';
import 'package:flutter/services.dart';
import 'providers/scan_provider.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'utils/constants.dart';
import 'navigation/app_router.dart';

// Add global key to help with graphics contexts
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Prevent screen rotation to reduce raster thread issues
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Apply platform-specific optimizations
  if (Platform.isAndroid) {
    // Properly configure Android for camera image handling
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Add GL-error prevention flags
    const methodChannel =
        MethodChannel('com.example.iris_flutter_app/settings');
    try {
      await methodChannel.invokeMethod('disableImpeller');

      // Additional settings to prevent raster thread crashes
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);

      // Reduce graphics pressure
      PaintingBinding.instance.imageCache.maximumSize =
          20; // Reduce image cache
      PaintingBinding.instance.imageCache.maximumSizeBytes =
          20 * 1024 * 1024; // 20 MB limit
    } catch (e) {
      print('Error configuring GPU optimizations: $e');
    }
  }

  // Initialize Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // Set up error handling for Flutter errors
  FlutterError.onError = (FlutterErrorDetails details) {
    // Log the error (you could send this to a logging service)
    print('Flutter error caught: ${details.exception}');
    FlutterError.presentError(details);
  };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ScanProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp(
            title: 'IRIS Eye Diagnostic',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            // Use the router for navigation with named routes
            onGenerateRoute: AppRouter.generateRoute,
            // Add navigator key for global access
            navigatorKey: navigatorKey,
            // Start with splash screen
            home: const SplashScreen(),
            // Add error handling
            builder: (context, child) {
              // Error handling widget wrapper
              ErrorWidget.builder = (FlutterErrorDetails details) {
                return SafeArea(
                  child: Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Theme.of(context).colorScheme.error,
                            size: 60,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'An error occurred.',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (context) => const SplashScreen(),
                                ),
                                (route) => false,
                              );
                            },
                            child: const Text('Restart App'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              };
              return child ?? const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }
}
