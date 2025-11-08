import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/whatsapp_config.dart';

/// خدمة إرسال رموز التحقق عبر الواتساب باستخدام wasenderapi
class WhatsAppOtpService {
  /// Constructor - إنشاء خدمة WhatsApp OTP
  WhatsAppOtpService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: _baseUrl,
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 30),
                headers: {
                  'Authorization': 'Bearer $_apiKey',
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ) {
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
    }
  }
  static const String _baseUrl = WhatsAppConfig.baseUrl;
  static const String _apiKey = WhatsAppConfig.apiKey;

  final Dio _dio;

  /// توليد رمز OTP عشوائي مكون من 6 أرقام
  String generateOtp() {
    final random = Random.secure();
    final otp = (random.nextInt(900000) + 100000).toString();
    return otp;
  }

  /// إرسال رمز OTP عبر الواتساب
  ///
  /// [phone] رقم الهاتف بصيغة E.164 (مثال: +967777123456)
  /// [otp] رمز التحقق المكون من 6 أرقام
  ///
  /// Returns: true إذا تم الإرسال بنجاح، false إذا فشل
  Future<WhatsAppOtpResponse> sendOtp({required String phone, required String otp, String? recipientName}) async {
    try {
      // تنسيق رقم الهاتف
      final formattedPhone = _formatPhoneNumber(phone);

      // إنشاء رسالة مخصصة
      final message = _buildOtpMessage(otp, recipientName);

      if (kDebugMode) {
        print('📱 إرسال OTP عبر الواتساب إلى: $formattedPhone');
        print('📝 الرسالة: $message');
      }

      // إرسال الطلب إلى wasenderapi
      final response = await _dio.post<Map<String, dynamic>>(
        '/send',
        data: {'phone': formattedPhone, 'message': message},
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('✅ تم إرسال رمز التحقق بنجاح');
        }
        return WhatsAppOtpResponse(success: true, message: 'تم إرسال رمز التحقق إلى واتساب', data: response.data);
      } else {
        if (kDebugMode) {
          print('❌ فشل إرسال رمز التحقق: ${response.statusCode}');
        }
        return WhatsAppOtpResponse(
          success: false,
          message: 'فشل إرسال رمز التحقق',
          error: 'HTTP ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ خطأ في الاتصال بـ wasenderapi: ${e.message}');
      }
      return WhatsAppOtpResponse(success: false, message: _handleDioError(e), error: e.toString());
    } catch (e) {
      if (kDebugMode) {
        print('❌ خطأ غير متوقع: $e');
      }
      return WhatsAppOtpResponse(success: false, message: 'حدث خطأ غير متوقع', error: e.toString());
    }
  }

  /// إرسال OTP مع توليده تلقائياً
  Future<WhatsAppOtpResult> sendOtpWithGeneration({required String phone, String? recipientName}) async {
    final otp = generateOtp();
    final response = await sendOtp(phone: phone, otp: otp, recipientName: recipientName);

    return WhatsAppOtpResult(response: response, generatedOtp: otp);
  }

  /// بناء رسالة OTP مخصصة وجميلة
  String _buildOtpMessage(String otp, String? recipientName) {
    return WhatsAppConfig.getOtpMessageTemplate(otp: otp, recipientName: recipientName);
  }

  /// تنسيق رقم الهاتف إلى صيغة E.164
  String _formatPhoneNumber(String phone) {
    return WhatsAppConfig.formatPhoneToE164(phone);
  }

  /// معالجة أخطاء Dio
  String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'انتهت مهلة الاتصال، يرجى المحاولة مرة أخرى';

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) {
          return 'خطأ في مفتاح API، يرجى التحقق من الإعدادات';
        } else if (statusCode == 429) {
          return 'تم تجاوز حد الطلبات، يرجى الانتظار قليلاً';
        } else if (statusCode == 400) {
          return 'رقم الهاتف غير صالح أو البيانات غير صحيحة';
        }
        return 'فشل إرسال رمز التحقق (خطأ $statusCode)';

      case DioExceptionType.cancel:
        return 'تم إلغاء الطلب';

      case DioExceptionType.badCertificate:
        return 'خطأ في شهادة الأمان، يرجى التحقق من الاتصال';

      case DioExceptionType.unknown:
        if (error.message?.contains('SocketException') ?? false) {
          return 'لا يوجد اتصال بالإنترنت';
        }
        return 'حدث خطأ في الاتصال';

      default:
        return 'حدث خطأ غير متوقع';
    }
  }

  /// التحقق من حالة API (للاختبار)
  Future<bool> checkApiStatus() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/status');
      return response.statusCode == 200;
    } on Exception catch (e) {
      if (kDebugMode) {
        print('❌ فشل التحقق من حالة API: $e');
      }
      return false;
    }
  }

  /// إرسال رسالة مخصصة عبر الواتساب (للاستخدامات الأخرى)
  Future<WhatsAppOtpResponse> sendCustomMessage({required String phone, required String message}) async {
    try {
      final formattedPhone = _formatPhoneNumber(phone);

      final response = await _dio.post<Map<String, dynamic>>(
        '/send',
        data: {'phone': formattedPhone, 'message': message},
      );

      if (response.statusCode == 200) {
        return WhatsAppOtpResponse(success: true, message: 'تم إرسال الرسالة بنجاح', data: response.data);
      } else {
        return WhatsAppOtpResponse(success: false, message: 'فشل إرسال الرسالة', error: 'HTTP ${response.statusCode}');
      }
    } on Exception catch (e) {
      return WhatsAppOtpResponse(success: false, message: 'حدث خطأ أثناء إرسال الرسالة', error: e.toString());
    }
  }
}

/// نموذج الاستجابة من خدمة WhatsApp OTP
class WhatsAppOtpResponse {
  /// Constructor
  WhatsAppOtpResponse({required this.success, required this.message, this.data, this.error});

  final bool success;
  final String message;
  final dynamic data;
  final String? error;

  @override
  String toString() {
    return 'WhatsAppOtpResponse(success: $success, message: $message, error: $error)';
  }
}

/// نموذج نتيجة إرسال OTP مع الرمز المولد
class WhatsAppOtpResult {
  /// Constructor
  WhatsAppOtpResult({required this.response, required this.generatedOtp});

  final WhatsAppOtpResponse response;
  final String generatedOtp;

  bool get success => response.success;
  String get message => response.message;
  String get otp => generatedOtp;
}
