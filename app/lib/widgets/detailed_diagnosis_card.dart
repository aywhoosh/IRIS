import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/diagnostic_result.dart';

class DetailedDiagnosisCard extends StatelessWidget {
  final DiagnosticResult result;
  final VoidCallback? onTap;

  const DetailedDiagnosisCard({
    Key? key,
    required this.result,
    this.onTap,
  }) : super(key: key);

  // Get color based on condition
  Color _getConditionColor(BuildContext context) {
    final Map<String, Color> conditionColors = {
      'normal': Colors.green.shade600,
      'healthy': Colors.green.shade600,
      'conjunctivitis': Colors.orange.shade600,
      'pink_eye': Colors.orange.shade600,
      'cataract': Colors.amber.shade700,
      'glaucoma': Colors.red.shade700,
      'diabeticretinopathy': Colors.purple.shade700,
      'diabetic retinopathy': Colors.purple.shade700,
      'pterygium': Colors.deepOrange.shade400,
      'keratoconus': Colors.purple.shade600,
      'strabismus': Colors.blue.shade700,
      'stye': Colors.brown.shade500,
      'trachoma': Colors.deepPurple.shade700,
      'uveitis': Colors.red.shade900,
    };

    return conditionColors[result.condition.toLowerCase()] ??
        Theme.of(context).primaryColor;
  }

  // Get an icon asset based on condition
  String _getIconAsset() {
    switch (result.condition.toLowerCase()) {
      case 'cataract':
        return 'assets/icons/cataract.svg';
      case 'glaucoma':
        return 'assets/icons/glaucoma.svg';
      case 'conjunctivitis':
      case 'pink_eye':
        return 'assets/icons/conjunctivitis.svg';
      case 'diabeticretinopathy':
      case 'diabetic retinopathy':
      case 'retinopathy':
        return 'assets/icons/retinopathy.svg';
      default:
        return 'assets/eye.svg';
    }
  }

  // Get a description of what causes this condition
  String _getCauseDescription() {
    switch (result.condition.toLowerCase()) {
      case 'normal':
      case 'healthy':
        return 'Your eyes appear healthy with no signs of conditions requiring attention.';
      case 'cataract':
        return 'Cataracts are caused by protein buildup in the lens of your eye, making it cloudy. This typically develops with age, but can also be caused by injury, certain medications, or medical conditions like diabetes.';
      case 'glaucoma':
        return 'Glaucoma typically occurs when fluid builds up in the front part of your eye, increasing pressure and damaging the optic nerve. It can be hereditary and may not show symptoms until vision loss occurs.';
      case 'conjunctivitis':
      case 'pink_eye':
        return 'Conjunctivitis is an inflammation of the conjunctiva (the thin transparent layer covering the eye) caused by allergies, irritants, bacteria, or viruses. It\'s often contagious in its viral or bacterial forms.';
      case 'diabeticretinopathy':
      case 'diabetic retinopathy':
        return 'Diabetic retinopathy is caused by damage to blood vessels in the retina due to high blood sugar levels. It develops in people with diabetes when sugar blocks the tiny blood vessels that nourish the retina.';
      case 'pterygium':
        return 'Pterygium is caused by prolonged exposure to ultraviolet light, dust, and wind. It\'s a growth of pink, fleshy tissue on the conjunctiva that can extend to the cornea.';
      case 'keratoconus':
        return 'Keratoconus occurs when the cornea thins and bulges outward into a cone shape, causing distorted vision. The exact cause is unknown, but genetic and environmental factors are believed to contribute.';
      case 'strabismus':
        return 'Strabismus is caused by imbalanced muscles that position the eyes, neurological problems, or other conditions. It can be hereditary and may develop in childhood or adulthood.';
      case 'stye':
        return 'A stye is caused by a bacterial infection in an oil gland or hair follicle at the edge of the eyelid. Poor hygiene, stress, and hormonal changes can contribute to their formation.';
      case 'trachoma':
        return 'Trachoma is caused by a bacterial infection (Chlamydia trachomatis) and is spread through direct contact with infected eye or nose discharge. It\'s prevalent in areas with limited access to clean water and sanitation.';
      case 'uveitis':
        return 'Uveitis is an inflammation of the uvea (middle layer of the eye) caused by immune system conditions, infections, or exposure to toxins. Some cases have no identifiable cause.';
      default:
        return 'This condition may have various causes. Consult with an ophthalmologist for a proper diagnosis and explanation.';
    }
  }

