class EdomQuestionsResponse {
  final bool success;
  final String? message;
  final List<EdomIndikator>? data;

  EdomQuestionsResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory EdomQuestionsResponse.fromJson(Map<String, dynamic> json) {
    return EdomQuestionsResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null
          ? List<EdomIndikator>.from(
              json['data'].map((x) => EdomIndikator.fromJson(x)))
          : null,
    );
  }
}

class EdomIndikator {
  final String idkompetensi;
  final String namakompetensi;
  final List<EdomSoal> itemsoal;

  EdomIndikator({
    required this.idkompetensi,
    required this.namakompetensi,
    required this.itemsoal,
  });

  factory EdomIndikator.fromJson(Map<String, dynamic> json) {
    return EdomIndikator(
      idkompetensi: json['idkompetensi']?.toString() ?? '',
      namakompetensi: json['namakompetensi']?.toString() ?? '',
      itemsoal: json['itemsoal'] != null
          ? List<EdomSoal>.from(json['itemsoal'].map((x) => EdomSoal.fromJson(x)))
          : [],
    );
  }
}

class EdomSoal {
  final String idsoal;
  final String idkompetensi;
  final String pertanyaan;
  final String? urlimage;
  final List<EdomJawaban> itemjawaban;

  EdomSoal({
    required this.idsoal,
    required this.idkompetensi,
    required this.pertanyaan,
    this.urlimage,
    required this.itemjawaban,
  });

  factory EdomSoal.fromJson(Map<String, dynamic> json) {
    return EdomSoal(
      idsoal: json['idsoal']?.toString() ?? '',
      idkompetensi: json['idkompetensi']?.toString() ?? '',
      pertanyaan: json['pertanyaan']?.toString() ?? '',
      urlimage: json['urlimage'],
      itemjawaban: json['itemjawaban'] != null
          ? List<EdomJawaban>.from(
              json['itemjawaban'].map((x) => EdomJawaban.fromJson(x)))
          : [],
    );
  }
}

class EdomJawaban {
  final String pilihan;
  final String indexpilihan;
  final String value;
  String terjawab; // mutable "Y"/"N"

  EdomJawaban({
    required this.pilihan,
    required this.indexpilihan,
    required this.value,
    required this.terjawab,
  });

  factory EdomJawaban.fromJson(Map<String, dynamic> json) {
    return EdomJawaban(
      pilihan: json['pilihan']?.toString() ?? '',
      indexpilihan: json['indexpilihan']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
      terjawab: json['terjawab']?.toString() ?? 'N',
    );
  }
}
