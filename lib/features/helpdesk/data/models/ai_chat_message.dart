import 'ai_chat_response.dart';

class AiChatMessage {
  final String id;
  final int? messageId;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isFallback;
  final String? whatsappLink;
  final AiCsContact? csContact;
  final String? sessionId;
  final bool? feedbackGiven; // null = none, true = thumbs up, false = thumbs down
  final String? feedbackComment;
  final bool isLoading;
  final bool isError;

  AiChatMessage({
    required this.id,
    this.messageId,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isFallback = false,
    this.whatsappLink,
    this.csContact,
    this.sessionId,
    this.feedbackGiven,
    this.feedbackComment,
    this.isLoading = false,
    this.isError = false,
  });

  AiChatMessage copyWith({
    String? id,
    int? messageId,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    bool? isFallback,
    String? whatsappLink,
    AiCsContact? csContact,
    String? sessionId,
    bool? feedbackGiven,
    String? feedbackComment,
    bool? isLoading,
    bool? isError,
  }) {
    return AiChatMessage(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      isFallback: isFallback ?? this.isFallback,
      whatsappLink: whatsappLink ?? this.whatsappLink,
      csContact: csContact ?? this.csContact,
      sessionId: sessionId ?? this.sessionId,
      feedbackGiven: feedbackGiven ?? this.feedbackGiven,
      feedbackComment: feedbackComment ?? this.feedbackComment,
      isLoading: isLoading ?? this.isLoading,
      isError: isError ?? this.isError,
    );
  }

  factory AiChatMessage.fromJson(Map<String, dynamic> json) {
    return AiChatMessage(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      messageId: json['message_id'] is int
          ? json['message_id']
          : int.tryParse(json['message_id']?.toString() ?? ''),
      text: json['text']?.toString() ?? '',
      isUser: json['is_user'] == true,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isFallback: json['is_fallback'] == true,
      whatsappLink: json['whatsapp_link']?.toString(),
      csContact: json['cs_contact'] != null && json['cs_contact'] is Map<String, dynamic>
          ? AiCsContact.fromJson(json['cs_contact'] as Map<String, dynamic>)
          : null,
      sessionId: json['session_id']?.toString(),
      feedbackGiven: json['feedback_given'] is bool ? json['feedback_given'] : null,
      feedbackComment: json['feedback_comment']?.toString(),
      isLoading: false, // Don't persist loading state as true
      isError: json['is_error'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message_id': messageId,
      'text': text,
      'is_user': isUser,
      'timestamp': timestamp.toIso8601String(),
      'is_fallback': isFallback,
      'whatsapp_link': whatsappLink,
      'cs_contact': csContact?.toJson(),
      'session_id': sessionId,
      'feedback_given': feedbackGiven,
      'feedback_comment': feedbackComment,
      'is_error': isError,
    };
  }
}
