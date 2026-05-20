/// Typed result from POST /api/v1/check-match.
class MatchResult {
  final String status; // 'safe' | 'caution' | 'danger'
  final List<String> messages;
  final bool canUnblurPhotos;

  const MatchResult({
    required this.status,
    required this.messages,
    required this.canUnblurPhotos,
  });

  factory MatchResult.fromJson(Map<String, dynamic> json) {
    return MatchResult(
      status: json['status'] as String? ?? 'unknown',
      messages: (json['messages'] as List<dynamic>?)
              ?.map((m) => m.toString())
              .toList() ??
          [],
      canUnblurPhotos: json['can_unblur_photos'] as bool? ?? false,
    );
  }
}
