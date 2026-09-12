class AiFeedbackResponse {
  final bool success;
  final String message;

  AiFeedbackResponse({
    required this.success,
    required this.message,
  });

  factory AiFeedbackResponse.fromJson(Map<String, dynamic> json) {
    return AiFeedbackResponse(
      success: json['success'] == true,
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
