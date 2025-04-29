import 'dart:convert';
import 'diagnostic_result.dart';

class ScanResult {
  final String id;
  final String patientId;
  final String eyeSide;
  final String imageUrl;
  final String? thumbnailUrl;
  final DateTime scanDate;
  final List<DiagnosticResult> diagnosticResults;
  final String? notes;
  final String? status;
  final DateTime createdAt;

  ScanResult({
    required this.id,
    required this.patientId,
    required this.eyeSide,
    required this.imageUrl,
    this.thumbnailUrl,
    required this.scanDate,
    required this.diagnosticResults,
    this.notes,
    this.status,
    required this.createdAt,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    // Process diagnostic results
    List<DiagnosticResult> diagnosticResults = [];

    // Check if scan_results is present (from Supabase)
    if (json['scan_results'] != null &&
        json['scan_results'] is List &&
        json['scan_results'].isNotEmpty) {
      for (var result in json['scan_results']) {
        List<String> recommendations = [];

        // Extract recommendations - handle different formats
        if (result['recommendations'] != null) {
          if (result['recommendations'] is Map) {
            // Handle case where recommendations is a JSONB object with 'suggestions' array
            var recsMap = result['recommendations'] as Map;
            if (recsMap.containsKey('suggestions') &&
                recsMap['suggestions'] is List) {
              recommendations = (recsMap['suggestions'] as List)
                  .map((item) => item.toString())
                  .toList();
            }
          } else if (result['recommendations'] is List) {
            // Handle case where recommendations is directly a List
            recommendations = (result['recommendations'] as List)
                .map((item) => item.toString())
                .toList();
          } else if (result['recommendations'] is String) {
            // Handle case where it might be a String (possibly JSON)
            try {
              var recsJson = jsonDecode(result['recommendations']);
              if (recsJson is List) {
                recommendations =
                    recsJson.map((item) => item.toString()).toList();
              }
            } catch (_) {
              // If not valid JSON, just add as a single recommendation
              recommendations.add(result['recommendations'].toString());
            }
          }
        }

        // If still no recommendations, add default based on condition
        if (recommendations.isEmpty) {
          recommendations = _getDefaultRecommendations(
              result['condition']?.toString() ?? 'unknown');
        }

        diagnosticResults.add(
          DiagnosticResult(
            id: result['id'] ?? '',
            scanId: json['id'] ?? '',
            condition: result['condition'] ?? 'unknown',
            confidence: (result['confidence'] is int)
                ? (result['confidence'] as int).toDouble()
                : result['confidence']?.toDouble() ?? 0.0,
            severity: result['severity'] ?? 'unknown',
            diagnosis: result['diagnosis'] ?? '',
            recommendations: recommendations,
            createdAt: result['created_at'] != null
                ? DateTime.parse(result['created_at'].toString())
                : DateTime.now(),
          ),
        );
      }
    }
    // Legacy format - fallback to old format if scan_results not available
    else if (json['diagnostics'] != null) {
      final diagnostics = json['diagnostics'];
      List<String> recommendations = [];

      // Extract recommendations - handle different formats
      if (json['recommendations'] != null) {
        if (json['recommendations'] is Map) {
          // Handle case where recommendations is a JSONB object with 'suggestions' array
          var recsMap = json['recommendations'] as Map;
          if (recsMap.containsKey('suggestions') &&
              recsMap['suggestions'] is List) {
            recommendations = (recsMap['suggestions'] as List)
                .map((item) => item.toString())
                .toList();
          }
        } else if (json['recommendations'] is List) {
          // Handle case where recommendations is directly a List
          recommendations = (json['recommendations'] as List)
              .map((item) => item.toString())
              .toList();
        }
      }

      // If still no recommendations, add default based on condition
      if (recommendations.isEmpty) {
        recommendations = _getDefaultRecommendations(
            diagnostics['condition']?.toString() ?? 'unknown');
      }

      diagnosticResults.add(
        DiagnosticResult(
          id: diagnostics['id'] ?? '',
          scanId: json['id'] ?? '',
          condition: diagnostics['condition'] ?? 'unknown',
          confidence: (diagnostics['confidence'] is int)
              ? (diagnostics['confidence'] as int).toDouble()
              : diagnostics['confidence']?.toDouble() ?? 0.0,
          severity: diagnostics['severity'] ?? 'unknown',
          diagnosis: diagnostics['diagnosis'] ?? '',
          recommendations: recommendations,
          createdAt: diagnostics['createdAt'] != null
              ? DateTime.parse(diagnostics['createdAt'].toString())
              : DateTime.now(),
        ),
      );
    }

    // Return the scan result with the diagnostic results
    return ScanResult(
      id: json['id'] as String,
      patientId:
          json['patientId'] as String? ?? json['user_id'] as String? ?? '',
      eyeSide: json['eyeSide'] as String? ??
          json['eye_side'] as String? ??
          'unknown',
      imageUrl: json['imageUrl'] as String? ??
          json['image_url'] as String? ??
          json['image_path'] as String? ??
          '',
      thumbnailUrl: json['thumbnailUrl'] as String? ??
          json['thumbnail_url'] as String? ??
          json['image_path'] as String?,
      scanDate: json['scanDate'] != null
          ? DateTime.parse(json['scanDate'].toString())
          : json['created_at'] != null
              ? DateTime.parse(json['created_at'].toString())
              : DateTime.now(),
      diagnosticResults: diagnosticResults,
      notes: json['notes'] as String?,
      status: json['status'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : json['created_at'] != null
              ? DateTime.parse(json['created_at'].toString())
              : DateTime.now(),
    );
  }

  // Helper method to provide default recommendations based on eye condition
  static List<String> _getDefaultRecommendations(String condition) {
    switch (condition.toLowerCase()) {
      case 'cataract':
        return [
          'Consult an ophthalmologist for proper evaluation',
          'Consider cataract surgery if vision is significantly affected',
          'Use brighter lighting for reading and other activities',
          'Protect your eyes from UV exposure with sunglasses'
        ];
      case 'glaucoma':
        return [
          'Take prescribed eye drops regularly to control intraocular pressure',
          'Have regular eye pressure checks',
          'Avoid activities that increase eye pressure',
          'Consider lifestyle changes like moderate exercise and balanced diet'
        ];
      case 'pterygium':
        return [
          'Protect eyes from sunlight, wind, and dust with sunglasses',
          'Use artificial tears to keep the eye surface moist',
          'Avoid dry, dusty environments when possible',
          'Consider surgical removal if vision is affected or for cosmetic reasons'
        ];
      case 'keratoconus':
        return [
          'Consider specialized contact lenses for vision correction',
          'Avoid rubbing eyes as it can worsen the condition',
          'Regular follow-ups with your eye doctor to monitor progression',
          'Discuss corneal cross-linking procedure to prevent progression'
        ];
      case 'strabismus':
        return [
          'Consider vision therapy exercises',
          'Consult an ophthalmologist about potential corrective surgery',
          'Use prescribed eyeglasses or prism lenses if recommended',
          'For children, patching treatment may be recommended'
        ];
      case 'pink_eye':
        return [
          'Avoid touching or rubbing your eyes',
          'Wash hands frequently to prevent spreading infection',
          'Use cool compresses to relieve discomfort',
          'Complete the full course of prescribed antibiotics if bacterial'
        ];
      case 'stye':
        return [
          'Apply warm compresses to the affected eye several times daily',
          'Keep the eyelid clean and avoid eye makeup',
          'Do not squeeze or try to pop the stye',
          'Consult a doctor if it doesn\'t improve within a week'
        ];
      case 'trachoma':
        return [
          'Complete the full course of prescribed antibiotics',
          'Practice good hygiene - wash face and hands regularly',
          'Avoid sharing towels, pillows, or other personal items',
          'Consider surgery for eyelid correction in advanced cases'
        ];
      case 'uveitis':
        return [
          'Take anti-inflammatory medications as prescribed',
          'Protect eyes from bright light with sunglasses',
          'Regular follow-up visits to monitor the condition',
          'Discuss long-term management strategies with your ophthalmologist'
        ];
      case 'healthy':
        return [
          'Continue regular eye check-ups',
          'Maintain a healthy diet rich in vitamins A and E',
          'Use eye protection in bright sunlight',
          'Take regular breaks when using digital screens'
        ];
      default:
        return [
          'Consult with an ophthalmologist for proper evaluation',
          'Protect your eyes from UV exposure with sunglasses',
          'Maintain good eye hygiene and overall health',
          'Schedule regular eye examinations'
        ];
    }
  }
}
