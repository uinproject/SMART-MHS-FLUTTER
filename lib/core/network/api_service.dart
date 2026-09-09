import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/app_constants.dart';
import '../security/bni_encryption.dart';
import '../../features/auth/data/models/api_responses.dart';
import '../../features/auth/data/models/login_data.dart';
import '../../features/home/data/models/pengumuman_response.dart';
import '../../features/home/data/models/jadwal_response.dart';
import '../../features/bills/data/models/tuition_bill_response.dart';
import '../../features/bills/data/models/payment_history_response.dart';
import '../../features/bills/data/models/payment_method_response.dart';
import '../../features/offers/data/models/penawaran_response.dart';
import '../../features/krs/data/models/krs_response.dart';
import '../../features/krs/data/models/krs_list_response.dart';
import '../../features/edom/data/models/edom_semester_response.dart';
import '../../features/edom/data/models/edom_makul_response.dart';
import '../../features/edom/data/models/edom_soal_response.dart';
import '../../features/edom/data/models/edom_post_models.dart';

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

  /// digits-only NIM, same as legacy: `nim?.filter { it.isDigit() }`
  static String nimDigits(String nim) => nim.replaceAll(RegExp(r'\D'), '');

  /// POST {legacy}/tagihanmhs — plain params (no encryption), NO language field (same as legacy).
  /// Non-200 -> success=false + message "error {code}" (same as legacy).
  /// Connection failure -> success=false + message=null (UI shows no-internet state, same as legacy).
  Future<TuitionBillResponse> getTuitionBills({
    required String nim,
    required String kdjen,
    required String kdpst,
  }) async {
    try {
      final data = {
        'unim': nimDigits(nim),
        'kdjen': kdjen,
        'kdpst': kdpst,
      };

      final response = await _dio.post(
        '${AppConstants.baseUrlLegacy}tagihanmhs',
        data: data,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data is String
            ? jsonDecode(response.data)
            : response.data;
        return TuitionBillResponse.fromJson(responseData);
      }
      return TuitionBillResponse(
        success: false,
        message: 'error ${response.statusCode} ${response.statusMessage}',
        data: const [],
      );
    } catch (e) {
      return TuitionBillResponse(success: false, message: null, data: const []);
    }
  }

  /// POST {legacy}/rekappembayaran — plain params (no encryption), NO language field (same as legacy).
  Future<PaymentHistoryResponse> getPaymentHistory({
    required String nim,
    required String kdjen,
    required String kdpst,
  }) async {
    try {
      final data = {
        'unim': nimDigits(nim),
        'kdjen': kdjen,
        'kdpst': kdpst,
      };

      final response = await _dio.post(
        '${AppConstants.baseUrlLegacy}rekappembayaran',
        data: data,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data is String
            ? jsonDecode(response.data)
            : response.data;
        return PaymentHistoryResponse.fromJson(responseData);
      }
      return PaymentHistoryResponse(
        success: false,
        message: 'error ${response.statusCode} ${response.statusMessage}',
        data: const [],
      );
    } catch (e) {
      return PaymentHistoryResponse(success: false, message: null, data: const []);
    }
  }

  /// POST {legacy}/tatacarapembayaran — plain params, WITH language field (same as legacy).
  Future<PaymentMethodResponse> getPaymentMethods({
    required String nim,
    String language = 'in',
  }) async {
    try {
      final data = {
        'unim': nimDigits(nim),
        'language': language,
      };

      final response = await _dio.post(
        '${AppConstants.baseUrlLegacy}tatacarapembayaran',
        data: data,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data is String
            ? jsonDecode(response.data)
            : response.data;
        return PaymentMethodResponse.fromJson(responseData);
      }
      return PaymentMethodResponse(
        success: false,
        message: 'error ${response.statusCode} ${response.statusMessage}',
        data: const [],
      );
    } catch (e) {
      return PaymentMethodResponse(success: false, message: null, data: const []);
    }
  }

  /// GET {APIV2}/Penawaranmkservices/list_penawaran_mk — BNI-hashed query
  /// params (unim, kode_pst, kode_jen) + plain `language`; plain JSON response.
  /// NIM is hashed AS-IS (no digits-only filtering, same as legacy PMK).
  /// Non-200 -> success=false + "error {code}" (same as legacy).
  /// Connection failure -> success=false + message=null (no-internet state).
  Future<PenawaranListResponse> getPenawaranList({
    required String nim,
    required String kdjen,
    required String kdpst,
    String language = 'id',
  }) async {
    try {
      final response = await _dio.get(
        'Penawaranmkservices/list_penawaran_mk',
        queryParameters: {
          'unim': BniEncryption.hashData(nim, AppConstants.cidV2, AppConstants.secretKeyV2),
          'kode_pst': BniEncryption.hashData(kdpst, AppConstants.cidV2, AppConstants.secretKeyV2),
          'kode_jen': BniEncryption.hashData(kdjen, AppConstants.cidV2, AppConstants.secretKeyV2),
          'language': language,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data is String
            ? jsonDecode(response.data)
            : response.data;
        return PenawaranListResponse.fromJson(responseData);
      }
      return PenawaranListResponse(
        success: false,
        message: 'error ${response.statusCode} ${response.statusMessage}',
      );
    } catch (e) {
      return PenawaranListResponse(success: false, message: null);
    }
  }

  /// GET {APIV2}/Penawaranmkservices/riwayat_penawaran_mk — BNI-hashed query
  /// params (unim, kode_pst, kode_jen, semester) + plain `language`.
  Future<PenawaranRiwayatResponse> getPenawaranRiwayat({
    required String nim,
    required String kdjen,
    required String kdpst,
    required int semester,
    String language = 'id',
  }) async {
    try {
      final response = await _dio.get(
        'Penawaranmkservices/riwayat_penawaran_mk',
        queryParameters: {
          'unim': BniEncryption.hashData(nim, AppConstants.cidV2, AppConstants.secretKeyV2),
          'kode_pst': BniEncryption.hashData(kdpst, AppConstants.cidV2, AppConstants.secretKeyV2),
          'kode_jen': BniEncryption.hashData(kdjen, AppConstants.cidV2, AppConstants.secretKeyV2),
          'semester': BniEncryption.hashData(semester.toString(), AppConstants.cidV2, AppConstants.secretKeyV2),
          'language': language,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data is String
            ? jsonDecode(response.data)
            : response.data;
        return PenawaranRiwayatResponse.fromJson(responseData);
      }
      return PenawaranRiwayatResponse(
        success: false,
        message: 'error ${response.statusCode} ${response.statusMessage}',
      );
    } catch (e) {
      return PenawaranRiwayatResponse(success: false, message: null);
    }
  }

  /// POST {APIV2}/Penawaranmkservices/input_penawaran_mata_kuliah —
  /// form-urlencoded with BNI-hashed fields (unim, kode_pst, kode_jen,
  /// data_input_penawaran_mk = hash of the JSON array
  /// `[{"kode_mk":"...","sks_mk":n}]`) + plain `language`.
  /// Legacy always surfaces a failure message, so connection errors map to
  /// "error ..." instead of null.
  Future<PenawaranPostResponse> submitPenawaran({
    required String nim,
    required String kdjen,
    required String kdpst,
    required String dataJson,
    String language = 'id',
  }) async {
    try {
      final data = {
        'unim': BniEncryption.hashData(nim, AppConstants.cidV2, AppConstants.secretKeyV2),
        'kode_pst': BniEncryption.hashData(kdpst, AppConstants.cidV2, AppConstants.secretKeyV2),
        'kode_jen': BniEncryption.hashData(kdjen, AppConstants.cidV2, AppConstants.secretKeyV2),
        'data_input_penawaran_mk': BniEncryption.hashData(dataJson, AppConstants.cidV2, AppConstants.secretKeyV2),
        'language': language,
      };

      final response = await _dio.post(
        'Penawaranmkservices/input_penawaran_mata_kuliah',
        data: data,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data is String
            ? jsonDecode(response.data)
            : response.data;
        return PenawaranPostResponse.fromJson(responseData);
      }
      return PenawaranPostResponse(
        success: false,
        message: 'error ${response.statusCode} ${response.statusMessage}',
      );
    } catch (e) {
      return PenawaranPostResponse(
        success: false,
        message: 'error ${e is DioException ? e.message : e}',
      );
    }
  }

  /// GET {APIV2}/krsservices/krs — BNI-hashed query params
  /// (`unim`, **`kdpst`**, **`kdjen`** — NOTE the short names, unlike the
  /// list/input endpoints) + plain `language`; plain JSON response.
  /// NIM is hashed AS-IS (legacy KRS does not digits-filter the NIM).
  /// Non-200 -> success=false + "error {code}"; connection failure ->
  /// success=false + message=null (no-internet state).
  Future<KrsResponse> getKrs({
    required String nim,
    required String kdjen,
    required String kdpst,
    String language = 'id',
  }) async {
    try {
      final response = await _dio.get(
        'krsservices/krs',
        queryParameters: {
          'unim': BniEncryption.hashData(nim, AppConstants.cidV2, AppConstants.secretKeyV2),
          'kdpst': BniEncryption.hashData(kdpst, AppConstants.cidV2, AppConstants.secretKeyV2),
          'kdjen': BniEncryption.hashData(kdjen, AppConstants.cidV2, AppConstants.secretKeyV2),
          'language': language,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data is String
            ? jsonDecode(response.data)
            : response.data;
        return KrsResponse.fromJson(responseData);
      }
      return KrsResponse(
        success: false,
        message: 'error ${response.statusCode} ${response.statusMessage}',
      );
    } catch (e) {
      return KrsResponse(success: false, message: null);
    }
  }

  /// GET {APIV2}/krsservices/list_krs_mk — BNI-hashed query params
  /// (`unim`, **`kode_pst`**, **`kode_jen`** — long names, unlike the
  /// krs endpoint) + plain `language`; plain JSON response.
  Future<KrsListResponse> getKrsList({
    required String nim,
    required String kdjen,
    required String kdpst,
    String language = 'id',
  }) async {
    try {
      final response = await _dio.get(
        'krsservices/list_krs_mk',
        queryParameters: {
          'unim': BniEncryption.hashData(nim, AppConstants.cidV2, AppConstants.secretKeyV2),
          'kode_pst': BniEncryption.hashData(kdpst, AppConstants.cidV2, AppConstants.secretKeyV2),
          'kode_jen': BniEncryption.hashData(kdjen, AppConstants.cidV2, AppConstants.secretKeyV2),
          'language': language,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data is String
            ? jsonDecode(response.data)
            : response.data;
        return KrsListResponse.fromJson(responseData);
      }
      return KrsListResponse(
        success: false,
        message: 'error ${response.statusCode} ${response.statusMessage}',
      );
    } catch (e) {
      return KrsListResponse(success: false, message: null);
    }
  }

  /// POST {APIV2}/krsservices/input_krs_mata_kuliah — form-urlencoded with
  /// BNI-hashed fields (unim, kode_pst, kode_jen,
  /// `data_input_krs_mk` = hash of the JSON array from `KrsInputItem.toJson`)
  /// + plain `language`. Legacy always surfaces a failure message on POST,
  /// so connection errors map to "error ..." instead of null.
  Future<KrsPostResponse> submitKrs({
    required String nim,
    required String kdjen,
    required String kdpst,
    required String dataJson,
    String language = 'id',
  }) async {
    try {
      final data = {
        'unim': BniEncryption.hashData(nim, AppConstants.cidV2, AppConstants.secretKeyV2),
        'kode_pst': BniEncryption.hashData(kdpst, AppConstants.cidV2, AppConstants.secretKeyV2),
        'kode_jen': BniEncryption.hashData(kdjen, AppConstants.cidV2, AppConstants.secretKeyV2),
        'data_input_krs_mk': BniEncryption.hashData(dataJson, AppConstants.cidV2, AppConstants.secretKeyV2),
        'language': language,
      };

      final response = await _dio.post(
        'krsservices/input_krs_mata_kuliah',
        data: data,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data is String
            ? jsonDecode(response.data)
            : response.data;
        return KrsPostResponse.fromJson(responseData);
      }
      return KrsPostResponse(
        success: false,
        message: 'error ${response.statusCode} ${response.statusMessage}',
        tglInput: 'xxx',
      );
    } catch (e) {
      return KrsPostResponse(
        success: false,
        message: 'error ${e is DioException ? e.message : e}',
        tglInput: 'xxx',
      );
    }
  }

  // ---- EDOM (Edomservices/*) ----
  // ⚠️ Error mapping DIFFERS from other modules: the legacy EDOM activities
  // build `message = "error ${t.message}"` on connection failure (never
  // null), so the no-internet state never occurs — every failure surfaces
  // as a server-error message.

  /// GET {APIV2}/Edomservices/list_semester_evaluasi — BNI-hashed `unim`
  /// (NIM as-is, no digits filtering) + plain `language`.
  Future<EdomSemestersResponse> getEdomSemesters({
    required String nim,
    String language = 'id',
  }) async {
    try {
      final response = await _dio.get(
        'Edomservices/list_semester_evaluasi',
        queryParameters: {
          'unim': BniEncryption.hashData(nim, AppConstants.cidV2, AppConstants.secretKeyV2),
          'language': language,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data is String
            ? jsonDecode(response.data)
            : response.data;
        return EdomSemestersResponse.fromJson(responseData);
      }
      return EdomSemestersResponse(
        success: false,
        message: 'error ${response.statusCode} ${response.statusMessage}',
      );
    } catch (e) {
      return EdomSemestersResponse(
        success: false,
        message: 'error ${e is DioException ? e.message : e}',
      );
    }
  }

  /// GET {APIV2}/Edomservices/list_makul_evaluasi — BNI-hashed `unim` +
  /// `thsms` + plain `language`.
  Future<EdomCoursesResponse> getEdomCourses({
    required String nim,
    required String thsms,
    String language = 'id',
  }) async {
    try {
      final response = await _dio.get(
        'Edomservices/list_makul_evaluasi',
        queryParameters: {
          'unim': BniEncryption.hashData(nim, AppConstants.cidV2, AppConstants.secretKeyV2),
          'thsms': BniEncryption.hashData(thsms, AppConstants.cidV2, AppConstants.secretKeyV2),
          'language': language,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data is String
            ? jsonDecode(response.data)
            : response.data;
        return EdomCoursesResponse.fromJson(responseData);
      }
      return EdomCoursesResponse(
        success: false,
        message: 'error ${response.statusCode} ${response.statusMessage}',
      );
    } catch (e) {
      return EdomCoursesResponse(
        success: false,
        message: 'error ${e is DioException ? e.message : e}',
      );
    }
  }

  /// GET {APIV2}/Edomservices/list_soal_evaluasi — BNI-hashed `ideval` +
  /// plain `language`.
  Future<EdomQuestionsResponse> getEdomQuestions({
    required String ideval,
    String language = 'id',
  }) async {
    try {
      final response = await _dio.get(
        'Edomservices/list_soal_evaluasi',
        queryParameters: {
          'ideval': BniEncryption.hashData(ideval, AppConstants.cidV2, AppConstants.secretKeyV2),
          'language': language,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data is String
            ? jsonDecode(response.data)
            : response.data;
        return EdomQuestionsResponse.fromJson(responseData);
      }
      return EdomQuestionsResponse(
        success: false,
        message: 'error ${response.statusCode} ${response.statusMessage}',
      );
    } catch (e) {
      return EdomQuestionsResponse(
        success: false,
        message: 'error ${e is DioException ? e.message : e}',
      );
    }
  }

  /// POST {APIV2}/Edomservices/simpan_eval_dosen — ⚠️ JSON body (NOT
  /// form-urlencoded like other modules): `{"data": BNI-hash of the
  /// EdomPostData JSON}`. Legacy surfaces a fixed message when the body is
  /// null/unparseable ("Periksa koneksimu..."), so connection errors map to
  /// an "error ..." message (never success-by-default).
  Future<EdomPostResponse> submitEdomEvaluation({
    required String dataJson,
  }) async {
    try {
      final response = await _dio.post(
        'Edomservices/simpan_eval_dosen',
        data: {
          'data': BniEncryption.hashData(dataJson, AppConstants.cidV2, AppConstants.secretKeyV2),
        },
        options: Options(contentType: Headers.jsonContentType),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data is String
            ? jsonDecode(response.data)
            : response.data;
        return EdomPostResponse.fromJson(responseData);
      }
      return EdomPostResponse(
        success: false,
        message: 'error ${response.statusCode} ${response.statusMessage}',
        komentar: '',
      );
    } catch (e) {
      return EdomPostResponse(
        success: false,
        message: 'error ${e is DioException ? e.message : e}',
        komentar: '',
      );
    }
  }

  /// Download a receipt (kuitansi) PDF from the exact same URL as the legacy app
  /// (`link_kuitansi` with `\/` unescaped). Saves as
  /// `kuitansi_{nim}_semester{semester}.pdf`. On Android tries the public
  /// Download folder first (same as legacy DownloadManager), falls back to the
  /// app documents directory (also used on iOS). Returns the saved file path.
  Future<String> downloadReceipt({
    required String url,
    required String fileName,
    void Function(int received, int total)? onReceiveProgress,
  }) async {
    final cleanUrl = url.replaceAll('\\/', '/');
    String? savedPath;

    if (Platform.isAndroid) {
      final publicDownloadDir = Directory('/storage/emulated/0/Download');
      if (await publicDownloadDir.exists()) {
        final target = '${publicDownloadDir.path}/$fileName';
        try {
          await _dio.download(
            cleanUrl,
            target,
            options: Options(headers: const {'Authorization': AppConstants.authHeader}),
            onReceiveProgress: onReceiveProgress,
          );
          savedPath = target;
        } catch (_) {
          savedPath = null; // scoped storage / permission denied -> fallback below
        }
      }
    }

    if (savedPath == null) {
      final appDir = await getApplicationDocumentsDirectory();
      final target = '${appDir.path}/$fileName';
      await _dio.download(
        cleanUrl,
        target,
        onReceiveProgress: onReceiveProgress,
      );
      savedPath = target;
    }

    return savedPath;
  }
}
