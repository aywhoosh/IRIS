import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:math' as math;
import 'package:iris_app/theme/colors.dart';

class AuroraBackground extends StatefulWidget {
  final Widget child;
  final double intensity;
  final double speed;
  final AuroraColorScheme? colorScheme;

  const AuroraBackground({
    super.key,
    required this.child,
    this.intensity = 1.0,
    this.speed = 1.0,
    this.colorScheme,
  });

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _time = 0;

  // Control the frame rate to reduce CPU usage
  static const int _frameSkip = 10; // Even less frequent updates
  int _frameCount = 0;

  @override
  void initState() {
    super.initState();
    // Drastically reduce animation update frequency
    _ticker = createTicker((elapsed) {
      _frameCount++;
      if (_frameCount % _frameSkip == 0) {
        setState(() {
          // Much slower animation speed to reduce CPU load
          _time = elapsed.inMilliseconds / 5000.0 * widget.speed * 0.05;
        });
      }
    })
      ..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use RepaintBoundary to isolate painting operations
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          _StaticAuroraBackground(
            colorScheme: widget.colorScheme ?? IrisColors.auroraStandard,
          ),
          // Only use the animated aurora on high frame updates
          if (_frameCount % _frameSkip == 0)
            _OptimizedAuroraBackground(
              time: _time,
              intensity: widget.intensity * 0.3, // Further reduce intensity
              colorScheme: widget.colorScheme ?? IrisColors.auroraStandard,
            ),
          widget.child,
        ],
      ),
    );
  }
}

// Static background to reduce repainting
class _StaticAuroraBackground extends StatelessWidget {
  final AuroraColorScheme colorScheme;

  const _StaticAuroraBackground({
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colorScheme.background, Colors.white],
        ),
      ),
    );
  }
}

class _OptimizedAuroraBackground extends StatelessWidget {
  final double time;
  final double intensity;
  final AuroraColorScheme colorScheme;

  const _OptimizedAuroraBackground({
    required this.time,
    required this.intensity,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GlobularAuroraPainter(
        time: time,
        intensity: intensity,
        colorScheme: colorScheme,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _GlobularAuroraPainter extends CustomPainter {
  final double time;
  final double intensity;
  final AuroraColorScheme colorScheme;

  _GlobularAuroraPainter({
    required this.time,
    required this.intensity,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 32);

    // Create multiple globular shapes
    final bubbles = 3;
    for (var i = 0; i < bubbles; i++) {
      final progress = (time + i / bubbles) % 1.0;
      final x = size.width * (0.3 + 0.4 * math.sin(progress * 2 * math.pi));
      final y = size.height * (0.3 + 0.4 * math.cos(progress * 2 * math.pi));
      final gradient = RadialGradient(
        center: Alignment.center,
        radius: 1.2,
        colors: [
          Color.fromRGBO(
            colorScheme.primary.r.toInt(),
            colorScheme.primary.g.toInt(),
            colorScheme.primary.b.toInt(),
            0.3 * intensity,
          ),
          Color.fromRGBO(
            colorScheme.secondary.r.toInt(),
            colorScheme.secondary.g.toInt(),
            colorScheme.secondary.b.toInt(),
            0.2 * intensity,
          ),
          Color.fromRGBO(
            colorScheme.background.r.toInt(),
            colorScheme.background.g.toInt(),
            colorScheme.background.b.toInt(),
            0.1 * intensity,
          ),
        ],
      );

      paint.shader = gradient.createShader(
        Rect.fromCircle(center: Offset(x, y), radius: size.width * 0.4),
      );

      canvas.drawCircle(
        Offset(x, y),
        size.width * 0.4,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GlobularAuroraPainter oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.intensity != intensity ||
        oldDelegate.colorScheme != colorScheme;
  }
}
