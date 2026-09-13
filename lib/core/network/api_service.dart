import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../storage/session_manager.dart';
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
import '../../features/khs/data/models/khs_response.dart';
import '../../features/academic_history/data/models/riwayat_akademik_response.dart';
import '../utils/presence_constants.dart';
import '../../features/presence/data/models/presence_verification_response.dart';
import '../../features/presence/data/models/presence_save_response.dart';
import '../../features/attendance/data/models/attendance_courses_response.dart';
import '../../features/attendance/data/models/attendance_list_response.dart';
import '../../features/attendance/data/models/attendance_detail_response.dart';
import '../../features/news/data/models/berita_response.dart';
import '../../features/helpdesk/data/models/cs_response.dart';
import '../../features/keamanan_akun/data/models/active_device_model.dart';

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
  final _sessionManager = SessionManager();

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Authorization': AppConstants.authHeader,
          'SMART-API-KEY': AppConstants.apiKey,
        },
      ),
    );

    // Bypass SSL certificate validation (Trust All) as in the legacy project
    _dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
        return client;
      },
    );

    // Automatically inject 'language' parameter into every request
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final lang = _sessionManager.getLocale();

          if (options.method == 'GET') {
            options.queryParameters['language'] = lang;
          } else {
            // For POST/PUT/etc.
            if (options.data is Map) {
              options.data['language'] = lang;
            } else {
              options.data ??= {'language': lang};
            }
          }
          return handler.next(options);
        },
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
      ),
    );
  }

  Future<LoginResult> login({
    required String nim,
    required String password,
    required String deviceId,
    required String deviceName,
    String resyncronDevice = 'ayang',
    String tokenNotif = 'undefined',
  }) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final versionApp = packageInfo.version;

      final data = {
        'unim': BniEncryption.hashData(
          nim,
          AppConstants.cidV2,
          AppConstants.secretKeyV2,
        ),
        'upassword': BniEncryption.hashData(
          password,
          AppConstants.cidV2,
          AppConstants.secretKeyV2,
        ),
        'deviceid': BniEncryption.hashData(
          deviceId,
          AppConstants.cidV2,
          AppConstants.secretKeyV2,
        ),
        'devicename': BniEncryption.hashData(
          deviceName,
          AppConstants.cidV2,
          AppConstants.secretKeyV2,
        ),
        'resyncrondevice': BniEncryption.hashData(
          resyncronDevice,
          AppConstants.cidV2,
          AppConstants.secretKeyV2,
        ),
        'tokennotif': BniEncryption.hashData(
          tokenNotif,
          AppConstants.cidV2,
          AppConstants.secretKeyV2,
        ),
        'versionapp': BniEncryption.hashData(
          versionApp,
          AppConstants.cidV2,
          AppConstants.secretKeyV2,
        ),
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
      return LoginResult(
        success: false,
        message: 'Server error: ${response.statusCode}',
      );
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
        'unim': BniEncryption.hashData(
          nim,
          AppConstants.cidV2,
          AppConstants.secretKeyV2,
        ),
        'deviceid': BniEncryption.hashData(
          deviceId,
          AppConstants.cidV2,
          AppConstants.secretKeyV2,
        ),
        'tokennotif': BniEncryption.hashData(
          tokenNotif,
          AppConstants.cidV2,
          AppConstants.secretKeyV2,
        ),
        'versionapp': BniEncryption.hashData(
          versionApp,
          AppConstants.cidV2,
          AppConstants.secretKeyV2,
        ),
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
    String? nim,
    String? kodeJen,
    String? kodeFak,
    String? kodePst,
    int? page,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'unim': nim,
        'kodejen': kodeJen,
        'kodefak': kodeFak,
        'kodepst': kodePst,
      };
      if (page != null) {
        queryParams['page'] = page;
      }
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }

      final response = await _dio.get(
        'Pengumumanservices/pengumuman',
        queryParameters: queryParams,
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

  Future<List<BeritaResponse>> getBerita({
    required bool isRektorat,
    String? kodeFakultas,
    int page = 1,
    int perPage = 10,
    String? search,
  }) async {
    try {
      final String endpointUrl;
      final queryParams = <String, dynamic>{
        'filter[orderby]': 'date',
        'order': 'desc',
        'page': page,
        'per_page': perPage,
      };

      if (isRektorat) {
        endpointUrl = 'https://uinsalatiga.ac.id/wp-json/wp/v2/posts?_embed';
        queryParams['categories'] = '12';
      } else {
        final kode = kodeFakultas?.trim().toUpperCase();
        final String baseUrl;
        switch (kode) {
          case 'D':
            baseUrl = 'https://dakwah.uinsalatiga.ac.id/wp-json/wp/v2/';
            break;
          case 'E':
            baseUrl = 'https://febi.uinsalatiga.ac.id/wp-json/wp/v2/';
            break;
          case 'PS':
            baseUrl = 'https://pps.uinsalatiga.ac.id/wp-json/wp/v2/';
            break;
          case 'T':
            baseUrl = 'https://tarbiyah.uinsalatiga.ac.id/wp-json/wp/v2/';
            break;
          case 'U':
            baseUrl = 'https://fuadah.uinsalatiga.ac.id/wp-json/wp/v2/';
            break;
          case 'SI':
            baseUrl = 'https://saintek.uinsalatiga.ac.id/wp-json/wp/v2/';
            break;
          default:
            baseUrl = 'https://syariah.uinsalatiga.ac.id/wp-json/wp/v2/';
            break;
        }
        endpointUrl = '${baseUrl}posts?_embed';
      }

      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }

      final response = await _dio.get(
        endpointUrl,
        queryParameters: queryParams,
        options: Options(
          headers: {},
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> listData = response.data is String
            ? jsonDecode(response.data)
            : response.data;
        return listData
            .whereType<Map<String, dynamic>>()
            .map((e) => BeritaResponse.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getOtp({
    required String nim,
    required String kdpst,
    required String email,
  }) async {
    try {
      final data = {
        'unim': BniEncryption.hashData(
          nim,
          AppConstants.cid,
          AppConstants.secretKey,
        ),
        'kode_pst': BniEncryption.hashData(
          kdpst,
          AppConstants.cid,
          AppConstants.secretKey,
        ),
        'uemail': BniEncryption.hashData(
          email,
          AppConstants.cid,
          AppConstants.secretKey,
        ),
      };

      final response = await _dio.post(
        '${AppConstants.baseUrlLegacy}create_otp_verif_email',
        data: data,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.statusCode == 200) {
        return response.data is String
            ? jsonDecode(response.data)
            : response.data;
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
    String? ganti,
  }) async {
    try {
      final data = {
        'unim': BniEncryption.hashData(
          nim,
          AppConstants.cid,
          AppConstants.secretKey,
        ),
        'kode_pst': BniEncryption.hashData(
          kdpst,
          AppConstants.cid,
          AppConstants.secretKey,
        ),
        'uemail': BniEncryption.hashData(
          email,
          AppConstants.cid,
          AppConstants.secretKey,
        ),
        'otp': BniEncryption.hashData(
          otp,
          AppConstants.cid,
          AppConstants.secretKey,
        ),
        if (ganti != null) 'ganti': ganti,
      };

      final response = await _dio.post(
        '${AppConstants.baseUrlLegacy}verif_email_mhs',
        data: data,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.statusCode == 200) {
        return response.data is String
            ? jsonDecode(response.data)
            : response.data;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getOtpResetPassword({
    required String nim,
    required String email,
  }) async {
    try {
      final data = {
        'unim': BniEncryption.hashData(
          nim,
          AppConstants.cidV2,
          AppConstants.secretKeyV2,
        ),
        'uemail': BniEncryption.hashData(
          email,
          AppConstants.cidV2,
          AppConstants.secretKeyV2,
        ),
      };

      final response = await _dio.post(
        'Managerpassword/create_otp_reset_password',
        data: data,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.statusCode == 200) {
        return response.data is String
            ? jsonDecode(response.data)
            : response.data;
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
  }) async {
    try {
      final data = {
        'unim': BniEncryption.hashData(
          nim,
          AppConstants.cidV2,
          AppConstants.secretKeyV2,
        ),
        'uemail': BniEncryption.hashData(
          email,
          AppConstants.cidV2,
          AppConstants.secretKeyV2,
        ),
        'otp': BniEncryption.hashData(
          otp,
          AppConstants.cidV2,
          AppConstants.secretKeyV2,
        ),
      };

      final response = await _dio.post(
        'Managerpassword/verif_otp_reset_password_mhs',
        data: data,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data is String
            ? jsonDecode(response.data)
            : response.data;
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
  }) async {
    try {
      final data = {
        'encnim': encNim,
        'uemail': BniEncryption.hashData(
          email,
          AppConstants.cidV2,
          AppConstants.secretKeyV2,
        ),
        'otp': BniEncryption.hashData(
          otp,
          AppConstants.cidV2,
          AppConstants.secretKeyV2,
        ),
        'encnewpassword': BniEncryption.hashData(
          newPassword,
          AppConstants.cidV2,
          AppConstants.secretKeyV2,
        ),
      };

      final response = await _dio.post(
        'Managerpassword/change_password_mhs',
        data: data,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data is String
            ? jsonDecode(response.data)
            : response.data;
        return ChangePasswordResponse.fromJson(responseData);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<ChangePasswordResponse?> changePasswordUseOldPass({
    required String nim,
    required String oldPassword,
    required String newPassword,
    required String email,
    required String language,
  }) async {
    try {
      final data = {
        'encnim': BniEncryption.hashData(
          nim,
          AppConstants.cidV2,
          AppConstants.secretKeyV2,
        ),
        'encoldpassword': BniEncryption.hashData(
          oldPassword,
          AppConstants.cidV2,
          AppConstants.secretKeyV2,
        ),
        'encnewpassword': BniEncryption.hashData(
          newPassword,
          AppConstants.cidV2,
          AppConstants.secretKeyV2,
        ),
        'uemail': BniEncryption.hashData(
          email,
          AppConstants.cidV2,
          AppConstants.secretKeyV2,
        ),
        'language': language,
      };

      final response = await _dio.post(
        'Managerpassword/change_password_mhs_use_old_password',
        data: data,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data is String
            ? jsonDecode(response.data)
            : response.data;
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
  }) async {
    try {
      final data = {
        'unim': BniEncryption.hashData(
          nim,
          AppConstants.cidV2,
          AppConstants.secretKeyV2,
        ),
        'selected_semester': BniEncryption.hashData(
          semester.toString(),
          AppConstants.cidV2,
          AppConstants.secretKeyV2,
        ),
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

  /// Uniform failure description for API calls — used by page-level catch
  /// blocks to decide the error state:
  /// - network/timeout failure -> null (UI shows the localized no-internet state)
  /// - HTTP error (4xx/5xx)    -> "Error {code}" (e.g. "Error 500")
  /// - anything else           -> "error {cause}" (same shape as legacy EDOM)
  static String? describeFailure(Object e) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return null;
        case DioExceptionType.badResponse:
          final code = e.response?.statusCode;
          return code == null ? 'error ${e.message}' : 'Error $code';
        default:
          return 'error ${e.message}';
      }
    }
    return 'error $e';
  }

  /// POST {legacy}/tagihanmhs — plain params (no encryption), NO language field (same as legacy).
  /// A RETURNED response means the API answered (status + message come from
  /// the server); API-level failures (network / HTTP error / bad payload)
  /// THROW — callers describe them via `ApiService.describeFailure`.
  Future<TuitionBillResponse> getTuitionBills({
    required String nim,
    required String kdjen,
    required String kdpst,
  }) async {
    final data = {'unim': nimDigits(nim), 'kdjen': kdjen, 'kdpst': kdpst};

    final response = await _dio.post(
      '${AppConstants.baseUrlLegacy}tagihanmhs',
      data: data,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    final Map<String, dynamic> responseData = response.data is String
        ? jsonDecode(response.data)
        : response.data;
    return TuitionBillResponse.fromJson(responseData);
  }

  /// POST {legacy}/rekappembayaran — plain params (no encryption), NO language field (same as legacy).
  /// A RETURNED response means the API answered; API-level failures THROW
  /// (see [getTuitionBills]).
  Future<PaymentHistoryResponse> getPaymentHistory({
    required String nim,
    required String kdjen,
    required String kdpst,
  }) async {
    final data = {'unim': nimDigits(nim), 'kdjen': kdjen, 'kdpst': kdpst};

    final response = await _dio.post(
      '${AppConstants.baseUrlLegacy}rekappembayaran',
      data: data,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    final Map<String, dynamic> responseData = response.data is String
        ? jsonDecode(response.data)
        : response.data;
    return PaymentHistoryResponse.fromJson(responseData);
  }

  /// POST {legacy}/tatacarapembayaran — plain params, WITH language field (same as legacy).
  /// A RETURNED response means the API answered; API-level failures THROW
  /// (see [getTuitionBills]).
  Future<PaymentMethodResponse> getPaymentMethods({
    required String nim,
  }) async {
    final data = {'unim': nimDigits(nim)};

    final response = await _dio.post(
      '${AppConstants.baseUrlLegacy}tatacarapembayaran',
      data: data,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    final Map<String, dynamic> responseData = response.data is String
        ? jsonDecode(response.data)
        : response.data;
    return PaymentMethodResponse.fromJson(responseData);
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
  }) async {
    try {
      final response = await _dio.get(
        'Penawaranmkservices/list_penawaran_mk',
        queryParameters: {
          'unim': BniEncryption.hashData(
            nim,
            AppConstants.cidV2,
            AppConstants.secretKeyV2,
          ),
          'kode_pst': BniEncryption.hashData(
            kdpst,
            AppConstants.cidV2,
            AppConstants.secretKeyV2,
          ),
          'kode_jen': BniEncryption.hashData(
            kdjen,
            AppConstants.cidV2,
            AppConstants.secretKeyV2,
          ),
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
  }) async {
    try {
      final response = await _dio.get(
        'Penawaranmkservices/riwayat_penawaran_mk',
        queryParameters: {
          'unim': BniEncryption.hashData(
            nim,
            AppConstants.cidV2,
            AppConstants.secretKeyV2,
          ),
          'kode_pst': BniEncryption.hashData(
            kdpst,
            AppConstants.cidV2,
            AppConstants.secretKeyV2,
          ),
          'kode_jen': BniEncryption.hashData(
            kdjen,
            AppConstants.cidV2,
            AppConstants.secretKeyV2,
          ),
          'semester': BniEncryption.hashData(
            semester.toString(),
            AppConstants.cidV2,
            AppConstants.secretKeyV2,
          ),
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
  }) async {
    try {
      final data = {
        'unim': BniEncryption.hashData(
          nim,
          AppConstants.cidV2,
          AppConstants.secretKeyV2,
        ),
        'kode_pst': BniEncryption.hashData(
          kdpst,
          AppConstants.cidV2,
          AppConstants.secretKeyV2,
        ),
        'kode_jen': BniEncryption.hashData(
          kdjen,
          AppConstants.cidV2,
          AppConstants.secretKeyV2,
        ),
        'data_input_penawaran_mk': BniEncryption.hashData(
          dataJson,
          AppConstants.cidV2,
          AppConstants.secretKeyV2,
        ),
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
  }) async {
    try {
      final response = await _dio.get(
        'krsservices/krs',
        queryParameters: {
          'unim': BniEncryption.hashData(
            nim,
            AppConstants.cidV2,
            AppConstants.secretKeyV2,
          ),
          'kdpst': BniEncryption.hashData(
            kdpst,
            AppConstants.cidV2,
            AppConstants.secretKeyV2,
          ),
          'kdjen': BniEncryption.hashData(
            kdjen,
            AppConstants.cidV2,
            AppConstants.secretKeyV2,
          ),
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
  }) async {
    try {
      final response = await _dio.get(
        'krsservices/list_krs_mk',
        queryParameters: {
          'unim': BniEncryption.hashData(
            nim,
            AppConstants.cidV2,
            AppConstants.secretKeyV2,
          ),
          'kode_pst': BniEncryption.hashData(
            kdpst,
            AppConstants.cidV2,
            AppConstants.secretKeyV2,
          ),
          'kode_jen': BniEncryption.hashData(
            kdjen,
            AppConstants.cidV2,
            AppConstants.secretKeyV2,
          ),
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
  }) async {
    try {
      final data = {
        'unim': BniEncryption.hashData(
          nim,
          AppConstants.cidV2,
          AppConstants.secretKeyV2,
        ),
        'kode_pst': BniEncryption.hashData(
          kdpst,
          AppConstants.cidV2,
          AppConstants.secretKeyV2,
        ),
        'kode_jen': BniEncryption.hashData(
          kdjen,
          AppConstants.cidV2,
          AppConstants.secretKeyV2,
        ),
        'data_input_krs_mk': BniEncryption.hashData(
          dataJson,
          AppConstants.cidV2,
          AppConstants.secretKeyV2,
        ),
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
  }) async {
    try {
      final response = await _dio.get(
        'Edomservices/list_semester_evaluasi',
        queryParameters: {
          'unim': BniEncryption.hashData(
            nim,
            AppConstants.cidV2,
            AppConstants.secretKeyV2,
          ),
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
  }) async {
    try {
      final response = await _dio.get(
        'Edomservices/list_makul_evaluasi',
        queryParameters: {
          'unim': BniEncryption.hashData(
            nim,
            AppConstants.cidV2,
            AppConstants.secretKeyV2,
          ),
          'thsms': BniEncryption.hashData(
            thsms,
            AppConstants.cidV2,
            AppConstants.secretKeyV2,
          ),
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
  }) async {
    try {
      final response = await _dio.get(
        'Edomservices/list_soal_evaluasi',
        queryParameters: {
          'ideval': BniEncryption.hashData(
            ideval,
            AppConstants.cidV2,
            AppConstants.secretKeyV2,
          ),
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
          'data': BniEncryption.hashData(
            dataJson,
            AppConstants.cidV2,
            AppConstants.secretKeyV2,
          ),
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

  // ---- KHS (khsservices/*) ----

  /// POST {APIV2}/khsservices/khs — form-urlencoded body with BNI-hashed
  /// `selected_semester` + `unim` + `kdjen` + `kdpst` and plain `language`
  /// (exact port of the legacy `ApiEndpoint.get_khs`). Response is plain
  /// JSON (no decryption).
  ///
  /// Error mapping mirrors the legacy `KhsActivity` callbacks:
  /// non-200 -> success=false + "error {code} {message}" (shown as a
  /// server-error message), connection failure -> success=false +
  /// message=null (no-internet state).
  Future<KhsResponse> getKhs({
    required int semester,
    required String nim,
    required String kdjen,
    required String kdpst,
  }) async {
    try {
      final data = {
        'selected_semester': BniEncryption.hashData(
          semester.toString(),
          AppConstants.cidV2,
          AppConstants.secretKeyV2,
        ),
        'unim': BniEncryption.hashData(
          nim,
          AppConstants.cidV2,
          AppConstants.secretKeyV2,
        ),
        'kdjen': BniEncryption.hashData(
          kdjen,
          AppConstants.cidV2,
          AppConstants.secretKeyV2,
        ),
        'kdpst': BniEncryption.hashData(
          kdpst,
          AppConstants.cidV2,
          AppConstants.secretKeyV2,
        ),
      };

      final response = await _dio.post(
        'khsservices/khs',
        data: data,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data is String
            ? jsonDecode(response.data)
            : response.data;
        return KhsResponse.fromJson(responseData);
      }
      return KhsResponse(
        success: false,
        message: 'error ${response.statusCode} ${response.statusMessage}',
        semester: semester.toString(),
      );
    } catch (e) {
      return KhsResponse(
        success: false,
        message: null,
        semester: semester.toString(),
      );
    }
  }

  /// GET {APIV2}/khsservices/riwayatakademik — BNI-hashed `unim` parameter.
  Future<RiwayatAkademikResponse> getAcademicHistory({
    required String nim,
  }) async {
    try {
      final response = await _dio.get(
        'khsservices/riwayatakademik',
        queryParameters: {
          'unim': nim,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data is String
            ? jsonDecode(response.data)
            : response.data;
        return RiwayatAkademikResponse.fromJson(responseData);
      }
      return RiwayatAkademikResponse(
        success: false,
        message: 'error ${response.statusCode} ${response.statusMessage}',
      );
    } catch (e) {
      return RiwayatAkademikResponse(
        success: false,
        message: 'error ${e is DioException ? e.message : e}',
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
            options: Options(
              headers: const {'Authorization': AppConstants.authHeader},
            ),
            onReceiveProgress: onReceiveProgress,
          );
          savedPath = target;
        } catch (_) {
          savedPath =
              null; // scoped storage / permission denied -> fallback below
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

  /// Verify presence via QR Code
  Future<PresenceVerificationResponse> verifyPresenceQr({
    required String nim,
    required String qrKey,
    required String language,
  }) async {
    try {
      final response = await _dio.post(
        '${PresenceConstants.baseUrl}smartabsensimhs_get_qrdpkloc',
        data: FormData.fromMap({
          'unim': nim,
          'qrkey': qrKey,
          'language': language,
        }),
        options: Options(
          headers: {
            'Authorization': PresenceConstants.authHeader,
            'SIMONA-API-KEY': PresenceConstants.simonaApiKey,
          },
        ),
      );

      if (response.data is Map<String, dynamic>) {
        return PresenceVerificationResponse.fromJson(response.data);
      } else if (response.data is String) {
        final decoded = json.decode(response.data);
        return PresenceVerificationResponse.fromJson(decoded);
      }
      return PresenceVerificationResponse(
        success: false,
        message: 'Format respon tidak sesuai',
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ??
          e.message ??
          'Terjadi kesalahan koneksi';
      return PresenceVerificationResponse(success: false, message: msg);
    } catch (e) {
      return PresenceVerificationResponse(success: false, message: e.toString());
    }
  }

  /// Verify presence via Short Code
  Future<PresenceVerificationResponse> verifyPresenceShortCode({
    required String nim,
    required String shortCode,
    required String language,
  }) async {
    try {
      final response = await _dio.post(
        '${PresenceConstants.baseUrl}smartabsensimhs_get_scdpkloc',
        data: FormData.fromMap({
          'unim': nim,
          'shortcode': shortCode,
          'language': language,
        }),
        options: Options(
          headers: {
            'Authorization': PresenceConstants.authHeader,
            'SIMONA-API-KEY': PresenceConstants.simonaApiKey,
          },
        ),
      );

      if (response.data is Map<String, dynamic>) {
        return PresenceVerificationResponse.fromJson(response.data);
      } else if (response.data is String) {
        final decoded = json.decode(response.data);
        return PresenceVerificationResponse.fromJson(decoded);
      }
      return PresenceVerificationResponse(
        success: false,
        message: 'Format respon tidak sesuai',
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ??
          e.message ??
          'Terjadi kesalahan koneksi';
      return PresenceVerificationResponse(success: false, message: msg);
    } catch (e) {
      return PresenceVerificationResponse(success: false, message: e.toString());
    }
  }

  /// Save attendance presence
  Future<PresenceSaveResponse> savePresence({
    required String nim,
    required String idAbsensi,
    required String pertemuanKe,
    required String idDevice,
    String fakeLoc = 'false',
  }) async {
    try {
      final response = await _dio.post(
        '${PresenceConstants.baseUrl}smartabsensimhs_saveabsloc',
        data: FormData.fromMap({
          'unim': nim,
          'idabsensi': idAbsensi,
          'pertemuanke': pertemuanKe,
          'iddevice': idDevice,
          'fakeloc': fakeLoc,
        }),
        options: Options(
          headers: {
            'Authorization': PresenceConstants.authHeader,
            'SIMONA-API-KEY': PresenceConstants.simonaApiKey,
          },
        ),
      );

      if (response.data is Map<String, dynamic>) {
        return PresenceSaveResponse.fromJson(response.data);
      } else if (response.data is String) {
        final decoded = json.decode(response.data);
        return PresenceSaveResponse.fromJson(decoded);
      }
      return PresenceSaveResponse(
        success: false,
        message: 'Format respon tidak sesuai',
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ??
          e.message ??
          'Terjadi kesalahan koneksi';
      return PresenceSaveResponse(success: false, message: msg);
    } catch (e) {
      return PresenceSaveResponse(success: false, message: e.toString());
    }
  }

  /// Get list of courses for attendance history
  Future<AttendanceCoursesResponse> getAttendanceCourses({
    required String nim,
    required String language,
  }) async {
    try {
      final response = await _dio.post(
        '${PresenceConstants.baseUrl}list_all_makul_absensi',
        data: FormData.fromMap({
          'unim': nim,
          'language': language,
        }),
        options: Options(
          headers: {
            'Authorization': PresenceConstants.authHeader,
            'SIMONA-API-KEY': PresenceConstants.simonaApiKey,
          },
        ),
      );

      if (response.data is Map<String, dynamic>) {
        return AttendanceCoursesResponse.fromJson(response.data);
      } else if (response.data is String) {
        final decoded = json.decode(response.data);
        return AttendanceCoursesResponse.fromJson(decoded);
      }
      return AttendanceCoursesResponse(
        success: false,
        message: 'Format respon tidak sesuai',
        data: [],
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ??
          e.message ??
          'Terjadi kesalahan koneksi';
      return AttendanceCoursesResponse(success: false, message: msg, data: []);
    } catch (e) {
      return AttendanceCoursesResponse(success: false, message: e.toString(), data: []);
    }
  }

  /// Get attendance history list for a specific course
  Future<AttendanceListResponse> getAttendanceListPerCourse({
    required String nim,
    required int semester,
    required String idAbsensi,
    required String kodeMk,
    required String language,
  }) async {
    try {
      final response = await _dio.post(
        '${PresenceConstants.baseUrl}rekap_kehadiran_mhs',
        data: FormData.fromMap({
          'unim': nim,
          'semester': semester,
          'idabsensi': idAbsensi,
          'kode_makul': kodeMk,
          'language': language,
        }),
        options: Options(
          headers: {
            'Authorization': PresenceConstants.authHeader,
            'SIMONA-API-KEY': PresenceConstants.simonaApiKey,
          },
        ),
      );

      if (response.data is Map<String, dynamic>) {
        return AttendanceListResponse.fromJson(response.data);
      } else if (response.data is String) {
        final decoded = json.decode(response.data);
        return AttendanceListResponse.fromJson(decoded);
      }
      return AttendanceListResponse(
        success: false,
        message: 'Format respon tidak sesuai',
        data: [],
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ??
          e.message ??
          'Terjadi kesalahan koneksi';
      return AttendanceListResponse(success: false, message: msg, data: []);
    } catch (e) {
      return AttendanceListResponse(success: false, message: e.toString(), data: []);
    }
  }

  /// Get meeting detail including uploaded lecture materials
  Future<AttendanceDetailResponse> getAttendanceDetailMeeting({
    required String nim,
    required int semester,
    required String idAbsensi,
    required String kodeMk,
    required int pertemuanKe,
    required String language,
  }) async {
    try {
      final response = await _dio.post(
        '${PresenceConstants.baseUrl}detail_absensi',
        data: FormData.fromMap({
          'unim': nim,
          'semester': semester,
          'idabsensi': idAbsensi,
          'kode_makul': kodeMk,
          'pertemuanke': pertemuanKe,
          'language': language,
        }),
        options: Options(
          headers: {
            'Authorization': PresenceConstants.authHeader,
            'SIMONA-API-KEY': PresenceConstants.simonaApiKey,
          },
        ),
      );

      if (response.data is Map<String, dynamic>) {
        return AttendanceDetailResponse.fromJson(response.data);
      } else if (response.data is String) {
        final decoded = json.decode(response.data);
        return AttendanceDetailResponse.fromJson(decoded);
      }
      return AttendanceDetailResponse(
        success: false,
        message: 'Format respon tidak sesuai',
        data: null,
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ??
          e.message ??
          'Terjadi kesalahan koneksi';
      return AttendanceDetailResponse(success: false, message: msg, data: null);
    } catch (e) {
      return AttendanceDetailResponse(success: false, message: e.toString(), data: null);
    }
  }

  /// Download a lecture material file with progress tracking
  Future<String> downloadMaterialFile({
    required String url,
    required String fileName,
    void Function(int received, int total)? onReceiveProgress,
  }) async {
    final cleanUrl = Uri.decodeFull(url.replaceAll('\\/', '/'));
    String? savedPath;

    if (Platform.isAndroid) {
      final publicDownloadDir = Directory('/storage/emulated/0/Download');
      if (await publicDownloadDir.exists()) {
        final target = '${publicDownloadDir.path}/$fileName';
        try {
          await _dio.download(
            cleanUrl,
            target,
            onReceiveProgress: onReceiveProgress,
          );
          savedPath = target;
        } catch (_) {
          savedPath = null;
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

  /// Get list of Customer Service / Helpdesk officers
  Future<CsResponse> getCsList({
    required String kodeFak,
    required String kodePst,
    String? language,
  }) async {
    try {
      final response = await _dio.get(
        'Csservices/cs',
        queryParameters: {
          'kode_fak': kodeFak,
          'kode_pst': kodePst,
          if (language != null) 'language': language,
        },
      );

      if (response.data is Map<String, dynamic>) {
        return CsResponse.fromJson(response.data);
      } else if (response.data is String) {
        final decoded = json.decode(response.data);
        return CsResponse.fromJson(decoded);
      }
      return _getFallbackCsResponse('Format respon tidak sesuai');
    } catch (e) {
      return _getFallbackCsResponse('Terjadi kendala jaringan');
    }
  }

  CsResponse _getFallbackCsResponse(String message) {
    return CsResponse(
      success: true,
      message: message,
      data: [
        CsDetail(
          nowa: '+6285643008884',
          namaadmin: 'Maulana Ayub',
          linkimageprofil:
              'https://akademik2.uinsalatiga.ac.id/media/images/logosmartmobilemhs/fotodeveloper1by1.JPG',
          namabagian: 'Teknologi Informasi & Pangkalan Data',
          jamoperasional: '09.00 - 15.00',
          layanan: 'Kendala Teknis Aplikasi (error bug)',
          online: false,
          keteranganhari: 'ok jam kerja',
        ),
      ],
    );
  }

  /// Get all active other devices for the logged in user
  Future<ActiveDevicesResponse> getAllActiveDevices({
    required String nim,
    required String deviceId,
  }) async {
    try {
      final response = await _dio.get(
        'Authservices/get_all_perangkat_user_aktif',
        queryParameters: {
          'unim': nim,
          'deviceid': deviceId,
        },
      );

      final Map<String, dynamic> responseData = response.data is String
          ? jsonDecode(response.data)
          : (response.data as Map<String, dynamic>);

      return ActiveDevicesResponse.fromJson(responseData);
    } catch (e) {
      return ActiveDevicesResponse(
        success: false,
        message: 'Gagal memuat perangkat aktif: $e',
        devices: [],
      );
    }
  }

  /// Force logout user account from a specific target device
  Future<Map<String, dynamic>> forceLogoutDevice({
    required String nim,
    required String targetDeviceId,
  }) async {
    try {
      final response = await _dio.post(
        'Authservices/keluarkan_akun_dari_perangkat',
        data: {
          'unim': nim,
          'deviceid': targetDeviceId,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      final Map<String, dynamic> responseData = response.data is String
          ? jsonDecode(response.data)
          : (response.data as Map<String, dynamic>);

      return responseData;
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal mengeluarkan akun dari perangkat: $e',
      };
    }
  }

  /// Upload Foto Profil Mahasiswa ke SI-MONA
  Future<Map<String, dynamic>> uploadProfilePhoto({
    required String nim,
    required String angkatan,
    required String imageBase64,
  }) async {
    try {
      final uploadDio = Dio(
        BaseOptions(
          baseUrl: 'https://si-mona.uinsalatiga.ac.id/user_log/',
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final response = await uploadDio.post(
        'upload_fp_pribadi',
        data: {
          'nim': nim,
          'angkatan': angkatan,
          'image': imageBase64,
        },
        options: Options(
          headers: {
            'Authorization':
                'Basic bWFzYXl1Ymt1eWFuZ2dhbnRlbmc6aXppbnVwbG9hZGZvdG8=',
          },
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      final Map<String, dynamic> responseData = response.data is String
          ? jsonDecode(response.data)
          : (response.data as Map<String, dynamic>);

      return responseData;
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal mengunggah foto profil: $e',
      };
    }
  }
}

