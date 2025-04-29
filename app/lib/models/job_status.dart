/// Represents the status of a processing job.
/// Used to track the progress of eye scan analysis.

class JobStatus {
  final JobProcessingStatus status;
  final int progress;
  final String? errorMessage;

  JobStatus({
    required this.status,
    required this.progress,
    this.errorMessage,
  });

  /// Creates a JobStatus object from a JSON map.
  factory JobStatus.fromJson(Map<String, dynamic> json) {
    return JobStatus(
      status: _parseStatus(json['status'] as String? ?? 'processing'),
      progress: json['progress'] as int? ?? 0,
      errorMessage: json['error_message'] as String?,
    );
  }

  /// Helper method to convert status string to enum
  static JobProcessingStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return JobProcessingStatus.completed;
      case 'failed':
        return JobProcessingStatus.failed;
      case 'queued':
        return JobProcessingStatus.queued;
      case 'processing':
      default:
        return JobProcessingStatus.processing;
    }
  }
}

/// Enum representation of job processing status.
enum JobProcessingStatus {
  queued,
  processing,
  completed,
  failed,
}
