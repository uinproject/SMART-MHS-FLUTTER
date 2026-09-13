import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pengumuman_response.dart';

/// Cache storage for Home data (Pengumuman Penting and Pengumuman Slider)
/// Enables offline / poor-connection persistence.
class HomeCacheStorage {
  static const String _pengumumanKeyPrefix = 'cached_home_pengumuman_';
  static const String _lastUpdatedKeyPrefix = 'cached_home_pengumuman_time_';

  /// Saves PengumumanResponse (both important message and carousel slider data) to local cache.
  static Future<void> savePengumuman(String? nim, PengumumanResponse pengumuman) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_pengumumanKeyPrefix${nim ?? 'guest'}';
      final timeKey = '$_lastUpdatedKeyPrefix${nim ?? 'guest'}';

      final jsonStr = jsonEncode(pengumuman.toJson());
      await prefs.setString(key, jsonStr);
      await prefs.setString(timeKey, DateTime.now().toIso8601String());
      debugPrint('[HomeCacheStorage] Saved pengumuman cache for NIM: $nim');
    } catch (e) {
      debugPrint('[HomeCacheStorage] Failed to save pengumuman cache: $e');
    }
  }

  /// Loads cached PengumumanResponse for the given student NIM.
  /// Returns null if no cache exists or if parsing fails.
  static Future<PengumumanResponse?> loadPengumuman(String? nim) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_pengumumanKeyPrefix${nim ?? 'guest'}';
      String? jsonStr = prefs.getString(key);

      // Fallback: if student-specific cache is not found, check guest cache
      if (jsonStr == null || jsonStr.isEmpty) {
        final guestKey = '${_pengumumanKeyPrefix}guest';
        jsonStr = prefs.getString(guestKey);
      }

      if (jsonStr == null || jsonStr.isEmpty) {
        return null;
      }

      final decoded = jsonDecode(jsonStr);
      if (decoded is Map<String, dynamic>) {
        return PengumumanResponse.fromJson(decoded);
      }
      return null;
    } catch (e) {
      debugPrint('[HomeCacheStorage] Failed to load pengumuman cache: $e');
      return null;
    }
  }

  /// Gets the timestamp when the cache was last saved.
  static Future<DateTime?> getLastUpdated(String? nim) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeKey = '$_lastUpdatedKeyPrefix${nim ?? 'guest'}';
      final raw = prefs.getString(timeKey);
      if (raw != null) return DateTime.tryParse(raw);
    } catch (_) {}
    return null;
  }

  /// Clears cached pengumuman for a student.
  static Future<void> clearPengumuman(String? nim) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_pengumumanKeyPrefix${nim ?? 'guest'}');
      await prefs.remove('$_lastUpdatedKeyPrefix${nim ?? 'guest'}');
    } catch (_) {}
  }
}
