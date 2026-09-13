import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartmahsiswaflutter/features/helpdesk/data/models/ai_chat_message.dart';
import 'package:smartmahsiswaflutter/features/helpdesk/data/models/ai_chat_response.dart';
import 'package:smartmahsiswaflutter/features/helpdesk/data/models/ai_feedback_response.dart';
import 'package:smartmahsiswaflutter/features/helpdesk/data/storage/ai_chat_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AiChatResponse Tests', () {
    test('parse successful regular response', () {
      final json = {
        "message_id": 11,
        "answer": "Ya, saya mengetahui Prof. Zakiyuddin Baidhawy.",
        "is_fallback": false,
        "whatsapp_link": null,
        "cs_contact": null,
        "session_id": "14118431-20260912"
      };

      final response = AiChatResponse.fromJson(json);
      expect(response.messageId, 11);
      expect(response.answer, "Ya, saya mengetahui Prof. Zakiyuddin Baidhawy.");
      expect(response.isFallback, false);
      expect(response.whatsappLink, isNull);
      expect(response.csContact, isNull);
      expect(response.sessionId, "14118431-20260912");
    });

    test('parse fallback response with whatsapp link and cs contact', () {
      final json = {
        "message_id": 15,
        "answer": "Maaf, Saga belum menemukan jawaban lengkap terkait pertanyaan tersebut.",
        "is_fallback": true,
        "whatsapp_link": "https://wa.me/6281234567892?text=Halo%20CS",
        "cs_contact": {
          "id": "kemahasiswaan",
          "label": "CS Kemahasiswaan",
          "number": "6281234567892"
        },
        "session_id": "14118431-20260912"
      };

      final response = AiChatResponse.fromJson(json);
      expect(response.messageId, 15);
      expect(response.isFallback, true);
      expect(response.whatsappLink, "https://wa.me/6281234567892?text=Halo%20CS");
      expect(response.csContact, isNotNull);
      expect(response.csContact?.id, "kemahasiswaan");
      expect(response.csContact?.label, "CS Kemahasiswaan");
      expect(response.csContact?.number, "6281234567892");
    });
  });

  group('AiFeedbackResponse Tests', () {
    test('parse feedback response', () {
      final json = {
        "success": true,
        "message": "Terima kasih atas penilaian dan masukan Anda! Feedback berhasil dicatat."
      };

      final feedback = AiFeedbackResponse.fromJson(json);
      expect(feedback.success, true);
      expect(feedback.message, contains("berhasil dicatat"));
    });
  });

  group('AiChatMessage Serialization Tests', () {
    test('serialize and deserialize AiChatMessage', () {
      final original = AiChatMessage(
        id: 'msg_1',
        messageId: 42,
        text: 'Bagaimana cara reset password?',
        isUser: true,
        timestamp: DateTime(2026, 9, 12, 10, 30),
        sessionId: '14118431-20260912',
      );

      final json = original.toJson();
      final restored = AiChatMessage.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.messageId, 42);
      expect(restored.text, original.text);
      expect(restored.isUser, true);
      expect(restored.sessionId, '14118431-20260912');
    });

    test('AiChatMessage copyWith updates feedback', () {
      final original = AiChatMessage(
        id: 'msg_2',
        messageId: 42,
        text: 'Jawaban AI',
        isUser: false,
        timestamp: DateTime.now(),
      );

      final updated = original.copyWith(
        feedbackGiven: true,
        feedbackComment: 'Jawaban akurat',
      );

      expect(updated.feedbackGiven, true);
      expect(updated.feedbackComment, 'Jawaban akurat');
    });
  });

  group('AiChatStorage Session Logic Tests', () {
    test('generateTodaySessionId has correct format nim-yyyyMMdd', () {
      final sessionId = AiChatStorage.generateTodaySessionId('14118431');
      expect(sessionId.startsWith('14118431-'), true);
      expect(sessionId.length, '14118431-20260912'.length);
    });

    test('isSessionExpired returns false for fresh session without prior chat', () async {
      final isExpired = await AiChatStorage.isSessionExpired('14118431');
      expect(isExpired, false);
    });
  });
}
