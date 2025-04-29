# IRIS Backend Integration Guide for Flutter

## Table of Contents
1. [Introduction](#introduction)
2. [API Service Setup](#api-service-setup)
3. [Authentication Integration](#authentication-integration)
4. [Retinal Image Processing](#retinal-image-processing)
5. [UI Connection Points](#ui-connection-points)
6. [State Management](#state-management)
7. [Offline Support](#offline-support)
8. [Platform-Specific Considerations](#platform-specific-considerations)
9. [Testing Strategies](#testing-strategies)

## Introduction

This guide provides step-by-step instructions for integrating the IRIS backend with your Flutter application. It covers all aspects of the integration process, from setting up the API service to implementing offline support and testing strategies.

## API Service Setup

### Core API Client Implementation

Create a centralized API client to handle all communication with the backend:

```dart
// lib/services/api/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../auth/auth_service.dart';
import '../../utils/constants.dart';

class ApiClient {
  final http.Client _httpClient;
  final AuthService _authService;
  final FlutterSecureStorage _secureStorage;
  
  ApiClient({
    http.Client? httpClient,
    AuthService? authService,
    FlutterSecureStorage? secureStorage,
  }) : 
    _httpClient = httpClient ?? http.Client(),
    _authService = authService ?? AuthService(),
    _secureStorage = secureStorage ?? const FlutterSecureStorage();
  
  // Base URL from environment configuration
  String get baseUrl => AppConstants.apiBaseUrl;
  
  // GET request with authentication
  Future<http.Response> get(String endpoint, {Map<String, String>? headers}) async {
    final token = await _authService.getAccessToken();
    final requestHeaders = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      ...?headers,
    };
    
    final response = await _httpClient.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: requestHeaders,
    );
    
    // Handle 401 Unauthorized (token expired)
    if (response.statusCode == 401) {
      final refreshed = await _authService.refreshToken();
      if (refreshed) {
        // Retry with new token
        return get(endpoint, headers: headers);
      }
    }
    
    return response;
  }
  
  // POST request with authentication
  Future<http.Response> post(
    String endpoint, 
    {Map<String, String>? headers, dynamic body}
  ) async {
    final token = await _authService.getAccessToken();
    final requestHeaders = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      ...?headers,
    };
    
    final response = await _httpClient.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: requestHeaders,
      body: body != null ? json.encode(body) : null,
    );
    
    // Handle 401 Unauthorized (token expired)
    if (response.statusCode == 401) {
      final refreshed = await _authService.refreshToken();
      if (refreshed) {
        // Retry with new token
        return post(endpoint, headers: headers, body: body);
      }
    }
    
    return response;
  }
  
  // PUT request with authentication
  Future<http.Response> put(
    String endpoint, 
    {Map<String, String>? headers, dynamic body}
  ) async {
    final token = await _authService.getAccessToken();
    final requestHeaders = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      ...?headers,
    };
    
    final response = await _httpClient.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: requestHeaders,
      body: body != null ? json.encode(body) : null,
    );
    
    // Handle 401 Unauthorized (token expired)
    if (response.statusCode == 401) {
      final refreshed = await _authService.refreshToken();
      if (refreshed) {
        // Retry with new token
        return put(endpoint, headers: headers, body: body);
      }
    }
    
    return response;
  }
  
  // DELETE request with authentication
  Future<http.Response> delete(
    String endpoint, 
    {Map<String, String>? headers}
  ) async {
    final token = await _authService.getAccessToken();
    final requestHeaders = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      ...?headers,
    };
    
    final response = await _httpClient.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: requestHeaders,
    );
    
    // Handle 401 Unauthorized (token expired)
    if (response.statusCode == 401) {
      final refreshed = await _authService.refreshToken();
      if (refreshed) {
        // Retry with new token
        return delete(endpoint, headers: headers);
      }
    }
    
    return response;
  }
  
  // Multipart request for file uploads
  Future<http.Response> uploadFile(
    String endpoint,
    String filePath,
    String fieldName,
    {Map<String, String>? fields}
  ) async {
    final token = await _authService.getAccessToken();
    final uri = Uri.parse('$baseUrl$endpoint');
    
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath(fieldName, filePath));
    
    // Add additional fields if provided
    if (fields != null) {
      fields.forEach((key, value) {
        request.fields[key] = value;
      });
    }
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    // Handle 401 Unauthorized (token expired)
    if (response.statusCode == 401) {
      final refreshed = await _authService.refreshToken();
      if (refreshed) {
        // Retry with new token
        return uploadFile(endpoint, filePath, fieldName, fields: fields);
      }
    }
    
    return response;
  }
}
```

### Environment Configuration

Create a constants file to manage environment-specific configuration:

```dart
// lib/utils/constants.dart
class AppConstants {
  // API Configuration
  static const String apiBaseUrl = 'https://iris-api.example.com/api';
  
  // Feature Flags
  static const bool enableOfflineMode = true;
  static const bool enablePushNotifications = true;
  
  // Timeouts
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
  
  // Cache Configuration
  static const int maxCacheAge = 86400000; // 24 hours in milliseconds
  
  // Image Quality Settings
  static const double uploadImageQuality = 0.8; // 80% quality for uploads
  static const int maxImageWidth = 1920; // Max width for uploaded images
  static const int maxImageHeight = 1920; // Max height for uploaded images
}
```

### Request/Response Handling

Create models for standardized API responses:

```dart
// lib/models/api_response.dart
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final List<String>? errors;
  
  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });
  
  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic) fromJsonT) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      errors: json['errors'] != null 
        ? List<String>.from(json['errors'].map((e) => e.toString()))
        : null,
    );
  }
  
  factory ApiResponse.error(String message, [List<String>? errors]) {
    return ApiResponse(
      success: false,
      message: message,
      errors: errors,
    );
  }
}
```

Create service classes for each API domain:

```dart
// lib/services/api/scan_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/scan_result.dart';
import '../../models/api_response.dart';
import 'api_client.dart';

class ScanService {
  final ApiClient _apiClient;
  
  ScanService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();
  
  // Upload eye scan
  Future<ApiResponse<ScanUploadResult>> uploadEyeScan(
    String imagePath,
    String eyeSide,
    {String? notes, Map<String, dynamic>? deviceInfo}
  ) async {
    try {
      final fields = {
        'eyeSide': eyeSide,
        if (notes != null) 'notes': notes,
        if (deviceInfo != null) 'deviceInfo': json.encode(deviceInfo),
      };
      
      final response = await _apiClient.uploadFile(
        '/eye-scans/upload',
        imagePath,
        'image',
        fields: fields,
      );
      
      if (response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        return ApiResponse.fromJson(
          jsonResponse,
          (data) => ScanUploadResult.fromJson(data),
        );
      } else {
        return ApiResponse.error(
          'Failed to upload scan: ${response.statusCode}',
          [response.body],
        );
      }
    } catch (e) {
      return ApiResponse.error('Error uploading scan: $e');
    }
  }
  
  // Get user's scan history
  Future<ApiResponse<List<ScanResult>>> getUserScans({
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final response = await _apiClient.get(
        '/eye-scans/user/me?limit=$limit&offset=$offset',
      );
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return ApiResponse.fromJson(
          jsonResponse,
          (data) => (data['scans'] as List)
            .map((scan) => ScanResult.fromJson(scan))
            .toList(),
        );
      } else {
        return ApiResponse.error(
          'Failed to get scans: ${response.statusCode}',
          [response.body],
        );
      }
    } catch (e) {
      return ApiResponse.error('Error getting scans: $e');
    }
  }
  
  // Get scan details
  Future<ApiResponse<ScanResult>> getScanDetails(String scanId) async {
    try {
      final response = await _apiClient.get('/eye-scans/$scanId');
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return ApiResponse.fromJson(
          jsonResponse,
          (data) => ScanResult.fromJson(data),
        );
      } else {
        return ApiResponse.error(
          'Failed to get scan details: ${response.statusCode}',
          [response.body],
        );
      }
    } catch (e) {
      return ApiResponse.error('Error getting scan details: $e');
    }
  }
}
```

## Authentication Integration

### JWT Token Management

Create an authentication service to manage JWT tokens:

```dart
// lib/services/auth/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../models/user.dart';
import '../../models/api_response.dart';
import '../../utils/constants.dart';

class AuthService {
  final http.Client _httpClient;
  final FlutterSecureStorage _secureStorage;
  
  // Keys for secure storage
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';
  
  // Current authenticated user
  User? _currentUser;
  User? get currentUser => _currentUser;
  
  // Authentication state
  bool get isAuthenticated => _currentUser != null;
  
  AuthService({
    http.Client? httpClient,
    FlutterSecureStorage? secureStorage,
  }) : 
    _httpClient = httpClient ?? http.Client(),
    _secureStorage = secureStorage ?? const FlutterSecureStorage();
  
  // Initialize auth state from storage
  Future<bool> init() async {
    final userData = await _secureStorage.read(key: _userDataKey);
    final accessToken = await _secureStorage.read(key: _accessTokenKey);
    
    if (userData != null && accessToken != null) {
      try {
        _currentUser = User.fromJson(json.decode(userData));
        return true;
      } catch (e) {
        await logout();
        return false;
      }
    }
    
    return false;
  }
  
  // Register a new user
  Future<ApiResponse<User>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? dateOfBirth,
    String? phoneNumber,
  }) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('${AppConstants.apiBaseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
          if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
          if (phoneNumber != null) 'phoneNumber': phoneNumber,
        }),
      );
      
      if (response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        return ApiResponse.fromJson(
          jsonResponse,
          (data) => User.fromJson(data),
        );
      } else {
        final jsonResponse = json.decode(response.body);
        return ApiResponse.error(
          jsonResponse['message'] ?? 'Registration failed',
          jsonResponse['errors'] != null 
            ? List<String>.from(jsonResponse['errors'])
            : null,
        );
      }
    } catch (e) {
      return ApiResponse.error('Error during registration: $e');
    }
  }
  
  // Login user
  Future<ApiResponse<User>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('${AppConstants.apiBaseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        
        // Save tokens and user data
        await _secureStorage.write(
          key: _accessTokenKey,
          value: jsonResponse['data']['accessToken'],
        );
        await _secureStorage.write(
          key: _refreshTokenKey,
          value: jsonResponse['data']['refreshToken'],
        );
        
        final user = User.fromJson(jsonResponse['data']['user']);
        await _secureStorage.write(
          key: _userDataKey,
          value: json.encode(user.toJson()),
        );
        
        _currentUser = user;
        
        return ApiResponse(
          success: true,
          message: jsonResponse['message'] ?? 'Login successful',
          data: user,
        );
      } else {
        final jsonResponse = json.decode(response.body);
        return ApiResponse.error(
          jsonResponse['message'] ?? 'Login failed',
          jsonResponse['errors'] != null 
            ? List<String>.from(jsonResponse['errors'])
            : null,
        );
      }
    } catch (e) {
      return ApiResponse.error('Error during login: $e');
    }
  }
  
  // Logout user
  Future<void> logout() async {
    try {
      final token = await getAccessToken();
      if (token != null) {
        await _httpClient.post(
          Uri.parse('${AppConstants.apiBaseUrl}/auth/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      }
    } catch (e) {
      // Ignore errors during logout
    } finally {
      // Clear local storage
      await _secureStorage.delete(key: _accessTokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      await _secureStorage.delete(key: _userDataKey);
      _currentUser = null;
    }
  }
  
  // Get access token
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _accessTokenKey);
  }
  
  // Refresh token
  Future<bool> refreshToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      if (refreshToken == null) {
        return false;
      }
      
      final response = await _httpClient.post(
        Uri.parse('${AppConstants.apiBaseUrl}/auth/refresh-token'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'refreshToken': refreshToken,
        }),
      );
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        
        // Save new tokens
        await _secureStorage.write(
          key: _accessTokenKey,
          value: jsonResponse['data']['accessToken'],
        );
        await _secureStorage.write(
          key: _refreshTokenKey,
          value: jsonResponse['data']['refreshToken'],
        );
        
        return true;
      } else {
        // If refresh fails, logout
        await logout();
        return false;
      }
    } catch (e) {
      await logout();
      return false;
    }
  }
}
```

### Secure Storage Implementation

The `flutter_secure_storage` package is used for securely storing sensitive information:

```yaml
# Add to pubspec.yaml
dependencies:
  flutter_secure_storage: ^8.0.0
```

### Login/Registration Flows

Create login and registration screens that connect to the authentication service:

```dart
// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth/auth_service.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await authProvider.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.success) {
        // Navigate to home screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        setState(() {
          _errorMessage = response.message;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'IRIS',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Login'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                  child: const Text('Don\'t have an account? Register'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

## Retinal Image Processing

### Camera Capture Integration

Enhance the existing camera screen to connect with the backend:

```dart
// lib/screens/camera_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../providers/scan_provider.dart';
import '../widgets/camera_controls.dart';
import 'processing_screen.dart';

class CameraScreen extends StatefulWidget {
  final String eyeSide;
  
  const CameraScreen({Key? key, required this.eyeSide}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isCapturing = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? controller = _controller;
    
    // App state changed before camera was initialized
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }
  
  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      
      if (_cameras!.isEmpty) {
        setState(() {
          _isInitialized = false;
        });
        return;
      }
      
      // Use the first back camera
      final backCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );
      
      _controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      
      await _controller!.initialize();
      
      // Enable flash for better retinal imaging
      await _controller!.setFlashMode(FlashMode.torch);
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing camera: $e');
      setState(() {
        _isInitialized = false;
      });
    }
  }
  
  Future<void> _captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) {
      return;
    }
    
    setState(() {
      _isCapturing = true;
    });
    
    try {
      // Capture image
      final XFile image = await _controller!.takePicture();
      
      // Get device info for metadata
      final deviceInfo = {
        'model': Platform.isAndroid ? 'Android Device' : 'iOS Device',
        'os': Platform.operatingSystem,
        'osVersion': Platform.operatingSystemVersion,
      };
      
      // Navigate to processing screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ProcessingScreen(
              imagePath: image.path,
              eyeSide: widget.eyeSide,
              deviceInfo: deviceInfo,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error capturing image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error capturing image: $e')),
      );
      setState(() {
        _isCapturing = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      body: Stack(
        children: [
          // Camera preview
          Positioned.fill(
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: CameraPreview(_controller!),
            ),
          ),
          
          // Camera controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CameraControls(
              onCapture: _captureImage,
              isCapturing: _isCapturing,
              eyeSide: widget.eyeSide,
            ),
          ),
          
          // Eye side indicator
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.eyeSide.toUpperCase()} EYE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

### Image Compression Techniques

Implement image compression before uploading to the backend:

```dart
// lib/utils/image_utils.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'constants.dart';

class ImageUtils {
  // Compress image for upload
  static Future<File> compressImage(String imagePath) async {
    final File file = File(imagePath);
    final Directory tempDir = await getTemporaryDirectory();
    final String targetPath = path.join(
      tempDir.path, 
      '${path.basenameWithoutExtension(imagePath)}_compressed.jpg'
    );
    
    // Get image dimensions
    final Image image = Image.file(file);
    final Completer<Size> completer = Completer<Size>();
    
    image.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        completer.complete(Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        ));
      })
    );
    
    final Size imageSize = await completer.future;
    
    // Calculate target dimensions while maintaining aspect ratio
    int targetWidth = AppConstants.maxImageWidth;
    int targetHeight = AppConstants.maxImageHeight;
    
    if (imageSize.width > imageSize.height) {
      targetHeight = (imageSize.height * targetWidth / imageSize.width).round();
    } else {
      targetWidth = (imageSize.width * targetHeight / imageSize.height).round();
    }
    
    // Compress the image
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: (AppConstants.uploadImageQuality * 100).round(),
      minWidth: targetWidth,
      minHeight: targetHeight,
    );
    
    if (result == null) {
      // If compression fails, return original file
      return file;
    }
    
    return File(result.path);
  }
}
```

### Upload with Progress Tracking

Enhance the processing screen to handle upload with progress tracking:

```dart
// lib/screens/processing_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/scan_provider.dart';
import '../widgets/pulsating_orb.dart';
import '../utils/image_utils.dart';
import 'results_screen.dart';

class ProcessingScreen extends StatefulWidget {
  final String imagePath;
  final String eyeSide;
  final Map<String, dynamic>? deviceInfo;
  
  const ProcessingScreen({
    Key? key,
    required this.imagePath,
    required this.eyeSide,
    this.deviceInfo,
  }) : super(key: key);

  @override
  _ProcessingScreenState createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  bool _isUploading = false;
  bool _isProcessing = false;
  String _currentStep = 'Preparing image...';
  double _progress = 0.0;
  String? _errorMessage;
  String? _scanId;
  String? _jobId;
  
  @override
  void initState() {
    super.initState();
    _processImage();
  }
  
  Future<void> _processImage() async {
    try {
      setState(() {
        _isUploading = true;
        _currentStep = 'Preparing image...';
        _progress = 0.1;
      });
      
      // Compress image
      final File compressedImage = await ImageUtils.compressImage(widget.imagePath);
      
      setState(() {
        _currentStep = 'Uploading image...';
        _progress = 0.2;
      });
      
      // Upload image
      final scanProvider = Provider.of<ScanProvider>(context, listen: false);
      final uploadResult = await scanProvider.uploadEyeScan(
        compressedImage.path,
        widget.eyeSide,
        deviceInfo: widget.deviceInfo,
      );
      
      if (!uploadResult.success) {
        setState(() {
          _errorMessage = uploadResult.message;
          _isUploading = false;
        });
        return;
      }
      
      setState(() {
        _isUploading = false;
        _isProcessing = true;
        _scanId = uploadResult.data?.scanId;
        _currentStep = 'Starting analysis...';
        _progress = 0.3;
      });
      
      // Create processing job
      final jobResult = await scanProvider.createProcessingJob(_scanId!);
      
      if (!jobResult.success) {
        setState(() {
          _errorMessage = jobResult.message;
          _isProcessing = false;
        });
        return;
      }
      
      _jobId = jobResult.data?.jobId;
      
      // Poll for job status
      await _pollJobStatus();
      
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isUploading = false;
        _isProcessing = false;
      });
    }
  }
  
  Future<void> _pollJobStatus() async {
    if (_jobId == null) return;
    
    final scanProvider = Provider.of<ScanProvider>(context, listen: false);
    bool isCompleted = false;
    int retryCount = 0;
    
    while (!isCompleted && retryCount < 60) { // Timeout after 60 attempts (5 minutes)
      await Future.delayed(Duration(seconds: 5)); // Poll every 5 seconds
      
      final jobStatus = await scanProvider.getJobStatus(_jobId!);
      
      if (!jobStatus.success) {
        retryCount++;
        continue;
      }
      
      final status = jobStatus.data?.status;
      final progress = jobStatus.data?.progress ?? 0;
      
      setState(() {
        _progress = 0.3 + (progress / 100 * 0.7); // Scale to 30%-100%
        
        switch (progress) {
          case 0:
            _currentStep = 'Waiting in queue...';
            break;
          case 10:
            _currentStep = 'Analyzing image characteristics...';
            break;
          case 30:
            _currentStep = 'Processing retinal patterns...';
            break;
          case 50:
            _currentStep = 'Detecting potential conditions...';
            break;
          case 70:
            _currentStep = 'Generating diagnostic report...';
            break;
          case 90:
            _currentStep = 'Finalizing analysis results...';
            break;
          case 100:
            _currentStep = 'Analysis complete!';
            break;
          default:
            _currentStep = 'Processing...';
        }
      });
      
      if (status == 'completed') {
        isCompleted = true;
        
        // Navigate to results screen
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ResultsScreen(scanId: _scanId!),
            ),
          );
        }
      } else if (status == 'failed') {
        setState(() {
          _errorMessage = jobStatus.data?.error ?? 'Processing failed';
          _isProcessing = false;
        });
        return;
      }
      
      retryCount++;
    }
    
    if (!isCompleted) {
      setState(() {
        _errorMessage = 'Processing timed out. Please try again.';
        _isProcessing = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primaryContainer,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_errorMessage == null) ...[
                    PulsatingOrb(
                      size: 120,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(height: 48),
                    Text(
                      _currentStep,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ] else ...[
                    Icon(
                      Icons.error_outline,
                      size: 80,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Error',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text('Go Back'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

### WebSocket Setup for Real-time Updates

Implement WebSocket connection for real-time processing updates:

```dart
// lib/services/websocket_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import '../utils/constants.dart';
import 'auth/auth_service.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final AuthService _authService;
  final StreamController<Map<String, dynamic>> _messageController = StreamController.broadcast();
  
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  bool _isConnected = false;
  bool get isConnected => _isConnected;
  
  WebSocketService({AuthService? authService}) 
    : _authService = authService ?? AuthService();
  
  // Connect to WebSocket server
  Future<bool> connect() async {
    if (_isConnected) {
      return true;
    }
    
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        return false;
      }
      
      final wsUrl = AppConstants.apiBaseUrl.replaceFirst('http', 'ws');
      _channel = IOWebSocketChannel.connect(
        Uri.parse('$wsUrl/ws?token=$token'),
      );
      
      _channel!.stream.listen(
        (message) {
          try {
            final data = json.decode(message);
            _messageController.add(data);
          } catch (e) {
            print('Error parsing WebSocket message: $e');
          }
        },
        onDone: () {
          _isConnected = false;
          // Try to reconnect after a delay
          Future.delayed(Duration(seconds: 5), () {
            if (!_isConnected) {
              connect();
            }
          });
        },
        onError: (error) {
          print('WebSocket error: $error');
          _isConnected = false;
        },
      );
      
      _isConnected = true;
      return true;
    } catch (e) {
      print('Error connecting to WebSocket: $e');
      _isConnected = false;
      return false;
    }
  }
  
  // Subscribe to job updates
  void subscribeToJob(String jobId) {
    if (!_isConnected || _channel == null) {
      connect().then((success) {
        if (success) {
          _sendSubscription(jobId);
        }
      });
    } else {
      _sendSubscription(jobId);
    }
  }
  
  // Send subscription message
  void _sendSubscription(String jobId) {
    _channel!.sink.add(json.encode({
      'type': 'subscribe',
      'channel': 'job_updates',
      'jobId': jobId,
    }));
  }
  
  // Unsubscribe from job updates
  void unsubscribeFromJob(String jobId) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(json.encode({
        'type': 'unsubscribe',
        'channel': 'job_updates',
        'jobId': jobId,
      }));
    }
  }
  
  // Close WebSocket connection
  void disconnect() {
    _channel?.sink.close();
    _isConnected = false;
  }
  
  // Dispose resources
  void dispose() {
    disconnect();
    _messageController.close();
  }
}
```

## UI Connection Points

### How Backend Supports Improved Camera Controls

The backend supports improved camera controls through metadata handling and image quality assessment:

```dart
// lib/widgets/camera_controls.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraControls extends StatelessWidget {
  final VoidCallback onCapture;
  final bool isCapturing;
  final String eyeSide;
  
  const CameraControls({
    Key? key,
    required this.onCapture,
    required this.isCapturing,
    required this.eyeSide,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Capture button
          GestureDetector(
            onTap: isCapturing ? null : onCapture,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 4,
                ),
              ),
              child: Center(
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  width: isCapturing ? 60 : 70,
                  height: isCapturing ? 60 : 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCapturing 
                      ? Theme.of(context).colorScheme.secondary
                      : Colors.white,
                  ),
                  child: isCapturing
                    ? Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : null,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Guidance text
          Text(
            'Position the ${eyeSide.toLowerCase()} eye in the center and tap to capture',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
```

### Connecting Progress Updates to Animation States

Connect the backend processing status to the animation states in the UI:

```dart
// lib/widgets/pulsating_orb.dart
import 'package:flutter/material.dart';

class PulsatingOrb extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;
  
  const PulsatingOrb({
    Key? key,
    required this.size,
    required this.color,
    this.duration = const Duration(seconds: 2),
  }) : super(key: key);

  @override
  _PulsatingOrbState createState() => _PulsatingOrbState();
}

class _PulsatingOrbState extends State<PulsatingOrb> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulsating circle
              Transform.scale(
                scale: _animation.value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withOpacity(0.3),
                  ),
                ),
              ),
              
              // Middle pulsating circle
              Transform.scale(
                scale: _animation.value * 0.8,
                child: Container(
                  width: widget.size * 0.8,
                  height: widget.size * 0.8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withOpacity(0.5),
                  ),
                ),
              ),
              
              // Inner solid circle
              Container(
                width: widget.size * 0.6,
                height: widget.size * 0.6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                ),
                child: Icon(
                  Icons.remove_red_eye,
                  color: Colors.white,
                  size: widget.size * 0.3,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

### Populating Interactive Diagnosis Cards

Connect the backend diagnostic results to the interactive diagnosis cards:

```dart
// lib/widgets/diagnosis_card.dart
import 'package:flutter/material.dart';
import '../models/scan_result.dart';

class DiagnosisCard extends StatelessWidget {
  final DiagnosticResult result;
  final VoidCallback onTap;
  
  const DiagnosisCard({
    Key? key,
    required this.result,
    required this.onTap,
  }) : super(key: key);
  
  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'moderate':
        return Colors.orange;
      case 'low':
        return Colors.yellow;
      case 'none':
      default:
        return Colors.green;
    }
  }
  
  IconData _getConditionIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'glaucoma':
        return Icons.visibility_off;
      case 'cataract':
        return Icons.blur_on;
      case 'diabeticretinopathy':
        return Icons.bloodtype;
      case 'conjunctivitis':
        return Icons.coronavirus;
      case 'normal':
      default:
        return Icons.check_circle;
    }
  }
  
  String _formatConditionName(String condition) {
    if (condition == 'diabeticretinopathy') {
      return 'Diabetic Retinopathy';
    }
    
    // Capitalize first letter of each word
    return condition.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => ' ${match.group(0)}',
    ).trim().split(' ').map((word) => 
      word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
    ).join(' ');
  }
  
  @override
  Widget build(BuildContext context) {
    final severityColor = _getSeverityColor(result.severity);
    final conditionIcon = _getConditionIcon(result.condition);
    final conditionName = _formatConditionName(result.condition);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with condition and severity
              Row(
                children: [
                  Icon(
                    conditionIcon,
                    color: severityColor,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          conditionName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: severityColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                result.severity.toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Confidence: ${(result.confidence * 100).toStringAsFixed(0)}%',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right),
                ],
              ),
              
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              
              // Diagnosis summary
              Text(
                result.diagnosis,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 16),
              
              // Top recommendation
              if (result.recommendations.isNotEmpty)
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        result.recommendations.first.recommendation,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## State Management

### Recommended Approach Compatible with Material Design 3

Use Provider for state management, which works well with Material Design 3:

```dart
// lib/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/api_response.dart';
import '../services/auth/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  
  User? _user;
  bool _isLoading = false;
  String? _error;
  
  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  AuthProvider({AuthService? authService}) 
    : _authService = authService ?? AuthService();
  
  // Initialize auth state
  Future<bool> init() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final result = await _authService.init();
      if (result) {
        _user = _authService.currentUser;
      }
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  // Register a new user
  Future<ApiResponse<User>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? dateOfBirth,
    String? phoneNumber,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _authService.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: dateOfBirth,
        phoneNumber: phoneNumber,
      );
      
      _isLoading = false;
      notifyListeners();
      
      return response;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      
      return ApiResponse.error('Error during registration: $e');
    }
  }
  
  // Login user
  Future<ApiResponse<User>> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _authService.login(
        email: email,
        password: password,
      );
      
      if (response.success) {
        _user = response.data;
      }
      
      _isLoading = false;
      notifyListeners();
      
      return response;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      
      return ApiResponse.error('Error during login: $e');
    }
  }
  
  // Logout user
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _authService.logout();
      _user = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

