import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartmahsiswaflutter/features/helpdesk/data/models/ai_chat_message.dart';
import 'package:smartmahsiswaflutter/features/helpdesk/data/storage/ai_chat_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AiChatStorage 24h Session Tests', () {
    const nim = '210101001';

    test('generateTodaySessionId generates nim-yyyyMMdd', () {
      final now = DateTime.now();
      final expected = '$nim-${DateFormat('yyyyMMdd').format(now)}';
      expect(AiChatStorage.generateTodaySessionId(nim), equals(expected));
    });

    test('Session persists within 24 hours of last chat', () async {
      // 1. Initial session
      final sessionId = await AiChatStorage.getOrInitActiveSessionId(nim);
      expect(sessionId, contains(nim));

      // 2. Save a chat message 2 hours ago
      final twoHoursAgo = DateTime.now().subtract(const Duration(hours: 2));
      final msg = AiChatMessage(
        id: '1',
        text: 'Halo AI',
        isUser: true,
        timestamp: twoHoursAgo,
        sessionId: sessionId,
      );
      await AiChatStorage.saveMessages(sessionId, [msg]);

      // 3. Verify session is not expired
      final expired = await AiChatStorage.isSessionExpired(nim);
      expect(expired, isFalse);

      // 4. Session ID should remain the same
      final currentSession = await AiChatStorage.getOrInitActiveSessionId(nim);
      expect(currentSession, equals(sessionId));

      // 5. Messages should still be loaded
      final loaded = await AiChatStorage.loadMessages(sessionId);
      expect(loaded.length, equals(1));
      expect(loaded.first.text, equals('Halo AI'));
    });

    test('Session expires and resets after 24 hours from last chat', () async {
      // 1. Setup old session from 2 days ago
      final oldDate = DateTime.now().subtract(const Duration(days: 2));
      final oldSessionId = '$nim-${DateFormat('yyyyMMdd').format(oldDate)}';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ai_chat_last_session_$nim', oldSessionId);
      // Last chat was 25 hours ago
      final twentyFiveHoursAgo = DateTime.now().subtract(const Duration(hours: 25));
      await prefs.setString(
        'ai_chat_last_timestamp_$nim',
        twentyFiveHoursAgo.toIso8601String(),
      );

      final oldMsg = AiChatMessage(
        id: 'old_1',
        text: 'Chat kemarin lusa',
        isUser: true,
        timestamp: twentyFiveHoursAgo,
        sessionId: oldSessionId,
      );
      await prefs.setString(
        'ai_chat_history_$oldSessionId',
        '[${oldMsg.toJson()}]',
      );

      // 2. Verify it is detected as expired
      final isExpired = await AiChatStorage.isSessionExpired(nim);
      expect(isExpired, isTrue);

      // 3. Requesting active session should clear old and return new session with today's date
      final newSessionId = await AiChatStorage.getOrInitActiveSessionId(nim);
      final todayStr = DateFormat('yyyyMMdd').format(DateTime.now());
      expect(newSessionId, equals('$nim-$todayStr'));
      expect(newSessionId, isNot(equals(oldSessionId)));

      // 4. Old messages should be cleared
      final messagesAfter = await AiChatStorage.loadMessages(oldSessionId);
      expect(messagesAfter, isEmpty);

      // 5. New session has no messages yet
      final newSessionMessages = await AiChatStorage.loadMessages(newSessionId);
      expect(newSessionMessages, isEmpty);
    });

    test('cleanExpiredSessions cleans old expired sessions', () async {
      final prefs = await SharedPreferences.getInstance();
      const otherNim = '999999999';
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      final oldSession = '$otherNim-${DateFormat('yyyyMMdd').format(twoDaysAgo)}';

      await prefs.setString('ai_chat_last_session_$otherNim', oldSession);
      await prefs.setString(
        'ai_chat_last_timestamp_$otherNim',
        twoDaysAgo.toIso8601String(),
      );
      await prefs.setString('ai_chat_history_$oldSession', '[]');

      await AiChatStorage.cleanExpiredSessions();

      expect(prefs.containsKey('ai_chat_last_session_$otherNim'), isFalse);
      expect(prefs.containsKey('ai_chat_history_$oldSession'), isFalse);
    });
  });
}
