import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/utils/app_constants.dart';
import '../models/ai_chat_response.dart';
import '../models/ai_feedback_response.dart';

class AiChatService {
  late final Dio _dio;

  AiChatService({String? baseUrl, String? apiKey}) {
    final effectiveBaseUrl = baseUrl ?? AppConstants.aiChatBaseUrl;
    final effectiveApiKey = apiKey ?? AppConstants.aiChatApiKey;

    _dio = Dio(
      BaseOptions(
        baseUrl: effectiveBaseUrl,
        connectTimeout: const Duration(minutes: 5), // 5 minutes timeout per requirement
        receiveTimeout: const Duration(minutes: 5), // 5 minutes timeout per requirement
        headers: {
          'X-api-key': effectiveApiKey,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Bypass SSL validation for internal/self-signed certs
    _dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
        return client;
      },
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (obj) => debugPrint('[AiChatService] $obj'),
        ),
      );
    }
  }

  /// Send user question to AI chat endpoint
  Future<AiChatResponse> sendMessage({
    required String question,
    required String sessionId,
    required String nim,
    required String nama,
    required String kodeFakultas,
    required String namaFakultas,
    required String kodeProdi,
    required String namaProdi,
  }) async {
    final body = {
      'question': question,
      'session_id': sessionId,
      'nim': nim,
      'nama': nama,
      'kode_fakultas': kodeFakultas,
      'nama_fakultas': namaFakultas,
      'kode_prodi': kodeProdi,
      'nama_prodi': namaProdi,
    };

    try {
      final response = await _dio.post(
        'chat',
        data: jsonEncode(body),
      );

      if (response.data is Map<String, dynamic>) {
        return AiChatResponse.fromJson(response.data as Map<String, dynamic>);
      } else if (response.data is String) {
        final decoded = jsonDecode(response.data as String);
        if (decoded is Map<String, dynamic>) {
          return AiChatResponse.fromJson(decoded);
        }
      }
      throw Exception('Format respon AI tidak valid');
    } on DioException catch (e) {
      debugPrint('[AiChatService] sendMessage DioException: ${e.message}');
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('Koneksi timeout. Server membutuhkan waktu terlalu lama untuk merespon.');
      }
      if (e.response?.data != null) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          throw Exception(data['message'].toString());
        }
      }
      throw Exception(e.message ?? 'Terjadi kendala saat menghubungi server AI');
    } catch (e) {
      debugPrint('[AiChatService] sendMessage Error: $e');
      rethrow;
    }
  }

  /// Send user feedback (thumbs up / down)
  Future<AiFeedbackResponse> sendFeedback({
    required int messageId,
    required bool isHelpful,
    String? comment,
  }) async {
    final body = {
      'message_id': messageId,
      'is_helpful': isHelpful,
      if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
    };

    try {
      final response = await _dio.post(
        'feedback',
        data: jsonEncode(body),
      );

      if (response.data is Map<String, dynamic>) {
        return AiFeedbackResponse.fromJson(response.data as Map<String, dynamic>);
      } else if (response.data is String) {
        final decoded = jsonDecode(response.data as String);
        if (decoded is Map<String, dynamic>) {
          return AiFeedbackResponse.fromJson(decoded);
        }
      }
      return AiFeedbackResponse(
        success: true,
        message: 'Feedback berhasil dikirim',
      );
    } on DioException catch (e) {
      debugPrint('[AiChatService] sendFeedback DioException: ${e.message}');
      if (e.response?.data != null) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          return AiFeedbackResponse(
            success: false,
            message: data['message'].toString(),
          );
        }
      }
      return AiFeedbackResponse(
        success: false,
        message: e.message ?? 'Gagal mengirim feedback',
      );
    } catch (e) {
      debugPrint('[AiChatService] sendFeedback Error: $e');
      return AiFeedbackResponse(
        success: false,
        message: e.toString(),
      );
    }
  }
}
