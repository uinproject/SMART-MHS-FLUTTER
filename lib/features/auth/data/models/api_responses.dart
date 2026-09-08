class LoginResponse {
  final bool success;
  final String message;
  final bool resyncronDevice;
  final String data;

  LoginResponse({
    required this.success,
    required this.message,
    required this.resyncronDevice,
    required this.data,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      resyncronDevice: json['resyncrondevice'] ?? false,
      data: json['data'] ?? '',
    );
  }
}

class RefreshSessionResponse {
  final bool success;
  final String message;
  final bool forceLogout;
  final String data;

  RefreshSessionResponse({
    required this.success,
    required this.message,
    required this.forceLogout,
    required this.data,
  });

  factory RefreshSessionResponse.fromJson(Map<String, dynamic> json) {
    return RefreshSessionResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      forceLogout: json['forcelogout'] ?? false,
      data: json['data'] ?? '',
    );
  }
}

class VerOTPResetPasswordResponse {
  final bool success;
  final String message;
  final String nimenc;

  VerOTPResetPasswordResponse({
    required this.success,
    required this.message,
    required this.nimenc,
  });

  factory VerOTPResetPasswordResponse.fromJson(Map<String, dynamic> json) {
    return VerOTPResetPasswordResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      nimenc: json['nimenc'] ?? '',
    );
  }
}

class ChangePasswordResponse {
  final bool success;
  final String message;

  ChangePasswordResponse({
    required this.success,
    required this.message,
  });

  factory ChangePasswordResponse.fromJson(Map<String, dynamic> json) {
    return ChangePasswordResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
    );
  }
}
