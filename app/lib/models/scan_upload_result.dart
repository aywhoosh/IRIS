class ScanUploadResult {
  final String scanId;
  final String jobId;

  ScanUploadResult({
    required this.scanId,
    required this.jobId,
  });

  factory ScanUploadResult.fromJson(Map<String, dynamic> json) {
    return ScanUploadResult(
      scanId: json['scanId'] as String? ?? json['scan_id'] as String? ?? '',
      jobId: json['jobId'] as String? ?? json['job_id'] as String? ?? '',
    );
  }
}
