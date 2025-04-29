import 'package:flutter/material.dart';
import '../models/diagnostic_result.dart';

class DiagnosisCard extends StatelessWidget {
  final DiagnosticResult result;
  final VoidCallback? onTap;

  const DiagnosisCard({
    Key? key,
    required this.result,
    this.onTap,
  }) : super(key: key);

  // Get color based on condition
  Color _getConditionColor() {
    switch (result.condition.toLowerCase()) {
      case 'normal':
        return Colors.green;
      case 'conjunctivitis':
        return Colors.yellow.shade700;
      case 'cataract':
        return Colors.orange;
      case 'glaucoma':
        return Colors.red.shade700;
      case 'diabeticretinopathy':
      case 'diabetic retinopathy':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  // Get icon based on condition
  IconData _getConditionIcon() {
    switch (result.condition.toLowerCase()) {
      case 'normal':
        return Icons.check_circle;
      case 'conjunctivitis':
        return Icons.remove_red_eye;
      case 'cataract':
        return Icons.opacity;
      case 'glaucoma':
        return Icons.warning;
      case 'diabeticretinopathy':
      case 'diabetic retinopathy':
        return Icons.bloodtype;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getConditionColor();
    final icon = _getConditionIcon();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.5), width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      result.condition.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: color,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      result.severity.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                result.diagnosis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (result.recommendations.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Recommendations:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                ...result.recommendations.map((rec) => Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.arrow_right, size: 16),
                          const SizedBox(width: 4),
                          Expanded(child: Text(rec)),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
