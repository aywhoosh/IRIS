/// Represents a summary of a past scan, used for history lists.
/// Corresponds to the data returned by the `/api/scans/user/me` endpoint.

class ScanSummary {
  final String id;
  final String scanId;
  final String eyeSide;
  final String? thumbnailUrl;
  final int? imageQuality;
  final DateTime scanDate;
  final String? status;
  final DateTime createdAt;

  ScanSummary({
    required this.id,
    required this.scanId,
    required this.eyeSide,
    this.thumbnailUrl,
    this.imageQuality,
    required this.scanDate,
    this.status,
    required this.createdAt,
  });

  /// Creates a ScanSummary object from a JSON map.
  factory ScanSummary.fromJson(Map<String, dynamic> json) {
    return ScanSummary(
      id: json['id'] as String? ?? '',
      scanId: json['scan_id'] as String? ?? json['id'] as String? ?? '',
      eyeSide: json['eye_side'] as String? ?? 'unknown',
      thumbnailUrl: json['thumbnail_url'] as String?,
      imageQuality: json['image_quality'] as int?,
      scanDate: json['scan_date'] != null
          ? DateTime.parse(json['scan_date'] as String)
          : DateTime.now(),
      status: json['status'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}
