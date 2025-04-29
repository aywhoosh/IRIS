import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PulsatingOrb extends StatefulWidget {
  final dynamic imagePath;
  final double size;
  final bool animate;

  const PulsatingOrb({
    super.key,
    required this.imagePath,
    required this.size,
    this.animate = true,
  });

  @override
  State<PulsatingOrb> createState() => _PulsatingOrbState();
}

class _PulsatingOrbState extends State<PulsatingOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.2),
        weight: 1,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.contain,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: widget.size * 1.2,
          maxHeight: widget.size * 1.2,
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow layers
                Container(
                  width: widget.size * 1.1,
                  height: widget.size * 1.1,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue[300]!.withAlpha(50),
                        blurRadius: 25,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
                Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: Colors.blue[100]!,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue[200]!.withAlpha(100),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: _buildImage(),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (kIsWeb) {
      if (widget.imagePath is Uint8List) {
        return Image.memory(
          widget.imagePath,
          fit: BoxFit.cover,
          errorBuilder: _buildErrorWidget,
        );
      }
      return Image.network(
        widget.imagePath.toString(),
        fit: BoxFit.cover,
        errorBuilder: _buildErrorWidget,
      );
    }

    return Image.file(
      File(widget.imagePath),
      fit: BoxFit.cover,
      errorBuilder: _buildErrorWidget,
    );
  }

  Widget _buildErrorWidget(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return Container(
      color: Colors.red.withAlpha(25), // 0.1 * 255
      child: const Center(
        child: Icon(
          Icons.error_outline_rounded,
          color: Colors.red,
          size: 40,
        ),
      ),
    );
  }
}
