class DiagnosticResult {
  final String id;
  final String scanId;
  final String condition;
  final double confidence;
  final String severity;
  final String diagnosis;
  final List<String> recommendations;
  final DateTime createdAt;

  DiagnosticResult({
    required this.id,
    required this.scanId,
    required this.condition,
    required this.confidence,
    required this.severity,
    required this.diagnosis,
    required this.recommendations,
    required this.createdAt,
  });

  factory DiagnosticResult.fromJson(Map<String, dynamic> json) {
    return DiagnosticResult(
      id: json['id'],
      scanId: json['scanId'],
      condition: json['condition'],
      confidence: (json['confidence'] is int)
          ? (json['confidence'] as int).toDouble()
          : json['confidence']?.toDouble() ?? 0.0,
      severity: json['severity'],
      diagnosis: json['diagnosis'],
      recommendations: (json['recommendations'] as List?)
              ?.map((rec) => rec.toString())
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}
