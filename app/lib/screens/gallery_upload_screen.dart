import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iris_app/screens/processing_screen.dart';
import 'package:iris_app/theme/colors.dart';
import 'package:permission_handler/permission_handler.dart';

class GalleryUploadScreen extends StatefulWidget {
  final bool animated;

  const GalleryUploadScreen({
    super.key,
    this.animated = true,
  });

  @override
  State<GalleryUploadScreen> createState() => _GalleryUploadScreenState();
}

class _GalleryUploadScreenState extends State<GalleryUploadScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  String? _error;
  bool _isLoading = false;
  late AnimationController _previewAnimationController;
  late Animation<double> _previewScaleAnimation;

  @override
  void initState() {
    super.initState();
    _previewAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _previewScaleAnimation = CurvedAnimation(
      parent: _previewAnimationController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _previewAnimationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final status = await Permission.photos.request();
      if (!status.isGranted) {
        setState(() => _error = 'Gallery permission denied');
        return;
      }

      setState(() {
        _isLoading = true;
        _error = null;
      });

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 95,
      );

      if (image == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Validate image
      final File file = File(image.path);
      final int fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) {
        // 10MB limit
        setState(() {
          _error = 'Image size too large. Please select an image under 10MB.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _selectedImage = image;
        _isLoading = false;
      });
      _previewAnimationController.forward();
      HapticFeedback.mediumImpact();
    } catch (e) {
      setState(() {
        _error = 'Error selecting image: $e';
        _isLoading = false;
      });
    }
  }

  void _processImage() {
    if (_selectedImage == null) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return ProcessingScreen(
            imagePath: _selectedImage!.path,
            eyeSide:
                'unknown', // Default value since we don't know which eye from gallery
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IrisColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Select Image',
          style: GoogleFonts.inter(
            color: IrisColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: IrisColors.textPrimary,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) _buildErrorMessage(),
              if (_selectedImage != null) _buildImagePreview(),
              const SizedBox(height: 32),
              _buildUploadButton(),
              if (_selectedImage != null) ...[
                const SizedBox(height: 16),
                _buildProcessButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.fromRGBO(
          IrisColors.error.r.toInt(),
          IrisColors.error.g.toInt(),
          IrisColors.error.b.toInt(),
          0.1,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color.fromRGBO(
            IrisColors.error.r.toInt(),
            IrisColors.error.g.toInt(),
            IrisColors.error.b.toInt(),
            0.3,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: IrisColors.error,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: GoogleFonts.inter(
                color: IrisColors.error,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Expanded(
      child: ScaleTransition(
        scale: _previewScaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(
                  IrisColors.primary.r.toInt(),
                  IrisColors.primary.g.toInt(),
                  IrisColors.primary.b.toInt(),
                  0.2,
                ),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(
                  File(_selectedImage!.path),
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    onPressed: () {
                      setState(() => _selectedImage = null);
                      _previewAnimationController.reverse();
                    },
                    icon: const Icon(Icons.close_rounded),
                    color: Colors.white,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                      padding: const EdgeInsets.all(8),
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

  Widget _buildUploadButton() {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _pickImage,
      style: ElevatedButton.styleFrom(
        backgroundColor: IrisColors.primary,
        foregroundColor: Colors.white, // Add this to ensure text is visible
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
        disabledBackgroundColor: Color.fromRGBO(
            IrisColors.primary.r.toInt(),
            IrisColors.primary.g.toInt(),
            IrisColors.primary.b.toInt(),
            0.6), // Add this for disabled state
        disabledForegroundColor:
            Color.fromRGBO(255, 255, 255, 0.8), // Add this for disabled state
      ),
      icon: _isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.photo_library_rounded, color: Colors.white),
      label: Text(
        _selectedImage == null ? 'Select from Gallery' : 'Choose Another Image',
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white, // Explicitly set text color
        ),
      ),
    );
  }

  Widget _buildProcessButton() {
    return ElevatedButton.icon(
      onPressed: _processImage,
      style: ElevatedButton.styleFrom(
        backgroundColor: IrisColors.secondary,
        foregroundColor: Colors.white, // Add this to ensure text is visible
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      icon: const Icon(Icons.visibility_rounded, color: Colors.white),
      label: Text(
        'Analyze Image',
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white, // Explicitly set text color
        ),
      ),
    );
  }
}