### Data Flow Architecture

Implement a clean data flow architecture with providers, services, and models:

```dart
// lib/providers/scan_provider.dart
import 'package:flutter/foundation.dart';
import '../models/scan_result.dart';
import '../models/api_response.dart';
import '../services/api/scan_service.dart';
import '../services/api/processing_service.dart';

class ScanProvider with ChangeNotifier {
  final ScanService _scanService;
  final ProcessingService _processingService;
  
  List<ScanResult> _scans = [];
  bool _isLoading = false;
  String? _error;
  
  List<ScanResult> get scans => _scans;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  ScanProvider({
    ScanService? scanService,
    ProcessingService? processingService,
  }) : 
    _scanService = scanService ?? ScanService(),
    _processingService = processingService ?? ProcessingService();
  
  // Upload eye scan
  Future<ApiResponse<ScanUploadResult>> uploadEyeScan(
    String imagePath,
    String eyeSide,
    {String? notes, Map<String, dynamic>? deviceInfo}
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _scanService.uploadEyeScan(
        imagePath,
        eyeSide,
        notes: notes,
        deviceInfo: deviceInfo,
      );
      
      _isLoading = false;
      notifyListeners();
      
      return response;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      
      return ApiResponse.error('Error uploading scan: $e');
    }
  }
  
  // Create processing job
  Future<ApiResponse<ProcessingJob>> createProcessingJob(String scanId) async {
    try {
      return await _processingService.createProcessingJob(scanId);
    } catch (e) {
      return ApiResponse.error('Error creating processing job: $e');
    }
  }
  
  // Get job status
  Future<ApiResponse<ProcessingJob>> getJobStatus(String jobId) async {
    try {
      return await _processingService.getJobStatus(jobId);
    } catch (e) {
      return ApiResponse.error('Error getting job status: $e');
    }
  }
  
  // Get user's scan history
  Future<void> loadUserScans({int limit = 10, int offset = 0}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _scanService.getUserScans(
        limit: limit,
        offset: offset,
      );
      
      if (response.success) {
        if (offset == 0) {
          _scans = response.data ?? [];
        } else {
          _scans.addAll(response.data ?? []);
        }
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Get scan details
  Future<ApiResponse<ScanResult>> getScanDetails(String scanId) async {
    try {
      return await _scanService.getScanDetails(scanId);
    } catch (e) {
      return ApiResponse.error('Error getting scan details: $e');
    }
  }
}
```

