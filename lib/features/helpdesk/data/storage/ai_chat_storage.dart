import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_chat_message.dart';

class AiChatStorage {
  static const String _keyPrefix = 'ai_chat_history_';
  static const String _lastSessionPrefix = 'ai_chat_last_session_';

  /// Generates a session ID for today in format: {nim}-yyyyMMdd
  static String generateTodaySessionId(String nim) {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd').format(now);
    return '$nim-$dateStr';
  }

  /// Calculates expiry date for a session ID.
  /// Session is valid until 23:59:59 of the NEXT day after the session date.
  static DateTime? getSessionExpiry(String sessionId) {
    try {
      final parts = sessionId.split('-');
      if (parts.length < 2) return null;
      final dateStr = parts.last;
      if (dateStr.length != 8) return null;

      final year = int.parse(dateStr.substring(0, 4));
      final month = int.parse(dateStr.substring(4, 6));
      final day = int.parse(dateStr.substring(6, 8));

      // End of next day: (day + 1) at 23:59:59
      final sessionDate = DateTime(year, month, day);
      final nextDay = sessionDate.add(const Duration(days: 1));
      return DateTime(nextDay.year, nextDay.month, nextDay.day, 23, 59, 59);
    } catch (e) {
      debugPrint('[AiChatStorage] Error parsing session expiry: $e');
      return null;
    }
  }

  /// Checks if a session ID is still valid (now <= 23:59 of the next day)
  static bool isSessionValid(String sessionId) {
    final expiry = getSessionExpiry(sessionId);
    if (expiry == null) return false;
    return DateTime.now().isBefore(expiry);
  }

  /// Resolves the current active session ID for a student.
  /// If the last used session is still valid, return it so history persists.
  /// Otherwise, generate today's session ID.
  static Future<String> getOrInitActiveSessionId(String nim) async {
    final prefs = await SharedPreferences.getInstance();
    final lastSession = prefs.getString('$_lastSessionPrefix$nim');

    if (lastSession != null && isSessionValid(lastSession)) {
      return lastSession;
    }

    final newSession = generateTodaySessionId(nim);
    await prefs.setString('$_lastSessionPrefix$nim', newSession);
    return newSession;
  }

  /// Save chat messages for a session ID
  static Future<void> saveMessages(String sessionId, List<AiChatMessage> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = messages.map((m) => m.toJson()).toList();
      await prefs.setString('$_keyPrefix$sessionId', jsonEncode(jsonList));

      // Also extract NIM and save as last active session
      final parts = sessionId.split('-');
      if (parts.length >= 2) {
        final nim = parts.sublist(0, parts.length - 1).join('-');
        await prefs.setString('$_lastSessionPrefix$nim', sessionId);
      }
    } catch (e) {
      debugPrint('[AiChatStorage] Error saving messages: $e');
    }
  }

  /// Load chat messages for a session ID
  static Future<List<AiChatMessage>> loadMessages(String sessionId) async {
    try {
      // If the session is already expired, return empty list and clear it
      if (!isSessionValid(sessionId)) {
        await clearSession(sessionId);
        return [];
      }

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_keyPrefix$sessionId');
      if (raw == null || raw.isEmpty) return [];

      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .map((item) => AiChatMessage.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[AiChatStorage] Error loading messages: $e');
      return [];
    }
  }

  /// Clear a specific session
  static Future<void> clearSession(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_keyPrefix$sessionId');
    } catch (e) {
      debugPrint('[AiChatStorage] Error clearing session: $e');
    }
  }

  /// Clean up all expired sessions across all users
  static Future<void> cleanExpiredSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();

      for (final key in allKeys) {
        if (key.startsWith(_keyPrefix)) {
          final sessionId = key.substring(_keyPrefix.length);
          if (!isSessionValid(sessionId)) {
            await prefs.remove(key);
            debugPrint('[AiChatStorage] Removed expired session: $sessionId');
          }
        }
      }
    } catch (e) {
      debugPrint('[AiChatStorage] Error cleaning expired sessions: $e');
    }
  }
}
