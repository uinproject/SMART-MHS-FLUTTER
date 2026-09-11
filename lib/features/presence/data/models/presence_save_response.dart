class PresenceSaveResponse {
  final bool success;
  final String message;

  PresenceSaveResponse({
    required this.success,
    required this.message,
  });

  factory PresenceSaveResponse.fromJson(Map<String, dynamic> json) {
    return PresenceSaveResponse(
      success: json['success'] == true || json['success'] == 1 || json['success'] == 'true',
      message: json['message']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
    };
  }
}
