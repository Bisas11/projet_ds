import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/scan_result.dart';
import '../widgets/result_card.dart';
import '../widgets/ml_widgets.dart';

/// Full-detail view for a saved scan result, opened from HistoryScreen.
/// Parses the stored [ScanResult.resultData] JSON and renders type-specific UI.
/// No ML processing is re-run — all data comes from the database.
class HistoryDetailScreen extends StatelessWidget {
  final ScanResult result;

  const HistoryDetailScreen({super.key, required this.result});

  // ── Helpers ──────────────────────────────────────────────────────────────

  Color get _typeColor {
    switch (result.type) {
      case 'labeling':
        return const Color(0xFF6366F1);
      case 'selfie_segmentation':
        return const Color(0xFF0D9488);
      case 'face_detection':
        return const Color(0xFFF97316);
      case 'photo_assistant':
        return const Color(0xFF4F46E5);
      default:
        return Colors.grey;
    }
  }

  IconData get _typeIcon {
    switch (result.type) {
      case 'labeling':
        return Icons.label_rounded;
      case 'selfie_segmentation':
        return Icons.crop_free_rounded;
      case 'face_detection':
        return Icons.face_rounded;
      case 'photo_assistant':
        return Icons.auto_awesome_rounded;
      default:
        return Icons.image_rounded;
    }
  }

  String _typeLabel(BuildContext context) {
    switch (result.type) {
      case 'labeling':
        return 'Image Labeling';
      case 'selfie_segmentation':
        return 'Selfie Segmentation';
      case 'face_detection':
        return 'Face Detection';
      case 'photo_assistant':
        return 'Photo Assistant';
      default:
        return result.type;
    }
  }

  String get _formattedTimestamp =>
      result.timestamp.substring(0, 16).replaceAll('T', '  ·  ');

  // ── Type-specific body builders ──────────────────────────────────────────

