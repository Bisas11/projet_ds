import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/database_service.dart';
import '../models/scan_result.dart';

/// Screen that displays the history of saved ML Kit scan results.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _dbService = DatabaseService();
  List<ScanResult> _results = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  /// Load all results from the database.
  Future<void> _loadResults() async {
    setState(() => _isLoading = true);
    final results = await _dbService.getResults();
    setState(() {
      _results = results;
      _isLoading = false;
    });
  }

  /// Delete a single result and its image file.
  Future<void> _deleteResult(ScanResult result) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.confirmDelete),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirm == true && result.id != null) {
      await _dbService.deleteImageFile(result.imagePath);
      await _dbService.deleteResult(result.id!);
      _loadResults();
    }
  }

  /// Clear all history.
  Future<void> _clearAll() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAll),
        content: Text(l10n.confirmDeleteAll),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Delete all image files
      for (final result in _results) {
        await _dbService.deleteImageFile(result.imagePath);
      }
      await _dbService.clearResults();
      _loadResults();
    }
  }

  /// Get a user-friendly label for the scan type.
  String _getTypeLabel(String type, AppLocalizations l10n) {
    switch (type) {
      case 'labeling':
        return l10n.imageLabeling;
      case 'selfie_segmentation':
        return l10n.selfieSegmentation;
      case 'face_detection':
        return l10n.faceDetection;
      default:
        return type;
    }
  }

  /// Get a short summary of the result data.
  String _getResultSummary(ScanResult result, AppLocalizations l10n) {
    try {
      final data = jsonDecode(result.resultData);
      if (result.type == 'labeling' && data is List) {
        return '${data.length} ${l10n.labelsDetected}';
      } else if (result.type == 'selfie_segmentation' && data is Map) {
        final pct = (data['personPercentage'] as num?)?.toStringAsFixed(1);
        return '${l10n.personDetected}: $pct%';
      } else if (result.type == 'face_detection' && data is Map) {
        final count = data['facesCount'] ?? 0;
        return '$count ${l10n.facesDetected}';
      }
    } catch (_) {}
    return '';
  }

  /// Get an icon for the scan type.
  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'labeling':
        return Icons.label;
      case 'selfie_segmentation':
        return Icons.face;
      case 'face_detection':
        return Icons.face_retouching_natural;
      default:
        return Icons.image;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.history),
        actions: [
          if (_results.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearAll,
              tooltip: l10n.deleteAll,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(l10n.noHistory),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final result = _results[index];
                final imageFile = File(result.imagePath);
                final imageExists = imageFile.existsSync();

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    // Show image thumbnail if it exists
                    leading: imageExists
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.file(
                              imageFile,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(_getTypeIcon(result.type), size: 40),
                    title: Text(_getTypeLabel(result.type, l10n)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_getResultSummary(result, l10n)),
                        Text(
                          result.timestamp
                              .substring(0, 16)
                              .replaceAll('T', ' '),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteResult(result),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
