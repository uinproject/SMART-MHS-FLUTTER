class AiChatResponse {
  final int? messageId;
  final String answer;
  final bool isFallback;
  final String? whatsappLink;
  final AiCsContact? csContact;
  final String? sessionId;

  AiChatResponse({
    this.messageId,
    required this.answer,
    this.isFallback = false,
    this.whatsappLink,
    this.csContact,
    this.sessionId,
  });

  factory AiChatResponse.fromJson(Map<String, dynamic> json) {
    return AiChatResponse(
      messageId: json['message_id'] is int
          ? json['message_id']
          : int.tryParse(json['message_id']?.toString() ?? ''),
      answer: json['answer']?.toString() ?? '',
      isFallback: json['is_fallback'] == true,
      whatsappLink: json['whatsapp_link']?.toString(),
      csContact: json['cs_contact'] != null && json['cs_contact'] is Map<String, dynamic>
          ? AiCsContact.fromJson(json['cs_contact'] as Map<String, dynamic>)
          : null,
      sessionId: json['session_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message_id': messageId,
      'answer': answer,
      'is_fallback': isFallback,
      'whatsapp_link': whatsappLink,
      'cs_contact': csContact?.toJson(),
      'session_id': sessionId,
    };
  }
}

class AiCsContact {
  final String? id;
  final String? label;
  final String? number;

  AiCsContact({
    this.id,
    this.label,
    this.number,
  });

  factory AiCsContact.fromJson(Map<String, dynamic> json) {
    return AiCsContact(
      id: json['id']?.toString(),
      label: json['label']?.toString(),
      number: json['number']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'number': number,
    };
  }
}
