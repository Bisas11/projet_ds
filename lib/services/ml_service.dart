import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Service that wraps all ML Kit operations.
/// Each method creates its own ML Kit instance, processes, and closes it.
class MLService {
  // ──────────────────────────────────────────────
  // IMAGE LABELING
  // ──────────────────────────────────────────────

  /// Label objects, animals, places, etc. in the given image.
  /// Returns a list of [ImageLabel] with label text and confidence.
  static Future<List<ImageLabel>> labelImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final labeler = ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: 0.5),
    );

    try {
      final labels = await labeler.processImage(inputImage);
      return labels;
    } finally {
      labeler.close();
    }
  }

  // ──────────────────────────────────────────────
  // SELFIE SEGMENTATION
  // ──────────────────────────────────────────────

  /// Segment a selfie to separate person from background.
  /// Returns a [SegmentationMask] with per-pixel confidence values.
  static Future<SegmentationMask?> segmentSelfie(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final segmenter = SelfieSegmenter(
      mode: SegmenterMode.single, // Still image mode
      enableRawSizeMask: true, // Mask same size as input image
    );

    try {
      final mask = await segmenter.processImage(inputImage);
      return mask;
    } finally {
      segmenter.close();
    }
  }

  /// Convert a selfie segmentation mask into a green overlay PNG image.
  /// Person pixels are shown in green, background is transparent.
  static Future<Uint8List?> maskToOverlayImage(SegmentationMask mask) async {
    final width = mask.width;
    final height = mask.height;
    final confidences = mask.confidences;

    // Create RGBA pixel data
    final pixels = Uint8List(width * height * 4);
    for (int i = 0; i < confidences.length && i < width * height; i++) {
      final offset = i * 4;
      final confidence = confidences[i];

      if (confidence > 0.5) {
        // Person pixel: green with variable opacity based on confidence
        pixels[offset] = 76; // R
        pixels[offset + 1] = 175; // G
        pixels[offset + 2] = 80; // B
        pixels[offset + 3] = (180 * confidence).toInt().clamp(0, 255); // A
      }
      // else: transparent (all zeros)
    }

    // Convert raw RGBA pixels to a PNG-encoded image
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels,
      width,
      height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );

    final image = await completer.future;
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    return byteData?.buffer.asUint8List();
  }

  /// Calculate the percentage of the image that is person (selfie mask).
  static double calculatePersonPercentage(SegmentationMask mask) {
    int personPixels = 0;
    for (final confidence in mask.confidences) {
      if (confidence > 0.5) personPixels++;
    }
    return (personPixels / mask.confidences.length) * 100;
  }

  // ──────────────────────────────────────────────
  // FACE DETECTION
  // ──────────────────────────────────────────────

  /// Detect faces in the given image with landmarks, contours, and classifications.
  /// Returns a list of [Face] with bounding boxes, landmarks, and expressions.
  static Future<List<Face>> detectFaces(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final detector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        enableLandmarks: true,
        enableContours: true,
        enableTracking: true,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );

    try {
      final faces = await detector.processImage(inputImage);
      return faces;
    } finally {
      detector.close();
    }
  }
}
