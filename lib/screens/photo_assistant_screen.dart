import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/scan_result.dart';
import '../providers/settings_provider.dart';
import '../services/database_service.dart';
import '../services/ml_service.dart';
import '../services/photo_feedback_service.dart';
import '../services/sound_service.dart';

/// AI Photo Assistant — the main user-facing feature screen.
///
/// Picks ONE photo and runs all three ML analyses concurrently:
///   • Face Detection  → expression / eye-state tips
///   • Image Labeling  → scene / lighting tips
///   • Selfie Segmentation → subject framing tips
///
/// Results are combined into a quality score (0-100) + actionable tips.
class PhotoAssistantScreen extends StatefulWidget {
  const PhotoAssistantScreen({super.key});

  @override
  State<PhotoAssistantScreen> createState() => _PhotoAssistantScreenState();
}

class _PhotoAssistantScreenState extends State<PhotoAssistantScreen> {
  File? _imageFile;
  bool _isAnalyzing = false;

  List<Face> _faces = [];
  List<ImageLabel> _labels = [];
  double? _personPercentage;
  Uint8List? _maskOverlay;
  int? _score;
  List<PhotoTip>? _tips;

  final _picker = ImagePicker();

  // ── Analysis ───────────────────────────────────────────────────────────────

  Future<void> _analyze(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    setState(() {
      _imageFile = File(picked.path);
      _isAnalyzing = true;
      _faces = [];
      _labels = [];
      _personPercentage = null;
      _maskOverlay = null;
      _score = null;
      _tips = null;
    });

    try {
      final file = _imageFile!;

      // Run all 3 analyses concurrently for speed
      final results = await Future.wait<dynamic>([
        MLService.detectFaces(file),
        MLService.labelImage(file),
        MLService.segmentSelfie(file),
      ]);

      final faces = results[0] as List<Face>;
      final labels = results[1] as List<ImageLabel>;
      final mask = results[2]; // SegmentationMask?

      double? personPct;
      Uint8List? overlay;
      if (mask != null) {
        personPct = MLService.calculatePersonPercentage(mask);
        overlay = await MLService.maskToOverlayImage(mask);
      }

      final score = PhotoFeedbackService.computeScore(
        faces: faces,
        labels: labels,
        personPercentage: personPct,
      );
      final tips = PhotoFeedbackService.generateTips(
        faces: faces,
        labels: labels,
        personPercentage: personPct,
      );

      setState(() {
        _faces = faces;
        _labels = labels;
        _personPercentage = personPct;
        _maskOverlay = overlay;
        _score = score;
        _tips = tips;
        _isAnalyzing = false;
      });

      if (mounted) {
        final settings = Provider.of<SettingsProvider>(context, listen: false);
        SoundService.playFeedback(settings);
      }
    } catch (e) {
      setState(() => _isAnalyzing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
        );
      }
    }
  }

  Future<void> _save() async {
    if (_imageFile == null || _score == null) return;
    final appDir = await getApplicationDocumentsDirectory();
    final fileName =
        'photo_assistant_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final saved = await _imageFile!.copy('${appDir.path}/$fileName');

    final resultData = jsonEncode({
      'score': _score,
      'faces': _faces.length,
      'personPct': _personPercentage,
      'labels': _labels.take(5).map((l) => l.label).toList(),
    });

    await DatabaseService().insertResult(
      ScanResult(
        type: 'photo_assistant',
        imagePath: saved.path,
        resultData: resultData,
        timestamp: DateTime.now().toIso8601String(),
      ),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.resultSaved)),
      );
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.photoReport)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Pick source buttons ────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isAnalyzing
                        ? null
                        : () => _analyze(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: Text(l10n.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: _isAnalyzing
                        ? null
                        : () => _analyze(ImageSource.gallery),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.photo_library),
                        const SizedBox(width: 8),
                        Text(l10n.gallery),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Photo preview with segmentation overlay ────────────────
            if (_imageFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.file(
                      _imageFile!,
                      height: 260,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    if (_maskOverlay != null)
                      Opacity(
                        opacity: 0.45,
                        child: Image.memory(
                          _maskOverlay!,
                          height: 260,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // ── Analyzing indicator ────────────────────────────────────
            if (_isAnalyzing)
              Column(
                children: [
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(l10n.analyzing, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                ],
              ),

            // ── Results ───────────────────────────────────────────────
            if (_score != null) ...[
              _ScoreCard(score: _score!, l10n: l10n),
              const SizedBox(height: 12),
              _TipsCard(tips: _tips!, l10n: l10n),
              if (_labels.isNotEmpty) ...[
                const SizedBox(height: 12),
                _SceneCard(labels: _labels.take(5).toList(), l10n: l10n),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: Text(l10n.saveResult),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                ),
              ),
            ],

            // ── Empty state hint ──────────────────────────────────────
            if (_imageFile == null && !_isAnalyzing)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 56),
                child: Column(
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      size: 72,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.35),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.tapPhotoToStart,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                        height: 1.5,
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
}

// ── Score Card ───────────────────────────────────────────────────────────────

class _ScoreCard extends StatelessWidget {
  final int score;
  final AppLocalizations l10n;

  const _ScoreCard({required this.score, required this.l10n});

  Color get _color {
    if (score >= 80) return Colors.green;
    if (score >= 55) return Colors.orange;
    return Colors.red;
  }

  String get _label {
    if (score >= 80) return 'Excellent';
    if (score >= 65) return 'Good';
    if (score >= 50) return 'Fair';
    return 'Needs Work';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            // Circular score indicator
            SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 6,
                    backgroundColor: _color.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(_color),
                  ),
                  Text(
                    '$score',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.photoScore,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _label,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _color,
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
}

// ── Tips Card ────────────────────────────────────────────────────────────────

class _TipsCard extends StatelessWidget {
  final List<PhotoTip> tips;
  final AppLocalizations l10n;

  const _TipsCard({required this.tips, required this.l10n});

  Color _tipColor(BuildContext context, TipType type) {
    switch (type) {
      case TipType.good:
        return Colors.green;
      case TipType.warning:
        return Colors.red;
      case TipType.suggestion:
        return Theme.of(context).colorScheme.primary;
      case TipType.info:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tips_and_updates, size: 18),
                const SizedBox(width: 8),
                Text(
                  l10n.aiTips,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...tips.map(
              (tip) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      tip.icon,
                      size: 18,
                      color: _tipColor(context, tip.type),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tip.message,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Scene Context Card ───────────────────────────────────────────────────────

class _SceneCard extends StatelessWidget {
  final List<ImageLabel> labels;
  final AppLocalizations l10n;

  const _SceneCard({required this.labels, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.image_search, size: 18),
                const SizedBox(width: 8),
                Text(
                  l10n.sceneContext,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: labels
                  .map(
                    (label) => Chip(
                      label: Text(
                        '${label.label} '
                        '${(label.confidence * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 12),
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