  Widget _buildLabelingBody(BuildContext context, dynamic data) {
    final l10n = AppLocalizations.of(context)!;
    if (data is! List || data.isEmpty) {
      return Center(child: Text(l10n.noResults));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MlSectionHeader(
          icon: Icons.label_rounded,
          label: '${data.length} ${l10n.labelsDetected}',
          color: _typeColor,
        ),
        const SizedBox(height: 8),
        ...data.map<Widget>((item) {
          final label = item['label'] as String? ?? '—';
          final confidence = (item['confidence'] as num?)?.toDouble();
          return ResultCard(
            icon: Icons.sell_rounded,
            title: label,
            confidence: confidence,
          );
        }),
      ],
    );
  }

  Widget _buildFaceDetectionBody(BuildContext context, dynamic data) {
    final l10n = AppLocalizations.of(context)!;
    if (data is! Map) {
      return Center(child: Text(l10n.noResults));
    }
    final facesCount = data['facesCount'] as int? ?? 0;
    final faces = data['faces'] as List? ?? [];

    if (facesCount == 0) {
      return MlEmptyState(
        icon: Icons.face_rounded,
        message: l10n.noFacesDetected,
        color: _typeColor,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MlSectionHeader(
          icon: Icons.face_rounded,
          label: '$facesCount ${l10n.facesDetected}',
          color: _typeColor,
        ),
        const SizedBox(height: 8),
        ...faces.asMap().entries.map<Widget>((entry) {
          final i = entry.key;
          final face = entry.value as Map;
          return _FaceCard(
            index: i + 1,
            smiling: (face['smiling'] as num?)?.toDouble(),
            leftEyeOpen: (face['leftEyeOpen'] as num?)?.toDouble(),
            rightEyeOpen: (face['rightEyeOpen'] as num?)?.toDouble(),
            headAngleY: (face['headAngleY'] as num?)?.toDouble(),
            headAngleZ: (face['headAngleZ'] as num?)?.toDouble(),
            accentColor: _typeColor,
          );
        }),
      ],
    );
  }

  Widget _buildSegmentationBody(BuildContext context, dynamic data) {
    final l10n = AppLocalizations.of(context)!;
    if (data is! Map) {
      return Center(child: Text(l10n.noResults));
    }
    final pct = (data['personPercentage'] as num?)?.toDouble() ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MlSectionHeader(
          icon: Icons.crop_free_rounded,
          label: l10n.segmentationResult,
          color: _typeColor,
        ),
        const SizedBox(height: 20),
        Center(
          child: _PercentageCircle(percentage: pct, color: _typeColor),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              pct < 5
                  ? l10n.subjectTooSmall
                  : pct >= 70
                  ? l10n.subjectTooClose
                  : l10n.goodFraming,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoAssistantBody(BuildContext context, dynamic data) {
    final l10n = AppLocalizations.of(context)!;
    if (data is! Map) {
      return Center(child: Text(l10n.noResults));
    }
    final score = data['score'] as int? ?? 0;
    final facesCount = data['faces'] as int? ?? 0;
    final personPct = (data['personPct'] as num?)?.toDouble();
    final labels = (data['labels'] as List?)?.cast<String>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Score card
        _ScoreCard(score: score, color: _typeColor),
        const SizedBox(height: 16),
        // Summary stats
        MlSectionHeader(
          icon: Icons.insights_rounded,
          label: l10n.analysisSummary,
          color: _typeColor,
        ),
        const SizedBox(height: 8),
        ResultCard(
          icon: Icons.face_rounded,
          title: l10n.facesDetected,
          subtitle:
              '$facesCount face${facesCount != 1 ? 's' : ''} in the photo',
        ),
        if (personPct != null)
          ResultCard(
            icon: Icons.crop_free_rounded,
            title: l10n.subjectCoverage,
            subtitle: '${personPct.toStringAsFixed(1)}% of the frame',
          ),
        if (labels.isNotEmpty) ...[
          const SizedBox(height: 12),
          MlSectionHeader(
            icon: Icons.label_rounded,
            label: l10n.topSceneLabels,
            color: _typeColor,
          ),
          const SizedBox(height: 8),
          ...labels.map<Widget>(
            (label) => ResultCard(icon: Icons.sell_rounded, title: label),
          ),
        ],
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    try {
      final data = jsonDecode(result.resultData);
      switch (result.type) {
        case 'labeling':
          return _buildLabelingBody(context, data);
        case 'face_detection':
          return _buildFaceDetectionBody(context, data);
        case 'selfie_segmentation':
          return _buildSegmentationBody(context, data);
        case 'photo_assistant':
          return _buildPhotoAssistantBody(context, data);
        default:
          return const Center(child: Text('Unknown result type.'));
      }
    } catch (_) {
      return const Center(child: Text('Could not parse stored result.'));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final imageFile = File(result.imagePath);
    final imageExists = imageFile.existsSync();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Hero image app bar ─────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              // Gradient overlay so the back arrow is always readable
              background: Stack(
                fit: StackFit.expand,
                children: [
                  imageExists
                      ? Hero(
                          tag: 'history_image_${result.id}',
                          child: Image.file(
                            imageFile,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                      : Container(
                          color: _typeColor.withOpacity(0.15),
                          child: Icon(_typeIcon, size: 72, color: _typeColor),
                        ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.5),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Type badge + timestamp ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _typeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_typeIcon, size: 13, color: _typeColor),
                        const SizedBox(width: 5),
                        Text(
                          _typeLabel(context),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _typeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _formattedTimestamp,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Results ────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            sliver: SliverToBoxAdapter(child: _buildBody(context)),
          ),
        ],
      ),
    );
  }
}

// ── Private sub-widgets ────────────────────────────────────────────────────

/// Face attribute card — shows one detected face's attributes.
class _FaceCard extends StatelessWidget {
  final int index;
  final double? smiling;
  final double? leftEyeOpen;
  final double? rightEyeOpen;
  final double? headAngleY;
  final double? headAngleZ;
  final Color accentColor;

  const _FaceCard({
    required this.index,
    this.smiling,
    this.leftEyeOpen,
    this.rightEyeOpen,
    this.headAngleY,
    this.headAngleZ,
    required this.accentColor,
  });

  String _pct(double? v) =>
      v == null ? 'N/A' : '${(v * 100).toStringAsFixed(1)}%';
  String _deg(double? v) => v == null ? 'N/A' : '${v.toStringAsFixed(1)}°';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Face #$index',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _InfoRow(label: l10n.smilingProbability, value: _pct(smiling)),
            _InfoRow(label: l10n.leftEyeOpen, value: _pct(leftEyeOpen)),
            _InfoRow(label: l10n.rightEyeOpen, value: _pct(rightEyeOpen)),
            _InfoRow(label: l10n.headAngleY, value: _deg(headAngleY)),
            _InfoRow(label: l10n.headAngleZ, value: _deg(headAngleZ)),
          ],
        ),
      ),
    );
  }
}

/// Simple two-column label/value row.
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Circular percentage indicator for selfie segmentation coverage.
class _PercentageCircle extends StatelessWidget {
  final double percentage;
  final Color color;
  const _PercentageCircle({required this.percentage, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: (percentage / 100).clamp(0.0, 1.0),
              strokeWidth: 10,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                AppLocalizations.of(context)!.person,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.55),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Large score display card for photo_assistant results.
class _ScoreCard extends StatelessWidget {
  final int score;
  final Color color;
  const _ScoreCard({required this.score, required this.color});

  Color _scoreColor() {
    if (score >= 81) return const Color(0xFF16A34A);
    if (score >= 66) return const Color(0xFF4ADE80);
    if (score >= 41) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }

  String _scoreLabel(AppLocalizations l10n) {
    if (score >= 80) return l10n.scoreExcellent;
    if (score >= 60) return l10n.scoreGood;
    if (score >= 40) return l10n.scoreFair;
    return l10n.scoreNeedsWork;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sc = _scoreColor();
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          children: [
            Text(
              l10n.photoScore,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$score',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: sc,
              ),
            ),
            Text(
              _scoreLabel(l10n),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: sc,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: score / 100,
                minHeight: 8,
                backgroundColor: sc.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation<Color>(sc),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
