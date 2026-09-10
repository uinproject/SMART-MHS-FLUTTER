// Model for the KHS (Kartu Hasil Studi / Study Result) endpoint.
// Mirrors the legacy Kotlin model `KhsResponse.kt` (plain JSON response —
// no decryption, exact same serialized names):
//
// POST khsservices/khs -> { success, message, semester, cekeval,
//                            data: [ { makul, sks, kelas, nilaihuruf,
//                                      nilaiangka } ] }

/// POST khsservices/khs
class KhsResponse {
  final bool success;
  final String? message;
  final String? semester;

  /// Server-side EDOM gate (same pattern as `PenawaranMKgetResponse`).
  /// `false` = student must complete the lecturer evaluation (EDOM) before
  /// the KHS may be shown. Defaults to `true` when the server omits it.
  final bool cekEval;

  final List<KhsData>? data;

  KhsResponse({
    required this.success,
    this.message,
    this.semester,
    this.cekEval = true,
    this.data,
  });

  factory KhsResponse.fromJson(Map<String, dynamic> json) {
    return KhsResponse(
      success: json['success'] ?? false,
      message: json['message']?.toString(),
      semester: json['semester']?.toString(),
      cekEval: json['cekeval'] == null ? true : json['cekeval'] == true,
      data: json['data'] != null
          ? List<KhsData>.from(
              (json['data'] as List).map((x) => KhsData.fromJson(x)),
            )
          : null,
    );
  }
}

/// One graded course row of the KHS.
class KhsData {
  final String makul;
  final int sks;
  final String kelas;
  final String nilaihuruf;
  final double nilaiangka;

  KhsData({
    required this.makul,
    required this.sks,
    required this.kelas,
    required this.nilaihuruf,
    required this.nilaiangka,
  });

  factory KhsData.fromJson(Map<String, dynamic> json) {
    return KhsData(
      makul: json['makul']?.toString() ?? '',
      sks: _toInt(json['sks']) ?? 0,
      kelas: json['kelas']?.toString() ?? '',
      nilaihuruf: json['nilaihuruf']?.toString() ?? '',
      nilaiangka: _toDouble(json['nilaiangka']) ?? 0.0,
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final normalized = value.replaceAll(',', '.');
      return double.tryParse(normalized)?.round();
    }
    return null;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '.'));
    return null;
  }
}
