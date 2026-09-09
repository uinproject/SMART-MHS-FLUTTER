class RekapPembayaranResponse {
  final bool success;
  final String? message;
  final List<PembayaranData>? data;

  RekapPembayaranResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory RekapPembayaranResponse.fromJson(Map<String, dynamic> json) {
    return RekapPembayaranResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null
          ? List<PembayaranData>.from(
              json['data'].map((x) => PembayaranData.fromJson(x)))
          : null,
    );
  }
}

class PembayaranData {
  final String semester;
  final String namatagihan;
  final int jumlah;
  final String tanggalbayar;
  final String melalui;
  final String linkKuitansi;

  PembayaranData({
    required this.semester,
    required this.namatagihan,
    required this.jumlah,
    required this.tanggalbayar,
    required this.melalui,
    required this.linkKuitansi,
  });

  factory PembayaranData.fromJson(Map<String, dynamic> json) {
    return PembayaranData(
      semester: json['semester']?.toString() ?? '',
      namatagihan: json['namatagihan'] ?? '',
      jumlah: json['jumlah'] ?? 0,
      tanggalbayar: json['tanggalbayar'] ?? '',
      melalui: json['melalui'] ?? '',
      linkKuitansi: json['link_kuitansi'] ?? '',
    );
  }
}
