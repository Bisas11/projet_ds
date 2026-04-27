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
        return Icons.label_rounded;
      case 'selfie_segmentation':
        return Icons.crop_free_rounded;
      case 'face_detection':
        return Icons.face_rounded;
      default:
        return Icons.image_rounded;
    }
  }

  /// Get a color for the scan type badge.
  Color _getTypeColor(String type) {
    switch (type) {
      case 'labeling':
        return const Color(0xFF6366F1);
      case 'selfie_segmentation':
        return const Color(0xFF0D9488);
      case 'face_detection':
        return const Color(0xFFF97316);
      default:
        return Colors.grey;
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
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: _clearAll,
              tooltip: l10n.deleteAll,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
          ? _HistoryEmptyState(message: l10n.noHistory)
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final result = _results[index];
                final imageFile = File(result.imagePath);
                final imageExists = imageFile.existsSync();
                final typeColor = _getTypeColor(result.type);
                final typeIcon = _getTypeIcon(result.type);
                final timestamp = result.timestamp
                    .substring(0, 16)
                    .replaceAll('T', '  ·  ');

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {},
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Thumbnail
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: imageExists
                                  ? Image.file(
                                      imageFile,
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 64,
                                      height: 64,
                                      color: typeColor.withOpacity(0.1),
                                      child: Icon(
                                        typeIcon,
                                        color: typeColor,
                                        size: 28,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 14),
                            // Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Type badge + timestamp
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: typeColor.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          _getTypeLabel(result.type, l10n),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: typeColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _getResultSummary(result, l10n),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    timestamp,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.5),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            // Delete button
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.4),
                                size: 20,
                              ),
                              onPressed: () => _deleteResult(result),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ── History empty state ────────────────────────────────────────────────────

class _HistoryEmptyState extends StatelessWidget {
  final String message;
  const _HistoryEmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withOpacity(0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.history_rounded,
              size: 52,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
            ),
          ),
        ],
      ),
    );
  }
}
