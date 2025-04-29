import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/scan_provider.dart';
import '../models/job_status.dart';
import 'results_screen.dart';

class ProcessingScreen extends StatefulWidget {
  final String imagePath;
  final String eyeSide;

  const ProcessingScreen({
    super.key,
    required this.imagePath,
    required this.eyeSide,
  });

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

// Enhanced eye scanning animation
class ScanningEyeAnimation extends StatefulWidget {
  const ScanningEyeAnimation({super.key});

  @override
  State<ScanningEyeAnimation> createState() => _ScanningEyeAnimationState();
}

class _ScanningEyeAnimationState extends State<ScanningEyeAnimation>
    with TickerProviderStateMixin {
  late AnimationController _magnifyingGlassController;
  late AnimationController _pulseController;
  late AnimationController _scanLineController;

  late Animation<double> _positionAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scanLineAnimation;
  @override
  void initState() {
    super.initState();

    // Controller for the magnifying glass diagnostic pattern movement
    _magnifyingGlassController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    )..repeat();

    // Controller for pulsing effect
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Controller for scan line
    _scanLineController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat();

    // Z-pattern animation (custom curve for zig-zag movement)
    _positionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _magnifyingGlassController, curve: Curves.linear),
    );

    // Pulse animation for size
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Opacity animation for glowing effect
    _opacityAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Scan line animation
    _scanLineAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _magnifyingGlassController.dispose();
    _pulseController.dispose();
    _scanLineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double eyeSize = 80.0;
    const double magnifierSize = 50.0;
    final Color secondaryColor = Theme.of(context).colorScheme.secondary;

    return SizedBox(
      height: 160,
      width: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulse effect behind the eye
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: eyeSize * 1.6 * _scaleAnimation.value,
                height: eyeSize * 1.6 * _scaleAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                  boxShadow: [
                    BoxShadow(
                      color: secondaryColor
                          .withOpacity(0.3 * _opacityAnimation.value),
                      blurRadius: 20 * _opacityAnimation.value,
                      spreadRadius: 5 * _opacityAnimation.value,
                    ),
                  ],
                ),
              );
            },
          ),

          // Eye symbol with scan line
          AnimatedBuilder(
            animation: _scanLineAnimation,
            builder: (context, child) {
              return ClipOval(
                child: SizedBox(
                  width: eyeSize,
                  height: eyeSize,
                  child: Stack(
                    children: [
                      // Eye icon
                      const Center(
                        child: Icon(
                          Icons.remove_red_eye_rounded,
                          size: eyeSize,
                          color: Colors.white,
                        ),
                      ),

                      // Scanning line effect
                      Positioned.fill(
                        child: Transform.translate(
                          offset: Offset(0, eyeSize * _scanLineAnimation.value),
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: secondaryColor.withOpacity(0.8),
                              boxShadow: [
                                BoxShadow(
                                  color: secondaryColor.withOpacity(0.8),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ), // Magnifying glass with Z-pattern movement
          AnimatedBuilder(
            animation: _positionAnimation,
            builder: (context, child) {
              // Calculate Z-pattern position (top-left to top-right to bottom-left to bottom-right)
              final double value = _positionAnimation.value;
              double dx = 0.0;
              double dy = 0.0;

              if (value < 0.25) {
                // Top-left to top-right (first segment of Z)
                final segmentValue =
                    value * 4; // normalize to 0-1 for this segment
                dx = -eyeSize / 2 + segmentValue * eyeSize;
                dy = -eyeSize / 2;
              } else if (value < 0.5) {
                // Top-right to bottom-left (diagonal of Z)
                final segmentValue = (value - 0.25) * 4; // normalize to 0-1
                dx = eyeSize / 2 - segmentValue * eyeSize;
                dy = -eyeSize / 2 + segmentValue * eyeSize;
              } else if (value < 0.75) {
                // Bottom-left to bottom-right (last segment of Z)
                final segmentValue = (value - 0.5) * 4; // normalize to 0-1
                dx = -eyeSize / 2 + segmentValue * eyeSize;
                dy = eyeSize / 2;
              } else {
                // Reverse back: bottom-right to top-left (diagonal back)
                final segmentValue = (value - 0.75) * 4; // normalize to 0-1
                dx = eyeSize / 2 - segmentValue * 2 * eyeSize;
                dy = eyeSize / 2 - segmentValue * 2 * eyeSize;
              }

              return Transform.translate(
                offset: Offset(dx, dy),
                child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, _) {
                      return Transform.rotate(
                        angle: (_positionAnimation.value * 2 - 1) *
                            math.pi /
                            8, // subtle rotation
                        child: Container(
                          width: magnifierSize,
                          height: magnifierSize,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              width: 3,
                              color: Colors.white
                                  .withOpacity(_opacityAnimation.value),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: secondaryColor
                                    .withOpacity(0.5 * _opacityAnimation.value),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Magnifying glass handle
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Transform.rotate(
                                  angle: math.pi / 4,
                                  child: Container(
                                    width: 20,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.white
                                          .withOpacity(_opacityAnimation.value),
                                      borderRadius: BorderRadius.circular(2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: secondaryColor.withOpacity(
                                              0.5 * _opacityAnimation.value),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // Glass reflection effect
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  width: 10,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(
                                        0.6 * _opacityAnimation.value),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  double _progress = 0.0;
  String _currentStep = 'Preparing image...';
  bool _isUploading = true;
  String? _errorMessage;
  String? _scanId;
  String? _jobId;

  @override
  void initState() {
    super.initState();
    _processImage();
  }

  Future<void> _processImage() async {
    try {
      setState(() {
        _isUploading = true;
        _currentStep = 'Preparing image...';
        _progress = 0.1;
      });

      // Upload image
      final scanProvider = Provider.of<ScanProvider>(context, listen: false);
      final uploadResult = await scanProvider.uploadEyeScan(
        widget.imagePath,
        widget.eyeSide,
      );

      if (!uploadResult.success) {
        setState(() {
          _errorMessage = uploadResult.message;
          _isUploading = false;
        });
        return;
      }

      _scanId = uploadResult.data!.scanId;
      _jobId = uploadResult.data!.jobId;

      await _pollJobStatus();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error processing image: $e';
        _isUploading = false;
      });
    }
  }

  Future<void> _pollJobStatus() async {
    if (_jobId == null) return;

    setState(() {
      _currentStep = 'Uploading image...';
      _progress = 0.2;
    });

    final scanProvider = Provider.of<ScanProvider>(context, listen: false);
    bool isCompleted = false;
    int retryCount = 0;

    while (!isCompleted && retryCount < 60) {
      // Timeout after 60 attempts (5 minutes)
      await Future.delayed(const Duration(seconds: 2)); // Poll every 2 seconds

      final jobStatusResponse = await scanProvider.getJobStatus(_jobId!);

      if (!jobStatusResponse.success) {
        retryCount++;
        continue;
      }

      final status = jobStatusResponse.data!.status;
      final progress = jobStatusResponse.data!.progress;

      setState(() {
        _progress = 0.3 + (progress / 100 * 0.7); // Scale to 30%-100%

        switch (progress) {
          case 0:
            _currentStep = 'Waiting in queue...';
            break;
          case 10:
            _currentStep = 'Analyzing image characteristics...';
            break;
          case 30:
            _currentStep = 'Processing retinal patterns...';
            break;
          case 50:
            _currentStep = 'Detecting potential conditions...';
            break;
          case 70:
            _currentStep = 'Generating diagnostic report...';
            break;
          case 90:
            _currentStep = 'Finalizing analysis results...';
            break;
          case 100:
            _currentStep = 'Analysis complete!';
            break;
          default:
            _currentStep = 'Processing...';
        }
      });

      if (status == JobProcessingStatus.completed) {
        isCompleted = true;

        // Navigate to results screen
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ResultsScreen(scanId: _scanId!),
            ),
          );
        }
      } else if (status == JobProcessingStatus.failed) {
        setState(() {
          _errorMessage =
              jobStatusResponse.data?.errorMessage ?? 'Processing failed';
          _isUploading = false;
        });
        return;
      }

      // If we reach progress 100 but status is not completed yet
      if (progress >= 100) {
        isCompleted = true;
      }
    }

    // If we exited the loop without completing
    if (!isCompleted && mounted) {
      setState(() {
        _errorMessage = 'Processing timed out';
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primaryContainer,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Display the captured image
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white, width: 4),
                      image: DecorationImage(
                        image: FileImage(File(widget.imagePath)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (_isUploading && _errorMessage == null) ...[
                    Text(
                      _currentStep,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Eye with scanning animation
                    const ScanningEyeAnimation(),
                  ] else if (_errorMessage != null) ...[
                    Icon(
                      Icons.error_outline,
                      size: 80,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Error',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                      ),
                      child: const Text('Go Back'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