### State Persistence

Implement state persistence for offline support:

```dart
// lib/services/storage/local_storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/scan_result.dart';
import '../../models/user.dart';

class LocalStorageService {
  static const String _scansKey = 'scans';
  static const String _userKey = 'user';
  
  // Save scans to local storage
  Future<bool> saveScans(List<ScanResult> scans) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = scans.map((scan) => scan.toJson()).toList();
      return await prefs.setString(_scansKey, json.encode(jsonData));
    } catch (e) {
      print('Error saving scans to local storage: $e');
      return false;
    }
  }
  
  // Load scans from local storage
  Future<List<ScanResult>> loadScans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_scansKey);
      
      if (jsonString == null) {
        return [];
      }
      
      final jsonData = json.decode(jsonString) as List;
      return jsonData.map((item) => ScanResult.fromJson(item)).toList();
    } catch (e) {
      print('Error loading scans from local storage: $e');
      return [];
    }
  }
  
  // Save user to local storage
  Future<bool> saveUser(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_userKey, json.encode(user.toJson()));
    } catch (e) {
      print('Error saving user to local storage: $e');
      return false;
    }
  }
  
  // Load user from local storage
  Future<User?> loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_userKey);
      
      if (jsonString == null) {
        return null;
      }
      
      return User.fromJson(json.decode(jsonString));
    } catch (e) {
      print('Error loading user from local storage: $e');
      return null;
    }
  }
  
  // Clear all data
  Future<bool> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.clear();
    } catch (e) {
      print('Error clearing local storage: $e');
      return false;
    }
  }
}
```

