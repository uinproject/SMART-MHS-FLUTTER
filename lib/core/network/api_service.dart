import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../utils/app_constants.dart';
import '../security/bni_encryption.dart';
import '../../features/auth/data/models/api_responses.dart';
import '../../features/auth/data/models/login_data.dart';
import '../../features/home/data/models/pengumuman_response.dart';
import '../../features/home/data/models/jadwal_response.dart';
import '../../features/bills/data/models/tagihan_response.dart';

class ForceLogoutException implements Exception {
  final String message;
  ForceLogoutException(this.message);
}

class LoginResult {
  final bool success;
  final String message;
  final bool resyncrondevice;
  final LoginData? data;

  LoginResult({
    required this.success,
    required this.message,
    this.resyncrondevice = false,
    this.data,
  });
}

class ApiService {
  late Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Authorization': AppConstants.authHeader,
        'SMART-API-KEY': AppConstants.apiKey,
      },
    ));

    // Bypass SSL certificate validation (Trust All) as in the legacy project
    _dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
        return client;
      },
    );
    
    _dio.interceptors.add(LogInterceptor(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: false,
      error: true,
    ));
  }

  Future<LoginResult> login({
    required String nim,
    required String password,
    required String deviceId,
    required String deviceName,
    String resyncronDevice = 'ayang',
    String tokenNotif = 'undefined',
    String language = 'in',
  }) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final versionApp = packageInfo.version;

      final data = {
        'unim': BniEncryption.hashData(nim, AppConstants.cidV2, AppConstants.secretKeyV2),
        'upassword': BniEncryption.hashData(password, AppConstants.cidV2, AppConstants.secretKeyV2),
        'deviceid': BniEncryption.hashData(deviceId, AppConstants.cidV2, AppConstants.secretKeyV2),
        'devicename': BniEncryption.hashData(deviceName, AppConstants.cidV2, AppConstants.secretKeyV2),
        'resyncrondevice': BniEncryption.hashData(resyncronDevice, AppConstants.cidV2, AppConstants.secretKeyV2),
        'tokennotif': BniEncryption.hashData(tokenNotif, AppConstants.cidV2, AppConstants.secretKeyV2),
        'versionapp': BniEncryption.hashData(versionApp, AppConstants.cidV2, AppConstants.secretKeyV2),
        'language': language,
      };

      final response = await _dio.post(
        'Authservices/authenticationmhs',
        data: data,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data is String 
            ? jsonDecode(response.data) 
            : response.data;
            
        final loginResp = LoginResponse.fromJson(responseData);
        
        // Fix: Priority check for success: true
        if (loginResp.success) {
          final decryptedData = BniEncryption.parseData(
            loginResp.data,
            AppConstants.cidV2,
            AppConstants.secretKeyV2,
          );
          
          if (decryptedData != null) {
            return LoginResult(
              success: true,
              message: loginResp.message,
              data: LoginData.fromJson(jsonDecode(decryptedData)),
            );
          } else {
            return LoginResult(success: false, message: 'Decryption failed');
          }
        } else if (loginResp.resyncronDevice) {
          return LoginResult(
            success: false,
            message: loginResp.message,
            resyncrondevice: true,
          );
        } else {
          return LoginResult(success: false, message: loginResp.message);
        }
      }
      return LoginResult(success: false, message: 'Server error: ${response.statusCode}');
    } catch (e) {
      return LoginResult(success: false, message: 'Connection error: $e');
    }
  }

  Future<LoginData?> refreshSession({
    required String nim,
    required String deviceId,
    String tokenNotif = 'undefined',
  }) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final versionApp = packageInfo.version;

      final data = {
        'unim': BniEncryption.hashData(nim, AppConstants.cidV2, AppConstants.secretKeyV2),
        'deviceid': BniEncryption.hashData(deviceId, AppConstants.cidV2, AppConstants.secretKeyV2),
        'tokennotif': BniEncryption.hashData(tokenNotif, AppConstants.cidV2, AppConstants.secretKeyV2),
        'versionapp': BniEncryption.hashData(versionApp, AppConstants.cidV2, AppConstants.secretKeyV2),
      };

      final response = await _dio.post(
        'Authservices/refreshdata',
        data: data,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data is String 
            ? jsonDecode(response.data) 
            : response.data;

        final refreshResp = RefreshSessionResponse.fromJson(responseData);
        if (refreshResp.forceLogout) {
          throw ForceLogoutException(refreshResp.message);
        }
        
        if (refreshResp.success) {
          final decryptedData = BniEncryption.parseData(
            refreshResp.data,
            AppConstants.cidV2,
            AppConstants.secretKeyV2,
          );
          
          if (decryptedData != null) {
            return LoginData.fromJson(jsonDecode(decryptedData));
          }
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<PengumumanResponse?> getPengumuman({
    String? kodeJen,
    String? kodeFak,
    String? kodePst,
  }) async {
    try {
      final response = await _dio.get(
        'Pengumumanservices/pengumuman',
        queryParameters: {
          'kodejen': kodeJen,
          'kodefak': kodeFak,
          'kodepst': kodePst,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data is String 
            ? jsonDecode(response.data) 
            : response.data;
        return PengumumanResponse.fromJson(responseData);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getOtp({
    required String nim,
    required String kdpst,
    required String email,
    String language = 'in',
  }) async {
    try {
      final data = {
        'unim': BniEncryption.hashData(nim, AppConstants.cid, AppConstants.secretKey),
        'kode_pst': BniEncryption.hashData(kdpst, AppConstants.cid, AppConstants.secretKey),
        'uemail': BniEncryption.hashData(email, AppConstants.cid, AppConstants.secretKey),
        'language': language,
      };

      final response = await _dio.post(
        '${AppConstants.baseUrlLegacy}create_otp_verif_email',
        data: data,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.statusCode == 200) {
        return response.data is String ? jsonDecode(response.data) : response.data;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> verifyOtp({
    required String nim,
    required String kdpst,
    required String email,
    required String otp,
    String language = 'in',
  }) async {
    try {
      final data = {
        'unim': BniEncryption.hashData(nim, AppConstants.cid, AppConstants.secretKey),
        'kode_pst': BniEncryption.hashData(kdpst, AppConstants.cid, AppConstants.secretKey),
        'uemail': BniEncryption.hashData(email, AppConstants.cid, AppConstants.secretKey),
        'otp': BniEncryption.hashData(otp, AppConstants.cid, AppConstants.secretKey),
        'language': language,
      };

      final response = await _dio.post(
        '${AppConstants.baseUrlLegacy}verif_email_mhs',
        data: data,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.statusCode == 200) {
        return response.data is String ? jsonDecode(response.data) : response.data;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getOtpResetPassword({
    required String nim,
    required String email,
    String language = 'in',
  }) async {
    try {
      final data = {
        'unim': BniEncryption.hashData(nim, AppConstants.cidV2, AppConstants.secretKeyV2),
        'uemail': BniEncryption.hashData(email, AppConstants.cidV2, AppConstants.secretKeyV2),
        'language': language,
      };

      final response = await _dio.post(
        'Managerpassword/create_otp_reset_password',
        data: data,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.statusCode == 200) {
        return response.data is String ? jsonDecode(response.data) : response.data;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<VerOTPResetPasswordResponse?> verifyOtpResetPassword({
    required String nim,
    required String email,
    required String otp,
    String language = 'in',
  }) async {
    try {
      final data = {
        'unim': BniEncryption.hashData(nim, AppConstants.cidV2, AppConstants.secretKeyV2),
        'uemail': BniEncryption.hashData(email, AppConstants.cidV2, AppConstants.secretKeyV2),
        'otp': BniEncryption.hashData(otp, AppConstants.cidV2, AppConstants.secretKeyV2),
        'language': language,
      };

      final response = await _dio.post(
        'Managerpassword/verif_otp_reset_password_mhs',
        data: data,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data is String ? jsonDecode(response.data) : response.data;
        return VerOTPResetPasswordResponse.fromJson(responseData);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<ChangePasswordResponse?> changePassword({
    required String encNim,
    required String email,
    required String otp,
    required String newPassword,
    String language = 'in',
  }) async {
    try {
      final data = {
        'encnim': encNim,
        'uemail': BniEncryption.hashData(email, AppConstants.cidV2, AppConstants.secretKeyV2),
        'otp': BniEncryption.hashData(otp, AppConstants.cidV2, AppConstants.secretKeyV2),
        'encnewpassword': BniEncryption.hashData(newPassword, AppConstants.cidV2, AppConstants.secretKeyV2),
        'language': language,
      };

      final response = await _dio.post(
        'Managerpassword/change_password_mhs',
        data: data,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data is String ? jsonDecode(response.data) : response.data;
        return ChangePasswordResponse.fromJson(responseData);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<JadwalResponse?> getJadwalmhs({
    required String nim,
    required int semester,
    String language = 'in',
  }) async {
    try {
      final data = {
        'unim': BniEncryption.hashData(nim, AppConstants.cidV2, AppConstants.secretKeyV2),
        'selected_semester': BniEncryption.hashData(semester.toString(), AppConstants.cidV2, AppConstants.secretKeyV2),
        'language': language,
      };

      final response = await _dio.post(
        'Jadwalservices/jadwalmhsv2',
        data: data,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data is String 
            ? jsonDecode(response.data) 
            : response.data;
        return JadwalResponse.fromJson(responseData);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<TagihanResponse?> getTagihanmhs({
    required String nim,
    String language = 'in',
  }) async {
    try {
      final data = {
        'unim': BniEncryption.hashData(nim, AppConstants.cidV2, AppConstants.secretKeyV2),
        'language': language,
      };

      final response = await _dio.post(
        'Keuanganservices/tagihanmhsv2',
        data: data,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data is String 
            ? jsonDecode(response.data) 
            : response.data;
        return TagihanResponse.fromJson(responseData);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
}
