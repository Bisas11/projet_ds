import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import '../l10n/app_localizations.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import '../services/ml_service.dart';
import '../services/database_service.dart';
import '../services/sound_service.dart';
import '../providers/settings_provider.dart';
import '../models/scan_result.dart';
import '../widgets/result_card.dart';

/// Screen for the Image Labeling ML Kit feature.
/// Allows picking an image from camera or gallery, then labels objects in it.
class ImageLabelingScreen extends StatefulWidget {
  const ImageLabelingScreen({super.key});

  @override
  State<ImageLabelingScreen> createState() => _ImageLabelingScreenState();
}

class _ImageLabelingScreenState extends State<ImageLabelingScreen> {
  File? _imageFile;
  List<ImageLabel>? _labels;
  bool _isProcessing = false;
  final _imagePicker = ImagePicker();

  /// Pick an image from the given source, then run ML Kit image labeling.
  Future<void> _pickAndProcess(ImageSource source) async {
    final pickedFile = await _imagePicker.pickImage(source: source);
    if (pickedFile == null) return;

    setState(() {
      _imageFile = File(pickedFile.path);
      _labels = null;
      _isProcessing = true;
    });

    try {
      final labels = await MLService.labelImage(_imageFile!);
      setState(() {
        _labels = labels;
        _isProcessing = false;
      });

      // Play sound + vibration feedback
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
    if (_labels == null || _imageFile == null) return;

    // Copy image to app's documents directory for persistence
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'labeling_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedImage = await _imageFile!.copy('${appDir.path}/$fileName');

    // Encode labels as JSON
    final resultData = _labels!
        .map(
          (l) => {
            'label': l.label,
            'confidence': l.confidence,
            'index': l.index,
          },
        )
        .toList();

    final scanResult = ScanResult(
      type: 'labeling',
      imagePath: savedImage.path,
      resultData: jsonEncode(resultData),
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
      appBar: AppBar(title: Text(l10n.imageLabeling)),
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

            // Display the picked image
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
              Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 8),
                  Text(l10n.processing),
                ],
              ),

            // Results
            if (_labels != null && _labels!.isNotEmpty) ...[
              Text(
                '${l10n.labelsDetected}: ${_labels!.length}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ..._labels!.map(
                (label) => ResultCard(
                  title: label.label,
                  subtitle:
                      '${l10n.confidence}: ${(label.confidence * 100).toStringAsFixed(1)}%',
                  icon: Icons.label_outline,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _saveResult,
                icon: const Icon(Icons.save),
                label: Text(l10n.saveResult),
              ),
            ],

            // No results
            if (_labels != null && _labels!.isEmpty)
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