## Offline Support

### Local Data Caching

Implement local data caching for offline access:

```dart
// lib/services/cache/cache_manager.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import '../../utils/constants.dart';

class CacheManager {
  static const String _cacheDir = 'iris_cache';
  
  // Get cache directory
  Future<Directory> _getCacheDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory(path.join(appDir.path, _cacheDir));
    
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    
    return cacheDir;
  }
  
  // Cache image from URL
  Future<File?> cacheImage(String url, String filename) async {
    try {
      final cacheDir = await _getCacheDir();
      final file = File(path.join(cacheDir.path, filename));
      
      // Check if file exists and is not expired
      if (await file.exists()) {
        final fileStats = await file.stat();
        final fileAge = DateTime.now().difference(fileStats.modified).inMilliseconds;
        
        if (fileAge < AppConstants.maxCacheAge) {
          return file;
        }
      }
      
      // Download and cache file
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        return file;
      }
      
      return null;
    } catch (e) {
      print('Error caching image: $e');
      return null;
    }
  }
  
  // Get cached image
  Future<File?> getCachedImage(String filename) async {
    try {
      final cacheDir = await _getCacheDir();
      final file = File(path.join(cacheDir.path, filename));
      
      if (await file.exists()) {
        return file;
      }
      
      return null;
    } catch (e) {
      print('Error getting cached image: $e');
      return null;
    }
  }
  
  // Clear cache
  Future<bool> clearCache() async {
    try {
      final cacheDir = await _getCacheDir();
      
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        await cacheDir.create();
      }
      
      return true;
    } catch (e) {
      print('Error clearing cache: $e');
      return false;
    }
  }
}
```

