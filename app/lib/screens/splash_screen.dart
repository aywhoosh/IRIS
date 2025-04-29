import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'supabase_test_screen.dart'; //testing screen to test login and upload&fetch scans

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Delay for splash screen visibility
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.initialize();
    // final isAuthenticated = authProvider.isAuthenticated;
    final connectionTest = await authProvider.testSupabaseConnection();
    print("Supabase connection test result: $connectionTest");
    if (!mounted) return;

    // Use actual app navigation instead of test screen
    final isAuthenticated = authProvider.isAuthenticated;

    // Navigate based on authentication status
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) =>
            isAuthenticated ? const HomeScreen() : const LoginScreen(),
      ),
    );

    // Test screen navigation (commented out)
    // Navigator.of(context).pushReplacement(
    //   MaterialPageRoute(builder: (context) => const SupabaseTestScreen()),
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            // Comment out missing image for now to prevent loading issues
            // Image.asset(
            //   'assets/images/iris_logo.png',
            //   width: 150,
            //   height: 150,
            // ),
            const Icon(
              Icons.remove_red_eye,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            const Text(
              'IRIS',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Eye Diagnostic Tool',
              style: TextStyle(
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
