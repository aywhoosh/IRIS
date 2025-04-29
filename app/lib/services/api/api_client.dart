import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../utils/constants.dart';
import 'api_exception.dart';

class ApiClient {
  final String baseUrl;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final http.Client _httpClient = http.Client();

  ApiClient({required this.baseUrl});

  Future<Map<String, String>> _getHeaders({bool requireAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requireAuth) {
      final token = await _secureStorage.read(key: AppConstants.authTokenKey);
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<dynamic> get(String endpoint, {bool requireAuth = true}) async {
    try {
      final headers = await _getHeaders(requireAuth: requireAuth);
      final response = await _httpClient.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );

      return _processResponse(response);
    } on SocketException {
      throw ApiException('No internet connection');
    } catch (e) {
      throw ApiException('Failed to perform GET request: $e');
    }
  }

  Future<dynamic> post(String endpoint,
      {dynamic body, bool requireAuth = true}) async {
    try {
      final headers = await _getHeaders(requireAuth: requireAuth);
      final response = await _httpClient.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: body != null ? json.encode(body) : null,
      );

      return _processResponse(response);
    } on SocketException {
      throw ApiException('No internet connection');
    } catch (e) {
      throw ApiException('Failed to perform POST request: $e');
    }
  }

  Future<dynamic> put(String endpoint,
      {dynamic body, bool requireAuth = true}) async {
    try {
      final headers = await _getHeaders(requireAuth: requireAuth);
      final response = await _httpClient.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: body != null ? json.encode(body) : null,
      );

      return _processResponse(response);
    } on SocketException {
      throw ApiException('No internet connection');
    } catch (e) {
      throw ApiException('Failed to perform PUT request: $e');
    }
  }

  Future<dynamic> delete(String endpoint, {bool requireAuth = true}) async {
    try {
      final headers = await _getHeaders(requireAuth: requireAuth);
      final response = await _httpClient.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );

      return _processResponse(response);
    } on SocketException {
      throw ApiException('No internet connection');
    } catch (e) {
      throw ApiException('Failed to perform DELETE request: $e');
    }
  }

  // Special method for file uploads
  Future<dynamic> uploadFile(
    String endpoint,
    File file,
    String fieldName, {
    Map<String, String>? fields,
    bool requireAuth = true,
  }) async {
    try {
      final headers = await _getHeaders(requireAuth: requireAuth);
      // Remove content-type header as it will be set by multipart request
      headers.remove('Content-Type');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl$endpoint'),
      );

      request.headers.addAll(headers);
      request.files.add(await http.MultipartFile.fromPath(
        fieldName,
        file.path,
      ));

      if (fields != null) {
        request.fields.addAll(fields);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _processResponse(response);
    } on SocketException {
      throw ApiException('No internet connection');
    } catch (e) {
      throw ApiException('Failed to upload file: $e');
    }
  }

  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }
      return json.decode(response.body);
    }

    dynamic errorData;
    try {
      errorData = json.decode(response.body);
    } catch (e) {
      errorData = response.body;
    }

    final errorMessage = errorData is Map
        ? errorData['message'] ?? errorData['error'] ?? 'Server error'
        : 'Server error';

    throw ApiException(
      errorMessage,
      statusCode: response.statusCode,
      data: errorData,
    );
  }

  // Auth token management
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: AppConstants.authTokenKey, value: token);
  }

  Future<void> clearToken() async {
    await _secureStorage.delete(key: AppConstants.authTokenKey);
  }

  Future<bool> hasToken() async {
    final token = await _secureStorage.read(key: AppConstants.authTokenKey);
    return token != null && token.isNotEmpty;
  }
}