### Synchronization Strategies

Implement synchronization for offline changes:

```dart
// lib/services/sync/sync_service.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../storage/local_storage_service.dart';
import '../api/scan_service.dart';
import '../../models/scan_result.dart';

class SyncService {
  final LocalStorageService _localStorageService;
  final ScanService _scanService;
  final Connectivity _connectivity;
  
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isSyncing = false;
  
  SyncService({
    LocalStorageService? localStorageService,
    ScanService? scanService,
    Connectivity? connectivity,
  }) : 
    _localStorageService = localStorageService ?? LocalStorageService(),
    _scanService = scanService ?? ScanService(),
    _connectivity = connectivity ?? Connectivity();
  
  // Initialize sync service
  void init() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        syncData();
      }
    });
    
    // Check initial connection and sync if online
    _connectivity.checkConnectivity().then((result) {
      if (result != ConnectivityResult.none) {
        syncData();
      }
    });
  }
  
  // Sync data with server
  Future<bool> syncData() async {
    if (_isSyncing) {
      return false;
    }
    
    _isSyncing = true;
    
    try {
      // Sync scans
      await _syncScans();
      
      _isSyncing = false;
      return true;
    } catch (e) {
      print('Error syncing data: $e');
      _isSyncing = false;
      return false;
    }
  }
  
  // Sync scans with server
  Future<void> _syncScans() async {
    try {
      // Get latest scans from server
      final response = await _scanService.getUserScans(limit: 50);
      
      if (response.success && response.data != null) {
        // Save to local storage
        await _localStorageService.saveScans(response.data!);
      }
    } catch (e) {
      print('Error syncing scans: $e');
    }
  }
  
  // Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
```

