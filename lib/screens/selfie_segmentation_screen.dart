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

            // Display original image with mask overlay
            if (_imageFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.file(_imageFile!, height: 400, fit: BoxFit.contain),
                    // Green mask overlay on top of the original
                    if (_maskOverlay != null)
                      Opacity(
                        opacity: 0.6,
                        child: Image.memory(
                          _maskOverlay!,
                          height: 400,
                          fit: BoxFit.contain,
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Loading indicator
            if (_isProcessing)
              Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 8),
                  Text(l10n.processing),
                ],
              ),

            // Results
            if (_personPercentage != null) ...[
              Card(
                child: ListTile(
                  leading: const Icon(Icons.face, size: 40),
                  title: Text(l10n.personDetected),
                  subtitle: Text('${_personPercentage!.toStringAsFixed(1)}%'),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _saveResult,
                icon: const Icon(Icons.save),
                label: Text(l10n.saveResult),
              ),
            ],

            // No person detected
            if (_maskOverlay == null &&
                !_isProcessing &&
                _imageFile != null &&
                _personPercentage == null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(l10n.noResults),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
