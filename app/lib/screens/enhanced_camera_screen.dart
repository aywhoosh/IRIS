import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'processing_screen.dart';

class EnhancedCameraScreen extends StatefulWidget {
  const EnhancedCameraScreen({super.key});

  @override
  State<EnhancedCameraScreen> createState() => _EnhancedCameraScreenState();
}

class _EnhancedCameraScreenState extends State<EnhancedCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isCapturing = false;
  String? _errorMessage;
  String _selectedEyeSide = 'left';
  double _zoomLevel = 1.0;
  double _maxZoom = 3.0;
  double _minZoom = 1.0;
  bool _isTorchOn = false;
  bool _showGuides = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      // Request camera permission
      final status = await Permission.camera.request();
      if (status != PermissionStatus.granted) {
        setState(() {
          _errorMessage = 'Camera permission is required';
          _isInitialized = false;
        });
        return;
      }

      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _errorMessage = 'No cameras available';
          _isInitialized = false;
        });
        return;
      }

      // Select the back camera
      final backCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      // Initialize controller
      _controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();

      // Get zoom levels
      if (_controller!.value.isInitialized) {
        _maxZoom = await _controller!.getMaxZoomLevel();
        _minZoom = await _controller!.getMinZoomLevel();
      }

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Camera initialization failed: ${e.toString()}';
        _isInitialized = false;
      });
    }
  }

  Future<void> _captureImage() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isCapturing) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      // Provide pre-capture feedback
      HapticFeedback.mediumImpact();

      // Take the picture using a simpler approach
      final XFile image = await _controller!.takePicture();

      // Release camera resources before navigation
      // This is critical to prevent GL command issues
      final String savedImagePath = image.path;

      // Update state before navigation
      setState(() {
        _isCapturing = false;
      });

      if (!mounted) return;

      // Provide success feedback
      HapticFeedback.heavyImpact();

      // IMPORTANT: Add longer delay before navigation to prevent GL command issues
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // Use pushReplacement to fully dispose of camera resources
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ProcessingScreen(
            imagePath: savedImagePath,
            eyeSide: _selectedEyeSide,
          ),
        ),
      );
    } catch (e) {
      print('Error capturing image: $e');

      setState(() {
        _isCapturing = false;
        _errorMessage = 'Error capturing image: ${e.toString()}';
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2400,
        maxHeight: 2400,
        imageQuality: 95,
      );

      if (pickedFile != null && mounted) {
        // Provide haptic feedback
        HapticFeedback.mediumImpact();

        // Store path before navigation
        final String imagePath = pickedFile.path;

        // Add delay to ensure GL commands complete
        await Future.delayed(const Duration(milliseconds: 300));

        if (!mounted) return;

        // Use pushReplacement for consistency with camera method
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ProcessingScreen(
              imagePath: imagePath,
              eyeSide: _selectedEyeSide,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: ${e.toString()}')),
        );
      }
    }
  }

  void _toggleTorch() async {
    if (_controller != null && _controller!.value.isInitialized) {
      try {
        final newValue = !_isTorchOn;
        await _controller!
            .setFlashMode(newValue ? FlashMode.torch : FlashMode.off);

        // Feedback
        HapticFeedback.selectionClick();

        setState(() {
          _isTorchOn = newValue;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Flash not available on this device')),
        );
      }
    }
  }

  void _toggleEyeSide() {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedEyeSide = _selectedEyeSide == 'left' ? 'right' : 'left';
    });
  }

  void _toggleGuides() {
    HapticFeedback.selectionClick();
    setState(() {
      _showGuides = !_showGuides;
    });
  }

  Future<void> _adjustZoom(double newZoom) async {
    if (_controller != null && _controller!.value.isInitialized) {
      newZoom = newZoom.clamp(_minZoom, _maxZoom);
      if (newZoom != _zoomLevel) {
        await _controller!.setZoomLevel(newZoom);
        setState(() {
          _zoomLevel = newZoom;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Camera preview or error message
            _buildCameraView(),

            // Camera guides overlay
            if (_isInitialized && _showGuides) _buildCameraGuides(),

            // Top controls (back button and eye selector)
            _buildTopControls(),

            // Side zoom controls
            if (_isInitialized) _buildZoomControls(),

            // Bottom controls (flash, capture, gallery)
            if (_isInitialized) _buildBottomControls(),

            // Error banner if needed
            if (_errorMessage != null && _isInitialized) _buildErrorBanner(),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    if (!_isInitialized) {
      return Container(
        color: Colors.black,
        child: Center(
          child: _errorMessage != null
              ? _buildErrorMessage()
              : const CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    try {
      return ClipRRect(
        borderRadius: BorderRadius.circular(0),
        child: CameraPreview(_controller!),
      );
    } catch (e) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text(
            'Camera preview unavailable',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    }
  }

  Widget _buildErrorMessage() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 48),
        const SizedBox(height: 16),
        Text(
          _errorMessage ?? 'Unknown error',
          style: const TextStyle(color: Colors.white, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _initializeCamera,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text('Retry'),
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: Colors.red.withOpacity(0.8),
          child: Text(
            _errorMessage ?? '',
            style: const TextStyle(color: Colors.white, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildTopControls() {
    return Positioned(
      top: 16,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Back button
            Container(
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(30),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),

            // Eye selector chip
            InkWell(
              onTap: _toggleEyeSide,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.remove_red_eye,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_selectedEyeSide.toUpperCase()} EYE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Guide toggle
            Container(
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(30),
              ),
              child: IconButton(
                icon: Icon(
                  _showGuides ? Icons.grid_on : Icons.grid_off,
                  color: Colors.white,
                ),
                onPressed: _toggleGuides,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoomControls() {
    return Positioned(
      right: 16,
      top: MediaQuery.of(context).size.height * 0.25,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () => _adjustZoom(_zoomLevel + 0.25),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '${_zoomLevel.toStringAsFixed(1)}x',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove, color: Colors.white),
              onPressed: () => _adjustZoom(_zoomLevel - 0.25),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraGuides() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Text instruction
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Center your ${_selectedEyeSide.toUpperCase()} eye in the circle',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Circular guide
          Container(
            width: MediaQuery.of(context).size.width * 0.7,
            height: MediaQuery.of(context).size.width * 0.7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: CustomPaint(
              painter: EyeGuidePainter(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 24,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.transparent,
            ],
            stops: const [0.4, 1.0],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Flash toggle
            _buildRoundButton(
              icon: _isTorchOn ? Icons.flash_on : Icons.flash_off,
              onPressed: _toggleTorch,
              label: _isTorchOn ? 'On' : 'Off',
            ),

            // Capture button
            GestureDetector(
              onTap: _isCapturing ? null : _captureImage,
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: Center(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isCapturing ? Colors.grey : Colors.white,
                    ),
                    child: _isCapturing
                        ? const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation(Colors.black),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ),

            // Gallery button
            _buildRoundButton(
              icon: Icons.photo_library,
              onPressed: _pickImageFromGallery,
              label: 'Gallery',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black45,
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class EyeGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw crosshair
    canvas.drawLine(
      Offset(center.dx - 10, center.dy),
      Offset(center.dx + 10, center.dy),
      paint,
    );

    canvas.drawLine(
      Offset(center.dx, center.dy - 10),
      Offset(center.dx, center.dy + 10),
      paint,
    );

    // Draw smaller circle to suggest iris positioning
    canvas.drawCircle(center, radius * 0.4, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
