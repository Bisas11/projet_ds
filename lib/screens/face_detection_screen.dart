import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../l10n/app_localizations.dart';
import '../services/ml_service.dart';
import '../services/database_service.dart';
import '../services/sound_service.dart';
import '../providers/settings_provider.dart';
import '../models/scan_result.dart';
import '../widgets/ml_widgets.dart';

/// Screen for the Face Detection ML Kit feature.
/// Picks an image, detects faces with landmarks, contours,
/// and classifications (smiling, eyes open), and displays the results.
class FaceDetectionScreen extends StatefulWidget {
  const FaceDetectionScreen({super.key});

  @override
  State<FaceDetectionScreen> createState() => _FaceDetectionScreenState();
}

class _FaceDetectionScreenState extends State<FaceDetectionScreen> {
  File? _imageFile;
  List<Face>? _faces;
  bool _isProcessing = false;
  final _imagePicker = ImagePicker();

  /// Pick an image and run face detection.
  Future<void> _pickAndProcess(ImageSource source) async {
    final pickedFile = await _imagePicker.pickImage(source: source);
    if (pickedFile == null) return;

    setState(() {
      _imageFile = File(pickedFile.path);
      _faces = null;
      _isProcessing = true;
    });

    try {
      final faces = await MLService.detectFaces(_imageFile!);

      setState(() {
        _faces = faces;
        _isProcessing = false;
      });

      // Play feedback
      if (mounted) {
        final settings = Provider.of<SettingsProvider>(context, listen: false);
        SoundService.playFeedback(settings);
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
        );
      }
    }
  }

  /// Save the current result to the SQLite database.
  Future<void> _saveResult() async {
    if (_imageFile == null || _faces == null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'face_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedImage = await _imageFile!.copy('${appDir.path}/$fileName');

    final resultData = jsonEncode({
      'facesCount': _faces!.length,
      'faces': _faces!.map((face) {
        return {
          'smiling': face.smilingProbability,
          'leftEyeOpen': face.leftEyeOpenProbability,
          'rightEyeOpen': face.rightEyeOpenProbability,
          'headAngleY': face.headEulerAngleY,
          'headAngleZ': face.headEulerAngleZ,
        };
      }).toList(),
    });

    final scanResult = ScanResult(
      type: 'face_detection',
      imagePath: savedImage.path,
      resultData: resultData,
      timestamp: DateTime.now().toIso8601String(),
    );

    await DatabaseService().insertResult(scanResult);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.resultSaved)),
      );
    }
  }

  /// Format a probability value as a percentage string.
  String _formatProbability(double? value) {
    if (value == null) return 'N/A';
    return '${(value * 100).toStringAsFixed(1)}%';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.faceDetection)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Pick source buttons ─────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isProcessing
                        ? null
                        : () => _pickAndProcess(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: Text(l10n.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: _isProcessing
                        ? null
                        : () => _pickAndProcess(ImageSource.gallery),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.photo_library_rounded),
                        const SizedBox(width: 8),
                        Text(l10n.gallery),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Image preview ──────────────────────────────────────────
            if (_imageFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(
                  _imageFile!,
                  height: 280,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            // ── Empty state ────────────────────────────────────────────
            if (_imageFile == null && !_isProcessing)
              MlEmptyState(
                icon: Icons.face_rounded,
                message: l10n.tapPhotoToStart,
                color: const Color(0xFFF97316),
              ),

            // ── Loading ────────────────────────────────────────────────
            if (_isProcessing) MlLoadingState(message: l10n.processing),

            // ── Results ─────────────────────────────────────────────────
            if (_faces != null && _faces!.isNotEmpty) ...[
              const SizedBox(height: 20),
              MlSectionHeader(
                icon: Icons.face_rounded,
                label: '${_faces!.length} ${l10n.facesDetected}',
                color: const Color(0xFFF97316),
              ),
              const SizedBox(height: 10),
              ..._faces!.asMap().entries.map((entry) {
                final index = entry.key;
                final face = entry.value;
                final boundingBox = face.boundingBox;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFF97316,
                                  ).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.face_rounded,
                                  color: Color(0xFFF97316),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Face ${index + 1}',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Icons.crop_square_rounded,
                            label: 'Position',
                            value:
                                '(${boundingBox.left.toInt()}, ${boundingBox.top.toInt()}) '
                                '${boundingBox.width.toInt()}x${boundingBox.height.toInt()}',
                          ),
                          _InfoRow(
                            icon: Icons.sentiment_satisfied_alt_rounded,
                            label: l10n.smilingProbability,
                            value: _formatProbability(face.smilingProbability),
                          ),
                          _InfoRow(
                            icon: Icons.visibility_rounded,
                            label: l10n.leftEyeOpen,
                            value: _formatProbability(
                              face.leftEyeOpenProbability,
                            ),
                          ),
                          _InfoRow(
                            icon: Icons.visibility_rounded,
                            label: l10n.rightEyeOpen,
                            value: _formatProbability(
                              face.rightEyeOpenProbability,
                            ),
                          ),
                          if (face.headEulerAngleY != null)
                            _InfoRow(
                              icon: Icons.rotate_left_rounded,
                              label: l10n.headAngleY,
                              value:
                                  '${face.headEulerAngleY!.toStringAsFixed(1)}°',
                            ),
                          if (face.headEulerAngleZ != null)
                            _InfoRow(
                              icon: Icons.rotate_right_rounded,
                              label: l10n.headAngleZ,
                              value:
                                  '${face.headEulerAngleZ!.toStringAsFixed(1)}°',
                            ),
                          if (face.trackingId != null)
                            _InfoRow(
                              icon: Icons.tag_rounded,
                              label: 'Tracking ID',
                              value: '${face.trackingId}',
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saveResult,
                  icon: const Icon(Icons.save_rounded),
                  label: Text(l10n.saveResult),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ),
            ],

            if (_faces != null && _faces!.isEmpty)
              MlEmptyState(
                icon: Icons.face_retouching_off_rounded,
                message: l10n.noFacesDetected,
                color: Colors.grey,
              ),
          ],
        ),
      ),
    );
  }
}

/// A simple row with icon, label, and value for displaying face info.
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