### Error Handling Patterns

Implement robust error handling:

```dart
// lib/utils/error_handler.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/api_response.dart';

class ErrorHandler {
  // Handle API errors
  static String handleApiError(dynamic error) {
    if (error is SocketException) {
      return 'Network error. Please check your internet connection.';
    } else if (error is HttpException) {
      return 'Server error. Please try again later.';
    } else if (error is FormatException) {
      return 'Invalid response format. Please try again later.';
    } else if (error is TimeoutException) {
      return 'Connection timed out. Please try again later.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }
  
  // Show error dialog
  static void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
  
  // Show error snackbar
  static void showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  // Handle API response
  static void handleApiResponse<T>(
    BuildContext context,
    ApiResponse<T> response,
    {Function(T data)? onSuccess}
  ) {
    if (response.success) {
      if (onSuccess != null && response.data != null) {
        onSuccess(response.data!);
      }
    } else {
      showErrorSnackbar(context, response.message);
    }
  }
}
```

## Platform-Specific Considerations

### Android Specific Configuration

Add the following to your `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Internet permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    
    <!-- Camera permissions -->
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-feature android:name="android.hardware.camera" />
    <uses-feature android:name="android.hardware.camera.autofocus" />
    
    <!-- Storage permissions -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" 
                     android:maxSdkVersion="28" />
    
    <application
        android:label="IRIS"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:usesCleartextTraffic="true">
        <!-- ... rest of your manifest ... -->
        
        <!-- Network security config for API 28+ -->
        android:networkSecurityConfig="@xml/network_security_config"
    </application>
</manifest>
```

