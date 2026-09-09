class TuitionBillResponse {
  final bool success;
  final String? message;
  final List<SemesterBill>? data;

  TuitionBillResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory TuitionBillResponse.fromJson(Map<String, dynamic> json) {
    return TuitionBillResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null
          ? List<SemesterBill>.from(
              json['data'].map((x) => SemesterBill.fromJson(x)))
          : null,
    );
  }
}

class SemesterBill {
  final int semester;
  final List<BillItem> itemTagihan;

  SemesterBill({
    required this.semester,
    required this.itemTagihan,
  });

  factory SemesterBill.fromJson(Map<String, dynamic> json) {
    return SemesterBill(
      semester: _toInt(json['semester']),
      itemTagihan: json['item_tagihan'] != null
          ? List<BillItem>.from(
              json['item_tagihan'].map((x) => BillItem.fromJson(x)))
          : [],
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class BillItem {
  final String namatagihan;
  final int jumlah;

  BillItem({
    required this.namatagihan,
    required this.jumlah,
  });

  factory BillItem.fromJson(Map<String, dynamic> json) {
    return BillItem(
      namatagihan: json['namatagihan'] ?? '',
      jumlah: _toInt(json['jumlah']),
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
