import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iris_app/screens/processing_screen.dart';
import 'package:iris_app/theme/colors.dart';
import 'package:iris_app/widgets/aurora_background.dart';

class ScanHistoryScreen extends StatefulWidget {
  final bool animated;

  const ScanHistoryScreen({
    super.key,
    this.animated = true,
  });

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  bool _isLoading = true;
  List<ScanRecord> _scanRecords = [];

  @override
  void initState() {
    super.initState();
    _loadScanHistory();
  }

  Future<void> _loadScanHistory() async {
    // Simulate loading data from storage
    await Future.delayed(const Duration(milliseconds: 800));

    // Sample data - in a real app, this would come from local storage or a database
    setState(() {
      _scanRecords = [
        ScanRecord(
          id: '1',
          imagePath: 'assets/sample_eye1.jpg',
          scanDate: DateTime.now().subtract(const Duration(days: 2)),
          condition: 'Healthy',
          severity: 'None',
          confidence: 0.96,
          healthStatus: HealthStatus.normal,
        ),
        ScanRecord(
          id: '2',
          imagePath: 'assets/sample_eye2.jpg',
          scanDate: DateTime.now().subtract(const Duration(days: 10)),
          condition: 'Mild Cataract',
          severity: 'Low',
          confidence: 0.87,
          healthStatus: HealthStatus.warning,
        ),
        ScanRecord(
          id: '3',
          imagePath: 'assets/sample_eye3.jpg',
          scanDate: DateTime.now().subtract(const Duration(days: 30)),
          condition: 'Glaucoma',
          severity: 'Moderate',
          confidence: 0.92,
          healthStatus: HealthStatus.alert,
        ),
      ];
      _isLoading = false;
    });
  }

  Future<void> _deleteRecord(String id) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Scan Record'),
        content: const Text(
            'Are you sure you want to delete this scan record? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(color: IrisColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Delete record - in a real app, this would delete from storage
      setState(() {
        _scanRecords.removeWhere((record) => record.id == id);
      });

      // Show success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scan record deleted'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _viewScanDetails(ScanRecord record) {
    // Navigate to details screen - in a real app, this would show full details
    // For now, we'll just navigate to the processing screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProcessingScreen(
          imagePath: record.imagePath,
          eyeSide: record.eyeSide ?? 'unknown',
        ),
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
          'Scan History',
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
      body: widget.animated
          ? AuroraBackground(
              intensity: 0.3,
              speed: 0.5,
              child: _buildContent(),
            )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_scanRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No scan history yet',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your scan records will appear here',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _scanRecords.length,
      itemBuilder: (context, index) {
        final record = _scanRecords[index];
        return _ScanRecordCard(
          record: record,
          onDelete: () => _deleteRecord(record.id),
          onTap: () => _viewScanDetails(record),
        );
      },
    );
  }
}

class _ScanRecordCard extends StatelessWidget {
  final ScanRecord record;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _ScanRecordCard({
    required this.record,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final healthColor = _getHealthStatusColor(record.healthStatus);
    final formattedDate = _formatDate(record.scanDate);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color.fromRGBO(0, 0, 0, 0.05),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date and delete option
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formattedDate,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: Colors.grey.shade500,
                      onPressed: onDelete,
                      tooltip: 'Delete record',
                      splashRadius: 24,
                    ),
                  ],
                ),
              ),

              // Main content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Eye image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _buildImage(),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Scan details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: healthColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                record.condition,
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: IrisColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Severity: ${record.severity}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Confidence: ${(record.confidence * 100).toInt()}%',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Arrow indicator
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.grey.shade400,
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

  Widget _buildImage() {
    // In a real app, check if the file exists and display accordingly
    try {
      final file = File(record.imagePath);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
        );
      }
    } catch (_) {
      // File might not exist or path might be invalid
    }

    // Fallback to a placeholder
    return Container(
      color: Colors.grey.shade200,
      child: Icon(
        Icons.remove_red_eye_outlined,
        color: Colors.grey.shade400,
        size: 32,
      ),
    );
  }

  Color _getHealthStatusColor(HealthStatus status) {
    switch (status) {
      case HealthStatus.normal:
        return IrisColors.healthNormal;
      case HealthStatus.warning:
        return IrisColors.healthWarning;
      case HealthStatus.alert:
        return IrisColors.healthAlert;
      default:
        return IrisColors.healthUnknown;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year;
      return '$day/$month/$year';
    }
  }
}

class ScanRecord {
  final String id;
  final String imagePath;
  final DateTime scanDate;
  final String condition;
  final String severity;
  final double confidence;
  final HealthStatus healthStatus;
  final String? eyeSide;

  ScanRecord({
    required this.id,
    required this.imagePath,
    required this.scanDate,
    required this.condition,
    required this.severity,
    required this.confidence,
    required this.healthStatus,
    this.eyeSide,
  });
}

enum HealthStatus {
  normal,
  warning,
  alert,
  unknown,
}
