class PengumumanResponse {
  final bool success;
  final String? message;
  final String? pesanPenting;
  final String? aksiPesan;

  /// Server-side EDOM gate (same pattern as KHS / course offers /
  /// CheckLatestAppVersionResponse in the legacy app): `false` = the
  /// student has not completed the lecturer evaluation.
  /// NULLABLE — the server sometimes sends `cekeval: null` or omits it
  /// entirely; null simply means "no information" (never shows the
  /// reminder dialog).
  final bool? cekEval;

  final List<PengumumanData>? data;

  PengumumanResponse({
    required this.success,
    this.message,
    this.pesanPenting,
    this.aksiPesan,
    this.cekEval,
    this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'pesanpenting': pesanPenting,
      'aksipesan': aksiPesan,
      'cekeval': cekEval,
      'data': data?.map((x) => x.toJson()).toList(),
    };
  }

  factory PengumumanResponse.fromJson(Map<String, dynamic> json) {
    return PengumumanResponse(
      success: json['success'] ?? false,
      message: json['message'],
      pesanPenting: json['pesanpenting'],
      aksiPesan: json['aksipesan'],
      cekEval: _parseBool(json['cekeval']),
      data: json['data'] != null
          ? List<PengumumanData>.from(
              json['data'].map((x) => PengumumanData.fromJson(x)),
            )
          : null,
    );
  }

  /// Robust bool parse: null → null (no info), bool → itself,
  /// "true"/"false"/"1"/"0" strings and numbers → parsed, anything
  /// else → null (never a false positive that would wrongly show the
  /// EDOM reminder).
  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      switch (value.trim().toLowerCase()) {
        case 'true':
        case '1':
          return true;
        case 'false':
        case '0':
          return false;
      }
    }
    return null;
  }
}

class PengumumanData {
  final String judul;
  final String linkPicture;
  final String isi;
  final String tanggal;
  final String kategori;
  final String publisher;
  final bool cekEval;

  PengumumanData({
    required this.judul,
    required this.linkPicture,
    required this.isi,
    required this.tanggal,
    required this.kategori,
    required this.publisher,
    required this.cekEval,
  });

  Map<String, dynamic> toJson() {
    return {
      'judul': judul,
      'linkpicture': linkPicture,
      'isi': isi,
      'tanggal': tanggal,
      'kategori': kategori,
      'publisher': publisher,
      'cekeval': cekEval,
    };
  }

  factory PengumumanData.fromJson(Map<String, dynamic> json) {
    return PengumumanData(
      judul: json['judul'] ?? '',
      linkPicture: json['linkpicture'] ?? '',
      isi: json['isi'] ?? '',
      tanggal: json['tanggal'] ?? '',
      kategori: json['kategori'] ?? '',
      publisher: json['publisher'] ?? '',
      cekEval: json['cekeval'] == null ? true : json['cekeval'] == true,
    );
  }
}
