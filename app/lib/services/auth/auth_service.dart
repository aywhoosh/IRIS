import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../../utils/constants.dart';

/// Service responsible for user authentication logic.
/// Interacts with the ApiClient and secure storage.
class AuthService {
  final ApiClient _apiClient;
  final FlutterSecureStorage _secureStorage;

  // StreamController to notify listeners about authentication status changes.
  // Use broadcast stream to allow multiple listeners.
  final StreamController<bool> _authChangeController =
      StreamController<bool>.broadcast();

  AuthService(
      {required ApiClient apiClient, FlutterSecureStorage? secureStorage})
      : _apiClient = apiClient,
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Stream indicating whether the user is currently authenticated.
  /// Emits true when logged in, false when logged out.
  Stream<bool> get authStateChanges => _authChangeController.stream;

  /// Checks if the user is currently authenticated by verifying token presence.
  /// Note: This doesn't validate the token against the backend, only checks local storage.
  Future<bool> isAuthenticated() async {
    final token = await _secureStorage.read(key: AppConstants.authTokenKey);
    return token != null;
  }

  /// Process API response and handle errors
  dynamic _processResponse(dynamic response) {
    if (response == null) {
      throw ApiException('No response from server');
    }

    if (response is Map && response['success'] == false) {
      throw ApiException(response['message'] ?? 'Unknown error occurred',
          statusCode: response['statusCode'], data: response['data']);
    }

    return response;
  }

  /// Attempts to log in the user with email and password.
  /// Stores tokens securely on success.
  /// Throws [ApiException] on failure.
  Future<void> login(String email, String password) async {
    try {
      final response = await _apiClient.post(
        '/auth/login', // Or use AppConstants.loginEndpoint
        body: {'email': email, 'password': password},
      );
      final responseData =
          _processResponse(response); // Throws ApiException on error

      final accessToken = responseData['data']?['accessToken'];
      final refreshToken = responseData['data']?['refreshToken'];

      if (accessToken != null && refreshToken != null) {
        await _storeTokens(accessToken, refreshToken);
        _authChangeController.add(true); // Notify listeners of login
        debugPrint('AuthService: Login successful.');
      } else {
        debugPrint('AuthService: Login response missing tokens.');
        throw ApiException('Login failed: Invalid response from server.');
      }
    } on ApiException {
      rethrow; // Re-throw API exceptions for UI handling
    } catch (e) {
      debugPrint('AuthService: Unexpected login error: $e');
      throw ApiException('An unexpected error occurred during login.');
    }
  }

  /// Attempts to register a new user.
  /// Stores tokens securely on success (if backend returns them on register).
  /// Throws [ApiException] on failure.
  Future<void> register({
    required String name,
    required String email,
    required String password,
    String role = 'patient', // Default role, adjust if needed
  }) async {
    try {
      final response = await _apiClient.post(
        '/auth/register', // Or use AppConstants.registerEndpoint
        body: {
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        },
      );
      final responseData =
          _processResponse(response); // Throws ApiException on error

      // Assuming the backend sends tokens upon successful registration
      final accessToken = responseData['data']?['accessToken'];
      final refreshToken = responseData['data']?['refreshToken'];

      if (accessToken != null && refreshToken != null) {
        await _storeTokens(accessToken, refreshToken);
        _authChangeController.add(true); // Notify listeners of login
        debugPrint('AuthService: Registration successful.');
      } else {
        // If backend doesn't return tokens on register, just confirm success
        debugPrint(
            'AuthService: Registration successful (no tokens returned). User should log in.');
        // Optionally, you could automatically call login here, but it's often better
        // to direct the user to the login screen after registration.
      }
    } on ApiException {
      rethrow; // Re-throw API exceptions for UI handling
    } catch (e) {
      debugPrint('AuthService: Unexpected registration error: $e');
      throw ApiException('An unexpected error occurred during registration.');
    }
  }

  /// Logs out the user by clearing stored tokens.
  /// Optionally calls the backend logout endpoint if implemented.
  Future<void> logout() async {
    try {
      // Optional: Call backend logout endpoint if it exists and needs to invalidate tokens server-side
      // await _apiClient.post('/auth/logout');
    } catch (e) {
      // Log error but proceed with local logout anyway
      debugPrint(
          'AuthService: Error calling backend logout (proceeding locally): $e');
    } finally {
      await _clearTokens();
      _authChangeController.add(false); // Notify listeners of logout
      debugPrint('AuthService: Logged out.');
    }
  }

  /// Stores access and refresh tokens securely.
  Future<void> _storeTokens(String accessToken, String refreshToken) async {
    await _secureStorage.write(
        key: AppConstants.authTokenKey, value: accessToken);
    await _secureStorage.write(
        key: AppConstants.authTokenKey, value: refreshToken);
    debugPrint('AuthService: Tokens stored securely.');
  }

  /// Clears stored access and refresh tokens.
  Future<void> _clearTokens() async {
    await _secureStorage.delete(key: AppConstants.authTokenKey);
    await _secureStorage.delete(key: AppConstants.authTokenKey);
    debugPrint('AuthService: Tokens cleared.');
  }

  /// Disposes the stream controller when the service is no longer needed.
  void dispose() {
    _authChangeController.close();
    // The ApiClient might not have a dispose method, so we'll handle it safely
    try {
      (_apiClient as dynamic).dispose();
    } catch (e) {
      debugPrint('AuthService: ApiClient does not have dispose method: $e');
    }
  }
}