Create a network security configuration file at `android/app/src/main/res/xml/network_security_config.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="false">
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </base-config>
    <domain-config cleartextTrafficPermitted="true">
        <!-- Add your development domains here -->
        <domain includeSubdomains="true">localhost</domain>
        <domain includeSubdomains="true">10.0.2.2</domain>
    </domain-config>
</network-security-config>
```

### iOS Specific Configuration

Add the following to your `ios/Runner/Info.plist`:

```xml
<dict>
    <!-- ... other configurations ... -->
    
    <!-- Camera usage description -->
    <key>NSCameraUsageDescription</key>
    <string>IRIS needs access to your camera to capture retinal images for analysis.</string>
    
    <!-- Photo library usage description -->
    <key>NSPhotoLibraryUsageDescription</key>
    <string>IRIS needs access to your photo library to select retinal images for analysis.</string>
    
    <!-- App Transport Security settings -->
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <false/>
        <key>NSExceptionDomains</key>
        <dict>
            <!-- Add your development domains here -->
            <key>localhost</key>
            <dict>
                <key>NSExceptionAllowsInsecureHTTPLoads</key>
                <true/>
                <key>NSIncludesSubdomains</key>
                <true/>
            </dict>
        </dict>
    </dict>
</dict>
```

## Testing Strategies

