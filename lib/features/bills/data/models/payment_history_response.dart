class PaymentHistoryResponse {
  final bool success;
  final String? message;
  final List<HistoryItem>? data;

  PaymentHistoryResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory PaymentHistoryResponse.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null
          ? List<HistoryItem>.from(
              json['data'].map((x) => HistoryItem.fromJson(x)))
          : null,
    );
  }
}

class HistoryItem {
  final String semester;
  final String namatagihan;
  final int jumlah;
  final String tanggalbayar;
  final String melalui;
  final String linkKuitansi;

  HistoryItem({
    required this.semester,
    required this.namatagihan,
    required this.jumlah,
    required this.tanggalbayar,
    required this.melalui,
    required this.linkKuitansi,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      semester: json['semester']?.toString() ?? '',
      namatagihan: json['namatagihan'] ?? '',
      jumlah: _toInt(json['jumlah']),
      tanggalbayar: json['tanggalbayar'] ?? '',
      melalui: json['melalui'] ?? '',
      linkKuitansi: json['link_kuitansi'] ?? '',
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
