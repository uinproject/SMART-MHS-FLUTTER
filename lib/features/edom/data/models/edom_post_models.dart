class EdomPostData {
  final String nim;
  final bool validate;
  final String errorvalidatemessage;
  final String language;
  final List<EdomPostItem> datapost;
  final String saran;
  final String ideval;

  EdomPostData({
    required this.nim,
    required this.validate,
    required this.errorvalidatemessage,
    required this.language,
    required this.datapost,
    required this.saran,
    required this.ideval,
  });

  Map<String, dynamic> toJson() {
    return {
      'nim': nim,
      'validate': validate,
      'errorvalidatemessage': errorvalidatemessage,
      'language': language,
      'datapost': datapost.map((x) => x.toJson()).toList(),
      'saran': saran,
      'ideval': ideval,
    };
  }
}

class EdomPostItem {
  final String idkompetensi;
  final String idsoal;
  final String jawaban;
  final String bobotjawaban;

  EdomPostItem({
    required this.idkompetensi,
    required this.idsoal,
    required this.jawaban,
    required this.bobotjawaban,
  });

  Map<String, dynamic> toJson() {
    return {
      'idkompetensi': idkompetensi,
      'idsoal': idsoal,
      'jawaban': jawaban,
      'bobotjawaban': bobotjawaban,
    };
  }
}

class EdomPostResponse {
  final bool success;
  final String message;
  final double? rating;
  final String komentar;

  EdomPostResponse({
    required this.success,
    required this.message,
    this.rating,
    required this.komentar,
  });

  factory EdomPostResponse.fromJson(Map<String, dynamic> json) {
    return EdomPostResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      rating: _toDouble(json['rating']),
      komentar: json['komentar']?.toString() ?? '',
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
