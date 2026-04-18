/// Model representing a saved ML Kit scan result in the database.
class ScanResult {
  final int? id;

  /// Type of scan: 'labeling', 'selfie_segmentation', 'subject_segmentation'
  final String type;

  /// Path to the saved image file on disk
  final String imagePath;

  /// JSON-encoded string of the ML Kit results
  final String resultData;

  /// ISO 8601 timestamp of when the scan was performed
  final String timestamp;

  ScanResult({
    this.id,
    required this.type,
    required this.imagePath,
    required this.resultData,
    required this.timestamp,
  });

  /// Convert to a Map for SQLite insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'imagePath': imagePath,
      'resultData': resultData,
      'timestamp': timestamp,
    };
  }

  /// Create a ScanResult from a SQLite row Map
  factory ScanResult.fromMap(Map<String, dynamic> map) {
    return ScanResult(
      id: map['id'] as int?,
      type: map['type'] as String,
      imagePath: map['imagePath'] as String,
      resultData: map['resultData'] as String,
      timestamp: map['timestamp'] as String,
    );
  }
}
