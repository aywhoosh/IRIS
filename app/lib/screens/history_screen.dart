import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/scan_provider.dart';
import '../models/scan_summary.dart';
import 'results_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    _loadScans();
  }

  Future<void> _loadScans() async {
    final scanProvider = Provider.of<ScanProvider>(context, listen: false);
    await scanProvider.loadUserScans();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadScans,
          ),
        ],
      ),
      body: Consumer<ScanProvider>(
        builder: (context, scanProvider, child) {
          if (scanProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (scanProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading scans',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(scanProvider.error!),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loadScans,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (scanProvider.scans.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No scan history found',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text('Take your first scan to get started'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadScans,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: scanProvider.scans.length,
              itemBuilder: (context, index) {
                final scan = scanProvider.scans[index];
                return _buildScanCard(context, scan);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildScanCard(BuildContext context, ScanSummary scan) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ResultsScreen(scanId: scan.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Thumbnail or placeholder
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).colorScheme.primaryContainer,
                  image: scan.thumbnailUrl != null
                      ? DecorationImage(
                          image: NetworkImage(scan.thumbnailUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: scan.thumbnailUrl == null
                    ? Icon(
                        Icons.remove_red_eye,
                        size: 32,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              // Scan details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scan.eyeSide.capitalize(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(scan.createdAt),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 4),
                    _buildStatusChip(context, scan.status ?? 'unknown'),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String status) {
    // Return empty container if status is processing to hide the tag
    if (status.toLowerCase() == 'processing') {
      return Container();
    }

    Color color;
    String displayStatus;

    switch (status.toLowerCase()) {
      case 'completed':
        color = Colors.green;
        displayStatus = 'Completed';
        break;
      case 'failed':
        color = Colors.red;
        displayStatus = 'Failed';
        break;
      case 'queued':
        color = Colors.blue;
        displayStatus = 'Queued';
        break;
      default:
        color = Colors.grey;
        displayStatus = status.capitalize();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Color.fromRGBO(
          color.r.toInt(),
          color.g.toInt(),
          color.b.toInt(),
          0.2,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        displayStatus,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
