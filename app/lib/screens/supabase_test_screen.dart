import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../providers/scan_provider.dart';

class SupabaseTestScreen extends StatefulWidget {
  const SupabaseTestScreen({super.key});

  @override
  State<SupabaseTestScreen> createState() => _SupabaseTestScreenState();
}

class _SupabaseTestScreenState extends State<SupabaseTestScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  String _result = 'No operation performed yet';
  List<Map<String, dynamic>> _scans = [];

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  Future<void> _testFetchScans() async {
    setState(() {
      _isLoading = true;
      _result = 'Fetching scans...';
    });

    try {
      final response = await _supabase
          .from('scans')
          .select('*, scan_results(*)')
          .order('created_at', ascending: false)
          .limit(10);

      setState(() {
        _scans = List<Map<String, dynamic>>.from(response);
        _result = 'Successfully fetched ${_scans.length} scans';
      });
    } catch (e) {
      setState(() {
        _result = 'Error fetching scans: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testCreateAccount() async {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty) {
      setState(() {
        _result = 'Please fill all fields';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _result = 'Creating account...';
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await authProvider.register(
        _emailController.text,
        _passwordController.text,
        _firstNameController.text,
        _lastNameController.text,
      );

      setState(() {
        _result = response.success
            ? 'Account created successfully!'
            : 'Error: ${response.message}';
      });
    } catch (e) {
      setState(() {
        _result = 'Error creating account: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _result = 'Please enter email and password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _result = 'Logging in...';
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await authProvider.login(
        _emailController.text,
        _passwordController.text,
      );

      setState(() {
        _result = response.success
            ? 'Logged in successfully!'
            : 'Error: ${response.message}';
      });
    } catch (e) {
      setState(() {
        _result = 'Error logging in: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testCreateTestScan() async {
    setState(() {
      _isLoading = true;
      _result = 'Creating test scan...';
    });

    try {
      // Check if logged in
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _result = 'Error: No user logged in';
        });
        return;
      }

      // Create a temporary file
      final tempDir = await getTemporaryDirectory();
      final testFile = File('${tempDir.path}/test_image.png');

      // Create a simple image (1x1 pixel)
      await testFile.writeAsBytes(
          List<int>.filled(1024, 0)); // Upload to Supabase storage

      // Check if mounted before accessing Provider
      if (!mounted) return;

      final scanProvider = Provider.of<ScanProvider>(context, listen: false);
      final response = await scanProvider.uploadEyeScan(testFile.path, 'left');

      // Check if mounted again before updating state
      if (!mounted) return;

      setState(() {
        _result = response.success
            ? 'Successfully created test scan with ID: ${response.data?.scanId}'
            : 'Error: ${response.message}';
      });

      // Refresh the list
      if (response.success) {
        _testFetchScans();
      }
    } catch (e) {
      setState(() {
        _result = 'Error creating test scan: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testLogout() async {
    setState(() {
      _isLoading = true;
      _result = 'Logging out...';
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();

      setState(() {
        _result = 'Logged out successfully!';
        _scans = [];
      });
    } catch (e) {
      setState(() {
        _result = 'Error logging out: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoggedIn = authProvider.isAuthenticated;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Supabase Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              'Supabase Connection Test',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),

            // Login/Registration Form
            if (!isLoggedIn) ...[
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              TextField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
              ),
              TextField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _testCreateAccount,
                      child: const Text('Create Account'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _testLogin,
                      child: const Text('Login'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // User info
              Text('Logged in as: ${authProvider.currentUser?.email}'),
              Text(
                  'Name: ${authProvider.currentUser?.firstName} ${authProvider.currentUser?.lastName}'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _isLoading ? null : _testFetchScans,
                child: const Text('Fetch Scans'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _isLoading ? null : _testCreateTestScan,
                child: const Text('Create Test Scan'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _isLoading ? null : _testLogout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Logout'),
              ),
            ],

            const SizedBox(height: 16),
            // Results display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_result),
            ),

            const SizedBox(height: 16),
            // Scans list
            if (_scans.isNotEmpty) ...[
              Text(
                'Scans:',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              for (final scan in _scans)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text('Scan ID: ${scan['id']}'),
                    subtitle: Text(
                        'Eye Side: ${scan['eye_side']} • Status: ${scan['status']}\n'
                        'Created: ${scan['created_at'] != null ? DateTime.parse(scan['created_at']).toString().substring(0, 16) : 'Unknown'}'),
                    isThreeLine: true,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
