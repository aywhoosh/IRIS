import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'processing_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isCapturing = false;
  String? _errorMessage;
  String _selectedEyeSide = 'left'; // Default to left eye

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
    final CameraController? controller = _controller;

    // App state changed before camera was initialized
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      setState(() {
        _errorMessage = 'Camera permission is required to use this feature';
      });
    }
  }

  Future<void> _initializeCamera() async {
    try {
      await _requestCameraPermission();

      _cameras = await availableCameras();

      if (_cameras!.isEmpty) {
        setState(() {
          _errorMessage = 'No cameras found';
          _isInitialized = false;
        });
        return;
      }

      // Use the first back camera
      final backCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();

      setState(() {
        _isInitialized = true;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error initializing camera: $e';
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
      final image = await _controller!.takePicture();

      if (!mounted) return;

      setState(() {
        _isCapturing = false;
      });

      // Navigate to processing screen
      // Update any other screens that navigate to processing
      // For example:
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProcessingScreen(
            imagePath: image.path,
            eyeSide: _selectedEyeSide,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isCapturing = false;
        _errorMessage = 'Error capturing image: $e';
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 80,
      );

      if (image != null) {
        if (!mounted) return;

        // Navigate to processing screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProcessingScreen(
              imagePath: image.path,
              eyeSide: _selectedEyeSide,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking image: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('IRIS Scanner'),
      ),
      body: Stack(
        children: [
          // Camera preview or error message
          if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _initializeCamera,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (_isInitialized && _controller != null)
            Center(
              child: SizedBox(
                width: isTablet ? 500 : double.infinity,
                height: isTablet ? 500 : null,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CameraPreview(_controller!),
                  ),
                ),
              ),
            )
          else
            const Center(child: CircularProgressIndicator()),

          // Controls overlay
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: Column(
              children: [
                // Eye side selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: const Text('Left Eye'),
                      selected: _selectedEyeSide == 'left',
                      onSelected: (_) =>
                          setState(() => _selectedEyeSide = 'left'),
                    ),
                    const SizedBox(width: 16),
                    ChoiceChip(
                      label: const Text('Right Eye'),
                      selected: _selectedEyeSide == 'right',
                      onSelected: (_) =>
                          setState(() => _selectedEyeSide = 'right'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Camera controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Gallery button
                    FloatingActionButton(
                      heroTag: 'gallery',
                      onPressed: _pickImageFromGallery,
                      child: const Icon(Icons.photo_library),
                    ),
                    // Capture button
                    FloatingActionButton(
                      heroTag: 'capture',
                      onPressed: _isInitialized ? _captureImage : null,
                      child: _isCapturing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Icon(Icons.camera),
                    ),
                    // Help button (for symmetry)
                    FloatingActionButton(
                      heroTag: 'help',
                      onPressed: () {
                        // TODO: Add help functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Position the eye clearly in the center of the frame'),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      },
                      child: const Icon(Icons.help_outline),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
