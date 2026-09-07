import 'package:dio/dio.dart';
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
    String versionApp = '1.0.0',
    String language = 'in',
  }) async {
    try {
      final formData = FormData.fromMap({
        'unim': BniEncryption.hashData(nim, AppConstants.cidV2, AppConstants.secretKeyV2),
        'upassword': BniEncryption.hashData(password, AppConstants.cidV2, AppConstants.secretKeyV2),
        'deviceid': BniEncryption.hashData(deviceId, AppConstants.cidV2, AppConstants.secretKeyV2),
        'devicename': BniEncryption.hashData(deviceName, AppConstants.cidV2, AppConstants.secretKeyV2),
        'resyncrondevice': BniEncryption.hashData(resyncronDevice, AppConstants.cidV2, AppConstants.secretKeyV2),
        'tokennotif': BniEncryption.hashData(tokenNotif, AppConstants.cidV2, AppConstants.secretKeyV2),
        'versionapp': BniEncryption.hashData(versionApp, AppConstants.cidV2, AppConstants.secretKeyV2),
        'language': language,
      });

      final response = await _dio.post('Authservices/authenticationmhs', data: formData);
      
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

  Future<LoginData?> refreshSession({
    required String nim,
    required String deviceId,
    String tokenNotif = 'undefined',
    String versionApp = '1.0.0',
  }) async {
    try {
      final formData = FormData.fromMap({
        'unim': BniEncryption.hashData(nim, AppConstants.cidV2, AppConstants.secretKeyV2),
        'deviceid': BniEncryption.hashData(deviceId, AppConstants.cidV2, AppConstants.secretKeyV2),
        'tokennotif': BniEncryption.hashData(tokenNotif, AppConstants.cidV2, AppConstants.secretKeyV2),
        'versionapp': BniEncryption.hashData(versionApp, AppConstants.cidV2, AppConstants.secretKeyV2),
      });

      final response = await _dio.post('Authservices/refreshdata', data: formData);
      
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
