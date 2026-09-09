// Models for the PMK (Penawaran Mata Kuliah) endpoints.
// Mirrors the legacy Kotlin models `PenawaranMKgetResponse`,
// `PenawaranMKRiwayatResponse` and `PenawaranMKpostResponse`
// (plain JSON responses — no decryption, exact same serialized names).

/// GET Penawaranmkservices/list_penawaran_mk
class PenawaranListResponse {
  final bool success;
  final String? message;
  final int? jatahSks;
  final int? smtPenawaranMk;
  final int? smtAktifSebelumnya;
  final double? ipsSmtSebelumnya;
  final String? waktuMulai;
  final String? waktuSelesai;

  /// false -> student must complete lecturer evaluation (Edom) first.
  /// Errors construct `true` so the blocking dialog never shows on errors
  /// (same as legacy).
  final bool cekEval;
  final List<PenawaranSemester>? data;

  PenawaranListResponse({
    required this.success,
    this.message,
    this.jatahSks,
    this.smtPenawaranMk,
    this.smtAktifSebelumnya,
    this.ipsSmtSebelumnya,
    this.waktuMulai,
    this.waktuSelesai,
    this.cekEval = true,
    this.data,
  });

  factory PenawaranListResponse.fromJson(Map<String, dynamic> json) {
    return PenawaranListResponse(
      success: json['success'] ?? false,
      message: json['message']?.toString(),
      jatahSks: _toInt(json['jatah_sks']),
      smtPenawaranMk: _toInt(json['smt_penawaran_mk']),
      smtAktifSebelumnya: _toInt(json['smt_aktif_sebelumnya']),
      ipsSmtSebelumnya: _toDouble(json['ips_smt_sebelumnya']),
      waktuMulai: json['waktu_mulai']?.toString(),
      waktuSelesai: json['waktu_selesai']?.toString(),
      cekEval: json['cekeval'] ?? true,
      data: json['data'] != null
          ? List<PenawaranSemester>.from(
              json['data'].map((x) => PenawaranSemester.fromJson(x)))
          : null,
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

class PenawaranSemester {
  final int semester;
  final List<PenawaranMataKuliah> itemMakul;

  PenawaranSemester({
    required this.semester,
    required this.itemMakul,
  });

  factory PenawaranSemester.fromJson(Map<String, dynamic> json) {
    return PenawaranSemester(
      semester: _toInt(json['semester']) ?? 0,
      itemMakul: json['item_makul'] != null
          ? List<PenawaranMataKuliah>.from(
              json['item_makul'].map((x) => PenawaranMataKuliah.fromJson(x)))
          : [],
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class PenawaranMataKuliah {
  final int thsmsMk;
  final String kdjenMk;
  final String kdpstMk;
  final String kdmkMk;
  final String namaMk;
  final int sksMk;

  /// "Y" | "T" — mutated after a successful submit (same as legacy).
  String sudahInputPmk;
  String? tglInputPmk;

  /// Previous-take info shown verbatim (grade etc.).
  final String pernahAmbilMk;

  /// "ms" = selectable, "tms" = blocked (with HTML [desc] reason).
  final String keterangan;
  final String desc;

  PenawaranMataKuliah({
    required this.thsmsMk,
    required this.kdjenMk,
    required this.kdpstMk,
    required this.kdmkMk,
    required this.namaMk,
    required this.sksMk,
    this.sudahInputPmk = 'T',
    this.tglInputPmk,
    this.pernahAmbilMk = '',
    this.keterangan = 'ms',
    this.desc = '',
  });

  factory PenawaranMataKuliah.fromJson(Map<String, dynamic> json) {
    return PenawaranMataKuliah(
      thsmsMk: _toInt(json['thsms_mk']) ?? 0,
      kdjenMk: json['kdjen_mk']?.toString() ?? '',
      kdpstMk: json['kdpst_mk']?.toString() ?? '',
      kdmkMk: json['kdmk_mk']?.toString() ?? '',
      namaMk: json['nama_mk']?.toString() ?? '',
      sksMk: _toInt(json['sks_mk']) ?? 0,
      sudahInputPmk: json['sudah_input_pmk']?.toString() ?? 'T',
      tglInputPmk: json['tgl_input_pmk']?.toString(),
      pernahAmbilMk: json['pernah_ambil_mk']?.toString() ?? '',
      keterangan: json['keterangan']?.toString() ?? 'ms',
      desc: json['desc']?.toString() ?? '',
    );
  }

  bool get selectable => keterangan == 'ms';

  /// Legacy renders `desc` through Html.fromHtml — plain text is enough here.
  String get descPlain =>
      desc.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll(RegExp(r'\s+'), ' ').trim();

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}

/// GET Penawaranmkservices/riwayat_penawaran_mk
class PenawaranRiwayatResponse {
  final bool success;
  final String? message;
  final int? jatahSks;
  final int? smtPenawaranMk;
  final int? smtAktifSebelumnya;
  final double? ipsSmtSebelumnya;
  final List<PenawaranRiwayatSemester>? data;

  PenawaranRiwayatResponse({
    required this.success,
    this.message,
    this.jatahSks,
    this.smtPenawaranMk,
    this.smtAktifSebelumnya,
    this.ipsSmtSebelumnya,
    this.data,
  });

  factory PenawaranRiwayatResponse.fromJson(Map<String, dynamic> json) {
    return PenawaranRiwayatResponse(
      success: json['success'] ?? false,
      message: json['message']?.toString(),
      jatahSks: _toInt(json['jatah_sks']),
      smtPenawaranMk: _toInt(json['smt_penawaran_mk']),
      smtAktifSebelumnya: _toInt(json['smt_aktif_sebelumnya']),
      ipsSmtSebelumnya: _toDouble(json['ips_smt_sebelumnya']),
      data: json['data'] != null
          ? List<PenawaranRiwayatSemester>.from(
              json['data'].map((x) => PenawaranRiwayatSemester.fromJson(x)))
          : null,
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

class PenawaranRiwayatSemester {
  final int semester;
  final List<PenawaranRiwayatMataKuliah> itemMakul;

  PenawaranRiwayatSemester({
    required this.semester,
    required this.itemMakul,
  });

  factory PenawaranRiwayatSemester.fromJson(Map<String, dynamic> json) {
    return PenawaranRiwayatSemester(
      semester: _toInt(json['semester']) ?? 0,
      itemMakul: json['item_makul'] != null
          ? List<PenawaranRiwayatMataKuliah>.from(
              json['item_makul'].map((x) => PenawaranRiwayatMataKuliah.fromJson(x)))
          : [],
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class PenawaranRiwayatMataKuliah {
  final int thsmsMk;
  final String kdjenMk;
  final String kdpstMk;
  final String kdmkMk;
  final String namaMk;
  final int sksMk;
  final String? tglInputPmk;

  PenawaranRiwayatMataKuliah({
    required this.thsmsMk,
    required this.kdjenMk,
    required this.kdpstMk,
    required this.kdmkMk,
    required this.namaMk,
    required this.sksMk,
    this.tglInputPmk,
  });

  factory PenawaranRiwayatMataKuliah.fromJson(Map<String, dynamic> json) {
    return PenawaranRiwayatMataKuliah(
      thsmsMk: _toInt(json['thsms_mk']) ?? 0,
      kdjenMk: json['kdjen_mk']?.toString() ?? '',
      kdpstMk: json['kdpst_mk']?.toString() ?? '',
      kdmkMk: json['kdmk_mk']?.toString() ?? '',
      namaMk: json['nama_mk']?.toString() ?? '',
      sksMk: _toInt(json['sks_mk']) ?? 0,
      tglInputPmk: json['tgl_input_pmk']?.toString(),
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}

/// POST Penawaranmkservices/input_penawaran_mata_kuliah
class PenawaranPostResponse {
  final bool success;
  final String message;
  final String tglInput;

  PenawaranPostResponse({
    required this.success,
    required this.message,
    this.tglInput = '',
  });

  factory PenawaranPostResponse.fromJson(Map<String, dynamic> json) {
    return PenawaranPostResponse(
      success: json['success'] ?? false,
      message: json['message']?.toString() ?? '',
      tglInput: json['tgl_input']?.toString() ?? '',
    );
  }
}
