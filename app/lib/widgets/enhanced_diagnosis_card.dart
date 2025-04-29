import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EnhancedDiagnosisCard extends StatelessWidget {
  final String condition;
  final String severity;
  final double confidence;
  final String diagnosis;
  final List<String> recommendations;

  const EnhancedDiagnosisCard({
    Key? key,
    required this.condition,
    required this.severity,
    required this.confidence,
    required this.diagnosis,
    required this.recommendations,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Define condition-specific styling
    final Map<String, Color> conditionColors = {
      'healthy': Colors.green.shade600,
      'cataract': Colors.amber.shade700,
      'glaucoma': Colors.red.shade700,
      'pterygium': Colors.deepOrange.shade400,
      'keratoconus': Colors.purple.shade600,
      'strabismus': Colors.blue.shade700,
      'pink_eye': Colors.pink.shade700,
      'stye': Colors.brown.shade500,
      'trachoma': Colors.deepPurple.shade700,
      'uveitis': Colors.red.shade900,
    };

    // Get appropriate color based on condition
    final color =
        conditionColors[condition.toLowerCase()] ?? theme.primaryColor;

    // Get appropriate icon based on condition
    String iconAsset = 'assets/icons/';
    switch (condition.toLowerCase()) {
      case 'cataract':
        iconAsset += 'cataract.svg';
        break;
      case 'glaucoma':
        iconAsset += 'glaucoma.svg';
        break;
      case 'conjunctivitis':
      case 'pink_eye':
        iconAsset += 'conjunctivitis.svg';
        break;
      case 'diabetic_retinopathy':
      case 'retinopathy':
        iconAsset += 'retinopathy.svg';
        break;
      default:
        iconAsset = 'assets/eye.svg';
    }

    // Convert confidence to percentage
    final confidencePct = (confidence * 100).toInt();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: color.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with condition name and confidence
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                color: color,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: SvgPicture.asset(
                      iconAsset,
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${condition.toUpperCase()} - ${severity.toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: confidence,
                                  backgroundColor:
                                      Colors.white.withOpacity(0.3),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                  minHeight: 6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$confidencePct% confidence',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Diagnosis section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DIAGNOSIS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    diagnosis,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'RECOMMENDATIONS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...recommendations.map((recommendation) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: color,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                recommendation,
                                style:
                                    const TextStyle(fontSize: 14, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            // Footer with disclaimer
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              color: Colors.grey.shade100,
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.grey),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This is an AI-powered analysis. Always consult with a healthcare professional.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
