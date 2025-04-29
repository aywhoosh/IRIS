import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../../models/job_status.dart'; // Assuming you have this model

/// Service responsible for interacting with job processing API endpoints.
class ProcessingService {
  final ApiClient _apiClient;

  ProcessingService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetches the status of a specific processing job.
  ///
  /// Returns a [JobStatus] object.
  /// Throws [ApiException] on failure.
  Future<JobStatus> getJobStatus(String jobId) async {
    try {
      final response = await _apiClient.get(
        '/jobs/$jobId/status', // Or use AppConstants.jobStatusEndpoint(jobId)
      );
      final responseData = _processResponse(response);

      // Assuming the job status data is directly in responseData['data']
      final jobData = responseData['data'];
      if (jobData != null) {
        final status =
            JobStatus.fromJson(jobData); // Assumes JobStatus.fromJson exists
        debugPrint(
            'ProcessingService: Fetched status for job $jobId: ${status.status}');
        return status;
      } else {
        debugPrint(
            'ProcessingService: Job status data not found for job $jobId.');
        throw ApiException('Could not find status for this job.',
            statusCode: 404);
      }
    } on ApiException {
      rethrow; // Re-throw API exceptions for UI handling
    } catch (e) {
      debugPrint('ProcessingService: Error fetching job status for $jobId: $e');
      throw ApiException('Failed to retrieve job status.');
    }
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

  /// Dispose of any resources if needed
  void dispose() {
    // The ApiClient might not have a dispose method, so we'll handle it safely
    try {
      (_apiClient as dynamic).dispose();
    } catch (e) {
      debugPrint(
          'ProcessingService: ApiClient does not have dispose method: $e');
    }
  }
}
