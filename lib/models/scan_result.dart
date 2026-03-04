/// Represents the data extracted from a medical report scan (OCR).
class ScanResult {
  final String? genotype;
  final String? bloodGroup;

  const ScanResult({
    this.genotype,
    this.bloodGroup,
  });

  /// Create a [ScanResult] from the 'detected_data' JSON object.
  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      genotype: json['genotype'] as String?,
      bloodGroup: json['blood_group'] as String?,
    );
  }

  /// Whether any useful data was detected.
  bool get hasData => genotype != null || bloodGroup != null;
}
