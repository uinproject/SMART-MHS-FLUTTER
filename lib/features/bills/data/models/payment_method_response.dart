class PaymentMethodResponse {
  final bool success;
  final String? message;
  final List<PaymentMethodItem>? data;

  PaymentMethodResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory PaymentMethodResponse.fromJson(Map<String, dynamic> json) {
    return PaymentMethodResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null
          ? List<PaymentMethodItem>.from(
              json['data'].map((x) => PaymentMethodItem.fromJson(x)))
          : null,
    );
  }
}

class PaymentMethodItem {
  final String namaMetode;
  final String norek;
  final String deskripsi;
  final String linkLogo;
  final String tataCara;
  final int biayaAdm;

  PaymentMethodItem({
    required this.namaMetode,
    required this.norek,
    required this.deskripsi,
    required this.linkLogo,
    required this.tataCara,
    required this.biayaAdm,
  });

  factory PaymentMethodItem.fromJson(Map<String, dynamic> json) {
    return PaymentMethodItem(
      namaMetode: json['nama_metode'] ?? '',
      norek: json['norek'] ?? '',
      deskripsi: json['deskripsi'] ?? '',
      linkLogo: json['link_logo'] ?? '',
      tataCara: json['tata_cara'] ?? '',
      biayaAdm: _toInt(json['biaya_adm']),
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
