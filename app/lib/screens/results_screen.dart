import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/scan_provider.dart';
import '../models/scan_result.dart';
import '../widgets/detailed_diagnosis_card.dart';

class ResultsScreen extends StatefulWidget {
  final String scanId;

  const ResultsScreen({
    super.key,
    required this.scanId,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  ScanResult? _scanResult;

  @override
  void initState() {
    super.initState();
    _loadScanResult();
  }

  Future<void> _loadScanResult() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final scanProvider = Provider.of<ScanProvider>(context, listen: false);
      final response = await scanProvider.getScanResult(widget.scanId);

      setState(() {
        if (response.success) {
          _scanResult = response.data;
        } else {
          _errorMessage = response.message;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading scan results: $e';
        _isLoading = false;
      });
    }
  }

  // Show a confirmation dialog before deleting the scan
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Scan?'),
        content: const Text(
            'This will permanently delete this scan and all its diagnostic results. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              // Get a reference to the provider before any navigation
              final scanProvider =
                  Provider.of<ScanProvider>(context, listen: false);

              // Close the dialog first
              Navigator.pop(dialogContext);

              // Show loading indicator
              setState(() {
                _isLoading = true;
              });

              // Delete the scan using the stored provider reference
              final success = await scanProvider.deleteScan(_scanResult!.id);

              // Handle result
              if (success) {
                // Show a simple snackbar instead of using the unstable overlay
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: const [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 10),
                          Text('Scan deleted successfully'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }

                // Navigate back after a short delay
                Future.delayed(const Duration(milliseconds: 1200), () {
                  if (mounted) {
                    Navigator.pop(context);
                  }
                });
              } else {
                setState(() {
                  _isLoading = false;
                });
                if (mounted) {
                  // Check if widget is still mounted
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to delete scan'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'DELETE',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Results'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context)
              .pushNamedAndRemoveUntil('/', (route) => false),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete Scan',
            onPressed: () {
              _showDeleteConfirmation(context);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
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
                          onPressed: _loadScanResult,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Eye scan image
                      if (_scanResult?.imageUrl != null)
                        Container(
                          height: 200,
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            image: DecorationImage(
                              image: NetworkImage(_scanResult!.imageUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                      // Scan details
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Scan Details',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                                'Eye Side',
                                _scanResult!.eyeSide == 'left'
                                    ? 'Left Eye'
                                    : 'Right Eye'),
                            _buildDetailRow('Scan Date',
                                _formatDate(_scanResult!.scanDate)),
                            if (_scanResult!.notes != null &&
                                _scanResult!.notes!.isNotEmpty)
                              _buildDetailRow('Notes', _scanResult!.notes!),
                          ],
                        ),
                      ),

                      const Divider(),

                      // Diagnostic results
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Diagnostic Results',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 16),
                            if (_scanResult!.diagnosticResults.isEmpty)
                              const Center(
                                child: Text('No diagnostic results available'),
                              )
                            else
                              for (var result in _scanResult!.diagnosticResults)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: DetailedDiagnosisCard(
                                    result: result,
                                    onTap: () {
                                      // Popup is handled inside the card
                                    },
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
