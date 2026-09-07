class PengumumanResponse {
  final bool success;
  final String? message;
  final String? pesanPenting;
  final String? aksiPesan;
  final List<PengumumanData>? data;

  PengumumanResponse({
    required this.success,
    this.message,
    this.pesanPenting,
    this.aksiPesan,
    this.data,
  });

  factory PengumumanResponse.fromJson(Map<String, dynamic> json) {
    return PengumumanResponse(
      success: json['success'] ?? false,
      message: json['message'],
      pesanPenting: json['pesanpenting'],
      aksiPesan: json['aksipesan'],
      data: json['data'] != null
          ? List<PengumumanData>.from(
              json['data'].map((x) => PengumumanData.fromJson(x)))
          : null,
    );
  }
}

class PengumumanData {
  final String judul;
  final String linkPicture;
  final String isi;
  final String tanggal;
  final String kategori;
  final String publisher;

  PengumumanData({
    required this.judul,
    required this.linkPicture,
    required this.isi,
    required this.tanggal,
    required this.kategori,
    required this.publisher,
  });

  factory PengumumanData.fromJson(Map<String, dynamic> json) {
    return PengumumanData(
      judul: json['judul'] ?? '',
      linkPicture: json['linkpicture'] ?? '',
      isi: json['isi'] ?? '',
      tanggal: json['tanggal'] ?? '',
      kategori: json['kategori'] ?? '',
      publisher: json['publisher'] ?? '',
    );
  }
}
