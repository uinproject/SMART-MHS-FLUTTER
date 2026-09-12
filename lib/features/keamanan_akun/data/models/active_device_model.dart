class ActiveDevice {
  final String modelPerangkat;
  final String idPerangkat;
  final String versiApp;
  final String tanggalLogin;
  final String tanggalAkhirAktif;

  ActiveDevice({
    required this.modelPerangkat,
    required this.idPerangkat,
    required this.versiApp,
    required this.tanggalLogin,
    required this.tanggalAkhirAktif,
  });

  factory ActiveDevice.fromJson(Map<String, dynamic> json) {
    return ActiveDevice(
      modelPerangkat: json['Model_Perangkat']?.toString() ?? '',
      idPerangkat: json['ID_Perangkat']?.toString() ?? '',
      versiApp: json['Versi_App']?.toString() ?? '',
      tanggalLogin: json['Tanggal_Login']?.toString() ?? '',
      tanggalAkhirAktif: json['Tanggal_Akhir_Aktif']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Model_Perangkat': modelPerangkat,
      'ID_Perangkat': idPerangkat,
      'Versi_App': versiApp,
      'Tanggal_Login': tanggalLogin,
      'Tanggal_Akhir_Aktif': tanggalAkhirAktif,
    };
  }
}

class ActiveDevicesResponse {
  final bool success;
  final String message;
  final List<ActiveDevice> devices;

  ActiveDevicesResponse({
    required this.success,
    required this.message,
    required this.devices,
  });

  factory ActiveDevicesResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    List<ActiveDevice> list = [];
    if (rawData is List) {
      list = rawData
          .map((e) => ActiveDevice.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return ActiveDevicesResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      devices: list,
    );
  }
}
