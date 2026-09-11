import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:geocoding/geocoding.dart';

class LocationHelper {
  /// Converts latitude & longitude to a human-friendly address like "Sidorejo, Salatiga"
  static Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    // 1. Try native geocoder first via Geocoding instance
    try {
      final geocoding = Geocoding();
      final placemarks = await geocoding.placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final sub = place.subLocality?.trim() ?? '';
        final loc = (place.locality?.trim().isNotEmpty == true)
            ? place.locality!.trim()
            : (place.subAdministrativeArea?.trim() ?? '');

        if (sub.isNotEmpty && loc.isNotEmpty) {
          return '$sub, $loc';
        } else if (loc.isNotEmpty) {
          return loc;
        } else if (sub.isNotEmpty) {
          return sub;
        } else if (place.name?.trim().isNotEmpty == true) {
          return place.name!.trim();
        }
      }
    } catch (_) {}

    // 2. Fallback via free reverse geocode API if native geocoder is unavailable
    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );
      final res = await dio.get(
        'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$lat&longitude=$lng&localityLanguage=id',
      );
      if (res.statusCode == 200 && res.data != null) {
        final data = res.data is Map ? res.data : jsonDecode(res.data.toString());
        final locality = (data['locality'] ?? '').toString().trim();
        final city = (data['city'] ?? '').toString().trim();
        if (locality.isNotEmpty && city.isNotEmpty && locality != city) {
          return '$locality, $city';
        } else if (city.isNotEmpty) {
          return city;
        } else if (locality.isNotEmpty) {
          return locality;
        }
      }
    } catch (_) {}

    return null;
  }
}