  // Get additional information about the long-term effects
  String _getLongTermEffects() {
    switch (result.condition.toLowerCase()) {
      case 'normal':
      case 'healthy':
        return 'Maintaining regular check-ups can help preserve your eye health for years to come.';
      case 'cataract':
        return 'Without treatment, cataracts can lead to increasingly blurred vision, increased sensitivity to glare, difficulty with night vision, and eventually significant vision loss that impacts daily activities.';
      case 'glaucoma':
        return 'If untreated, glaucoma can cause progressive vision loss starting with peripheral vision, leading to tunnel vision and potentially complete blindness. Early detection and treatment are crucial.';
      case 'conjunctivitis':
      case 'pink_eye':
        return 'Most cases resolve without long-term effects, but severe or untreated bacterial cases can lead to corneal damage. Chronic conjunctivitis may indicate underlying conditions requiring attention.';
      case 'diabeticretinopathy':
      case 'diabetic retinopathy':
        return 'Advanced stages can cause retinal detachment, glaucoma, or vision loss. Proper management of diabetes and early treatment are essential to prevent these complications.';
      case 'pterygium':
        return 'If it grows over the cornea, it can distort the shape of the cornea\'s surface, causing astigmatism and affecting vision. Large pterygiums may require surgical removal.';
      case 'keratoconus':
        return 'Progressive thinning and bulging can lead to significant vision distortion, requiring special contact lenses or, in advanced cases, corneal transplant surgery.';
      case 'strabismus':
        return 'Untreated strabismus can lead to amblyopia (lazy eye), double vision, poor depth perception, and vision loss in the affected eye.';
      case 'stye':
        return 'Most styes heal without complications, but recurrent styes may indicate an underlying condition like blepharitis or may require medical intervention.';
      case 'trachoma':
        return 'Repeated infections can lead to scarring of the eyelid, causing the eyelashes to turn inward and scratch the cornea (trichiasis), potentially resulting in corneal scarring and blindness.';
      case 'uveitis':
        return 'Chronic or untreated uveitis can lead to glaucoma, cataracts, retinal problems, and permanent vision loss. Early diagnosis and management are essential.';
      default:
        return 'Without proper diagnosis and treatment, eye conditions can progress and potentially lead to vision impairment or loss. Consult with an ophthalmologist for proper care.';
    }
  }

  // Format condition name for display
  String _formatConditionName() {
    if (result.condition.toLowerCase() == 'diabeticretinopathy') {
      return 'Diabetic Retinopathy';
    }

    // Capitalize first letter of each word and handle special cases
    return result.condition
        .replaceAllMapped(RegExp(r'[A-Z]'), (match) => ' ${match.group(0)}')
        .split('_')
        .join(' ')
        .trim()
        .split(' ')
        .map((word) => word.isEmpty
            ? ''
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
  }

  void _showDetailedInfo(BuildContext context, Color color) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final dialogWidth = isTablet ? size.width * 0.7 : size.width * 0.9;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        insetPadding: EdgeInsets.symmetric(
          horizontal: (size.width - dialogWidth) / 2,
          vertical: 24,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with condition name
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  color: color,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: SvgPicture.asset(
                          _getIconAsset(),
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
                              _formatConditionName(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Severity: ${result.severity.toUpperCase()}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content sections
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Official diagnosis
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
                        result.diagnosis,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // What causes this condition
                      const Text(
                        'WHAT CAUSES THIS CONDITION',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getCauseDescription(),
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Long-term effects
                      const Text(
                        'LONG-TERM EFFECTS',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getLongTermEffects(),
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Recommendations
                      const Text(
                        'RECOMMENDATIONS',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...result.recommendations.map((rec) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: color,
                                  size: 18,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    rec,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),

                      const SizedBox(height: 20),

                      // Confidence level indicator
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'AI CONFIDENCE LEVEL',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                '${(result.confidence * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: result.confidence,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Footer with disclaimer
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  color: Colors.grey.shade100,
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'This is an AI-powered analysis. Always consult with a healthcare professional for accurate diagnosis and treatment.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Close button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _getConditionColor(context);
    final conditionName = _formatConditionName();
    final confidencePct = (result.confidence * 100).toInt();
    final iconAsset = _getIconAsset();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: color.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: () => _showDetailedInfo(context, color),
        borderRadius: BorderRadius.circular(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with condition name and confidence
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                            conditionName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  result.severity.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '$confidencePct% confidence',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.info_outline,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),

              // Diagnosis summary
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.diagnosis,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (result.recommendations.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'PRIMARY RECOMMENDATION',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
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
                              result.recommendations.first,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // "View more" button
              Container(
                color: Colors.grey.shade50,
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'View detailed information',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: color,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
