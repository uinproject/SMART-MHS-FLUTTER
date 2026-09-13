import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_chat_message.dart';

class AiChatStorage {
  static const String _keyPrefix = 'ai_chat_history_';
  static const String _lastSessionPrefix = 'ai_chat_last_session_';
  static const String _lastChatTimestampPrefix = 'ai_chat_last_timestamp_';

  /// Generates a session ID for today in format: {nim}-yyyyMMdd
  static String generateTodaySessionId(String nim) {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd').format(now);
    return '$nim-$dateStr';
  }

  /// Extracts NIM from a session ID (everything before the last '-yyyyMMdd')
  static String _extractNim(String sessionId) {
    final lastDash = sessionId.lastIndexOf('-');
    if (lastDash > 0) {
      return sessionId.substring(0, lastDash);
    }
    return sessionId;
  }

  /// Extracts date from session ID if available ({nim}-yyyyMMdd)
  static DateTime? _extractDateFromSessionId(String sessionId) {
    try {
      final lastDash = sessionId.lastIndexOf('-');
      if (lastDash > 0 && lastDash + 1 < sessionId.length) {
        final dateStr = sessionId.substring(lastDash + 1);
        if (dateStr.length == 8) {
          return DateFormat('yyyyMMdd').tryParse(dateStr);
        }
      }
    } catch (_) {}
    return null;
  }

  /// Gets the timestamp of the last chat activity for a given NIM
  static Future<DateTime?> getLastChatTimestamp(String nim) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_lastChatTimestampPrefix$nim');
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  /// Updates the last chat timestamp for a given NIM
  static Future<void> _updateLastChatTimestamp(String nim, [DateTime? timestamp]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_lastChatTimestampPrefix$nim',
      (timestamp ?? DateTime.now()).toIso8601String(),
    );
  }

  /// Checks if the session has expired (more than 24 hours since last chat)
  static Future<bool> isSessionExpired(String nim) async {
    final prefs = await SharedPreferences.getInstance();
    final lastTimestamp = await getLastChatTimestamp(nim);

    if (lastTimestamp != null) {
      final elapsed = DateTime.now().difference(lastTimestamp);
      return elapsed >= const Duration(hours: 24);
    }

    // Fallback: If no explicit timestamp recorded yet, check date in stored last session ID
    final lastSession = prefs.getString('$_lastSessionPrefix$nim');
    if (lastSession != null) {
      final date = _extractDateFromSessionId(lastSession);
      if (date != null) {
        final elapsed = DateTime.now().difference(date);
        return elapsed >= const Duration(hours: 24);
      }
      return true; // Malformed session ID, treat as expired
    }

    return false; // No previous session exists
  }

  /// Resolves the current active session ID for a student.
  /// If within 24 hours of last chat, returns existing session ID so history persists.
  /// If 24+ hours since last chat, clears old history and generates a new session ID with today's date.
  static Future<String> getOrInitActiveSessionId(String nim) async {
    final prefs = await SharedPreferences.getInstance();
    final lastSession = prefs.getString('$_lastSessionPrefix$nim');

    if (lastSession != null) {
      final expired = await isSessionExpired(nim);
      if (!expired) {
        // Session is still active (within 24 hours of last chat)
        return lastSession;
      }

      // Session expired (24+ hours since last chat) — clear old history
      debugPrint('[AiChatStorage] Session expired for NIM $nim (>24h since last chat), clearing old chat');
      await clearSession(lastSession);
    }

    // Generate fresh session ID based on current date: {nim}-yyyyMMdd
    final newSession = generateTodaySessionId(nim);
    await prefs.setString('$_lastSessionPrefix$nim', newSession);
    await prefs.remove('$_lastChatTimestampPrefix$nim');
    return newSession;
  }

  /// Save chat messages for a session ID and update last chat timestamp
  static Future<void> saveMessages(String sessionId, List<AiChatMessage> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = messages.map((m) => m.toJson()).toList();
      await prefs.setString('$_keyPrefix$sessionId', jsonEncode(jsonList));

      final nim = _extractNim(sessionId);
      await prefs.setString('$_lastSessionPrefix$nim', sessionId);

      // Determine timestamp: use the timestamp of the latest message, or now
      DateTime lastTimestamp = DateTime.now();
      if (messages.isNotEmpty) {
        lastTimestamp = messages.last.timestamp;
      }
      await _updateLastChatTimestamp(nim, lastTimestamp);
    } catch (e) {
      debugPrint('[AiChatStorage] Error saving messages: $e');
    }
  }

  /// Load chat messages for a session ID.
  /// Returns empty list and clears if 24+ hours have passed since last chat.
  static Future<List<AiChatMessage>> loadMessages(String sessionId) async {
    try {
      final nim = _extractNim(sessionId);
      final expired = await isSessionExpired(nim);

      if (expired) {
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

  /// Clear a specific session and its references
  static Future<void> clearSession(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_keyPrefix$sessionId');

      final nim = _extractNim(sessionId);
      final currentLastSession = prefs.getString('$_lastSessionPrefix$nim');
      if (currentLastSession == sessionId) {
        await prefs.remove('$_lastSessionPrefix$nim');
        await prefs.remove('$_lastChatTimestampPrefix$nim');
      }
    } catch (e) {
      debugPrint('[AiChatStorage] Error clearing session: $e');
    }
  }

  /// Clean up all expired sessions across all users
  static Future<void> cleanExpiredSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys().toList();

      for (final key in allKeys) {
        if (key.startsWith(_lastSessionPrefix)) {
          final nim = key.substring(_lastSessionPrefix.length);
          final expired = await isSessionExpired(nim);
          if (expired) {
            final lastSession = prefs.getString(key);
            if (lastSession != null) {
              await prefs.remove('$_keyPrefix$lastSession');
              debugPrint('[AiChatStorage] Cleaned expired session: $lastSession');
            }
            await prefs.remove(key);
            await prefs.remove('$_lastChatTimestampPrefix$nim');
          }
        }
      }
    } catch (e) {
      debugPrint('[AiChatStorage] Error cleaning expired sessions: $e');
    }
  }
}
