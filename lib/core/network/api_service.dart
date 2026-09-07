import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../utils/app_constants.dart';
import '../security/bni_encryption.dart';
import '../../features/auth/data/models/api_responses.dart';
import '../../features/auth/data/models/login_data.dart';
import 'dart:convert';

class ApiService {
  late Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Authorization': AppConstants.authHeader,
        'SMART-API-KEY': AppConstants.apiKey,
      },
    ));
    
    _dio.interceptors.add(LogInterceptor(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: false,
      error: true,
    ));
  }

  Future<LoginData?> login({
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
        final loginResp = LoginResponse.fromJson(response.data);
        if (loginResp.success) {
          final decryptedData = BniEncryption.parseData(
            loginResp.data,
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
        'create_otp_verif_email',
        data: data,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
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
        'verif_email_mhs',
        data: data,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      rethrow;
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
        final refreshResp = RefreshSessionResponse.fromJson(response.data);
        if (refreshResp.success && !refreshResp.forceLogout) {
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
}
