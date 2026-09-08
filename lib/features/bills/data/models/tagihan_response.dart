class TagihanResponse {
  final bool success;
  final String message;
  final String? data; // Encrypted NIM usually
  final String? semester;
  final List<ItemTagihan>? itemTagihan;

  TagihanResponse({
    required this.success,
    required this.message,
    this.data,
    this.semester,
    this.itemTagihan,
  });

  factory TagihanResponse.fromJson(Map<String, dynamic> json) {
    return TagihanResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'],
      semester: json['semester']?.toString(),
      itemTagihan: json['item_tagihan'] != null
          ? List<ItemTagihan>.from(
              json['item_tagihan'].map((x) => ItemTagihan.fromJson(x)))
          : null,
    );
  }
}

class ItemTagihan {
  final String uraian;
  final String nominal;
  final String status;

  ItemTagihan({
    required this.uraian,
    required this.nominal,
    required this.status,
  });

  factory ItemTagihan.fromJson(Map<String, dynamic> json) {
    return ItemTagihan(
      uraian: json['uraian'] ?? '',
      nominal: json['nominal'] ?? '0',
      status: json['status'] ?? '',
    );
  }

  int get nominalInt {
    return int.tryParse(nominal.replaceAll('.', '').replaceAll(',', '')) ?? 0;
  }
}