### Unit Testing

Create unit tests for your services and providers:

```dart
// test/services/auth_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:iris/services/auth/auth_service.dart';
import 'package:iris/models/user.dart';

// Mock classes
class MockHttpClient extends Mock implements http.Client {}
class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late AuthService authService;
  late MockHttpClient mockHttpClient;
  late MockSecureStorage mockSecureStorage;
  
  setUp(() {
    mockHttpClient = MockHttpClient();
    mockSecureStorage = MockSecureStorage();
    authService = AuthService(
      httpClient: mockHttpClient,
      secureStorage: mockSecureStorage,
    );
  });
  
  group('AuthService', () {
    test('login should return success response when credentials are valid', () async {
      // Arrange
      when(mockHttpClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
        '{"success":true,"message":"Login successful","data":{"accessToken":"test_token","refreshToken":"test_refresh_token","user":{"id":"123","email":"test@example.com","firstName":"John","lastName":"Doe","role":"patient"}}}',
        200,
      ));
      
      // Act
      final result = await authService.login(
        email: 'test@example.com',
        password: 'password123',
      );
      
      // Assert
      expect(result.success, true);
      expect(result.message, 'Login successful');
      expect(result.data, isA<User>());
      expect(result.data?.email, 'test@example.com');
      
      // Verify token storage
      verify(mockSecureStorage.write(
        key: anyNamed('key'),
        value: anyNamed('value'),
      )).called(3); // Access token, refresh token, user data
    });
    
    test('login should return error response when credentials are invalid', () async {
      // Arrange
      when(mockHttpClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
        '{"success":false,"message":"Invalid credentials"}',
        401,
      ));
      
      // Act
      final result = await authService.login(
        email: 'test@example.com',
        password: 'wrong_password',
      );
      
      // Assert
      expect(result.success, false);
      expect(result.message, 'Invalid credentials');
      expect(result.data, isNull);
      
      // Verify no token storage
      verifyNever(mockSecureStorage.write(
        key: anyNamed('key'),
        value: anyNamed('value'),
      ));
    });
  });
}
```

### Widget Testing

Create widget tests for your UI components:

```dart
// test/widgets/diagnosis_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/widgets/diagnosis_card.dart';
import 'package:iris/models/scan_result.dart';

void main() {
  testWidgets('DiagnosisCard displays correct information', (WidgetTester tester) async {
    // Create test data
    final diagnosticResult = DiagnosticResult(
      id: '123',
      condition: 'glaucoma',
      confidence: 0.92,
      severity: 'moderate',
      diagnosis: 'Potential indicators of glaucoma present.',
      recommendations: [
        Recommendation(recommendation: 'Schedule an appointment with an ophthalmologist immediately', priority: 1),
        Recommendation(recommendation: 'Early treatment can prevent vision loss', priority: 2),
      ],
      aiModelVersion: '2.0.0',
      createdAt: DateTime.now().toIso8601String(),
    );
    
    bool tapped = false;
    
    // Build widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DiagnosisCard(
            result: diagnosticResult,
            onTap: () {
              tapped = true;
            },
          ),
        ),
      ),
    );
    
    // Verify condition name is displayed
    expect(find.text('Glaucoma'), findsOneWidget);
    
    // Verify severity is displayed
    expect(find.text('MODERATE'), findsOneWidget);
    
    // Verify confidence is displayed
    expect(find.text('Confidence: 92%'), findsOneWidget);
    
    // Verify diagnosis is displayed
    expect(find.text('Potential indicators of glaucoma present.'), findsOneWidget);
    
    // Verify top recommendation is displayed
    expect(find.text('Schedule an appointment with an ophthalmologist immediately'), findsOneWidget);
    
    // Test tap functionality
    await tester.tap(find.byType(DiagnosisCard));
    expect(tapped, true);
  });
}
```

### Integration Testing

Create integration tests to verify the complete flow:

```dart
// integration_test/app_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:iris/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('End-to-end test', () {
    testWidgets('Complete login flow', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();
      
      // Verify we're on the login screen
      expect(find.text('IRIS'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      
      // Enter credentials
      await tester.enterText(
        find.byType(TextFormField).at(0), 
        'test@example.com'
      );
      await tester.enterText(
        find.byType(TextFormField).at(1), 
        'password123'
      );
      
      // Tap login button
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();
      
      // Verify we're on the home screen
      expect(find.text('Welcome'), findsOneWidget);
      
      // Navigate to scan history
      await tester.tap(find.text('Scan History'));
      await tester.pumpAndSettle();
      
      // Verify we're on the scan history screen
      expect(find.text('Scan History'), findsOneWidget);
    });
  });
}
```

This comprehensive guide covers all aspects of integrating the IRIS backend with your Flutter application, including API service setup, authentication integration, retinal image processing, UI connection points, state management, offline support, platform-specific considerations, and testing strategies. Follow these steps to create a robust, maintainable, and user-friendly application that leverages the full capabilities of the IRIS backend.
