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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image source buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickAndProcess(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: Text(l10n.camera),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickAndProcess(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: Text(l10n.gallery),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Display original image
            if (_imageFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  _imageFile!,
                  height: 300,
                  fit: BoxFit.contain,
                ),
              ),
            const SizedBox(height: 16),

            // Loading indicator
            if (_isProcessing)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text('Processing...'),
                ],
              ),

            // Results
            if (_faces != null && _faces!.isNotEmpty) ...[
              Text(
                '${_faces!.length} ${l10n.facesDetected}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),

              // Display each detected face
              ..._faces!.asMap().entries.map((entry) {
                final index = entry.key;
                final face = entry.value;
                final boundingBox = face.boundingBox;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Face header
                        Row(
                          children: [
                            const Icon(Icons.face, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              'Face ${index + 1}',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ],
                        ),
                        const Divider(),

                        // Bounding box info
                        _InfoRow(
                          icon: Icons.crop_square,
                          label: 'Position',
                          value:
                              '(${boundingBox.left.toInt()}, ${boundingBox.top.toInt()}) '
                              '${boundingBox.width.toInt()}x${boundingBox.height.toInt()}',
                        ),

                        // Smiling probability
                        _InfoRow(
                          icon: Icons.sentiment_satisfied_alt,
                          label: l10n.smilingProbability,
                          value: _formatProbability(face.smilingProbability),
                        ),

                        // Left eye open
                        _InfoRow(
                          icon: Icons.visibility,
                          label: l10n.leftEyeOpen,
                          value: _formatProbability(
                            face.leftEyeOpenProbability,
                          ),
                        ),

                        // Right eye open
                        _InfoRow(
                          icon: Icons.visibility,
                          label: l10n.rightEyeOpen,
                          value: _formatProbability(
                            face.rightEyeOpenProbability,
                          ),
                        ),

                        // Head angles
                        if (face.headEulerAngleY != null)
                          _InfoRow(
                            icon: Icons.rotate_left,
                            label: l10n.headAngleY,
                            value:
                                '${face.headEulerAngleY!.toStringAsFixed(1)}°',
                          ),
                        if (face.headEulerAngleZ != null)
                          _InfoRow(
                            icon: Icons.rotate_right,
                            label: l10n.headAngleZ,
                            value:
                                '${face.headEulerAngleZ!.toStringAsFixed(1)}°',
                          ),

                        // Tracking ID
                        if (face.trackingId != null)
                          _InfoRow(
                            icon: Icons.tag,
                            label: 'Tracking ID',
                            value: '${face.trackingId}',
                          ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: _saveResult,
                icon: const Icon(Icons.save),
                label: Text(l10n.saveResult),
              ),
            ],

            // No faces detected
            if (_faces != null && _faces!.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.face_retouching_off,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(l10n.noFacesDetected),
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
