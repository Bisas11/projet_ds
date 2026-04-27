import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import '../l10n/app_localizations.dart';
import '../services/ml_service.dart';
import '../services/database_service.dart';
import '../services/sound_service.dart';
import '../providers/settings_provider.dart';
import '../models/scan_result.dart';
import '../widgets/ml_widgets.dart';

/// Screen for the Selfie Segmentation ML Kit feature.
/// Picks an image, segments the person from the background,
/// and displays a green mask overlay on top of the original image.
class SelfieSegmentationScreen extends StatefulWidget {
  const SelfieSegmentationScreen({super.key});

  @override
  State<SelfieSegmentationScreen> createState() =>
      _SelfieSegmentationScreenState();
}

class _SelfieSegmentationScreenState extends State<SelfieSegmentationScreen> {
  File? _imageFile;
  Uint8List? _maskOverlay; // PNG bytes of the green mask overlay
  double? _personPercentage;
  bool _isProcessing = false;
  final _imagePicker = ImagePicker();

  /// Pick an image and run selfie segmentation.
  Future<void> _pickAndProcess(ImageSource source) async {
    final pickedFile = await _imagePicker.pickImage(source: source);
    if (pickedFile == null) return;

    setState(() {
      _imageFile = File(pickedFile.path);
      _maskOverlay = null;
      _personPercentage = null;
      _isProcessing = true;
    });

    try {
      // Run selfie segmentation
      final mask = await MLService.segmentSelfie(_imageFile!);

      if (mask != null) {
        // Convert the mask to a green overlay image
        final overlayBytes = await MLService.maskToOverlayImage(mask);
        final percentage = MLService.calculatePersonPercentage(mask);

        setState(() {
          _maskOverlay = overlayBytes;
          _personPercentage = percentage;
          _isProcessing = false;
        });
      } else {
        setState(() => _isProcessing = false);
      }

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
    if (_imageFile == null || _personPercentage == null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'selfie_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedImage = await _imageFile!.copy('${appDir.path}/$fileName');

    final resultData = jsonEncode({'personPercentage': _personPercentage});

    final scanResult = ScanResult(
      type: 'selfie_segmentation',
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.selfieSegmentation)),
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

            // ── Image preview with mask overlay ───────────────────────
            if (_imageFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.file(
                      _imageFile!,
                      height: 320,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    if (_maskOverlay != null)
                      Opacity(
                        opacity: 0.55,
                        child: Image.memory(
                          _maskOverlay!,
                          height: 320,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                  ],
                ),
              ),

            // ── Empty state ────────────────────────────────────────────
            if (_imageFile == null && !_isProcessing)
              MlEmptyState(
                icon: Icons.crop_free_rounded,
                message: l10n.tapPhotoToStart,
                color: const Color(0xFF0D9488),
              ),

            // ── Loading ────────────────────────────────────────────────
            if (_isProcessing) MlLoadingState(message: l10n.processing),

            // ── Results ─────────────────────────────────────────────────
            if (_personPercentage != null) ...[
              const SizedBox(height: 20),
              MlSectionHeader(
                icon: Icons.person_rounded,
                label: l10n.personDetected,
                color: const Color(0xFF0D9488),
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Circular percentage indicator
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: _personPercentage! / 100,
                              strokeWidth: 8,
                              backgroundColor: const Color(
                                0xFF0D9488,
                              ).withOpacity(0.15),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF0D9488),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${_personPercentage!.toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0D9488),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.personDetected,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
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

            if (_maskOverlay == null &&
                !_isProcessing &&
                _imageFile != null &&
                _personPercentage == null)
              MlEmptyState(
                icon: Icons.person_off_rounded,
                message: l10n.noResults,
                color: Colors.grey,
              ),
          ],
        ),
      ),
    );
  }
}
