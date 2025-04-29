import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/scan_result.dart';
import '../models/scan_summary.dart';
import '../models/scan_upload_result.dart';
import '../models/job_status.dart';
import '../services/supabase/supabase_service.dart';
import '../services/api/api_response.dart';
import 'package:path/path.dart' as path;
import 'dart:convert'; // Add this for jsonDecode

class ScanProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  StreamSubscription? _scanSubscription;

  // State variables
  List<ScanSummary> _scans = [];
  bool _isLoading = false;
  String? _error;

  // Getters - retained from old implementation
  List<ScanSummary> get scans => _scans;
  bool get isLoading => _isLoading;
  String? get error => _error;
  // Load user scans - original method name from old impl
  Future<void> loadUserScans() async {
    _setLoading(true);
    _clearError();

    try {
      final rawScans = await _supabaseService
          .getUserScans(); // Convert the raw Supabase data to ScanSummary objects for compatibility
      final updatedScans = rawScans.map((scanData) {
        // Ensure all required fields exist
        return ScanSummary(
          id: scanData['id'] ?? '',
          scanId: scanData['scan_id'] ?? scanData['id'] ?? '',
          eyeSide: scanData['eye_side'] ?? 'unknown',
          scanDate: scanData['scan_date'] != null
              ? DateTime.parse(scanData['scan_date'].toString())
              : DateTime.now(),
          createdAt: scanData['created_at'] != null
              ? DateTime.parse(scanData['created_at'].toString())
              : DateTime.now(),
          // Use image_path as the thumbnailUrl since that's what we're storing in Supabase
          thumbnailUrl: scanData['image_path'],
          imageQuality: scanData['image_quality'],
          status: scanData['status'],
        );
      }).toList();

      // Sort by most recent first
      updatedScans.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Update state only once
      _scans = updatedScans;

      // Single notification after all changes are complete
      notifyListeners();
    } catch (e) {
      _setError('Failed to load scans: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Get the result of a scan by ID - original method name from old impl
  Future<ApiResponse<ScanResult>> getScanResult(String scanId) async {
    _setLoading(true);
    _clearError();

    try {
      final scanDetails = await _supabaseService.getScanDetails(scanId);
      final scanResult = ScanResult.fromJson(scanDetails);
      return ApiResponse.success(scanResult);
    } catch (e) {
      final message = 'Failed to get scan result: ${e.toString()}';
      _setError(message);
      return ApiResponse.error(message);
    } finally {
      _setLoading(false);
    }
  }

  // Upload a new scan - match old method signature
  Future<ApiResponse<ScanUploadResult>> uploadEyeScan(
      String imagePath, String eyeSide) async {
    _setLoading(true);
    _clearError();

    try {
      final file = File(imagePath);
      // Check if file exists
      if (!file.existsSync()) {
        throw Exception('Image file does not exist');
      }

      // Read the file as bytes
      final bytes = await file.readAsBytes();

      // Make API request to prediction endpoint
      final uri = Uri.parse('http://13.203.74.185:8000/predict');
      final request = http.MultipartRequest('POST', uri);

      // Add the file to the request
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: path.basename(file.path),
      );
      request.files.add(multipartFile);

      // Send the request and get response
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      var predictedLabel = "";

      // Check for successful response
      if (response.statusCode != 200) {
        print(
            'Prediction API failed: ${response.statusCode}, ${response.body}');
        // Continue with upload even if prediction fails
      } else {
        // Process prediction results if needed
        final predictionResult = jsonDecode(response.body);
        final classLabelResult = predictionResult["predicted_class_label"];
        predictedLabel = classLabelResult;
        print('Prediction result: $predictedLabel');
      }

      // Upload the image and create scan record
      final scanId = await _supabaseService.uploadScanImage(file, eyeSide);

      // Start processing the scan
      await _supabaseService.processScan(
          scanId, predictedLabel); // Pass the predicted label

      // Refresh the list of scans
      await loadUserScans();

      // Create a ScanUploadResult object to match old interface
      final uploadResult = ScanUploadResult(
        scanId: scanId,
        jobId: scanId, // Using scanId as jobId for Supabase implementation
      );

      return ApiResponse.success(uploadResult,
          message: 'Scan uploaded successfully');
    } catch (e) {
      final message = 'Failed to upload scan: ${e.toString()}';
      _setError(message);
      return ApiResponse.error(message);
    } finally {
      _setLoading(false);
    }
  }

  // Get job status - method from old implementation
  Future<ApiResponse<JobStatus>> getJobStatus(String jobId) async {
    try {
      // For Supabase implementation, we fetch the scan directly to check its status
      final scanDetails = await _supabaseService.getScanDetails(jobId);

      // Create a JobStatus object to match old interface
      // Check if scan_results exists to determine if processing is complete
      final hasResults = scanDetails['scan_results'] != null &&
          (scanDetails['scan_results'] as List)
              .isNotEmpty; // Set status based on whether results exist
      final status =
          hasResults ? 'processed' : (scanDetails['status'] ?? 'processing');

      // Hard-code progress values based on status to avoid using non-existent 'progress' column
      final progress = status == 'processed' ? 100 : 70;

      final jobStatus = JobStatus(
        status: _mapStatusString(status),
        progress: progress,
        errorMessage: scanDetails['error_message'],
      );

      return ApiResponse.success(jobStatus);
    } catch (e) {
      final message = 'Failed to get job status: ${e.toString()}';
      return ApiResponse.error(message);
    }
  }

  // Subscribe to real-time updates for the current user's scans
  void subscribeToPendingScans() {
    _scanSubscription?.cancel();
    _scanSubscription = _supabaseService.subscribeToPendingScans((scans) {
      // Convert the raw Supabase data to ScanSummary objects for compatibility
      _scans = scans.map((scanData) {
        // Ensure all required fields exist
        return ScanSummary(
          id: scanData['id'] ?? '',
          scanId: scanData['scan_id'] ?? scanData['id'] ?? '',
          eyeSide: scanData['eye_side'] ?? 'unknown',
          scanDate: scanData['scan_date'] != null
              ? DateTime.parse(scanData['scan_date'].toString())
              : DateTime.now(),
          createdAt: scanData['created_at'] != null
              ? DateTime.parse(scanData['created_at'].toString())
              : DateTime.now(),
          // Use image_path instead of thumbnail_url to match database schema
          thumbnailUrl: scanData['image_path'],
          imageQuality: scanData['image_quality'],
          status: scanData['status'],
        );
      }).toList();

      // Sort by most recent first
      _scans.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      notifyListeners();
    });
  }

  // Helper method to map status string to JobProcessingStatus enum
  JobProcessingStatus _mapStatusString(String status) {
    switch (status.toLowerCase()) {
      case 'processed':
      case 'completed':
        return JobProcessingStatus.completed;
      case 'failed':
        return JobProcessingStatus.failed;
      case 'processing':
        return JobProcessingStatus.processing;
      case 'queued':
        return JobProcessingStatus.queued;
      default:
        return JobProcessingStatus.processing;
    }
  }

  // Clean up subscriptions when provider is disposed
  @override
  void dispose() {
    _scanSubscription?.cancel();
    super.dispose();
  }

  // Helper methods for backward compatibility
  void _setLoading(bool loading) {
    _isLoading = loading;
    // Don't notify here - let the calling method control when to notify
  }

  void _setError(String error) {
    _error = error;
    // Don't notify here - let the calling method control when to notify
  }

  void _clearError() {
    _error = null;
    // Don't notify here - let the calling method control when to notify
  }

  // Delete a scan and its associated data
  Future<bool> deleteScan(String scanId) async {
    _setLoading(true);
    _clearError();

    try {
      // Call the SupabaseService to delete the scan
      final success = await _supabaseService.deleteScan(scanId);

      if (success) {
        // Remove the deleted scan from local cache if successful
        _scans.removeWhere((scan) => scan.scanId == scanId);
        notifyListeners();
      } else {
        _setError('Failed to delete scan');
      }

      return success;
    } catch (e) {
      _setError('Error deleting scan: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }
}
