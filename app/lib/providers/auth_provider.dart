import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/supabase/supabase_service.dart';
import '../services/api/api_response.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class AuthProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;

  // User state
  User? _currentUser;
  User? get currentUser => _currentUser;
  User? get user => _currentUser; // Alias for backward compatibility

  // Status getters for backward compatibility
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Authentication state
  bool get isAuthenticated => _currentUser != null;
  // Initialize auth state
  Future<void> initialize() async {
    if (_isInitialized) return;

    _setLoading(true);
    try {
      _currentUser = _supabaseService.currentUser;
      _isInitialized = true;
    } catch (e) {
      _setError('Failed to initialize: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
    notifyListeners();
  }

  // Register a new user
  Future<ApiResponse<User>> register(
    String email,
    String password,
    String firstName,
    String lastName,
  ) async {
    _setLoading(true);
    _clearError();

    try {
      await _supabaseService.signUp(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );

      _currentUser = _supabaseService.currentUser;
      notifyListeners();

      return ApiResponse.success(_currentUser,
          message: 'Registration successful');
    } catch (e) {
      _setError(e.toString());
      return ApiResponse.error('Registration failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Sign in an existing user
  Future<ApiResponse<User>> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      await _supabaseService.signIn(
        email: email,
        password: password,
      );

      _currentUser = _supabaseService.currentUser;
      notifyListeners();

      return ApiResponse.success(_currentUser, message: 'Login successful');
    } catch (e) {
      _setError(e.toString());
      return ApiResponse.error('Login failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Sign out
  Future<void> logout() async {
    _setLoading(true);

    try {
      await _supabaseService.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _setError('Logout failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Password reset
  Future<void> resetPassword(String email) async {
    _setLoading(true);

    try {
      await _supabaseService.resetPassword(email);
    } catch (e) {
      _setError('Password reset failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Update user profile
  Future<void> updateProfile({
    required String firstName,
    required String lastName,
  }) async {
    _setLoading(true);

    try {
      await _supabaseService.updateProfile(
        firstName: firstName,
        lastName: lastName,
      );

      // Refresh user after update
      _currentUser = _supabaseService.currentUser;
      notifyListeners();
    } catch (e) {
      _setError('Profile update failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Test Supabase Connection
  Future<bool> testSupabaseConnection() async {
    try {
      // Try to get the current session
      final session = supabase.Supabase.instance.client.auth.currentSession;
      debugPrint(
          "Supabase connection test: ${session != null ? 'Active session found' : 'No active session'}");
      return true;
    } catch (e) {
      debugPrint("Supabase connection test failed: $e");
      return false;
    }
  }

  // Helper methods for backward compatibility
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
