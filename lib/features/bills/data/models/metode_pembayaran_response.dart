class MetodePembayaranResponse {
  final bool success;
  final String? message;
  final List<MetodePembayaranData>? data;

  MetodePembayaranResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory MetodePembayaranResponse.fromJson(Map<String, dynamic> json) {
    return MetodePembayaranResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null
          ? List<MetodePembayaranData>.from(
              json['data'].map((x) => MetodePembayaranData.fromJson(x)))
          : null,
    );
  }
}

class MetodePembayaranData {
  final String namaMetode;
  final String norek;
  final String deskripsi;
  final String linkLogo;
  final String tataCara;
  final String biayaAdm;

  MetodePembayaranData({
    required this.namaMetode,
    required this.norek,
    required this.deskripsi,
    required this.linkLogo,
    required this.tataCara,
    required this.biayaAdm,
  });

  factory MetodePembayaranData.fromJson(Map<String, dynamic> json) {
    return MetodePembayaranData(
      namaMetode: json['nama_metode'] ?? '',
      norek: json['norek'] ?? '',
      deskripsi: json['deskripsi'] ?? '',
      linkLogo: json['link_logo'] ?? '',
      tataCara: json['tata_cara'] ?? '',
      biayaAdm: json['biaya_adm']?.toString() ?? '0',
    );
  }
}
