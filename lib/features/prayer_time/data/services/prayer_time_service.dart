import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prayer_timing_model.dart';

class PrayerTimingResult {
  final PrayerTimingModel? model;
  final bool isFromCache;
  final String? errorMessage;
  final String? address;

  PrayerTimingResult({
    required this.model,
    required this.isFromCache,
    this.errorMessage,
    this.address,
  });
}

class PrayerTimeService {
  final Dio _dio;

  static const String _cacheKeyData = 'cached_prayer_timing_data';
  static const String _cacheKeyDate = 'cached_prayer_timing_date';
  static const String _cacheKeyLat = 'cached_prayer_timing_lat';
  static const String _cacheKeyLng = 'cached_prayer_timing_lng';
  static const String _cacheKeyAddress = 'cached_prayer_timing_address';

  PrayerTimeService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                headers: {
                  'Accept': 'application/json',
                },
              ),
            );

  /// Fetches prayer times from AlAdhan API (method=20 Kemenag RI)
  /// Falls back to SharedPreferences cache if network call fails or when cache is valid
  Future<PrayerTimingResult> getPrayerTimes({
    required double latitude,
    required double longitude,
    String? currentAddress,
    bool forceRefresh = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateFormat('dd-MM-yyyy').format(DateTime.now());

    // Check cache first if not force refresh
    if (!forceRefresh) {
      final cachedDate = prefs.getString(_cacheKeyDate);
      final cachedJson = prefs.getString(_cacheKeyData);
      final cachedLat = prefs.getDouble(_cacheKeyLat);
      final cachedLng = prefs.getDouble(_cacheKeyLng);
      final cachedAddress = prefs.getString(_cacheKeyAddress);

      if (cachedJson != null && cachedDate == todayStr && cachedLat != null && cachedLng != null) {
        // Check if distance between user and cached location is within 25 km
        final distanceMeters = Geolocator.distanceBetween(latitude, longitude, cachedLat, cachedLng);
        if (distanceMeters < 25000) {
          try {
            final decoded = jsonDecode(cachedJson) as Map<String, dynamic>;
            final model = PrayerTimingModel.fromJson(decoded);
            return PrayerTimingResult(
              model: model,
              isFromCache: true,
              address: currentAddress ?? cachedAddress,
            );
          } catch (_) {
            // Corrupt cache, continue to fetch from API
          }
        }
      }
    }

    // Attempt fetching from API
    final url =
        'https://api.aladhan.com/v1/timings/$todayStr?latitude=$latitude&longitude=$longitude&method=20';

    try {
      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data != null) {
        final dataMap = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : jsonDecode(response.data.toString()) as Map<String, dynamic>;

        final model = PrayerTimingModel.fromJson(dataMap);

        // Save to cache
        await prefs.setString(_cacheKeyData, jsonEncode(dataMap));
        await prefs.setString(_cacheKeyDate, todayStr);
        await prefs.setDouble(_cacheKeyLat, latitude);
        await prefs.setDouble(_cacheKeyLng, longitude);
        if (currentAddress != null && currentAddress.isNotEmpty) {
          await prefs.setString(_cacheKeyAddress, currentAddress);
        }

        return PrayerTimingResult(
          model: model,
          isFromCache: false,
          address: currentAddress ?? prefs.getString(_cacheKeyAddress),
        );
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Gagal memuat jadwal dari server (Status ${response.statusCode})',
        );
      }
    } catch (e) {
      // Network/Server failed: Fallback to existing cache if available
      final cachedJson = prefs.getString(_cacheKeyData);
      final cachedAddress = prefs.getString(_cacheKeyAddress);
      if (cachedJson != null) {
        try {
          final decoded = jsonDecode(cachedJson) as Map<String, dynamic>;
          final cachedModel = PrayerTimingModel.fromJson(decoded);
          return PrayerTimingResult(
            model: cachedModel,
            isFromCache: true,
            errorMessage: 'Tidak dapat terhubung ke server. Menggunakan jadwal tersimpan.',
            address: currentAddress ?? cachedAddress,
          );
        } catch (_) {}
      }

      // No cache available at all
      String friendlyError = 'Gagal memuat jadwal sholat. Periksa koneksi internet Anda.';
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          friendlyError = 'Koneksi ke server jadwal sholat batas waktu habis (timeout).';
        } else if (e.type == DioExceptionType.connectionError) {
          friendlyError = 'Tidak ada koneksi internet. Silakan periksa jaringan Anda.';
        }
      }

      return PrayerTimingResult(
        model: null,
        isFromCache: false,
        errorMessage: friendlyError,
        address: currentAddress,
      );
    }
  }
}
